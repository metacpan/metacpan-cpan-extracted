use strict;
use warnings;
package Querylet::Output::Excel::OLE;
{
  $Querylet::Output::Excel::OLE::VERSION = '0.143';
}
use parent qw(Querylet::Output);
# ABSTRACT: output query results to Excel via OLE

use Carp;


sub default_type { 'excel' }


sub handler { \&_to_excel }

sub _to_excel {
	my $q = shift;

	my $workbook  = $q->option('excel_workbook');
	my $worksheet = $q->option('excel_worksheet');
	my $postproc  = $q->option('excel_postprocessing_callback');
	$postproc &&= eval $postproc;
	warn "couldn't eval postprocessing callback: $@" if $@;

	my $range = [[ map { $q->header($_) } @{$q->columns} ]];

	foreach my $row (@{$q->results}) {
		push @$range, [ @$row{@{$q->columns}} ];
	}

	my $rows   = @$range;
	my $column = column_name(scalar @{$range->[0]});

	return sub {
		require Win32::OLE;
		require Win32::OLE::Const;
		Win32::OLE::Const->import('Microsoft Excel');

		my $xl = Win32::OLE->new("Excel.Application")
			or croak "can't create a new Excel application";
	  $xl->{Visible} = 1;

		my ($xlb,$xls);

		if ($workbook) {
			$xlb = $xl->Workbooks->Open($workbook)
				or croak "can't open workbook $workbook";
		} else {
			$xlb = $xl->Workbooks->Add;
		}

		$xls = $xlb->Worksheets(defined $worksheet ? $worksheet : 1);

		unless ($xls) {
			$xls = $xlb->Worksheets->Add;
			$xls->{Name} = $worksheet if $worksheet;
		}
		unless ($xls)   { croak "can't find worksheet $worksheet" }

		$xls->Range("A1:$column$rows")->{Formula} = $range;
		$xls->Range("A1:${column}1")->{Font}->{Bold} = 1;
		$xls->Range("A1:${column}1")->AutoFit();

		$postproc->(
			{ excel => $xl, workbook => $xlb, worksheet=> $xls, query => $q }
		) if (ref($postproc)||'' eq 'CODE');
	}
}


sub column_name {
	my ($number) = @_;
	return unless $number > 0;

	my $name = '';
	my $zero  = ord('A') - 1;
	while ($number) {
		$name = chr($zero + (my $digit = ($number % 26) || 26)) . $name;
		($number -= $digit) /= 26;
	}
	return $name;
}

1;

__END__

=pod

=head1 NAME

Querylet::Output::Excel::OLE - output query results to Excel via OLE

=head1 VERSION

version 0.143

=head1 SYNOPSIS

 use Querylet::Output::Excel::OLE;
 use Querylet;

 database: bogosity

 query:
   SELECT detector_id, measurement
   FROM   bogon_detections

 output format: excel

=head1 DESCRIPTION

Querylet::Output::Excel::OLE provides an output handler for Querylet that will
create a new instance of Microsoft Excel using Win32::OLE and populate a
worksheet with the query results.

=head1 METHODS

This module isa Querylet::Output, and implements the interface described by
that module.

=head2 default_type

The Excel::OLE handler is by default registered for the 'excel' type.

=head2 handler

The Querylet::Output::Excel::OLE handler returns a coderef that, when called,
will create an Excel.Application object, then create a workbook, and then
populate its worksheet with the querylet's results.

If the "excel_workbook" and "excel_worksheet" options are set, it will attempt
to open the named workbook file and put its results into the named worksheet,
creating it if necessary.  If the workbook, but not worksheet, is set, it will
create a new worksheet in the named workbook.

If the "excel_postprocessing_callback" option is set, the handler will try to
evaluate it into a code reference, the code reference will be called after all
other processing is done.  It will be passed a hash reference with the
following keys:

 query     - the Querylet::Query object being output
 excel     - the Excel.Application object
 workbook  - the Workbook object
 worksheet - the Worksheet object

=head1 FUNCTIONS

=head2 column_name

  column_name($column_number)

This converts a column number to a column name, Excel style.  In other words:

    1 -> A
   26 -> Z
   27 -> AA
 2600 -> CUZ

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
