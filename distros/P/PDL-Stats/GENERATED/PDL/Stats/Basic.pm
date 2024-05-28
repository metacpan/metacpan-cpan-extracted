#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Stats::Basic;

our @EXPORT_OK = qw(binomial_test rtable which_id stdv stdv_unbiased var var_unbiased se ss skew skew_unbiased kurt kurt_unbiased cov cov_table corr corr_table t_corr n_pair corr_dev t_test t_test_nev t_test_paired );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Stats::Basic ;







#line 4 "stats_basic.pd"

use PDL::LiteF;
use PDL::NiceSlice;
use Carp;

eval { require PDL::Core; require PDL::GSL::CDF; };
my $CDF = 1 if !$@;

=head1 NAME

PDL::Stats::Basic -- basic statistics and related utilities such as standard deviation, Pearson correlation, and t-tests.

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are threadable and methods that are NOT threadable, respectively.

Does not have mean or median function here. see SEE ALSO.

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::NiceSlice;
    use PDL::Stats::Basic;

    my $stdv = $data->stdv;

or

    my $stdv = stdv( $data );  

=cut
#line 58 "Basic.pm"


=head1 FUNCTIONS

=cut






=head2 stdv

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Sample standard deviation.

=cut
  

=for bad

stdv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*stdv = \&PDL::stdv;






=head2 stdv_unbiased

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Unbiased estimate of population standard deviation.

=cut
  

=for bad

stdv_unbiased processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*stdv_unbiased = \&PDL::stdv_unbiased;






=head2 var

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Sample variance.

=cut
  

=for bad

var processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*var = \&PDL::var;






=head2 var_unbiased

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Unbiased estimate of population variance.

=cut
  

=for bad

var_unbiased processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*var_unbiased = \&PDL::var_unbiased;






=head2 se

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Standard error of the mean. Useful for calculating confidence intervals.

=for usage

    # 95% confidence interval for samples with large N

    $ci_95_upper = $data->average + 1.96 * $data->se;
    $ci_95_lower = $data->average - 1.96 * $data->se;

  

=for bad

se processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*se = \&PDL::se;






=head2 ss

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Sum of squared deviations from the mean.

=cut
  

=for bad

ss processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ss = \&PDL::ss;






=head2 skew

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Sample skewness, measure of asymmetry in data. skewness == 0 for normal distribution.

=cut
  

=for bad

skew processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*skew = \&PDL::skew;






=head2 skew_unbiased

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Unbiased estimate of population skewness. This is the number in GNumeric Descriptive Statistics.

=cut
  

=for bad

skew_unbiased processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*skew_unbiased = \&PDL::skew_unbiased;






=head2 kurt

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Sample kurtosis, measure of "peakedness" of data. kurtosis == 0 for normal distribution. 

=cut
  

=for bad

kurt processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*kurt = \&PDL::kurt;






=head2 kurt_unbiased

=for sig

  Signature: (a(n); float+ [o]b())

=for ref

Unbiased estimate of population kurtosis. This is the number in GNumeric Descriptive Statistics.

=cut
  

=for bad

kurt_unbiased processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*kurt_unbiased = \&PDL::kurt_unbiased;






=head2 cov

=for sig

  Signature: (a(n); b(n); float+ [o]c())

=for ref

Sample covariance. see B<corr> for ways to call

=cut
  

=for bad

cov processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cov = \&PDL::cov;






=head2 cov_table

=for sig

  Signature: (a(n,m); float+ [o]c(m,m))

=for ref

Square covariance table. Gives the same result as threading using B<cov> but it calculates only half the square, hence much faster. And it is easier to use with higher dimension pdls.

=for usage

Usage:

    # 5 obs x 3 var, 2 such data tables

    perldl> $a = random 5, 3, 2

    perldl> p $cov = $a->cov_table
    [
     [
      [ 8.9636438 -1.8624472 -1.2416588]
      [-1.8624472  14.341514 -1.4245366]
      [-1.2416588 -1.4245366  9.8690655]
     ]
     [
      [   10.32644 -0.31311789 -0.95643674]
      [-0.31311789   15.051779  -7.2759577]
      [-0.95643674  -7.2759577   5.4465141]
     ]
    ]
    # diagonal elements of the cov table are the variances
    perldl> p $a->var
    [
     [ 8.9636438  14.341514  9.8690655]
     [  10.32644  15.051779  5.4465141]
    ]

for the same cov matrix table using B<cov>,

    perldl> p $a->dummy(2)->cov($a->dummy(1)) 

  

=for bad

cov_table processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cov_table = \&PDL::cov_table;






=head2 corr

=for sig

  Signature: (a(n); b(n); float+ [o]c())

=for ref

Pearson correlation coefficient. r = cov(X,Y) / (stdv(X) * stdv(Y)).

=for usage 

Usage:

    perldl> $a = random 5, 3
    perldl> $b = sequence 5,3
    perldl> p $a->corr($b)

    [0.20934208 0.30949881 0.26713007]

for square corr table

    perldl> p $a->corr($a->dummy(1))

    [
     [           1  -0.41995259 -0.029301192]
     [ -0.41995259            1  -0.61927619]
     [-0.029301192  -0.61927619            1]
    ]

but it is easier and faster to use B<corr_table>.

=cut
  

=for bad

corr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*corr = \&PDL::corr;






=head2 corr_table

=for sig

  Signature: (a(n,m); float+ [o]c(m,m))

=for ref

Square Pearson correlation table. Gives the same result as threading using B<corr> but it calculates only half the square, hence much faster. And it is easier to use with higher dimension pdls.

=for usage

Usage:

    # 5 obs x 3 var, 2 such data tables
 
    perldl> $a = random 5, 3, 2
    
    perldl> p $a->corr_table
    [
     [
     [          1 -0.69835951 -0.18549048]
     [-0.69835951           1  0.72481605]
     [-0.18549048  0.72481605           1]
    ]
    [
     [          1  0.82722569 -0.71779883]
     [ 0.82722569           1 -0.63938828]
     [-0.71779883 -0.63938828           1]
     ]
    ]

for the same result using B<corr>,

    perldl> p $a->dummy(2)->corr($a->dummy(1)) 

This is also how to use B<t_corr> and B<n_pair> with such a table.

  

=for bad

corr_table processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*corr_table = \&PDL::corr_table;






=head2 t_corr

=for sig

  Signature: (r(); n(); [o]t())

=for usage

    $corr   = $data->corr( $data->dummy(1) );
    $n      = $data->n_pair( $data->dummy(1) );
    $t_corr = $corr->t_corr( $n );

    use PDL::GSL::CDF;

    $p_2tail = 2 * (1 - gsl_cdf_tdist_P( $t_corr->abs, $n-2 ));

=for ref

t significance test for Pearson correlations.

=cut
  

=for bad

t_corr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*t_corr = \&PDL::t_corr;






=head2 n_pair

=for sig

  Signature: (a(n); b(n); indx [o]c())

=for ref

Returns the number of good pairs between 2 lists. Useful with B<corr> (esp. when bad values are involved)

=cut
  

=for bad

n_pair processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*n_pair = \&PDL::n_pair;






=head2 corr_dev

=for sig

  Signature: (a(n); b(n); float+ [o]c())

=for usage

    $corr = $a->dev_m->corr_dev($b->dev_m);

=for ref

Calculates correlations from B<dev_m> vals. Seems faster than doing B<corr> from original vals when data pdl is big

=cut
  

=for bad

corr_dev processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*corr_dev = \&PDL::corr_dev;






=head2 t_test

=for sig

  Signature: (a(n); b(m); float+ [o]t(); [o]d())

=for usage

    my ($t, $df) = t_test( $pdl1, $pdl2 );

    use PDL::GSL::CDF;

    my $p_2tail = 2 * (1 - gsl_cdf_tdist_P( $t->abs, $df ));

=for ref

Independent sample t-test, assuming equal var.

=cut
  

=for bad

t_test processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*t_test = \&PDL::t_test;






=head2 t_test_nev

=for sig

  Signature: (a(n); b(m); float+ [o]t(); [o]d())

=for ref

Independent sample t-test, NOT assuming equal var. ie Welch two sample t test. Df follows Welch-Satterthwaite equation instead of Satterthwaite (1946, as cited by Hays, 1994, 5th ed.). It matches GNumeric, which matches R.

=for usage

    my ($t, $df) = $pdl1->t_test( $pdl2 );

=cut
  

=for bad

t_test_nev processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*t_test_nev = \&PDL::t_test_nev;






=head2 t_test_paired

=for sig

  Signature: (a(n); b(n); float+ [o]t(); [o]d())

=for ref

Paired sample t-test.

=cut
  

=for bad

t_test_paired processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*t_test_paired = \&PDL::t_test_paired;





#line 1251 "stats_basic.pd"

#line 1252 "stats_basic.pd"

=head2 binomial_test

=for Sig

  Signature: (x(); n(); p_expected(); [o]p())

=for ref

Binomial test. One-tailed significance test for two-outcome distribution. Given the number of successes, the number of trials, and the expected probability of success, returns the probability of getting this many or more successes.

This function does NOT currently support bad value in the number of successes.

=for usage

Usage:

  # assume a fair coin, ie. 0.5 probablity of getting heads
  # test whether getting 8 heads out of 10 coin flips is unusual

  my $p = binomial_test( 8, 10, 0.5 );  # 0.0107421875. Yes it is unusual.

=cut

*binomial_test = \&PDL::binomial_test;
sub PDL::binomial_test {
  my ($x, $n, $P) = @_;

  carp 'Please install PDL::GSL::CDF.' unless $CDF;
  carp 'This function does NOT currently support bad value in the number of successes.' if $x->badflag();

  my $pdlx = pdl($x);
  $pdlx->badflag(1);
  $pdlx = $pdlx->setvaltobad(0);

  my $p = 1 - PDL::GSL::CDF::gsl_cdf_binomial_P( $pdlx - 1, $P, $n );
  $p = $p->setbadtoval(1);
  $p->badflag(0);

  return $p;
}

=head1 METHODS

=head2 rtable

=for ref

Reads either file or file handle*. Returns observation x variable pdl and var and obs ids if specified. Ids in perl @ ref to allow for non-numeric ids. Other non-numeric entries are treated as missing, which are filled with $opt{MISSN} then set to BAD*. Can specify num of data rows to read from top but not arbitrary range.

*If passed handle, it will not be closed here.

=for options

Default options (case insensitive):

    V       => 1,        # verbose. prints simple status
    TYPE    => double,
    C_ID    => 1,        # boolean. file has col id.
    R_ID    => 1,        # boolean. file has row id.
    R_VAR   => 0,        # boolean. set to 1 if var in rows
    SEP     => "\t",     # can take regex qr//
    MISSN   => -999,     # this value treated as missing and set to BAD
    NROW    => '',       # set to read specified num of data rows

=for usage

Usage:

Sample file diet.txt:

    uid	height	weight	diet
    akw	72	320	1
    bcm	68	268	1
    clq	67	180	2
    dwm	70	200	2
  
    ($data, $idv, $ido) = rtable 'diet.txt';

    # By default prints out data info and @$idv index and element

    reading diet.txt for data and id... OK.
    data table as PDL dim o x v: PDL: Double D [4,3]
    0	height
    1	weight
    2	diet

Another way of using it,

    $data = rtable( \*STDIN, {TYPE=>long} );

=cut

sub rtable {
    # returns obs x var data matrix and var and obs ids
  my ($src, $opt) = @_;

  my $fh_in;
  if ($src =~ /STDIN/ or ref $src eq 'GLOB') { $fh_in = $src }
  else                                       { open $fh_in, $src or croak "$!" }

  my %opt = ( V       => 1,
              TYPE    => double,
              C_ID    => 1,
              R_ID    => 1,
              R_VAR   => 0,
              SEP     => "\t",
              MISSN   => -999,
              NROW    => '',
            );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt{V} and print STDERR "reading $src for data and id... ";
  
  local $PDL::undefval = $opt{MISSN};

  my $id_c = [];     # match declaration of $id_r for return purpose
  if ($opt{C_ID}) {
    chomp( $id_c = <$fh_in> );
    my @entries = split $opt{SEP}, $id_c;
    $opt{R_ID} and shift @entries;
    $id_c = \@entries;
  }

  my ($c_row, $id_r, $data, @data) = (0, [], PDL->null, );
  while (<$fh_in>) {
    chomp;
    my @entries = split /$opt{SEP}/, $_, -1;

    $opt{R_ID} and push @$id_r, shift @entries;
  
      # rudimentary check for numeric entry 
    for (@entries) { $_ = $opt{MISSN} unless defined $_ and m/\d\b/ }

    push @data, pdl( $opt{TYPE}, \@entries );
    $c_row ++;
    last
      if $opt{NROW} and $c_row == $opt{NROW};
  }
  # not explicitly closing $fh_in here in case it's passed from outside
  # $fh_in will close by going out of scope if opened here. 

  $data = pdl $opt{TYPE}, @data;
  @data = ();
    # rid of last col unless there is data there
  $data = $data(0:$data->getdim(0)-2, )->sever
    unless ( nelem $data(-1, )->where($data(-1, ) != $opt{MISSN}) ); 

  my ($idv, $ido) = ($id_r, $id_c);
    # var in columns instead of rows
  $opt{R_VAR} == 0
    and ($data, $idv, $ido) = ($data->inplace->transpose, $id_c, $id_r);

  if ($opt{V}) {
    print STDERR "OK.\ndata table as PDL dim o x v: " . $data->info . "\n";
    $idv and print STDERR "$_\t$$idv[$_]\n" for (0..$#$idv);
  }
 
  $data = $data->setvaltobad( $opt{MISSN} );
  $data->check_badflag;
  return wantarray? (@$idv? ($data, $idv, $ido) : ($data, $ido)) : $data;
}

=head2 group_by

Returns pdl reshaped according to the specified factor variable. Most useful when used in conjunction with other threading calculations such as average, stdv, etc. When the factor variable contains unequal number of cases in each level, the returned pdl is padded with bad values to fit the level with the most number of cases. This allows the subsequent calculation (average, stdv, etc) to return the correct results for each level.

Usage:

    # simple case with 1d pdl and equal number of n in each level of the factor

	pdl> p $a = sequence 10
	[0 1 2 3 4 5 6 7 8 9]

	pdl> p $factor = $a > 4
	[0 0 0 0 0 1 1 1 1 1]

	pdl> p $a->group_by( $factor )->average
	[2 7]

    # more complex case with threading and unequal number of n across levels in the factor

	pdl> p $a = sequence 10,2
	[
	 [ 0  1  2  3  4  5  6  7  8  9]
	 [10 11 12 13 14 15 16 17 18 19]
	]

	pdl> p $factor = qsort $a( ,0) % 3
	[
	 [0 0 0 0 1 1 1 2 2 2]
	]

	pdl> p $a->group_by( $factor )
	[
	 [
	  [ 0  1  2  3]
	  [10 11 12 13]
	 ]
	 [
	  [  4   5   6 BAD]
	  [ 14  15  16 BAD]
	 ]
	 [
	  [  7   8   9 BAD]
	  [ 17  18  19 BAD]
	 ]
	]
     ARRAY(0xa2a4e40)

    # group_by supports perl factors, multiple factors
    # returns factor labels in addition to pdl in array context

    pdl> p $a = sequence 12
    [0 1 2 3 4 5 6 7 8 9 10 11]

    pdl> $odd_even = [qw( e o e o e o e o e o e o )]

    pdl> $magnitude = [qw( l l l l l l h h h h h h )]

    pdl> ($a_grouped, $label) = $a->group_by( $odd_even, $magnitude )

    pdl> p $a_grouped
    [
     [
      [0 2 4]
      [1 3 5]
     ]
     [
      [ 6  8 10]
      [ 7  9 11]
     ]
    ]

    pdl> p Dumper $label
    $VAR1 = [
              [
                'e_l',
                'o_l'
              ],
              [
                'e_h',
                'o_h'
              ]
            ];

=cut

*group_by = \&PDL::group_by;
sub PDL::group_by {
    my $p = shift;
    my @factors = @_;

    if ( @factors == 1 ) {
        my $factor = $factors[0];
        my $label;
        if (ref $factor eq 'ARRAY') {
            $label  = _ordered_uniq($factor);
            $factor = _array_to_pdl($factor);
        } else {
            my $perl_factor = [$factor->list];
            $label  = _ordered_uniq($perl_factor);
        }

        my $p_reshaped = _group_by_single_factor( $p, $factor );

        return wantarray? ($p_reshaped, $label) : $p_reshaped;
    }

    # make sure all are arrays instead of pdls
    @factors = map { ref($_) eq 'PDL'? [$_->list] : $_ } @factors;

    my (@cells);
    for my $ele (0 .. $#{$factors[0]}) {
        my $c = join '_', map { $_->[$ele] } @factors;
        push @cells, $c;
    }
    # get uniq cell labels (ref List::MoreUtils::uniq)
    my %seen;
    my @uniq_cells = grep {! $seen{$_}++ } @cells;

    my $flat_factor = _array_to_pdl( \@cells );

    my $p_reshaped = _group_by_single_factor( $p, $flat_factor );

    # get levels of each factor and reshape accordingly
    my @levels;
    for (@factors) {
        my %uniq;
        @uniq{ @$_ } = ();
        push @levels, scalar keys %uniq;
    }

    $p_reshaped = $p_reshaped->reshape( $p_reshaped->dim(0), @levels )->sever;

    # make labels for the returned data structure matching pdl structure
    my @labels;
    if (wantarray) {
        for my $ifactor (0 .. $#levels) {
            my @factor_label;
            for my $ilevel (0 .. $levels[$ifactor]-1) {
                my $i = $ifactor * $levels[$ifactor] + $ilevel;
                push @factor_label, $uniq_cells[$i];
            }
            push @labels, \@factor_label;
        }
    }

    return wantarray? ($p_reshaped, \@labels) : $p_reshaped;
}

# get uniq cell labels (ref List::MoreUtils::uniq)
sub _ordered_uniq {
    my $arr = shift;

    my %seen;
    my @uniq = grep { ! $seen{$_}++ } @$arr;

    return \@uniq;
}

sub _group_by_single_factor {
    my $p = shift;
    my $factor = shift;

    $factor = $factor->squeeze;
    die "Currently support only 1d factor pdl."
        if $factor->ndims > 1;

    die "Data pdl and factor pdl do not match!"
        unless $factor->dim(0) == $p->dim(0);

    # get active dim that will be split according to factor and dims to thread over
	my @p_threaddims = $p->dims;
	my $p_dim0 = shift @p_threaddims;

    my $uniq = $factor->uniq;

    my @uniq_ns;
    for ($uniq->list) {
        push @uniq_ns, which( $factor == $_ )->nelem;
    }

    # get number of n's in each group, find the biggest, fit output pdl to this
    my $uniq_ns = pdl \@uniq_ns;
	my $max = pdl(\@uniq_ns)->max->sclr;

    my $badvalue = int($p->max + 1);
    my $p_tmp = ones($max, @p_threaddims, $uniq->nelem) * $badvalue;
    for (0 .. $#uniq_ns) {
        my $i = which $factor == $uniq($_);
        $p_tmp->dice_axis(-1,$_)->squeeze->(0:$uniq_ns[$_]-1, ) .= $p($i, );
    }

    $p_tmp->badflag(1);
    return $p_tmp->setvaltobad($badvalue);
}

=head2 which_id

=for ref

Lookup specified var (obs) ids in $idv ($ido) (see B<rtable>) and return indices in $idv ($ido) as pdl if found. The indices are ordered by the specified subset. Useful for selecting data by var (obs) id.

=for usage

    my $ind = which_id $ido, ['smith', 'summers', 'tesla'];

    my $data_subset = $data( $ind, );

    # take advantage of perl pattern matching
    # e.g. use data from people whose last name starts with s

    my $i = which_id $ido, [ grep { /^s/ } @$ido ];

    my $data_s = $data($i, );

=cut

sub which_id {
  my ($id, $id_s) = @_;

  my %ind;
  @ind{ @$id } = ( 0 .. $#$id );

  my @ind_select;
  for (@$id_s) {
    defined( $ind{$_} ) and push @ind_select, $ind{$_};
  }
  return pdl @ind_select;
}

sub _array_to_pdl {
  my ($var_ref) = @_;
  $var_ref = [ $var_ref->list ] if UNIVERSAL::isa($var_ref, 'PDL');

  my (%level, $l);
  $l = 0;
  for (@$var_ref) {
    if (defined($_) and $_ ne '' and $_ ne 'BAD') {
      $level{$_} = $l ++
        if !exists $level{$_};
    }
  }

  my $pdl = pdl( map { (defined($_) and $_ ne '' and $_ ne 'BAD')?  $level{$_} : -1 } @$var_ref );
  $pdl = $pdl->setvaltobad(-1);
  $pdl->check_badflag;

  return wantarray? ($pdl, \%level) : $pdl;
}

=head1 SEE ALSO

PDL::Basic (hist for frequency counts)

PDL::Ufunc (sum, avg, median, min, max, etc.)

PDL::GSL::CDF (various cumulative distribution functions)

=head1 	REFERENCES

Hays, W.L. (1994). Statistics (5th ed.). Fort Worth, TX: Harcourt Brace College Publishers.

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 1214 "Basic.pm"

# Exit with OK status

1;
