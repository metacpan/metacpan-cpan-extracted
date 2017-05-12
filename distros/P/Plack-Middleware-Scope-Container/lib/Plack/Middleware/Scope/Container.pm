package Plack::Middleware::Scope::Container;

use strict;
use warnings;
use parent qw(Plack::Middleware);
use Scope::Container;
use Plack::Util;

our $VERSION = '0.04';

sub call {
    my ( $self, $env) = @_;
    my $container = start_scope_container();
    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        my $res = shift;
        if ( defined $res->[2] ) {
            undef $container;
            return;
        }
        return sub {
            my $chunk = shift;
            if ( ! defined $chunk ) {
                undef $container;
                return;
            }
            return $chunk;
        };
    });
}

1;
__END__

=head1 NAME

Plack::Middleware::Scope::Container - per-request container 

=head1 SYNOPSIS

  use Plack::Builder;
  
  builder {
      enable "Plack::Middleware::Scope::Container";
      $app
  };
  
  # in your application
  package MyApp;

  use Scope::Container;

  sub getdb {
      if ( my $dbh = scope_container('db') ) {
          return $dbh;
      } else {
          my $dbh = DBI->connect(...);
          scope_container('db', $dbh)
          return $dbh;
      }
  }

  sub app {
    my $env = shift;
    getdb(); # do connect
    getdb(); # from container
    getdb(); # from container
    return [ '200', [] ["OK"]];
    # disconnect from db at end of request
  }

=head1 DESCRIPTION

Plack::Middleware::Scope::Container and L<Scope::Container> work like mod_perl's pnotes.
It gives a per-request container to your application.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Scope::Container>, L<Plack::Middleware::Scope::Session>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
