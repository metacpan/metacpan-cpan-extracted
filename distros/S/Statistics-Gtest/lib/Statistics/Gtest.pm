#!/usr/bin/perl -w

package Statistics::Gtest;

use strict;
use vars qw($VERSION);
use Carp;
use IO::File;

$VERSION = '0.07';

my $self;

sub new {
   my ($type, $data) = @_;
   my $datahandle;
   if (! $data) {
      _error(1);
   }
   if (@_ eq 3) {
      _error(2);
   }      
   if ($datahandle = _getHandle($data)) {
      $self  = {};
      _initialize($datahandle);
      bless($self, $type);
      $self;
   }  
   else {
      _error(3);
   }
}

sub getG {
   my $self = shift;
   $self->{'G'} = $self->getRawG() / $self->getQ();
   $self->{'G'};
}

sub getRawG {
   my $self = shift;
   $self->{'logsum'} = _sumCellOp();
   $self->{'G'} = 2 * $self->{'logsum'};
   2 * $self->{'logsum'};
}

sub getQ {
   my $self = shift;
   $self->{'q'} = _williamsC();
   $self->{'q'};
}

sub setExpected {
   my ($self, $expData) = @_;
   my $datahandle;
   my @expect;
   my $expectTotal = 0;
   if (@_ eq 3) {
      _error(2);
   }      
   if ($datahandle = _getHandle($expData)) {
      foreach my $row_ref (@{$datahandle}) {
      if (!ref $row_ref) {
         _error(4);
      }
      my @row = @{$row_ref};
         foreach my $cell (@row) {
            _checkNumValidity($cell);
            push(@expect, $cell);
            $expectTotal += $cell;
         }    
         $self->{'expected'} = \@expect;
         # Expected values no longer intrinsic to observed data, so set
         # flag to 0.
         $self->{'intrinsic'} = 0;  
      }
   }
   else {
      _error(3);
   }
   # Data sanity checks
   if ($expectTotal != $self->{'sumtotal'}) {
      warn "Warning: Total of expected values ($expectTotal) does not ",
      "equal total of observed values (",$self->{'sumtotal'},").\nThis ",
      "will invalidate the test unless the discrepancy is very minor ",
      "\n(e.g., the result of rounding error).\n";
   }
}

sub getObserved {
   my $self = shift;
   my $exp = _formatData($self->{'observed'});
   $exp;
}

sub getExpected {
   my $self = shift;
   my $exp = _formatData($self->{'expected'});
   $exp;
}

sub getDF {
   my $self = shift;
   $self->{'df'};
}

sub setDF {
   my $self = shift;
   $self->{'df'} = shift;
   # Degrees of freedom set externally.
   $self->{'df_extern'} = 1;
}

sub getDFstate {
   my $self = shift;
   $self->{'df_extern'};
}

sub getHypothesis {
   my $self = shift;
   $self->{'intrinsic'};
}

sub getRow {
   my $self = shift;
   my $idx = shift;
   if ($idx > ($self->{'nrows'} - 1)) {
      return;
   }   
   my @row = ();
   my $skip = $self->{'ncols'};
   my $offset = $idx * $skip;
   my $final = $offset + $skip;
   for my $cell ($offset .. $final - 1) {
      push(@row, $self->{'observed'}->[$cell]);
   }    
   \@row;
}

sub getCol {
   my $self = shift;
   my $idx = shift;
   if ($idx > ($self->{'ncols'} - 1)) {
      return;
   }   
   my @col = ();
   my $skip = $self->{'ncols'};
   my $max = $skip * $self->{'nrows'};
   for (my $cell = $idx; $cell < $max; $cell += $skip) {
      push(@col,$self->{'observed'}->[$cell]);
   }    
   \@col;
}

sub rowSum {
   my $self = shift;
   my $idx  = shift;
   $self->{'rowsums'}->[$idx];
}

sub colSum {
   my $self = shift;
   my $idx  = shift;
   $self->{'colsums'}->[$idx];
}
   
sub getRowNum {
   my $self = shift;
   $self->{'nrows'};
}

sub getColNum {
   my $self = shift;
   $self->{'ncols'};
}

sub getSumTotal {
   my $self = shift;
   $self->{'sumtotal'};
}

# private methods

# Do all the initialization work: verify the data and write it into the 
# object; calculate the row and column sums and grand total; determine
# the format of the data table (rows x columns); calculate the likely
# degrees of freedom and generate default expected values.  Set state
# flags indicating that the expected values are 'intrinsic' (generated
# from the observed data), and that the degrees of freedom are also
# based on table characteristics.
sub _initialize {
   my $datahandle = shift;
   my @datastruct = ();
   my @rowsums = ();
   my @sumcols = ();
   my ($ncols, $nrows, $sumtotal);
   my $totalN = 0;
   $self->{'colsums'} = ();

   foreach my $row_ref (@{$datahandle}) {
      if (!ref $row_ref) {
         _error(4);
      }
      my @row = @{$row_ref};
      $ncols = scalar @row;
      my $i = 0;
      foreach my $cell (@row) {
         _checkNumValidity($cell);
         push(@datastruct, $cell);
         $sumtotal += $cell;
         $self->{'colsums'}->[$i] += $cell;
         $i++;
         $totalN++;
      }    
      $nrows++;
      push(@rowsums, _rowsum(\@row));
   }

   # Data sanity checks; make sure data exist and are internally 
   # consistent.
   if ($totalN == 0) {
      _error(5);
   }

   if ($totalN != ($nrows * $ncols)) {
      _error(6); 
   }
      
     if (($ncols == 0) || ($nrows == 0)) { 
      _error(7); 
   }
      
   my $tSum = 0;   
   foreach my $r (@rowsums) {
      $tSum += $r;
   }
   if ($sumtotal != $tSum) {
      _error(6); 
   }
      
    $tSum = 0;   
   foreach my $r (@{$self->{'colsums'}}) {
      $tSum += $r;
   }
   if ($sumtotal != $tSum) {
      _error(6); 
   }

   $self->{'observed'} = \@datastruct;
   $self->{'rowsums'} = \@rowsums;
   $self->{'nrows'} = $nrows;
   $self->{'ncols'} = $ncols;
   $self->{'sumtotal'} = $sumtotal;

   # tabletype: 0 = 2-way, 1 = single column, 2 = single row
   if (($ncols == 1) || ($nrows == 1)) {
      if ($ncols == 1) { 
         $self->{'df'} = $nrows - 1; 
         $self->{'tabletype'} = 1;
      }
      if ($nrows == 1) { 
         $self->{'df'} = $ncols - 1; 
         $self->{'tabletype'} = 2;
      }    
   }
   else {
      $self->{'df'} = ($nrows - 1) * ($ncols - 1);
      $self->{'tabletype'} = 0;
   }    
   $self->{'expected'}= _expected(\@datastruct);
   $self->{'intrinsic'} = 1;
   $self->{'df_extern'} = 0;
}

# Calculate and return William's correction, q. Calculation varies 
# depending on table format (1-way vs. 2-way).
sub _williamsC {
   my $sumtotal = $self->{'sumtotal'};
   my $rowsums = $self->{'rowsums'};
   my $colsums = $self->{'colsums'};
   if ($self->{'tabletype'} == 1) {
      $self->{'q'} = 
         1 + ($self->{'nrows'} + 1) / (6 * $sumtotal);
   }
   elsif ($self->{'tabletype'} == 2) {
      $self->{'q'} = 
         1 + ($self->{'ncols'} + 1) / (6 * $sumtotal);
   }
   else {
      my $recipRows = 0;
      my $recipCols = 0;
      foreach my $rval (@{$rowsums}) {
         $recipRows += (1 / $rval);
      }    
      foreach my $cval (@{$colsums}) {
         $recipCols += (1 / $cval);
      }    
      my $denom = 6 * $sumtotal * $self->{'df'};
      my $num = ($sumtotal * $recipRows - 1) * ($sumtotal * $recipCols - 1);
      $self->{'q'} = 1 + $num / $denom;
   }
}

# Generate the default expected values, based on a hypothesis of 
# independence (no association) between factors.
# Return ref to expected array.
sub _expected {
   my $data = shift;
   my @expected = ();
   my $rows = $self->{'nrows'};
   my $cols = $self->{'ncols'};
   my $sumtotal = $self->{'sumtotal'};
   for my $row (0 .. $rows-1) {
      my $marginalRow = $self->{'rowsums'}->[$row] / $sumtotal;    
      my @a;
      for my $col (0 .. $cols-1) {
         my $marginalCol = $self->{'colsums'}->[$col] / $sumtotal;    
         push(@expected, ($marginalRow * $marginalCol * $sumtotal));
      } 
   }
   \@expected;
}

# Calculate the log-likelihood statistic.
# Return sum of Obs * ln(Obs/Exp) for all cells.
sub _sumCellOp {
   my $logsum = 0;
   my $ncells = $self->{'nrows'} * $self->{'ncols'};
   my $o = $self->{'observed'};
   my $e = $self->{'expected'};
   for my $cell (0 .. $ncells-1) {
      $logsum += $o->[$cell] * log($o->[$cell] / $e->[$cell]);    
   }        
   $logsum;
}

# Return sum of the cells in this row.
sub _rowsum {
   my $row = shift;
   my $total = 0;
   foreach my $val (@{$row}) {
      $total += $val;
   }    
   $total;
}

# Order the data array back into the format originally input.
sub _formatData {
   my $ref = shift;
   my @data;
   my $len =  scalar @{$ref};
   my $rlen = $len / $self->{'nrows'};
   my $idx = $rlen - 1;
   for (my $r=0; $r<$len; $r+=$rlen) {
      my $row = [ @{$ref}[$r ... $idx] ];
      return $row if ($rlen eq $len);
      push(@data, $row);
      $idx += $rlen;
   }
   \@data;
}

# Check to make sure the values are numbers, greater than 0.
# Throw error if any problems are found.
sub _checkNumValidity {
   my $value = shift;
   my $eString = "Invalid data.";
   if ($value !~ /^\d+\.?\d*$/) {
      _error(8); 
   }

   # Very low cell counts (< 5) aren't great, either. Maybe a 
   # warning is in order.
   if ($value < 5) {
      warn "Warning: Very small cell frequency (freq. < 5) found.\n",
		"This will reduce the reliability of the test.\n";
   }
   if ($value == 0) {
      _error(9); 
   }
}

# Take a filehandle, return an array reference.
sub _fileread {
   my $data = shift;
   my @a;
   while (<$data>) {
      my @row = split(/\s+/,$_);
      push(@a, \@row);
   }
   \@a;
}

# Try to take whatever input format is thrown at us, and turn it into
# an array reference, or just bail out completely if we can't figure
# it out.
sub _getHandle {
   my $data = shift;
   if (ref $data) {
      if ($data =~ /\AARRAY/) {
         if (ref $data->[0]) {
            return $data;
         }
         else {
            return [ $data ];
         }   
      }
      if ($data =~ /\AGLOB/) {
         return _fileread($data);
      }
      if ($data =~ /\AIO::File=GLOB/) {
         return _fileread($data);
      }
      else {
         _error(10);
      }
   }
   else {
      my $fh = new IO::File;
      if ($fh->open("< $data")) {
         return _fileread($fh);
      }
      else {
         my @a = split(/\s+/,$data);
         return [ \@a ];

      }
      undef $fh;
   }
   0;
}

# Keep all the error strings in one place.
sub _error {
   my ($code) = shift;
	my $errorbar = "\n!-----------------!\n";
   my @e = (
   "", # Normal execution
   "Input error: Must pass in a filename for a file containing the data.\n\tEx: \$g = new Statistics::Gtest(\$datafile);",
   "Input error: Can't use array or hash as data; pass array ref.",
   "Input error: Invalid data format.",
   "Input error: Data must be structured as array of array refs, with each array ref
   pointing to one row of data.",
   "Data inconsistency: No data found in table.",
   "Data inconsistency: sum of table values does not match total.",
   "Data inconsistency: could not read row or column.",
   "Data invalid: All data must be positive integers.",
   "Data invalid: Found a zero frequency value. Can't continue.",
   "Input error: Reference to invalid data type; must be reference to array.",
   );

	print $errorbar;
	print "\n Error",Carp::shortmess();
   print " ", $e[$code], "\n";
	print Carp::longmess(" Stack trace:\n");
	print $errorbar;
   exit $code; 
}

1; 

__END__

=head1 NAME

Statistics::Gtest - calculate G-statistic for tabular data

=head1 SYNOPSIS

   use Statistics::Gtest;

   $gt = Statistics::Gtest->new($data);
    
    $degreesOfFreedom = $gt->getDF();
    $gstat = $gt->getG();
    
    $gt->setExpected($expectedvalues);
    $uncorrectedG = $gt->getRawG();
    
=head1 DESCRIPTION

C<Statistics::Gtest> is a class that calculates the G-statistic for
goodness of fit for frequency data. It can be used on simple frequency
distributions (1-way tables) or for analyses of independence (2-way
tables).

Note that C<Statistics::Gtest> will B<not>, by itself, perform the
significance test for you -- it just provides the G-statistic that
can then be compared with the chi-square distribution to determine
significance.

=head1 OVERVIEW and EXAMPLES

A goodness of fit test attempts to determine if an observed frequency
distribution differs significantly from a hypothesized frequency
distribution. From C<Statistics::Gtest>'s point of view, these tests
come in two flavors: 1-way tests (where a single frequency distribution
is tested against an expected distribution) and 2-way tests (where a
matrix of observed values is tested for independence -- that is, the
lack of interaction effects among the two axes being measured).

A simple example might help here. You've grown 160 plants from seed
produced by a single parent plant. You observe that among the offspring
plants, some have spiny leaves, some have hairy leaves, and some have
smooth leaves. What is the likelihood that the distribution of this
trait follows the expected values for simple Mendelian inheritance?

 Observed values:
   Spiny Hairy Smooth
     95    53    12

 Expected values (for a 9:3:3:1 ratio):
     90    60    10

If the observed and expected values are put into two files,
C<Statistics::Gtest> can create a G-statistic object that will calculate
the likelihood that the observed distribution is significantly different
from the distribution that would be expected by simple inheritance. (The
value of G for this comparison is approximately 1.495, with 2 degrees
of freedom; the observed results are not significantly different from
expected at the .05 -- or even .1 level.)

2-way tests will usually not need a table of expected values, as the
expected values are generated from the observed value sums. However,
one can be loaded for 2-way tables as well.

To determine if the calculated G statistic indicates a statistically
significant result, you will need to look up the values in a chi-square
distribution on your own, or make use of the C<Statistics::Distributions>
module:

 use Statistics::Gtest;
 use Statistics::Distributions;

 ...

 my $gt = Statistics::Gtest->new($data);
 my $df = $gt->getDF();
 my $g = $gt->getG();
 my $sig = '.05';
 my $chis=Statistics::Distributions::chisqrdistr ($df,$sig);
 if ($g > $chis) {
   print "$g: Sig. at the $sv level. ($chis cutoff)\n"
 } 

By default, C<Statistics::Gtest> returns a G statistic that has been
modified by William's correction (Williams 1976). This correction reduces
the value of G for smaller sample sizes, and has progressively less
effect as the sample size increases. The raw, uncorrected G statistic
is also available.

=head3 References

=over 

=item 

Sokal, R.R., and F.J. Rohlf, Biometry. 1981.  W.H. Freeman and Company,
San Francisco.

=item 

Williams, D.A. 1976. Improved likelihood ratio test for complete
contingency tables. Biometrika, 63:33 - 37.

=back

=head2 Public Methods

=head3 Constructor

   $g = Statistics::Gtest->new($data);
   $g = new Statistics::Gtest($data);

I<$data> can be in several formats.  All of the following are valid:

 * whitespace-delimited string:          "95 53 12"  
 * reference to 1-dimensional array:     [ 95, 53, 12 ]   
 * reference to 2-dimensional array:     [ [ 10, 20 ], [ 20, 15 ] ]
 * external file or filehandle reference.

Data in files must be arranged into rows and columns, separated by
whitespace. In all cases,  must be B<no> non-numeric characters, B<no> 
empty cells, and B<no> zero counts.  Arrays are B<not> valid input. 

=head3 getG

   $float = $g->getG();

Returns the corrected G-statistic for the current observed and expected
frequency counts.

=head3 getRawG

   $float = $g->getRawG();

Returns the uncorrected G-statistic for the current observed and expected
frequency counts. This value can be misleadingly large for small sample
sizes (n < 200).

=head3 getQ

   $float = $g->getQ();

Returns Williams' correction (q) for this test.  (See explanation in
'Overview and Examples'.)

=head3 getObserved

   $arrayref = $g->getObserved();

Returns an array reference containing the observed cell values. The
array is formatted in the same row-column layout as the input data.

=head3 getExpected

   $arrayref = $g->getExpected();

Returns an array reference containing the expected cell values. The
array is formatted in the same row-column layout as the observed data.

=head3 setExpected

   $g->setExpected($string);
   $g->setExpected($arrayref);
   $g->setExpected($filename);
   $g->setExpected($filehandle);

If testing with a specific hypothesized distribution, the expected
frequency values for that distribution, given the total sample size,
must be input to C<Statistics::Gtest>. The input data has the same
contraints on format as does the initial data.

=head3 getDF

   $integer = $g->getDF();

Returns the current degrees of freedom for this distribution, which is
calculated automatically from the observed data (I<rows> - 1 for 1-way
tests, (I<rows> - 1) * (I<cols> - 1) for 2-way tests).

=head3 setDF

   $g->setDF($integer);

Sets the degrees of freedom for this distribution. Sometimes
this value needs to be modified beyond the standard rules used by
C<Statistics::Gtest>; C<setDF> makes this possible.

=head3 getRow

   $rowref = $g->getRow(rownum);

Returns a row from the array of observed data. Row numbering is
zero-based.

=head3 getCol

   $colref = $g->getCol(colnum);

Returns a column for the array of observed data. Column numbering is
zero-based.

=head3 rowSum

   $integer = $g->rowSum($index);

Returns the sum of the requested row.

=head3 colSum

   $integer = $g->colSum($index);

Returns the sum of the requested column.

=head3 getRowNum

   $integer = $g->getRowNum();

Returns the number of rows in the data table.

=head3 getColNum

   $integer = $g->getColNum();

Returns the number of columns in the data table.

=head3 getSumTotal

   $integer = $g->getSumTotal();

Returns the total number of observations.

=cut

