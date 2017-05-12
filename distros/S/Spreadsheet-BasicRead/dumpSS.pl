#! perl -w
#
#  dumpSS.pl

use Spreadsheet::BasicRead;
use strict;

my $xlsFileName = $ARGV[0];

my $ss = new Spreadsheet::BasicRead($xlsFileName) ||
	die "Could not open '$xlsFileName': $!";

do
{
	print '*** ', $ss->currentSheetName(), " ***\n";

	# Print the row number and data for each row of the
	# spreadsheet to stdout using '|' as a separator
	my $row = 0;
	while (my $data = $ss->getNextRow())
	{
		no warnings qw(uninitialized);
		$row++;
		print join('|', $row, @$data), "\n";
	}
} while ($ss->getNextSheet());

__END__

=head1 NAME

dumpSS.pl - Sample application to dump the entire contents of a spreadsheet

=head1 SYNOPSIS

dumpSS.pl some_spreadsheet.xls

=head1 DESCRIPTION

Print the sheet name, surrounded by '***' followed by the the contents
of each row printed on a single line with the pipe character '|' as a
separator between each cell.

Note:  There is nothing special done here to cater for pipe characters
in the contents of a cell.

=head1 SEE ALSO

Spreadsheet::BasicRead and Spreadsheet:ParseExcel on CPAN

=head1 AUTHOR

 Greg George, IT Technology Solutions P/L, Australia
 Mobile: +61-404-892-159, Email: gng@cpan.org

=head1 LICENSE

Copyright (c) 1999- Greg George. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 CVS ID

$Id: dumpSS.pl,v 1.1 2004/09/30 10:22:13 Greg Exp $

=head1 CVS LOG

$Log: dumpSS.pl,v $
Revision 1.1  2004/09/30 10:22:13  Greg
- Initial development as a CPAN example


=cut

#---< End of File >---#