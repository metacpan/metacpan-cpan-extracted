package Plack::Middleware::DBIx::DisconnectAll;

use strict;
use warnings;
use 5.008005;
use parent qw/Plack::Middleware/;
use DBIx::DisconnectAll;

our $VERSION = '0.02';

sub call {
    my ( $self, $env) = @_;
    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        my $res = shift;
        if ( defined $res->[2] ) {
            dbi_disconnect_all();
            return;
        }
        return sub {
            my $chunk = shift;
            if ( ! defined $chunk ) {
                dbi_disconnect_all();
                return;
            }
            return $chunk;
        };
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::DBIx::DisconnectAll - Disconnect all database connection at end of request

=head1 SYNOPSIS

  use Plack::Middleware::DBIx::DisconnectAll;

  use Plack::Builder;
  
  builder {
      enable "DBIx::DisconnectAll";
      $app
  };


=head1 DESCRIPTION

Plack::Middleware::DBIx::DisconnectAll calls DBIx::DisconnectAll at end of request
and disconnects all database connections.

This modules is useful for freeing resources.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 SEE ALSO

L<DBIx::DisconnectAll>

=head1 LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
