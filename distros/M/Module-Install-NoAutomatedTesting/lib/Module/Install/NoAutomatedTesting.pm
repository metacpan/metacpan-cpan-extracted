package Module::Install::NoAutomatedTesting;

use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.08';

sub no_auto_test {
  return if $Module::Install::AUTHOR;
  exit 0 if $ENV{AUTOMATED_TESTING};
}

'NO SMOKING';

__END__

=head1 NAME

Module::Install::NoAutomatedTesting - A Module::Install extension to avoid CPAN Testers

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  no_auto_test;

The Makefile.PL will exit if it detects that it is being run on a CPAN Tester's C<smoker>.

=head1 DESCRIPTION

CPAN Testers are great and do a worthy and thankless job, testing all the distributions uploaded to
CPAN. But sometimes we don't want a distribution to be tested by these gallant individuals.

Module::Install::NoAutomatedTesting is a L<Module::Install> extension that will exit from the C<Makefile.PL>
when it detects that it is being run by a CPAN Tester.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<no_auto_test>

Does nothing on the author-side. On the user side it detects whether or not automated testing is in effect
and exits accordingly.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

L<http://wiki.cpantesters.org/>
