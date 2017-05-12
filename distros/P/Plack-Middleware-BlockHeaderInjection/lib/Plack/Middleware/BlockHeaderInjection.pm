package Plack::Middleware::BlockHeaderInjection;

use strict;
use warnings;

use parent qw( Plack::Middleware );

use Plack::Util;
use Plack::Util::Accessor qw( logger status );

use version 0.77; our $VERSION = version->declare('v0.1.1');

=head1 NAME

Plack::Middleware::BlockHeaderInjection - block header injections in responses

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = ...

  $app = builder {
    enable 'BlockHeaderInjection',
      status => 500;
    $app;
  };

=head1 DESCRIPTION

This middleware will check responses for injected headers. If the
headers contain newlines, then the return code is set to C<500> and
the offending header(s) are removed.

A common source of header injections is when parameters are passed
unchecked into a header (such as the redirection location).

An attacker can use injected headers to bypass system security, by
forging a header used for security (such as a referrer or cookie).

=head1 OPTIONS

=head2 C<status>

The status code to return if an invalid header is found. By default,
this is C<500>.

=cut

sub call {
    my ( $self, $env ) = @_;

    # cache the logger
    $self->logger($env->{'psgix.logger'} || sub { })
        unless defined $self->logger;

    $self->status(500) unless $self->status;

    my $res = $self->app->($env);

    Plack::Util::response_cb(
        $res,
        sub {
            my $res = shift;

            # Sanity check headers

            my $hdrs = $res->[1];

            my $i = 0;
            while ($i < @{$hdrs}) {
                my $val = $hdrs->[$i+1];
                if ($val =~ /[\n\r]/) {
                    my $key = $hdrs->[$i];
                    $self->log(
                        error => "possible header injection detected in ${key}" );
                    $res->[0] = $self->status;
                    Plack::Util::header_remove($hdrs, $key);
                }
                $i+=2;
            }

        }
    );

}

# Note: ideas borrowed from XSRFBlock

sub log {
    my ($self, $level, $msg) = @_;
    $self->logger->({
        level   => $level,
        message => "BlockHeaderInjection: ${msg}",
    });
}

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/HTTP_header_injection>

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=over

=item Foxtons, Ltd.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut

1;
