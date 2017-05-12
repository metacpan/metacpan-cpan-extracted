# Perl 
#
# Class Report::Porf::Framework
#
# Perl Open Report Framework (Porf)
#
# Framework to create/configure Reports for any output format.
#
# Ralf Peine, Tue May 27 11:30:07 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "2.001";

package Report::Porf;

use strict; 
use warnings;

use Carp;

use Report::Porf::Framework;

use base qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(auto_report create_report);
our %EXPORT_TAGS = (
		all => [qw(auto_report create_report)],
);				 

sub auto_report {
	return Report::Porf::Framework::auto_report(@_);
}

sub create_report {
	die "Waits for implementation!";
}


1;
__END__

=head1 NAME

Report::Porf

Perl Open Report Framework

Framework to create/configure Reports for any output format.

=head1 VERSION

This documentation refers to version 2.001 of Report::Porf

All subs are no longer camel cased, so update your scripts, please.
A list for conversion can be find in Report/Porf/rename_list.pl

=head1 SYNOPSIS

   use Report::Porf qw(:all);

=head2 Structure of a Table::Simple Report

  Report
    Table
      Line (Conatining data of data row)
        Cell
  
  *============+============+============*  # Bold separator line
  |   Prename  |   Surname  |     Age    |  # The header line
  *------------+------------+------------*  # Separator line
  | Vorname 1  | <a cell>   | 7.69230769 |  # A data line with <cell>s
  | Vorname 2  | Name 2     | 15.3846153 |
  | Vorname 3  | Name 3     | 23.0769230 |
  | Vorname 4  | Name 4     | 30.7692307 |
  *============+============+============*

=head2 auto_report

Best for C< \@data_rows> as data rows as hashes, also usable for data rows
as arrays

   auto_report(\@data_rows);        # prints -max_rows => 10 to STDOUT
   auto_report(\@data_rows, $file); # prints all into file
   auto_report(\@data_rows, -file => $file, -format => 'html');
   auto_report(\@data_rows, -file => $file, -format => 'csv', -max_rows => 13);

Where

   my $file;

is filehandle or file name. If C< $file> is a file name (as string),
then ending of file name defines format of created table, if not
explicitely defined.

Filehandles don't know their filename, so format has to be select
explicit in this case.

C< -max_rows> defines maximum rows to print out. In case of printing
out at STDOUT there is a default max_rows set to 10 rows. That
makes live easy for debugging.

If using more than 2 args all arguments after first need to be named.

=head2 create_report

B<This feature waits for implementation!>

Configure columns explicit for objects, hashes, arrays or other by

   my $report = create_report(...);

   $report->write_all(\@data_rows);        # prints out
   $report->write_all(\@data_rows, $file); # writes into file

=head1 DESCRIPTION

The object oriented access to Porf gives you more possibilities, if
you need it.

=head2 create Report

  my $report_frame_work = Report::Porf::Framework::get();
  my $report            = $report_frame_work->create_report($format);

  # $report->set_verbose(3); # uncomment to see infos about configuring phase

Current supported formats:

  HTML
  Text
  Csv

=head2 Configure Report

After creation a report has to be configured. 

Call C<configure_column(%options)> to configure a report. Following
options are available:

=head3 Layout

  -header  -h   constant: Text
  -align   -a   constant: (left|center|right)
                          (l   |   c  |    r)
  -width   -w   constant: integer
  -format  -f   constant: string for sprintf
  -color   -c   constant / sub {...}

The sub {...} makes conditional coloring easy possible.

=head3 Value Manipulation

  -default_value        -def_val      -dv   constant: default value
  -escape_special_chars -esc_spec_chr -esc  constant: 1 or 0

Use default_cell_value if value is undef or ''.

To switch off special value escaping use

  escape_special_chars => 0

As next, access to the value has to be defined. There are 4 alternatives
to get the value of a cell depending of type (array, hash, object).

=head3 GetValue Alternative 1 --- ARRAY

  my $prename = 1;
  my $surname = 2;
  my $age     = 3;

  $report->configure_column(-header => 'Prename', -value_indexed => $prename ); # long
  $report->conf_col        (-h      => 'Surname', -val_idx       => $surname ); # short
  $report->cc              (-h      => 'Age',     -vi            => $age     ); # minimal

=head3 GetValue Alternative 2 --- HASH

  $report->configure_column(-header => 'Prename', -value_named => 'Prename' ); # long
  $report->conf_col        (-h      => 'Surname', -val_nam     => 'Surname' ); # short
  $report->cc              (-h      => 'Age',     -vn          => 'Age'     ); # minimal

=head3 GetValue Alternative 3 --- OBJECT

  $report->configure_column(-header => 'Prename', -value_object => 'get_prename()'); # long
  $report->conf_col        (-h      => 'Surname', -val_obj      => 'get_surname()'); # short
  $report->cc              (-h      => 'Age',     -vo           => 'get_age()'    ); # minimal

=head3 GetValue Alternative 4 --- Free 

  $report->configure_column(-h => 'Prename',  -value =>    '"Dr. " . $_[0]->{Surname}'    );
  $report->conf_col        (-h => 'Surname',    -val => sub { return $_[0]->{Prename}; }; );
  $report->cc              (-h => 'Age (Months)', -v =>     '(12.0 * $_[0]->get_age())'    );

=head2 When All Columns Are Configured

  $report->configure_complete(); 

=head2 Write Table Out Into File

  $report->write_all($person_rows, $out_file_name);

You can also put out single rows or single cells or start actions to do that.
[Needs to be explained more]

In "Report/Porf/examples" subdir you can find more examples.

=head1 Details

Here are the details for those, who want to modify an existing or
create a new ReportConfigurator. It's actually not complete. See
*ReportConfigurator.pm for more.

=head2 Report Attributes

There a following attributes of report, that can used by get*/Set*

  FileStart
    PageStart
      TableStart
        *============+====  # BoldSeparatorLine
        |   Prename  | ...  # HeaderRowStart HeaderStart <HeaderText> HeaderEnd ... HeaderRowEnd
        *------------+----  # SeparatorLine
        | Vorname 1  | ...  # RowStart       CellStart   <CellValue>  CellEnd   ... RowEnd
        | ...        | ...  # ...
        *============+====  # BoldSeparatorLine
      TableEnd
    PageEnd
  FileEnd

To be continued...

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 by Ralf Peine, Germany.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
