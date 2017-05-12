package Module::Install::AutomatedTester;

use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.04';

sub auto_tester {
  return if $Module::Install::AUTHOR;
  return $ENV{AUTOMATED_TESTING};
}

sub cpan_tester {
  &auto_tester;
}

'ARE WE BEING SMOKED?';

__END__

=head1 NAME

Module::Install::AutomatedTester - A Module::Install extension to detect whether we are being tested by CPAN Testers.

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  if ( auto_tester ) {
     # Do something if we are running under a CPAN Tester
     # like add some prereqs, etc.
  }

=head1 DESCRIPTION

CPAN Testers are great and do a worthy and thankless job, testing all the distributions uploaded to
CPAN. Sometimes we want to know if our distribution is being tested by one of these gallant individuals
and make them do some extra work.

Module::Install::AutomatedTesters is a L<Module::Install> extension that adds two extra commands to detect if
the disttribution is being run under a CPAN Tester environment so that we can do extra stuff or skip stuff.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<auto_tester>

Does nothing on the author-side. On the user side it detects whether or not automated testing is in effect.

=item C<cpan_tester>

Same as the above.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

L<http://wiki.cpantesters.org/>

=cut
