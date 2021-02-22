package Mojolicious::Plugin::ServerType;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = "0.02";

sub register {
    my ($self, $app, $conf) = (@_);
    $conf ||= {};

    $app->helper(
        server_type => sub {
            return undef;
        }
    );

    $app->hook( before_server_start => sub {
        my ( $server, $app ) = @_;

        my $serverType = ref $server;

        $app->helper(
            server_type => sub {
                return $serverType;
            }
        );
    });
}


1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::ServerType - A Mojolicious Plugin that provides a helper
that identifies the server type

=head1 SYNOPSIS

    use Mojo::Base -strict;

    use Mojolicious::Lite;

    plugin 'ServerType';

    get '/' => sub {
        my $c = shift;

        $c->render( json => {"serverType" => $c->app->server_type } );
    };

    app->start;

=head1 DESCRIPTION

Mojolicious::Plugin::ServerType is a Mojolicious Plugin that provides a helper
which can be used to identify the type of server that Mojolicious is
running in (e.g. C<Mojo::Server::Daemon>, C<Mojo::Server::Prefork>)

=head1 HELPERS

=over 4

=item C<server_type>

Mojolicious::Plugin::ServerType adds the C<server_type> helper which simply
returns the Class of the server that it's running under.  If not running under
a server or the server doesn't support the C<before_server_start> hook then
C<undef> will be returned.

=back

=head1 LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jason Cooper E<lt>JLCOOPER@cpan.orgE<gt>

=cut

