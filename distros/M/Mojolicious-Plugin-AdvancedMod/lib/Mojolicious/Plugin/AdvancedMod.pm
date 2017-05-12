package Mojolicious::Plugin::AdvancedMod;

our $VERSION = '0.38';

use DBI;
use List::Util 'any';
use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper;
our $AVAILABLE_MODS = {
  ActionFilter => 1,
  Configurator => 1,
  HashedParams => 1,
  TagHelpers   => 1,
  Authoriz     => 0,
  Fake         => 1
};

sub register {
  my ( $plugin, $app, $conf ) = @_;
  my ( $helpers, %only ) = {};

  foreach my $mod ( keys %$AVAILABLE_MODS ) {
    unless( $AVAILABLE_MODS->{$mod} ) {
      $app->log->debug( "** AdvancedMod $mod disable" );
      next;
    }

    if ( $conf->{only_mods} ) {
      unless ( any { lc( $_ ) eq lc( $mod ) } @{ $conf->{only_mods} } ) {
        $app->log->debug( "** AdvancedMod skipped $mod" );
        next;
      }
    }
    elsif ( $conf->{skip_mods} ) {
      if ( any { lc( $mod ) eq lc( $_ ) } @{ $conf->{skip_mods} } ) {
        $app->log->debug( "** AdvancedMod skipped $mod" );
        next;
      }
    }

    eval "use Mojolicious::Plugin::AdvancedMod::$mod;";

    # $app->defaults( { am_config => { errors => $@ } } ) if $@;

    unless ( $@ ) {
      eval 'Mojolicious::Plugin::AdvancedMod::' . $mod . '::init( $app, $helpers );';
    }
  }

  # add helper's
  if ( $conf->{only} ) {
    %only = map { $_ => 1 } @{ $conf->{only} };
  }

  foreach my $h ( keys %$helpers ) {
    if ( %only && !exists $only{$h} ) {
      delete $helpers->{$h};
      next;
    }
    $app->helper( $h => $helpers->{$h} );
    $app->log->debug( "** AdvancedMod load $h" );
  }

  # by am_config
  if ( $app->defaults( 'am_config' ) ) {
    my $am_cfg = $app->defaults( 'am_config' );

    # add db helper's
    foreach my $k ( keys %$am_cfg ) {
      if ( $k eq 'db' || $k =~ /^db_\w+$/ ) {
        $app->helper(
          $k => sub {
            return DBI->connect( @{ $am_cfg->{$k} }{qw/ dsn user password options /} );
          }
        );
      }
    }

    # change 'secrets' key
    $app->secrets( $am_cfg->{secrets} ) if $am_cfg->{secrets};
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod - More buns for Mojolicious

=head1 VERSION

This documentation covers version 0.38 of Mojolicious::Plugin::AdvancedMod* released Jan, 2014

=head1 SYNOPSIS

$self->plugin('AdvancedMod');

=head1 ARGS

=head2 skip_mods

  Skip selected modules

=head2 skip_helpers

  Skip selected helpers

=head2 only_mods (dev)

  Load selected modules, other skipped

=head2 only_helpers (dev)

  Load selected helpers, other skipped

=head1 SEE ALSO

=head2 L<Mojolicious::Plugin::AdvancedMod>

Load all AdvancedMod::*. Auto-generation database helpers's if config exist C<db_*> 

=head2 L<Mojolicious::Plugin::AdvancedMod::ActionFilter>

Analogue of Rails: before_filter, after_filter

=head2 L<Mojolicious::Plugin::AdvancedMod::HashedParams>

Transformation request parameters into a hash and multi-hash

=head2 L<Mojolicious::Plugin::AdvancedMod::Configurator>

Load YAML/JSON config, encapsulation, change 'templates_path' && 'static_path' by MOJO_MODE/config. 

=head2 L<Mojolicious::Plugin::AdvancedMod::TagHelpers>

Collection of HTML tag helpers

=head2 L<Mojolicious::Command::am>

Generic Mojolicious app, controllers, models, helpers, views

=head3 Example

=for text

  my_app/
  |__ etc
  |  |__ general.yml
  |
  |__ lib
  |   |__ MyApp
  |      |__ Controllers
  |      |  |__ App.pm
  |      |
  |      |__ Helpers
  |      |  |__ App.pm
  |      | 
  |      |__ Models
  |         |__ App.pm
  |
  |__ public
  |  |__ index.html
  |
  |__ script
  |  |__ my_app
  |
  |__ log
  |
  |__ t
  |  |__ basic.t
  |
  |__ templates
     |__ app
     |  |__ index.html.haml
     |  |__ show.html.haml
     | 
     |__ layouts
        |__ defaults.html.haml

=head1 AUTHOR

=over 2

=item

Grishkovelli L<grishkovelli@gmail.com>

=item

https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
