package Plack::Middleware::Apache2EnvironmentFix;

use strict;
use warnings;

use parent qw( Plack::Middleware );

sub call {
    my ( $self, $env ) = @_;

    # Plack::Handler::Apache2 deletes $ENV{MOD_PERL} at compile time,
    # but we also want it removed at run time.
    local $ENV{MOD_PERL};
    delete $ENV{MOD_PERL};
    delete $env->{MOD_PERL};

    my $res = $self->app->($env);

    return $res;
}

1;
__END__

=head1 NAME

Plack::Middleware::Apache2EnvironmentFix - Hacks for Plack under Apache2

=head1 DESCRIPTION

You may try to port your mod_perl site to Plack a bit at a time, by using
L<Plack::Handler::Apache2>, rather than jumping straight to another option
such as L<Starman>.

In this situation, if your Perl modules check $ENV{MOD_PERL} at runtime,
then they will think they are running in a mod_perl environment.

This middleware deletes $ENV{MOD_PERL} at runtime, so that your code will
behave the same as under any other PSGI environment.

In future, the scope of this module could be extended to reset other
environment variables, so that Apache2 more closely resembles the PSGI spec.

=head1 CAVEATS

This module messes with %ENV by localizing it.  This seems to cause problems
under at least some versions of mod_perl - %ENV does not stay localized.

One workaround we found for this was to change the core mod_perl handler:

  SetHandler modperl

But this caused us additional problems with bugs in L<CGI::Emulate::PSGI>
version 0.15, where since STDIN was no longer tied to Apache's $r, any POST
requests did not work.  Version 0.16 of that module introduced problems
around tied filehandles, so at the time of writing we do not have a fix for
this problem.

=head1 SEE ALSO

L<Plack::Middleware::Apache2CGIFix> for fixes specific to CGI.

L<https://groups.google.com/d/msg/psgi-plack/HWrjb3DaZlk/27mQCxmf0r0J>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 CV-Library Ltd.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
