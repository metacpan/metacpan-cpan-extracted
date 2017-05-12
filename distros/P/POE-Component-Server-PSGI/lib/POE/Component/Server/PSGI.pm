package POE::Component::Server::PSGI;
BEGIN {
  $POE::Component::Server::PSGI::VERSION = '0.6';
}

use Moose;

with 'POEx::Role::PSGIServer';

before run => sub {
    my $self = shift;
    my $host = $self->listen_ip;
    my $port = $self->listen_port;
    print STDERR "Listening on $host:$port\n";
};

1;

__END__

=head1 NAME

POE::Component::Server::PSGI

=head1 VERSION

version 0.6

=head1 DESCRIPTION

PSGI Server implementation for POE.

=head1 NOTE

We've switched over to using nperez's excellent L<POEx::Role::PSGIServer>,
since it's essentially a (much better) refactor of this module's original
code.  Use this if you just want a default implementation of his role with no
modifications.

=head1 SYNOPSIS

    use POE::Component::Server::PSGI;

    my $server = POE::Component::Server::PSGI->new(
        host => $host,
        port => $port,
    );
    $server->run($app);

=head1 INTERFACE

See Plack::Server.

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack>

=cut