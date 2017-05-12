package Plack::Middleware::Dispatch::GP::Request;
$Plack::Middleware::Dispatch::GP::Request::VERSION = '0.01';

=head1 NAME

Plack::Middleware::Dispatch::GP::Request - dispatcher middleware for general purposes request handling

=head1 DESCRIPTION

The module is derived from C<Plack::Middleware::Dispatch::GP>. It provides Plack::Request to registered dispatchers

=head1 VERSION

Version 0.01

=cut

use strict;
use warnings FATAL => 'all';

use parent "Plack::Middleware::Dispatch::GP";
use Plack::Util::Accessor qw/
    dispatch
    /;

use Plack::Request ();
use Scalar::Util   ();

=head1 SYNOPSIS

  use Plack::Builder;

  my $foo = Foo->new() # Foo should provide dispatch method

  my $app = sub { ... };
  builder {
    enable "Dispatch", dispatch => [\&cb, $foo];
    $app;
  };

  # cb(Plack::Request)
  sub cb {
    my($req) = @_;
    ...
  }


=head1 SUBROUTINES/METHODS

=head2 new($p)

see L<Plack::Middleware::Dispatch::GP>

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    return $class->SUPER::new(@_);
} ## end sub new

=head2 call($env)

delivers Plack::Request->new($env) to the dispatchers

=cut

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    $self->_dispatch($req);
    # foreach my $d (@{ $self->dispatch }) {
    #     $d->($req);
    # }

    $self->app->($env);
} ## end sub call

1;    # End of Plack::Middleware::Dispatch::GP::Request

=head1 AUTHOR

Alexei Pastuchov, C<< <palik at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/p-alik/Plack-Middleware-Dispatch-GP>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Dispatch::GP::Request

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alexei Pastuchov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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

=cut
