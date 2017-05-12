use strict;
use warnings;
package Plack::Middleware::ServerStatus::Tiny;
{
  $Plack::Middleware::ServerStatus::Tiny::VERSION = '0.002';
}
# git description: v0.001-4-geb5f2f5

BEGIN {
  $Plack::Middleware::ServerStatus::Tiny::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: tiny middleware for providing server status information

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(path _uptime _access_count);
use Plack::Response;

sub prepare_app
{
    my $self = shift;

    die 'missing required option: \'path\'' if not $self->path;
    warn 'path "' . $self->path . '" does not begin with /, and will never match' if $self->path !~ m{^/};

    $self->_uptime(time);
    $self->_access_count(0);
}

sub call
{
    my ($self, $env) = @_;

    $self->_access_count($self->_access_count + 1);

    if ($env->{PATH_INFO} eq $self->path)
    {
        my $content = 'uptime: ' . (time - $self->_uptime)
            . '; access count: ' . $self->_access_count;

        my $res = Plack::Response->new('200');
        $res->content_type('text/plain');
        $res->content_length(length $content);
        $res->body($content);
        return $res->finalize;
    }

    $self->app->($env);
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Karen Etheridge balancer pids irc

=head1 NAME

Plack::Middleware::ServerStatus::Tiny - tiny middleware for providing server status information

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'ServerStatus::Tiny', path => '/status';
        $app;
    };

    $ curl http://server:port/status
    uptime: 120; access count: 10

=head1 DESCRIPTION

This middleware is extremely lightweight: faster and smaller than
L<Plack::Middleware::ServerStatus::Lite>. While that middleware is useful for
showing the status of all workers, their pids and their last requests, it can
be a bit heavy for frequent pinging (for example by a load balancer to confirm
that the server is still up).

This middleware does not interrogate the system about running processes,
and does not use the disk, keeping all its data in memory in the
worker process. All it returns is the number of seconds since the last server
restart, and how many requests this particular process has serviced.

=head1 CONFIGURATION

=over 4

=item * C<path>

The path which returns the server status.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Plack-Middleware-ServerStatus-Tiny>
(or L<bug-Plack-Middleware-ServerStatus-Tiny@rt.cpan.org|mailto:bug-Plack-Middleware-ServerStatus-Tiny@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Plack::Middleware::ServerStatus::Lite>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
