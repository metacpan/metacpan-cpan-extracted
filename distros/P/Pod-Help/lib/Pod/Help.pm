## no critic
package Pod::Help;

use 5.006;
use strict;
use warnings FATAL => 'all';

our @ISA = qw();

our $VERSION = '1.00';

sub import($;@) {
	my $class = shift;
	foreach my $trigger (@_) {
		foreach my $argv (@ARGV) {
			no warnings 'uninitialized';
			$class->help() if $trigger eq $argv;
		}
	}
}	

sub help(;@) {
	my $class = shift;
	if (@_) {
		@ARGV = @_;
	} else {
		@ARGV = ('-F', $0);
	}
	my $rc = eval {
		require Pod::Perldoc;
		Pod::Perldoc->run() || 0
	} || 0;
	print STDERR "\n", $@ if length($@);
	exit( $rc );
}

1;
__END__

=for changes stop

=head1 NAME

Pod::Help - Perl module to automate POD display

=head1 SYNOPSIS

  use Pod::Help qw(-h --help);

  -or-

  use Pod::Help;
  ...
  Pod::Help->help() if (...);

  -or-
  use Pod::Help;
  ...
  Pod::Help->help('ACME::PodLib::FooPod');

=head1 DESCRIPTION

Pod::Help allows your script or program to automaticlly display its POD when the user gives a certain command line parameter.

Note: 'script or program'! I mean it, Pod::Help is not intended to be used by other modules.

There are three different ways to use Pod::Help:

=over 8

=item fully automatic

For fully automatic mode just use() Pod::Help and give it the command line parameters it should be triggered by as parameters:

  use Pod::Help qw(-h --help);

That's it, nothing more to do.

=item manually triggered

If you don't want Pod::Help to fiddle with your @ARGV, you may trigger the POD display manually. Use() Pod::Help without (or with an empty) parameter list and it will do nothing on its own. You may then call Pod::Help->help() at any time.

  use Pod::Help;
  ...
  Pod::Help->help() if (...);

=item POD from different file

If you have the POD in a different file you must use the manual mode. Then give the module name of the file containing your POD to the help() method.

  use Pod::Help;
  ...
  Pod::Help->help('ACME::PodLib::FooPod');

If the POD is in a file that cannot be found that way, give '-F' and the file name and path to help().

  use Pod::Help;
  ...
  Pod::Help->help('-F', $installdir.'/docs/scripts/podhelp/foo.pod');

You may give any parameters to help() that L<perldoc> would accept, too.

=back

=head1 METHODS

=over 8

=item help()

Calling help() will try to display the POD and exit. For details, see above.

=back

=for changes continue

=head1 HISTORY

=over 8

=item 0.99

Original version; created by h2xs 1.23 with options

  -A
	-C
	-X
	-b
	5.6.0
	-n
	Pod::Help
	--use-new-tests
	--skip-exporter
	-v
	0.99

=item 1.00

Updated packaging for newer standards. No changes to the coding.

=back

=for changes stop

=head1 SEE ALSO

For more information on perldoc and the Perl documentation format 'POD'
see L<perldoc>, L<perlpod> or L<perlpodspec>.

=head1 AUTHOR

Michael Jacob, E<lt>jacob@j-e-b.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2007 by Michael Jacob

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
