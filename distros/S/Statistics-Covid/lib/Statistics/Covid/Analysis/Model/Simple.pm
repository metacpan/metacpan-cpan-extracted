package Statistics::Covid::Analysis::Model::Simple;

use 5.006;
use strict;
use warnings;

use Statistics::Covid::Datum;
use Statistics::Covid::Utils;

use Math::Symbolic;
use Math::Symbolic::Parser;
use Math::Symbolic::Compiler;

use Algorithm::CurveFit;

use Data::Dump qw/pp/;

our $VERSION = '0.23';

our $DEBUG = 1;

sub     fit {
	# thick wrapper over Algorithm::CurveFit
	my $params = $_[0];
	my $dataframe = exists($params->{'dataframe'}) ? $params->{'dataframe'} : undef;
	if( ! defined $dataframe ){ warn "error, input parameter 'dataframe' is missing."; return undef }

	$Math::Symbolic::Parser::DEBUG = $DEBUG;
	$Math::Symbolic::Parser = Math::Symbolic::Parser->new(
		 implementation=>'Yapp'
	);

	my $m;

	# is this for fitting an exponential function c0 * c1^x ?
	my $exponential_fit = exists($params->{'exponential-fit'}) && defined($params->{'exponential-fit'}) ? $params->{'exponential-fit'} : 0;
	# is this a polynomial fit?
	my $polynomial_fit = exists($params->{'polynomial-fit'}) && defined($params->{'polynomial-fit'}) ? $params->{'polynomial-fit'} : 0;

	my $formula = undef;

	if( $exponential_fit and $polynomial_fit ){ warn "error, you can not ask for both exponential and polynomial fit."; return undef }
	elsif( $exponential_fit ){
		$formula = 'c1*c2^x';
		if( $DEBUG > 0 ){ warn "asked to do exponential fit : $formula" }
	} elsif( $polynomial_fit ){
		# asked for polynomial fit of degree $polynomial_fit (the max power of x)
		# all we have to do is to produce a polynomial of this degree
		$formula = 'c001 + c002 * x';
		$formula .= sprintf(' + c%03d',$_).' * x^' . $_ for 2..$polynomial_fit;
		if( $DEBUG > 0 ){ warn "asked to do polynomial fit of degree $polynomial_fit : $formula" }
	}

	# Required (formula): ONLY if not exponential fit or polynomial fit
	# specify the formula to fit, e.g. 'c1+c2*x^3' (exponential 'c1+c2*c3^x' is not robust at all!!!
	# in this case use exponential-fit
	if( ! defined $formula ){
		$formula = exists($params->{'formula'}) ? $params->{'formula'} : undef;
		if( ! defined $formula ){ warn "error, 'formula' was missing from the input params, it must be the column name for formula values."; return undef }
	}

	# make sure the formula compiles
	my $tree =  Math::Symbolic->parse_from_string($formula);
	if( ! defined $tree ){ warn "error, call to ".'Math::Symbolic->parse_from_string()'." has failed for formula: '$formula'."; return undef }
	if( $DEBUG > 0 ){ warn "formula parsed: $tree" }
	# and find all the constants in that formula (any var other than 'x')
	# fitting means to find those constants so that our function reproduces as accurately, the data
	my @constants = grep !/^x$/, $tree->explicit_signature();
	if( scalar(@constants) == 0 ){ warn "error, there are no constants in the formula to optimise : $formula"; return undef }
	if( $DEBUG > 0 ){ warn "coefficients in the formula to optimise are: '".join("','", @constants)."'" }

	# Required:
	# specify what the X and Y data are going to be for the particular group(s)
	my $X = exists($params->{'X'}) ? $params->{'X'} : undef;
	if( ! defined $X ){ warn "error, 'X' was missing from the input params, it must be the column name for X values."; return undef }
	my $Y = exists($params->{'Y'}) ? $params->{'Y'} : undef;
	if( ! defined $Y ){ warn "error, 'Y' was missing from the input params, it must be the column name for Y values."; return undef }

	# set every param's accuracy to our default:
	my %accuracy; $accuracy{$_} = 0.00005 for @constants;
	# Optional accuracy, one for all, or via a hash one for each
	if( exists($params->{'accuracy'}) && defined($m=$params->{'accuracy'}) ){
		if( ref($m) eq '' ){ map { $accuracy{$_} = $m } @constants }
		elsif( ref($m) eq 'HASH' ){ map { $accuracy{$_} = $m->{$_} } keys %$m }
		else { warn "error, coefficient 'accuracy' can be a single number (for all coefficients) or a hashref to define accuracy for individual coefficients."; return undef }
	}
	if( $DEBUG > 0 ){ warn "accuracy: ".pp(\%accuracy) }

	# set every param's initial guess to our default (stupid but convenient):
	my %guess; $guess{$_} = 1.0 for @constants;
	# Optional guess, one for all, or via a hash one for each
	if( exists($params->{'initial-guess'}) && defined($m=$params->{'initial-guess'}) ){
		if( ref($m) eq '' ){ map { $guess{$_} = $m } @constants }
		elsif( ref($m) eq 'HASH' ){ map { $guess{$_} = $m->{$_} } keys %$m }
		else { warn "error, parameter 'initial-guess' can be a single number (for all coefficients) or a hashref to define initial guess for individual coefficients."; return undef }
	}
	if( $DEBUG > 0 ){ warn "initial guess for coefficients: ".pp(\%guess) }

	# Optional, this must be the group i.e. a key to the DF hashref
	# if not specified then it will do all keys of the DF
	my @groups = defined($params->{'groups'}) ? @{$params->{'groups'}} : (sort keys %$dataframe);
	if( exists($params->{'groups'}) && defined($params->{'groups'}) ){
		@groups = @{$params->{'groups'}};
		# make a check these names are keys in the dataframe
		for my $k (@groups){ if( ! exists($dataframe->{$k}) || ! defined($dataframe->{$k}) ){ warn "error, no key '$k' exists in the input dataframe (this was specified in the 'groups' param), keys in the dataframe are: '".join("','", sort keys %$dataframe)."'."; return undef } }
	} else {
		# use as groups ALL the keys of the dataframe, that can cost a lot of time if caller does not know what is doing
		@groups = (sort keys %$dataframe)
	}
	# check that these X,Y names exist in the DF
	for my $k (@groups){
		if( ! exists($dataframe->{$k}->{$X}) || ! defined($dataframe->{$k}->{$X}) ){ warn "error, value corresponding for X='$X' in key '$k' of the input dataframe does not exist or is undefined."; return undef }
		if( ! exists($dataframe->{$k}->{$Y}) || ! defined($dataframe->{$k}->{$Y}) ){ warn "error, value corresponding for Y='$Y' in key '$k' of the input dataframe does not exist or is undefined."; return undef }
		# check they have the same size, X and Y
		if( scalar(@{$dataframe->{$k}->{$X}}) != scalar(@{$dataframe->{$k}->{$Y}}) ){ warn "error, different size for X='$X' (".scalar(@{$dataframe->{$k}->{$X}}).") and Y='$Y' (".scalar(@{$dataframe->{$k}->{$Y}}).")."; return undef }
	}

	# calling the CurveFit->curve_fit()
	# any other parameters to the fitter
	my %fitparams = (
		'xdata' => undef, # these will be set per group key
		'ydata' => undef,
		'formula' => undef, # later, we need to reparse because we set the coefficients and then goes crazy
		'params' => undef, # later for each call to function
		'variable' => 'x',
		'maximum_iterations' => 100000, # or after so many iterations
	);
	# append into our fitparams the user-specified ones if exist, overwriting our defaults
	if( exists($params->{'fit-params'}) && defined($params->{'fit-params'}) ){
		@fitparams{keys %{$params->{'fit-params'}}} = values %{$params->{'fit-params'}}
	}
	my (%ret, $square_residual, $dfk, $N, $i, $x, $y);
	for my $k (@groups){
		$dfk = $dataframe->{$k};
		# number of data points
		$N = scalar @{$dfk->{$X}};
		if( $N < 3 ){
			warn "$k : warning, too few data points ($N), skipping...";
			$ret{$k} = [10E10, undef];
			next;
		}
		$fitparams{'xdata'} = $dfk->{$X};
		if( $exponential_fit ){
			# take the log of all data points of Y,
			# it's a copy, it leaves the input dataframe's values unaffected
			$fitparams{'ydata'} = [ map { $_<=0 ? 0 : log($_) } @{$dfk->{$Y}} ];
		} else {
			$fitparams{'ydata'} = $dfk->{$Y};
		}
		# for each constant (e.g. 'c1', 'c2') curve_fit requires
		# a triplet of ['a', guess, accuracy]
		# guess is important but can't be bother to ask user to guess it
		# accuracy is standard, though smaller takes longer (see maximum_iterations)
		# careful don't feed previous params to next one!
		$fitparams{'params'} = [ map { [$_, $guess{$_}, $accuracy{$_}] } @constants ];
		if( $exponential_fit ){
			$fitparams{'formula'} = Math::Symbolic->parse_from_string('c1+c2*x');
		} else { $fitparams{'formula'} = Math::Symbolic->parse_from_string($formula); }
		eval {
			# NOTE:
			# the returned $square_residual is the sum of all errors squared, e.g.
			# square_residual += (predictedY - actualY)**2 for all Y
			$square_residual = Algorithm::CurveFit->curve_fit(%fitparams);
		};
		# the fitted parameters are where our 'initial-guess' was in $fitparams{'params'}
		if( $@ or ! defined($square_residual) ){
			warn "'$k' : error, call to ".'Algorithm::CurveFit::curve_fit()'." has failed".(defined($@)?": ".$@:""); warn "'$k' : this is the data we tried to fit:\n".join("\n", map { $dfk->{$X}->[$_] ."\t". $dfk->{$Y}->[$_] } 0..$N-1)."\nSkipping '$k' ...";
			$ret{$k} = [10E10, undef];
			next;
		}
		# convert their square_residual to mean
		$square_residual /= $N;

		if( $exponential_fit ){
			# un-log the coefficients
			$_->[1] = exp($_->[1]) for @{$fitparams{'params'}};
		}
		$ret{$k} = [$square_residual, $fitparams{'params'}];

		if( $DEBUG > 0 ){
			$tree =  Math::Symbolic->parse_from_string($formula); 
			# we need this so that we print the formula with the params
			for(@{$fitparams{'params'}}){
				print "coefficient '".$_->[0]."' = ".$_->[1]."\n";
				$tree->implement($_->[0] => $_->[1]);
			}
			my ($sub) = Math::Symbolic::Compiler->compile($tree);
			print STDOUT "# x\ty\tpredicted-y\n";
			for $i (0 .. $N-1){
				$x = $dfk->{$X}->[$i];
				$y = $dfk->{$Y}->[$i];
				print STDOUT join("\t",
					$x,
					$y,
					$sub->($x)
					)."\n"
				;
			}
			my $formstr = "$tree"; $formstr =~ s/\^/**/g; # convert ^ to perl's **
			warn "Fitted column '$k' with $N data points.\nMean square residual error: $square_residual.\nThis is the formula:\n$formstr";
		}
	}
	return \%ret
	# returns a hash where key=group-name, and
	# value=[ $mean_error,
	#  [
	#     ['c1', 0.123, 0.0005], # <<< coefficient c1=0.123, accuracy 0.00005 (ignore that)
	#     ['c2', 1.444, 0.0005]  # <<< coefficient c1=1.444
	#  ]
}
1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8

=head1 NAME

Statistics::Covid::Analysis::Model::Simple - Fits the data to various models

=head1 VERSION

Version 0.23

=head1 DESCRIPTION

This package contains routine(s) for modelling 2D data.
It can be used to model how markers in L<Statistics::Covid::Datum>,
like C<confirmed>, etc. vary with time by fitting the series
of C<time, value> pairs to a polynomial (C<c0+c1*x+c2*x^2+...cn*x^n>),
or an exponential (C<c0 * c1^x>) model.

=head1 SYNOPSIS

	use Statistics::Covid;
	use Statistics::Covid::Datum;
	use Statistics::Covid::Utils;
	use Statistics::Covid::Analysis::Model::Simple;

	# read data from db
	$covid = Statistics::Covid->new({   
		'config-file' => 't/config-for-t.json',
		'debug' => 2,
	}) or die "Statistics::Covid->new() failed";
	# retrieve data from DB for selected locations (in the UK)
	# data will come out as an array of Datum objects sorted wrt time
	# (the 'datetimeUnixEpoch' field)
	my $objs = $covid->select_datums_from_db_for_specific_location_time_ascending(
		#{'like' => 'Ha%'}, # the location (wildcard)
		['Halton', 'Havering'],
		#{'like' => 'Halton'}, # the location (wildcard)
		#{'like' => 'Havering'}, # the location (wildcard)
		'UK', # the belongsto (could have been wildcarded)
	);
	# create a dataframe
	my $df = Statistics::Covid::Utils::datums2dataframe({
		'datum-objs' => $objs,
		'groupby' => ['name'],
		'content' => ['confirmed', 'datetimeUnixEpoch'],
	});
	# convert all 'datetimeUnixEpoch' data to hours, the oldest will be hour 0
	for(sort keys %$df){
		Statistics::Covid::Utils::discretise_increasing_sequence_of_seconds(
			$df->{$_}->{'datetimeUnixEpoch'}, # in-place modification
			3600 # seconds->hours
		)
	}

	# do an exponential fit
	my $ret = Statistics::Covid::Analysis::Model::Simple::fit({
		'dataframe' => $df,
		'X' => 'datetimeUnixEpoch', # our X is this field from the dataframe
		'Y' => 'confirmed', # our Y is this field
		'initial-guess' => {'c1'=>1, 'c2'=>1}, # initial values guess
		'exponential-fit' => 1,
		'fit-params' => {
			'maximum_iterations' => 100000
		}
	});

	# fit to a polynomial of degree 10 (max power of x is 10)
	my $ret = Statistics::Covid::Analysis::Model::Simple::fit({
		'dataframe' => $df,
		'X' => 'datetimeUnixEpoch', # our X is this field from the dataframe
		'Y' => 'confirmed', # our Y is this field
		# initial values guess (here ONLY for some coefficients)
		'initial-guess' => {'c1'=>1, 'c2'=>1},
		'polynomial-fit' => 10, # max power of x is 10
		'fit-params' => {
			'maximum_iterations' => 100000
		}
	});

	# fit to an ad-hoc formula in 'x'
	# (see L<Math::Symbolic::Operator> for supported operators)
	my $ret = Statistics::Covid::Analysis::Model::Simple::fit({
		'dataframe' => $df,
		'X' => 'datetimeUnixEpoch', # our X is this field from the dataframe
		'Y' => 'confirmed', # our Y is this field
		# initial values guess (here ONLY for some coefficients)
		'initial-guess' => {'c1'=>1, 'c2'=>1},
		'formula' => 'c1*sin(x) + c2*cos(x)',
		'fit-params' => {
			'maximum_iterations' => 100000
		}
	});

	# this is what fit() returns

	# $ret is a hashref where key=group-name, and
	# value=[ 3.4,  # <<<< mean squared error of the fit
	#  [
	#     ['c1', 0.123, 0.0005], # <<< coefficient c1=0.123, accuracy 0.00005 (ignore that)
	#     ['c2', 1.444, 0.0005]  # <<< coefficient c1=1.444
	#  ]
	# and group-name in our example refers to each of the locations selected from DB
	# in this case data from 'Halton' in 'UK' was fitted on 0.123*1.444^time with an m.s.e=3.4

	# This is what the dataframe looks like:
	#  {
	#  Halton   => {
	#		confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  Havering => {
	#		confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  }

	# and after converting the datetimeUnixEpoch values to hours and setting the oldest to t=0
	#  {
	#  Halton   => {
	#                confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#                datetimeUnixEpoch => [0, 24, 48, 72, 104, 120, 144, 168, 192, 216, 240, 264],
	#              },
	#  Havering => {
	#                confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#                datetimeUnixEpoch => [0, 24, 48, 72, 104, 120, 144, 168, 192, 216, 240, 264],
	#              },
	#  }


=head2 fit

Tries to fit a model on some 2D data using L<Algorithm::CurveFit>. It
knows how to do an exponential fit (C<c0 * c1^x>), a polynomial fit
(C<c0+c1*x+c2*x^2+...cn*x^n>) or any other formula L<Math::Symbolic>
supports.

It takes a hashref of parameters:

=over 2

=item C<dataframe>, this is a hashref where each key is
a separate piece of data that needs to be fitted. For example,
key can be 'China' and/or 'Italy' etc. The value for each key
is a hashref. The keys of this are data names and the values
are arrayrefs of the corresponding values for that key.
Here is an example:

	$df = {
		'China' => {
			'confirmed' => [1,2,3],
			'datetimeUnixEpoch' => [1584262800, 1584264800, 1584266800],
		},
		'Italy' => {
			'confirmed' => [5,6,7],
			'datetimeUnixEpoch' => [1584265800, 1584267800, 1584269800],
		},

'China' and 'Italy' are completely independent, their datetimeUnixEpoch need not
be the same. Such a dataframe can hold any type of data. In our example
it's data from this situation. The number of 1st-level and 2nd-level
keys can be 1 or more (not just 2 as in the above example).
Such a dataframe can be converted from an array of L<Statistics::Covid::Datum>
objects using L<Statistics::Covid::Utils::datums2dataframe>.
An example of creating it is in the SYNOPSIS, above.

=item C<exponential-fit> if this key exists and is not zero, an exponential fit
will be done. It is optional. It can not exist at the same time as the C<polynomial-fit> key.

=item C<polynomial-fit> if this key exists and is not zero, an polynomial fit
will be done. It is optional. It can not exist at the same time as the C<exponential-fit> key.

=item <Cformula> must exist if neither C<exponential-fit> nor C<polynomial-fit> exist.
It is a string with a mathematical formula of a function in C<x> whose coefficients
(the constants, the parameters, etc.) will be found using L<Algorithm::CurveFit>.
An example: C<c1*x + c2*x^2> or C<a*sin(x) + b*cos(x)>. Only a few operatos
are supported (see L<Math::Symbolic::Operator> for what is supported.
The power (exponentiation) operator is C<^> (and not Perl's C<**>).

=item C<X>, a string of a field name (one of the 2nd-level keys of the input dataframe) which
will supply the x-data (in the above example, one of C<confirmed> or C<datetimeUnixEpoch>.
But since, be convention, C<X> is the independent variable, it makes sense to use
C<datetimeUnixEpoch>, time.

=item C<Y>, a string of a field name (one of the 2nd-level keys of the input dataframe).
C<Y> denotes a dependent variable and therefore C<confirmed> (which is a function of C<datetimeUnixEpoch>
can be used, in our case)

=item C<accuracy>, this can either be a scalar or a hashref and represents the
accuracy for each coefficient we seek to fit. If it's a scalar (a number in our case)
it will be used for all coefficients in the C<formula>. If it is a hashref, it
will hold accuracy values for one or more or all coefficients in the formula.

=item C<accuracy>, this can either be a scalar or a hashref and represents the
accuracy for each coefficient we seek to fit. If it's a scalar (a number in our case)
it will be used for all coefficients in the C<formula>. If it is a hashref, it
will hold accuracy values for one or more or all coefficients in the formula.

=item C<initial-guess>, this can either be a scalar or a hashref and represents the
initial (guessed) value for each coefficient we seek to fit. If it's a scalar (a number in our case)
it will be used for all coefficients in the C<formula>. If it is a hashref, it
will hold accuracy values for one or more or all coefficients in the formula.
Initial conditions are crucial in some cases. In other cases they can be omitted.
In rare occasions and for complex functions (not for exponential or polynomial fits)
L<Algorithm::CurveFit> can stall or break if this guess is not right, it complains
that its matrices are filled with C<Inf>.

=item C<groups>, this is an arrayref of one or more or all of the 1st-level keys.
Each key mentioned will be fitted. If C<groups> is omitted then all 1st-level keys
in the dataframe will be fitted.

=back

On failure it returns C<undef>. On success it returns a hashref
where key=group-name, and
        # value=[ 3.4,  # <<<< mean squared error of the fit
        #  [
        #     ['c1', 0.123, 0.0005], # <<< coefficient c1=0.123, accuracy 0.00005 (ignore that)
        #     ['c2', 1.444, 0.0005]  # <<< coefficient c1=1.444
	#     ... # for all the coefficients in the input formula (or polynomial)
        #  ]
        # and group-name in our example refers to each of the locations selected from DB
        # in this case data from 'Halton' in 'UK' was fitted on 0.123*1.444^time with an m.s.e=3.4

=head1 EXPORT

None by default. But C<Statistics::Covid::Analysis::Model::Simple::fit()>
is the sub to call. Also the C<$DEBUG> can be set to 1 or more
for more verbose output, like C<$Statistics::Covid::Analysis::Model::Simple::DEBUG=1;>

=head1 SEE ALSO

This package relies heavily on L<Algorithm::CurveFit>. The C<formula> notation
is exactly the one used by L<Math::Symbolic>.

L<Statistics::Regression> and L<Statistics::LineFit> can be used to do
linear regression. Which is a far simpler method that the symbolic approach
we take in this package. However, the benefit of our approach is that
it can try to fit data with any formula, any model. The cost is that
it is slower (for complex cases) and may lack robustness.

=head1 AUTHOR
	
Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>, C<< <andreashad2 at gmail.com> >>

=head1 BUGS

This module has been put together very quickly and under pressure.
There are must exist quite a few bugs.

Please report any bugs or feature requests to C<bug-statistics-Covid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Covid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Covid::Analysis::Model::Simple


You can also look for information at:

=over 4

=item * github L<repository|https://github.com/hadjiprocopis/statistics-covid>  which will host data and alpha releases

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Covid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Covid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Covid>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Covid/>

=item * Information about the basis module DBIx::Class

L<http://search.cpan.org/dist/DBIx-Class/>

=back


=head1 DEDICATIONS

Almaz

=head1 ACKNOWLEDGEMENTS

=over 2

=item L<Perlmonks|https://www.perlmonks.org> for supporting the world with answers and programming enlightment

=item L<DBIx::Class>

=item the data providers:

=over 2

=item L<John Hopkins University|https://www.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6>,

=item L<UK government|https://www.gov.uk/government/publications/covid-19-track-coronavirus-cases>,

=item L<https://www.bbc.co.uk> (for disseminating official results)

=back

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Andreas Hadjiprocopis.

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
