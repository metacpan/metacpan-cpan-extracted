package Spreadsheet::Engine::Functions;
## no critic

=head1 NAME

Spreadsheet::Engine::Functions - Spreadsheet functions (SUM, MAX, etc)

=head1 SYNOPSIS

  my $ok = calculate_function($fname, \@operand, \$errortext, \%typelookup, \%sheetdata);

=head1 DESCRIPTION

This provides all the spreadsheet functions (SUM, MAX, IRR, ISNULL,
etc). 

=cut

use strict;

use Spreadsheet::Engine::Sheet;    # bah!
use Time::Local;                   # For timegm in NOW and TODAY
use Encode;

use base 'Exporter';
our @EXPORT    = qw(calculate_function);
our @EXPORT_OK = qw(cr_to_coord);

#0 = no arguments
#>0 = exactly that many arguments
#<0 = that many arguments (abs value) or more

our %function_list = (
  COLUMNS   => [ \&columns_rows_function,   1 ],
  COUNTIF   => [ \&countif_sumif_functions, 2 ],
  DAVERAGE  => [ \&dseries_functions,       3 ],
  DCOUNT    => [ \&dseries_functions,       3 ],
  DCOUNTA   => [ \&dseries_functions,       3 ],
  DGET      => [ \&dseries_functions,       3 ],
  DMAX      => [ \&dseries_functions,       3 ],
  DMIN      => [ \&dseries_functions,       3 ],
  DPRODUCT  => [ \&dseries_functions,       3 ],
  DSTDEV    => [ \&dseries_functions,       3 ],
  DSTDEVP   => [ \&dseries_functions,       3 ],
  DSUM      => [ \&dseries_functions,       3 ],
  DVAR      => [ \&dseries_functions,       3 ],
  DVARP     => [ \&dseries_functions,       3 ],
  INDEX     => [ \&index_function,          -1 ],
  ROWS      => [ \&columns_rows_function,   1 ],
  SUMIF     => [ \&countif_sumif_functions, -2 ],
  HTML      => [ \&html_function,           -1 ],
  PLAINTEXT => [ \&text_function,           -1 ],
);

=head1 EXTENDING

=head2 register

  Spreadsheet::Engine->register(SUM => 'Spreadsheet::Engine::Function::SUM');

If you wish to make a new function available you should register it
here. A series of base classes are provided that do all the argument
checking etc., allowing you to concentrate on the calculations. Have a
look at how the existing functions are implemented for details (it
should hopefully be mostly self-explanatory!)

information on how many arguments should be passed:

=cut

my $_reg = {};

sub register {
  my ($class, %to_reg) = @_;
  while (my ($name, $where) = each %to_reg) {
    eval "use $where";
    die $@ if $@;
    $_reg->{$name} = $where;
  }
}

__PACKAGE__->register(
  map +($_ => "Spreadsheet::Engine::Function::$_"),
  qw/ ABS ACOS AND ASIN ATAN ATAN2 AVERAGE CHOOSE COS COUNT COUNTA
    COUNTBLANK DATE DAY DDB DEGREES ERRCELL EVEN EXACT EXP FACT FALSE FIND
    FV HLOOKUP HOUR IF INT IRR ISBLANK ISERR ISERROR ISLOGICAL ISNA
    ISNONTEXT ISNUMBER ISTEXT LEFT LEN LN LOG LOG10 LOWER MATCH MAX MID
    MIN MINUTE MOD MONTH N NA NOT NOW NPER NPV ODD OR PI PMT POWER PRODUCT
    PROPER PV RADIANS RATE REPLACE REPT RIGHT ROUND SECOND SIN SLN SQRT
    STDEV STDEVP SUBSTITUTE SUM SYD T TAN TIME TODAY TRIM TRUE TRUNC UPPER
    VALUE VAR VARP VLOOKUP WEEKDAY YEAR /
);

=head1 EXPORTS

=head2 calculate_function

  my $ok = calculate_function($fname, \@operand, \$errortext, \%typelookup, \%sheetdata);

=cut

sub calculate_function {

  my ($fname, $operand, $errortext, $typelookup, $sheetdata) = @_;

  # has the function been registered? (new style)
  if (my $fclass = $_reg->{$fname}) {
    my $fn = $fclass->new(
      fname      => $fname,
      operand    => $operand,
      errortext  => $errortext,
      typelookup => $typelookup,
      sheetdata  => $sheetdata,
    );
    $fn->execute;
    return 1;
  }

  # Otherwise is it in our function_list (old style)
  my ($function_sub, $want_args) = @{ $function_list{$fname} }[ 0, 1 ];

  if ($function_sub) {
    copy_function_args($operand, \my @foperand);

    my $have_args = scalar @foperand;

    if ( ($want_args < 0 and $have_args < -$want_args)
      or ($want_args >= 0 and $have_args != $want_args)) {
      function_args_error($fname, $operand, $errortext);
      return 0;
    }

    $function_sub->(
      $fname, $operand, \@foperand, $errortext, $typelookup, $sheetdata
    );
  } else {
    my $ttext = $fname;
    if (@$operand && $operand->[ @$operand - 1 ]->{type} eq "start")
    {    # no arguments - name or zero arg function
      pop @$operand;
      push @$operand, { type => "name", value => $ttext };
    } else {
      $$errortext = "Unknown function $ttext. ";
    }
  }
  return 1;
}

=head1 FUNCTION providers

=head2 dseries_functions

=over 

=item DAVERAGE(databaserange, fieldname, criteriarange)

=item DCOUNT(databaserange, fieldname, criteriarange)

=item DCOUNTA(databaserange, fieldname, criteriarange)

=item DGET(databaserange, fieldname, criteriarange)

=item DMAX(databaserange, fieldname, criteriarange)

=item DMIN(databaserange, fieldname, criteriarange)

=item DPRODUCT(databaserange, fieldname, criteriarange)

=item DSTDEV(databaserange, fieldname, criteriarange)

=item DSTDEVP(databaserange, fieldname, criteriarange)

=item DSUM(databaserange, fieldname, criteriarange)

=item DVAR(databaserange, fieldname, criteriarange)

=item DVARP(databaserange, fieldname, criteriarange)

=back

=cut

# Calculate all of these and then return the desired one (overhead is in accessing not calculating)
# If this routine is changed, check the series_functions, too.

sub dseries_functions {

  my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

  my ($value1, $tostype, $cr);

  my $sum           = 0;
  my $resulttypesum = "";
  my $count         = 0;
  my $counta        = 0;
  my $countblank    = 0;
  my $product       = 1;
  my $maxval;
  my $minval;
  my ($mk, $sk, $mk1, $sk1); # For variance, etc.: M sub k, k-1, and S sub k-1
       # as per Knuth "The Art of Computer Programming" Vol. 2 3rd edition, page 232

  my ($dbrange, $dbrangetype) =
    top_of_stack_value_and_type($sheetdata, $foperand, $errortext);
  my $fieldtype;
  my $fieldname =
    operand_value_and_type($sheetdata, $foperand, $errortext, \$fieldtype);
  my ($criteriarange, $criteriarangetype) =
    top_of_stack_value_and_type($sheetdata, $foperand, $errortext);

  if ($dbrangetype ne "range" || $criteriarangetype ne "range") {
    function_args_error($fname, $operand, $errortext);
    return 0;
  }

  my ($dbsheetdata, $dbcol1num, $ndbcols, $dbrow1num, $ndbrows) =
    decode_range_parts($sheetdata, $dbrange, $dbrangetype);
  my (
    $criteriasheetdata, $criteriacol1num, $ncriteriacols,
    $criteriarow1num,   $ncriteriarows
    )
    = decode_range_parts($sheetdata, $criteriarange, $criteriarangetype);

  my $fieldasnum =
    field_to_colnum($dbsheetdata, $dbcol1num, $ndbcols, $dbrow1num,
    $fieldname, $fieldtype);
  $fieldasnum = int($fieldasnum);
  if ($fieldasnum <= 0) {
    push @$operand, { type => "e#VALUE!", value => 0 };
    return;
  }

  my $targetcol = $dbcol1num + $fieldasnum - 1;

  my (@criteriafieldnums, $criteriafieldname, $criteriafieldtype,
    $criterianum);

  for (my $i = 0 ; $i < $ncriteriacols ; $i++) {  # get criteria field colnums
    my $criteriacr = cr_to_coord($criteriacol1num + $i, $criteriarow1num);
    $criteriafieldname = $criteriasheetdata->{datavalues}->{$criteriacr};
    $criteriafieldtype = $criteriasheetdata->{valuetypes}->{$criteriacr};
    $criterianum       =
      field_to_colnum($dbsheetdata, $dbcol1num, $ndbcols, $dbrow1num,
      $criteriafieldname, $criteriafieldtype);
    $criterianum = int($criterianum);
    if ($criterianum <= 0) {
      push @$operand, { type => "e#VALUE!", value => 0 };
      return;
    }
    push @criteriafieldnums, $dbcol1num + $criterianum - 1;
  }

  my ($testok, $criteria, $testcol, $testcr);

  for (my $i = 1 ; $i < $ndbrows ; $i++)
  {    # go through each row of the database
    $testok = 0;
    CRITERIAROW:
    for (my $j = 1 ; $j < $ncriteriarows ; $j++)
    {    # go through each criteria row
      for (my $k = 0 ; $k < $ncriteriacols ; $k++) {    # look at each column
        my $criteriacr =
          cr_to_coord($criteriacol1num + $k, $criteriarow1num + $j)
          ;                                             # where criteria is
        $criteria = $criteriasheetdata->{datavalues}->{$criteriacr};
        next unless $criteria;                          # blank items are OK
        $testcol =
          $criteriasheetdata->{datavalues}
          ->{ cr_to_coord($criteriacol1num + $k, $criteriarow1num) };
        $testcol = $criteriafieldnums[$k];
        $testcr = cr_to_coord($testcol, $dbrow1num + $i);    # cell to check
        next CRITERIAROW
          unless test_criteria($criteriasheetdata->{datavalues}->{$testcr},
          ($criteriasheetdata->{valuetypes}->{$testcr} || "b"), $criteria);
      }
      $testok = 1;
      last CRITERIAROW;
    }
    next unless $testok;

    $cr =
      cr_to_coord($targetcol, $dbrow1num + $i)
      ;    # get cell of this row to do the function on
    $value1  = $dbsheetdata->{datavalues}->{$cr};
    $tostype = $dbsheetdata->{valuetypes}->{$cr};
    $tostype ||= "b";
    if ($tostype eq "b") {    # blank
      $value1 = 0;
    }

    $count += 1 if substr($tostype, 0, 1) eq "n";
    $counta += 1 if substr($tostype, 0, 1) ne "b";
    $countblank += 1 if substr($tostype, 0, 1) eq "b";

    if (substr($tostype, 0, 1) eq "n") {
      $sum += $value1;
      $product *= $value1;
      $maxval =
        (defined $maxval) ? ($value1 > $maxval ? $value1 : $maxval) : $value1;
      $minval =
        (defined $minval) ? ($value1 < $minval ? $value1 : $minval) : $value1;
      if ($count eq 1)
      { # initialize with with first values for variance used in STDEV, VAR, etc.
        $mk1 = $value1;
        $sk1 = 0;
      } else {    # Accumulate S sub 1 through n as per Knuth noted above
        $mk = $mk1 + ($value1 - $mk1) / $count;
        $sk = $sk1 + ($value1 - $mk1) * ($value1 - $mk);
        $sk1 = $sk;
        $mk1 = $mk;
      }
      $resulttypesum =
        lookup_result_type($tostype, $resulttypesum || $tostype,
        $typelookup->{plus});
    } elsif (substr($tostype, 0, 1) eq "e"
      && substr($resulttypesum, 0, 1) ne "e") {
      $resulttypesum = $tostype;
    }
  }

  $resulttypesum ||= "n";

  if ($fname eq "DSUM") {
    push @$operand, { type => $resulttypesum, value => $sum };
  } elsif ($fname eq "DPRODUCT")
  {    # may handle cases with text differently than some other spreadsheets
    push @$operand, { type => $resulttypesum, value => $product };
  } elsif ($fname eq "DMIN") {
    push @$operand, { type => $resulttypesum, value => ($minval || 0) };
  } elsif ($fname eq "DMAX") {
    push @$operand, { type => $resulttypesum, value => ($maxval || 0) };
  } elsif ($fname eq "DCOUNT") {
    push @$operand, { type => "n", value => $count };
  } elsif ($fname eq "DCOUNTA") {
    push @$operand, { type => "n", value => $counta };
  } elsif ($fname eq "DAVERAGE") {
    if ($count > 0) {
      push @$operand, { type => $resulttypesum, value => ($sum / $count) };
    } else {
      push @$operand, { type => "e#DIV/0!", value => 0 };
    }
  } elsif ($fname eq "DSTDEV") {
    if ($count > 1) {
      push @$operand,
        { type => $resulttypesum, value => (sqrt($sk / ($count - 1))) };
    } else {
      push @$operand, { type => "e#DIV/0!", value => 0 };
    }
  } elsif ($fname eq "DSTDEVP") {
    if ($count > 1) {
      push @$operand,
        { type => $resulttypesum, value => (sqrt($sk / $count)) };
    } else {
      push @$operand, { type => "e#DIV/0!", value => 0 };
    }
  } elsif ($fname eq "DVAR") {
    if ($count > 1) {
      push @$operand,
        { type => $resulttypesum, value => ($sk / ($count - 1)) };
    } else {
      push @$operand, { type => "e#DIV/0!", value => 0 };
    }
  } elsif ($fname eq "DVARP") {
    if ($count > 1) {
      push @$operand, { type => $resulttypesum, value => ($sk / $count) };
    } else {
      push @$operand, { type => "e#DIV/0!", value => 0 };
    }
  } elsif ($fname eq "DGET") {
    if ($count == 1) {
      push @$operand, { type => $resulttypesum, value => $sum };
    } elsif ($count == 0) {
      push @$operand, { type => "e#VALUE!", value => 0 };
    } else {
      push @$operand, { type => "e#NUM!", value => 0 };
    }
  }

  return;
}

=head2 index_function

=over

=item INDEX(range, rownum, colnum)

=back

=cut

sub index_function {

  my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

  my ($range, $rangetype) =
    top_of_stack_value_and_type($sheetdata, $foperand, $errortext)
    ;    # get range
  if ($rangetype ne "range") {
    function_args_error($fname, $operand, $errortext);
    return 0;
  }
  my ($indexsheetdata, $col1num, $ncols, $row1num, $nrows) =
    decode_range_parts($sheetdata, $range, $rangetype);

  my $rowindex = 0;
  my $colindex = 0;
  my $tostype;

  if (scalar @$foperand) {    # look for row number
    $rowindex =
      operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
    if (substr($tostype, 0, 1) ne "n" || $rowindex < 0) {
      push @$operand, { type => "e#VALUE!", value => 0 };
      return;
    }
    if (scalar @$foperand) {    # look for col number
      $colindex =
        operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
      if (substr($tostype, 0, 1) ne "n" || $colindex < 0) {
        push @$operand, { type => "e#VALUE!", value => 0 };
        return;
      }
      if (scalar @$foperand) {
        function_args_error($fname, $operand, $errortext);
        return 0;
      }
    } else {                    # col number missing
      if ($nrows == 1) {   # if only one row, then rowindex is really colindex
        $colindex = $rowindex;
        $rowindex = 0;
      }
    }
  }

  if ($rowindex > $nrows || $colindex > $ncols) {
    push @$operand, { type => "e#REF!", value => 0 };
    return;
  }

  my ($result, $resulttype);

  if ($rowindex == 0) {
    if ($colindex == 0) {
      if ($nrows == 1 && $ncols == 1) {
        $result = cr_to_coord($col1num, $row1num);
        $resulttype = "coord";
      } else {
        $result =
          cr_to_coord($col1num, $row1num) . "|"
          . cr_to_coord($col1num + $ncols - 1, $row1num + $nrows - 1) . "|";
        $resulttype = "range";
      }
    } else {
      if ($nrows == 1) {
        $result = cr_to_coord($col1num + $colindex - 1, $row1num);
        $resulttype = "coord";
      } else {
        $result =
          cr_to_coord($col1num + $colindex - 1, $row1num) . "|"
          . cr_to_coord($col1num + $colindex - 1, $row1num + $nrows - 1)
          . "|";
        $resulttype = "range";
      }
    }
  } else {
    if ($colindex == 0) {
      if ($ncols == 1) {
        $result = cr_to_coord($col1num, $row1num + $rowindex - 1);
        $resulttype = "coord";
      } else {
        $result =
          cr_to_coord($col1num, $row1num + $rowindex - 1) . "|"
          . cr_to_coord($col1num + $ncols - 1, $row1num + $rowindex - 1)
          . "|";
        $resulttype = "range";
      }
    } else {
      $result =
        cr_to_coord($col1num + $colindex - 1, $row1num + $rowindex - 1);
      $resulttype = "coord";
    }
  }

  push @$operand, { type => $resulttype, value => $result };
  return;

}

=head2 countif_sumif_functions

=over

=item COUNTIF(c1:c2,"criteria")

=item SUMIF(c1:c2,"criteria")

=back

=cut

sub countif_sumif_functions {

  my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

  my ($tostype, $tostype2, $sumrangevalue, $sumrangetype);

  my ($rangevalue, $rangetype) =
    top_of_stack_value_and_type($sheetdata, $foperand, $errortext)
    ;    # get range or coord
  my ($criteriavalue, $criteriatype) =
    operand_as_text($sheetdata, $foperand, $errortext, \$tostype)
    ;    # get criteria
  if ($fname eq "SUMIF") {
    if ((scalar @$foperand) == 1) {    # three arg form of SUMIF
      ($sumrangevalue, $sumrangetype) =
        top_of_stack_value_and_type($sheetdata, $foperand, $errortext);
    } elsif ((scalar @$foperand) == 0) {    # two arg form
      $sumrangevalue = $rangevalue;
      $sumrangetype  = $rangetype;
    } else {
      function_args_error($fname, $operand, $errortext);
      return 0;
    }
  } else {
    $sumrangevalue = $rangevalue;
    $sumrangetype  = $rangetype;
  }

  my $ct = substr($criteriatype || '', 0, 1) || '';
  if ($ct eq "n") {
    $criteriavalue = "$criteriavalue";
  } elsif ($ct eq "e") {    # error
    undef $criteriavalue;
  } elsif ($ct eq "b") {    # blank here is undefined
    undef $criteriavalue;
  }

  if ($rangetype ne "coord" && $rangetype ne "range") {
    function_args_error($fname, $operand, $errortext);
    return 0;
  }

  if ( $fname eq "SUMIF"
    && $sumrangetype ne "coord"
    && $sumrangetype ne "range") {
    function_args_error($fname, $operand, $errortext);
    return 0;
  }

  push @$foperand, { type => $rangetype, value => $rangevalue };
  my @f2operand;    # to allow for 3 arg form
  push @f2operand, { type => $sumrangetype, value => $sumrangevalue };

  my $sum           = 0;
  my $resulttypesum = "";
  my $count         = 0;

  while (@$foperand) {
    my $value1 =
      operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
    my $value2 =
      operand_value_and_type($sheetdata, \@f2operand, $errortext, \$tostype2);

    next unless test_criteria($value1, $tostype, $criteriavalue);

    $count += 1;

    if (substr($tostype2, 0, 1) eq "n") {
      $sum += $value2;
      $resulttypesum =
        lookup_result_type($tostype2, $resulttypesum || $tostype2,
        $typelookup->{plus});
    } elsif (substr($tostype2, 0, 1) eq "e"
      && substr($resulttypesum, 0, 1) ne "e") {
      $resulttypesum = $tostype2;
    }
  }

  $resulttypesum ||= "n";

  if ($fname eq "SUMIF") {
    push @$operand, { type => $resulttypesum, value => $sum };
  } elsif ($fname eq "COUNTIF") {
    push @$operand, { type => "n", value => $count };
  }

  return;

}

=head2 columns_rows_function

=over

=item COLUMNS(c1:c2)

=item ROWS(c1:c2)

=back

=cut

sub columns_rows_function {

  my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

  my ($value1, $tostype, $resultvalue, $resulttype);

  ($value1, $tostype) =
    top_of_stack_value_and_type($sheetdata, $foperand, $errortext);

  if ($tostype eq "coord") {
    $resultvalue = 1;
    $resulttype  = "n";
  } elsif ($tostype eq "range") {
    my ($v1, $v2, $sequence) = split (/\|/, $value1);
    my ($sheet1, $sheet2);
    ($v1, $sheet1) = split (/!/, $v1);
    ($v2, $sheet2) = split (/!/, $v2);
    my ($c1, $r1) = coord_to_cr($v1);
    my ($c2, $r2) = coord_to_cr($v2);
    ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
    ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);

    if ($fname eq "COLUMNS") {
      $resultvalue = $c2 - $c1 + 1;
    } elsif ($fname eq "ROWS") {
      $resultvalue = $r2 - $r1 + 1;
    }
    $resulttype = "n";
  } else {
    $resultvalue = 0;
    $resulttype  = "e#VALUE!";
  }

  push @$operand, { type => $resulttype, value => $resultvalue };

  return;

}

=head2 text_function

=over

=item PLAINTEXT

=back

=cut

sub text_function {

  my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

  my ($value1, $tostype, $resulttype);

  my $textstr = "";
  $resulttype = "";
  while (@$foperand) {
    $value1 = operand_as_text($sheetdata, $foperand, $errortext, \$tostype);
    if (substr($tostype, 0, 1) eq "t") {
      $textstr .= $value1;
      $resulttype = lookup_result_type($tostype, $resulttype || $tostype,
        $typelookup->{concat});
    } elsif (substr($tostype, 0, 1) eq "e"
      && substr($resulttype, 0, 1) ne "e") {
      $resulttype = $tostype;
    }
  }
  $resulttype = substr($resulttype, 0, 1) eq "t" ? "t" : $resulttype;
  push @$operand, { type => $resulttype, value => $textstr };

  return;

}

=head2 html_function

=over

=item HTML

=back

=cut

sub html_function {

  my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

  my ($value1, $tostype, $resulttype);

  my $textstr = "";
  $resulttype = "";
  while (@$foperand) {
    $value1 = operand_as_text($sheetdata, $foperand, $errortext, \$tostype);
    if (substr($tostype, 0, 1) eq "t") {
      $textstr .= $value1;
      $resulttype = lookup_result_type($tostype, $resulttype || $tostype,
        $typelookup->{concat});
    } elsif (substr($tostype, 0, 1) eq "e"
      && substr($resulttype, 0, 1) ne "e") {
      $resulttype = $tostype;
    }
  }
  $resulttype = substr($resulttype, 0, 1) eq "t" ? "th" : $resulttype;
  push @$operand, { type => $resulttype, value => $textstr };

  return;

}

=head1 HELPERS

=head2 field_to_colnum

  $colnum = field_to_colnum(\@sheetdata, $col1num, $ncols, $row1num, $fieldname, $fieldtype)

If fieldname is a number, uses it, otherwise looks up string in cells in row to find field number

If not found, returns 0.

=cut

sub field_to_colnum {

  my ($sheetdata, $col1num, $ncols, $row1num, $fieldname, $fieldtype) = @_;

  if (substr($fieldtype, 0, 1) eq "n") {    # number - return it if legal
    if ($fieldname <= 0 || $fieldname > $ncols) {
      return 0;
    }
    return int($fieldname);
  }

  if (substr($fieldtype, 0, 1) ne "t") {    # must be text otherwise
    return 0;
  }

  $fieldname = decode('utf8', $fieldname);    # change UTF-8 bytes to chars
  $fieldname = lc $fieldname;

  my ($cr, $value);

  for (my $i = 0 ; $i < $ncols ; $i++)
  {    # look through column headers for a match
    $cr    = cr_to_coord($col1num + $i, $row1num);
    $value = $sheetdata->{datavalues}->{$cr};
    $value = decode('utf8', $value);
    $value = lc $value;                              #ignore case
    next if $value ne $fieldname;                    # no match
    return $i + 1;                                   # match
  }
  return 0;    # looked at all and no match
}

1;

__END__

=head1 HISTORY

This is a Modified Version of SocialCalc::Functions from SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0


