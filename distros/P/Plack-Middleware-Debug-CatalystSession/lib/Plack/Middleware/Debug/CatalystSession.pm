package Plack::Middleware::Debug::CatalystSession;

use 5.008;
use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);

use Catalyst;

use Class::Method::Modifiers qw(install_modifier);
use Data::Dumper;
use HTML::Entities qw/encode_entities_numeric/;

=head1 NAME

Plack::Middleware::Debug::CatalystSession - Debug panel to inspect the Catalyst Session

=head1 VERSION

Version 0.01003

=cut

our $VERSION = '0.01004';
# Starting with Catalyst 5.90097, the environment given to psgi middleware
# components was localized. This effectively made $c->req->env read only.
# If we are on those versions of Catalyst, we want to store a reference
# to the environment in a local variable.
use constant LOCALIZED_PSGI_ENV => $Catalyst::VERSION >= 5.90097 && $Catalyst::VERSION < 5.90100;
my $psgi_env; # Unused if LOCALIZED_PSGI_ENV is true
my $env_key = 'plack.middleware.catalyst_session';

install_modifier 'Catalyst', 'before', 'finalize' => sub {
    my $c = shift;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Deparse = 1;
    my $session =
        encode_entities_numeric( Dumper( $c->session ) );
    if (LOCALIZED_PSGI_ENV) {
      $psgi_env->{$env_key} = $session;
    } else {
      $c->req->env->{$env_key} = $session;
    }
};

sub run {
    my($self, $env, $panel) = @_;
    if (LOCALIZED_PSGI_ENV) {
      # At this point, $env is NOT a localized reference, so we store it
      $psgi_env = $env;
    }

    return sub {
        my $res = shift;

        my $session = delete $env->{$env_key} || 'No Session';
        $panel->content("<pre>$session</pre>");
        if (LOCALIZED_PSGI_ENV) {
          # Clean up our stored reference
          $psgi_env = undef;
        }
    };
}

=head1 SYNOPSIS

   builder {
      enable "Debug";
      enable "Debug::CatalystSession";
      sub { MyApp->run(@_) };
   };

or

   __PACKAGE__->config(
      'psgi_middleware', [
         'Debug' => {panels => [
            'CatalystSession'
         ]},
      ]
   );

=head1 AUTHOR

Thomas Kuyper, C<< <tkuyper at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-middleware-debug-catalystsession at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-Debug-CatalystSession>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Debug::CatalystSession


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-Debug-CatalystSession>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Middleware-Debug-CatalystSession>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-Debug-CatalystSession>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Middleware-Debug-CatalystSession/>

=back


=head1 ACKNOWLEDGEMENTS

For L<Plack::Middleware::Debug::CatalystStash> from which this is derived:

Mark Ellis E<lt>markellis@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::Middleware::Debug::CatalystStash>

L<Plack::Middleware::Debug>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Thomas Kuyper.

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

1; # End of Plack::Middleware::Debug::CatalystSession
