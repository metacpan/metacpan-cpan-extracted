package Mojolicious::Plugin::TagHelpersI18N;

# ABSTRACT: TagHelpers with I18N support

use strict;
use warnings;

use Mojolicious::Plugin::TagHelpers;

our $VERSION = 0.03;

use Mojo::Collection;
use Mojo::Util qw(deprecated xml_escape);
use Scalar::Util 'blessed';
use Unicode::Collate;

use Data::Dumper;

use parent 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $config) = @_;

    my $collate = Unicode::Collate->new;
    $app->helper( select_field => sub {
        _select_field(@_, collate => $collate )
    } );

    $config ||= {};
    $app->attr(
        translation_method => $config->{method} || 'l'
    );
}

sub _prepare {
    my ($self, $options, %attr) = @_;

    my %translated;
    my $index = 0;
    for my $option ( @{$options} ) {
        if (ref $option eq 'HASH') {
            deprecated
                'hash references are DEPRECATED in favor of Mojo::Collection objects';
            $option = Mojo::Collection->new(each %$option);
        }

        $option = [$option => $option] unless ref $option eq 'ARRAY';

        if ( !$attr{no_translation} ) {
            my $method   = $self->app->translation_method;
            $option->[0] = $self->$method( $option->[0] );
        }

        push @{ $translated{ $option->[0] } }, $index;

        $index++;
    }

    if ( $attr{sort} ) {
        my @sorted = $attr{collate}->sort( keys %translated );
        my @sorted_options = map{ @{$options}[ @{ $translated{$_} } ] }@sorted; 

        return \@sorted_options;
    }

    return $options;
}

sub _select_field {
    my ($self, $name, $options, %attrs) = (shift, shift, shift, @_);

    my %values = map { $_ => 1 } @{ $self->every_param($name) || [] };

    my %opts;
    my @fields = qw(no_translation sort collate);
    @opts{@fields} = delete @attrs{@fields};

    $options = _prepare( $self, $options, %opts );

    my $groups = '';
    for my $group (@$options) {

        # DEPRECATED in Top Hat!
        if (ref $group eq 'HASH') {
            deprecated
                'hash references are DEPRECATED in favor of Mojo::Collection objects';
            $group = Mojo::Collection->new(each %$group);
        }

        # "optgroup" tag
        if (blessed $group && $group->isa('Mojo::Collection')) {
            my ($label, $values) = splice @$group, 0, 2;
            my $prepared = _prepare( $self, $values, %opts );
            my $content = join '', map { Mojolicious::Plugin::TagHelpers::_option(\%values, $_) } @$prepared;
            $groups .= Mojolicious::Plugin::TagHelpers::_tag('optgroup', label => $label, @$group, sub {$content});
        }

        # "option" tag
        else { $groups .= Mojolicious::Plugin::TagHelpers::_option(\%values, $group) }
    }

    return Mojolicious::Plugin::TagHelpers::_validation(
        $self, $name, 'select', %attrs, name => $name, sub {$groups},
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::TagHelpersI18N - TagHelpers with I18N support

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Mojolicious::Lite;
  
  plugin('I18N' => { namespace => 'Local::I18N', default => 'de' } );
  plugin('TagHelpersI18N');
  
  any '/' => sub {
      my $self = shift;
  
      $self->render( 'default' );
  };
  
  any '/no' => sub { shift->render };
  
  app->start;
  
  __DATA__
  @@ default.html.ep
  %= select_field 'test' => [qw/hello test/];
  
  @@ no.html.ep
  %= select_field 'test' => [qw/hello test/], no_translation => 1

=head1 DESCRIPTION

The TagHelpers in I<Mojolicious::Plugin::TagHelpers> are really nice. Unfortunately, I need to create 
C<select> fields where the labels are translated.

This plugin is the solution for that.

=head1 HELPER

=head2 select_field

Additionally to the stock C<select_field> helper, you can pass the option I<no_translation> to avoid
translated values

  %= select_field test => [qw(hello one)];

results in

  <select name="test"><option value="hello">Hallo</option><option value="one">eins</option></select>

and

  %= select_field test => [qw(hello one)], no_translation => 1;

results in

  <select name="test"><option value="hello">hello</option><option value="one">one</option></select>

in de.pm:

  'hello' => 'Hallo',
  'one'   => 'eins',

With this module you can sort the options:

  %= select_field test => [qw/one hello/], sort => 1;

With translation enabled, the translated labels are sorted.

More info about I<select_field>: L<Mojolicious::Plugin::TagHelpers>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
