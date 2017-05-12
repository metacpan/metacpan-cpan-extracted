package SilkiX::Converter::Kwiki::HTMLToWiki;
BEGIN {
  $SilkiX::Converter::Kwiki::HTMLToWiki::VERSION = '0.03';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema::Page;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Silki::Formatter::HTMLToWiki';

has _wiki_link_fixer => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
    init_arg => 'wiki_link_fixer',
);

sub _handle_a {
    my $self = shift;
    my $node = shift;

    my $href = $node->attr('href');

    unless ( defined $href ) {
        $self->_handle_events_from_tree($node);
        return;
    }

    if ( $href =~ m{^/wiki/} ) {
        return $self->_handle_a_as_wiki_link( $node, $href );
    }
    elsif ( $href =~ m{index\.cgi\?(\w+)} ) {
        my $kwiki_title = $1;
        my $new_title   = $self->_wiki_link_fixer->($kwiki_title);

        return $self->_handle_a_as_wiki_link(
            $node,
            $self->_wiki->uri(
                      view => 'page/'
                    . Silki::Schema::Page->TitleToURIPath($new_title)
            ),
            $kwiki_title,
        );
    }
    elsif ( $href =~ m{/plugin/attachments/([^/]+)/([^/]+)} ) {
        my $kwiki_title = $1;
        my $filename = $2;

        my $new_title = $self->_wiki_link_fixer->($kwiki_title);

        $self->_print_to_stream(
            '{{file:' . $new_title . q{/} . $filename . '}}' );
    }
    else {
        return $self->_handle_a_as_external_link( $node, $href );
    }
}

sub _handle_a_as_wiki_link {
    my $self        = shift;
    my $node        = shift;
    my $href        = shift;
    my $kwiki_title = shift;

    if ( $href =~ m{^/wiki/([^/]+)/page/([^/]+)} ) {
        my $title = Silki::Schema::Page->URIPathToTitle($2);

        return $self->_page_link( $node, $1, $title, $kwiki_title );
    }
    elsif ( $href =~ m{^/wiki/([^/]+)/file/([^/]+)} ) {
        my $file = Silki::Schema::File->new( file_id => $2 );

        unless ($file) {
            $self->_print_to_stream( loc('(Link to non-existent file)') );
            return;
        }

        return $self->_file_link( $node, $1, $file );
    }
    else {
        return $self->_handle_a_as_external_link( $node, $href );
    }
}

sub _page_link {
    my $self        = shift;
    my $node        = shift;
    my $wiki_name   = shift;
    my $title       = shift;
    my $kwiki_title = shift;

    my $link = q{};
    if ( $wiki_name ne $self->_wiki()->short_name() ) {
        my $wiki = Silki::Schema::Wiki->new( short_name => $wiki_name );

        unless ($wiki) {
            $self->_print_to_stream(
                loc( '(Link to non-existent wiki: %1)', $wiki_name ) );
            return;
        }

        $link = $wiki->title() . q{/};
    }

    $link .= $title;

    my $child_text = $self->_text_from_node($node);

    $self->_print_to_stream( '[' . $child_text . ']' )
        unless $child_text eq $title
            || ( defined $kwiki_title && $child_text eq $kwiki_title );
    $self->_print_to_stream( '((' . $link . '))' );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Custom HTML to wiki conversion to do conversion from Kwiki

__END__
=pod

=head1 NAME

SilkiX::Converter::Kwiki::HTMLToWiki - Custom HTML to wiki conversion to do conversion from Kwiki

=head1 VERSION

version 0.03

=head1 AUTHOR

  Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0

=cut

