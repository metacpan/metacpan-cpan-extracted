package Pod::Weaver::Section::SQL;
{
  $Pod::Weaver::Section::SQL::VERSION = '0.03';
}

# ABSTRACT: Document SQL more easily by referencing only the SQL command in POD


use strict;
use warnings;

use Carp;
use List::Util 1.33 qw/any/;

use Moose;
with 'Pod::Weaver::Role::Section';
with 'Pod::Weaver::Role::Transformer';

use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Nester;
use Pod::Elemental::Transformer::Gatherer;

use SQL::Statement;

has __used_container => ( is => 'rw' );


sub transform_document {
    my ( $self, $document ) = @_;

    my $selector = s_command('sql');
    my $children = $document->children;

    # I don't know why this branch cannot be coverable, but manually my
    # tests cover both branches.
    #
    # uncoverable branch true
    # uncoverable branch false
    return unless grep { $selector->($_) } @$children;

    my $nester = Pod::Elemental::Transformer::Nester->new(
        {
            top_selector => $selector,
            content_selectors =>
              [ s_command( [qw/head2 head3 head4 over item back/] ), s_flat, ],
        }
    );

    my ($container_id) = grep {
        my $c = $children->[$_];
        $c->isa("Pod::Elemental::Element::Nested")
          and $c->command eq 'sql'
          and $c->content;
    } 0 .. $#$children;

    my $container =
      $container_id
      ? splice @{$children}, $container_id, 1
      : Pod::Elemental::Element::Nested->new(
        {
            command => 'head1',
            content => 'SQL',
        }
      );

    $self->__used_container($container);

    my $gatherer = Pod::Elemental::Transformer::Gatherer->new(
        {
            gather_selector => $selector,
            container       => $container,
        }
    );

    $nester->transform_node($document);
    $gatherer->transform_node($document);

    my @queue;
    push @queue, @{ $container->children };
    $container->children( [] );

    while ( my $node = shift @queue ) {
        if (    $node->can('command')
            and $node->command eq 'sql' )
        {
            if ( $node->can('children') ) {

                # Move up every child of sql node
                unshift @queue, @{ $node->children };
            }
            push @{ $container->children },
              Pod::Elemental::Element::Generic::Text->new(
                content => $self->format_sql( $node->content ) . "\n\n" );
        }
        else {
            push @{ $container->children }, $node;
        }
    }
}


sub weave_section {
    my ( $self, $document, $input ) = @_;

    return unless $self->__used_container;

    my $in_node = $input->{pod_document}->children;
    my @found;
    for my $i ( 0 .. $#$in_node ) {
        my $para = $in_node->[$i];
        push @found, $i
          if ( $para == $self->__used_container
            && @{ $self->__used_container->children } );
    }

    my @to_add;
    for my $i ( reverse @found ) {
        push @to_add, splice @{$in_node}, $i, 1;
    }

    push @{ $document->children }, @to_add;
}

has keywords => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
      my $parser = SQL::Parser->new( ANSI =>
        {
          RaiseError => 1,
          PrintError => 1
        }
      );
      my $stmt = SQL::Statement->new(
        'SELECT * FROM some_unknown_table',
        $parser
      );

      my @keywords = (
        keys %{$stmt->{opts}->{function_names}},
        keys %{$stmt->{opts}->{reserved_words}},
        keys %{$stmt->{opts}->{valid_commands}},
        keys %{$stmt->{opts}->{valid_comparison_operators}},
        keys %{$stmt->{opts}->{valid_data_types}}
      );
      return \@keywords;
    },
);


sub format_sql {
    my ( $self, $content ) = @_;

    if ( $content =~ m/SQL::Abstract/ ) {
        $content =~ s/\n//g;
        require SQL::Abstract;
        $content =~ s/SQL::Abstract/\$sql_abstract/;
        my $sql_abstract = SQL::Abstract->new;
        my ($stmt, @bind) = eval $content;
        if ($@) {
          croak "Trying to eval $content\n" . $@;
        }
        $content = $stmt;
    }

    my %words;
    map { $words{$_} = 1 } split ' ', $content;

    $content =~ s/C<([^>]+)>/C\[__\?:__$1__:\?__\]/g;

    my @keywords;
    if (    ref( $self->keywords )
        and ref( $self->keywords ) eq 'ARRAY' )
    {
        @keywords = @{ $self->keywords };
    }
    else {
        @keywords = split( ',', $self->keywords );
    }

    for my $word ( keys %words ) {
        if ( any { $word eq $_ } @keywords ) {
            my $new_word = $word;
            $new_word =~ s/</E\[__?:__lt__:?__\]/;
            $new_word =~ s/>/E\[__?:__gt__:?__\]/;
            $content =~ s/(^| |\n)${word}( |$)/${1}B\[__?:__${new_word}__:?__\]${2}/g;
        }
    }

    $content =~ s/\[__\?:__/</g;
    $content =~ s/__:\?__\]/>/g;
    return $content;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::SQL - Document SQL more easily by referencing only the SQL command in POD

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Update your weaver.ini file with

  [SQL]
  keywords = SELECT, INSERT, DELETE

It will then gather all B<=sql> section into one unique SQL section in your
documentation.

You can let keywords to it's default that is all known L<SQL::Statement> keywords.

=head1 METHODS

=head2 transform_document

Gathers all

  =sql

  =cut

Commands into the same Pod document node.

=head2 weave_section

Remove the section gathered in L<transform_document> from the source document.

=head2 format_sql

  my $formated = $section_sql->format_sql('SELECT toto FROM tata');

Reads and format SQL statements into Pod emphasised content.

=head1 AUTHOR

Armand Leclercq <armand.leclercq@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Armand Leclercq.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

