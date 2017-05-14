package Plack::Middleware::Apache2CGIFix;

use strict;
use warnings;

use parent qw( Plack::Middleware );

sub call {
    my ( $self, $env ) = @_;

    # Because we compile these modules under ModPerl::Registry,
    # we munge the internals for the duration of the Plack request.
    local $CGI::MOD_PERL         = 0;
    local $CGI::Cookie::MOD_PERL = 0;

    my $res = $self->app->($env);

    # CGI under mod_perl calls initialize_globals() at the end of
    # each request, but CGI::Compile calls it only at the start.  If
    # we want both in the same mod_perl process, we need to call it
    # as cleanup too.
    CGI::initialize_globals() if defined &CGI::initialize_globals;

    return $res;
}

1;
__END__

=head1 NAME

Plack::Middleware::Apache2CGIFix - Hacks for Plack and CGI under Apache2

=head1 DESCRIPTION

When migrating your mod_perl site to run under Plack, you may wish to move
part of your site to Plack at a time, rather than all at once.

In this situation, your Perl modules will be compiled under mod_perl in
Apache's startup.pl, but then run under Plack.  Commonly used modules
such as L<CGI> have optimizations for mod_perl environments, and certain
things like redirects will fail to work under Plack.

This middleware performs some ugly hacks to CGI and related modules, allowing
all this to work.

If you are running your entire site under Plack, then this middleware should
become unnecessary, because all CPAN modules will be preloaded in a Plack
environment, where $ENV{MOD_PERL} is not set.

=head1 CAVEATS

Did I mention ugly hacks?  This includes overriding variables internal to
L<CGI> and L<CGI::Cookie>.

=head1 SEE ALSO

L<https://groups.google.com/d/msg/psgi-plack/HWrjb3DaZlk/27mQCxmf0r0J>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 CV-Library Ltd.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
