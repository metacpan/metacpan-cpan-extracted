package Test::BoostUnit;

use 5.006;
use strict;
use warnings;

#use Format::PrintUtils qw(:ALL);
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use File::Find;
use Digest::MD5;
use Getopt::CommandLineExports qw(:ALL);

=head1 NAME

Test::BoostUnit - Allow Tests to output Boost C++ XML format test reports

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

A collection of routines to aid in automated testing

=head1 EXPORT

	compareTwoDirecoryTrees  
	compareTwoLists 
	makeCheck 
	makeCheckEqual 
	makeError 
	makeInfo 
	makeCDATA 
	makeCloseTestSuite
	linearRegression 
	correlateTwoHashes 
	matchTwoHashes 
	generateConfusionMatrix
	makeComment 
	makeOpenTestCase 
	makeCloseTestCase 
	makeOpenTestSuite 
	makeOpenTestLog 
	makeCloseTestLog
	calculateErrorMetricForTwoHashes 
	calculateWeightedKappaOnConfusionMatrix

=head1 SUBROUTINES/METHODS



=cut

package Test::BoostUnit;

#my $CLASS = __PACKAGE__;
BEGIN {
#	use  Test::More;
	use Exporter();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    @ISA = qw( Exporter);
	@EXPORT_OK = qw();
    %EXPORT_TAGS = ( ALL => [
        qw!&compareTwoDirecoryTrees  
            &compareTwoLists 
            &makeCheck 
            &makeCheckEqual 
            &makeError 
            &makeInfo 
            &makeCDATA 
            &makeCloseTestSuite
            &linearRegression 
            &correlateTwoHashes 
            &matchTwoHashes 
            &generateConfusionMatrix
            &makeComment 
            &makeOpenTestCase 
            &makeCloseTestCase 
            &makeOpenTestSuite 
            &makeOpenTestLog 
            &makeCloseTestLog
            &calculateErrorMetricForTwoHashes 
            &calculateWeightedKappaOnConfusionMatrix! ],
    ); # eg: TAG => [ qw!name1 name2! ],

#your exported package globals go here,
#as well as any optionally exported functions
    @EXPORT_OK = qw(&compareTwoDirecoryTrees  
                    &compareTwoLists 
                    &makeCheck 
                    &makeCheckEqual  
                    &makeError 
                    &makeInfo 
                    &makeCDATA 
                    &makeCloseTestSuite
                    &linearRegression 
                    &correlateTwoHashes 
                    &matchTwoHashes 
                    &generateConfusionMatrix
                    &makeComment 
                    &makeOpenTestCase   
                    &makeCloseTestCase 
                    &makeOpenTestSuite 
                    &makeOpenTestLog 
                    &makeCloseTestLog
                    &calculateErrorMetricForTwoHashes 
                    &calculateWeightedKappaOnConfusionMatrix
);

}

=head2 calculateErrorMetricForTwoHashes

Runs two hashes through a set of functions to return a single metric value

Assume N matching keys in both hashes (V1 and V2):
foreach n in N:
Run a COMPARE_FUNC C(V1(n), V2(n))
Run a ACCUMULATION_FUNC A(n) = A(A(n-1),C(V1(n), V2(n)))

Finally:

Return a SUMMARY_FUNC S(A(N),N)

The default calculates the L2 Norm

=cut

sub calculateErrorMetricForTwoHashes
{
    my %h = (
        METRIC    => "",
        VECTOR1   => undef,
        VECTOR2   => undef,
        COMPARE_FUNC => sub {my ($a, $b) = @_; return [($a-$b)*($a-$b)];},
        ACCUMULATION_FUNC => sub {my ($previousTotal, $currentValue) = @_;
                            return [${$previousTotal}[0] + ${$currentValue}[0]];},
        SUMMARY_FUNC => sub {my ($totalMetric, $totalPoints)= @_;
                            return 0 unless $totalPoints;
                            return ($$totalMetric[0]/$totalPoints) if $totalPoints;},
        (   parseArgs \@_, 'METRIC=s', 'VECTOR1=s%', 'VECTOR2=s%', 'COMPARE_FUNC=c&', 'ACCUMULATION_FUNC=c&', 'SUMMARY_FUNC=c&'),
    );
    my $V1 = $h{VECTOR1};
    my $V2 = $h{VECTOR2}; #Two Hash references
    my $numPoints = 0;
    my $totalMetric = [0];
    if ($h{METRIC} eq "RMS") 
    {
            $h{SUMMARY_FUNC} = sub {my ($totalMetric, $totalPoints)= @_;
                            return 0 unless $totalPoints;
                            return sqrt($$totalMetric[0]/$totalPoints) if $totalPoints;};
    
    }
    if ($h{METRIC} eq "Mean") 
    {
        $h{COMPARE_FUNC} = sub {my ($a, $b) = @_; return [($a-$b)];};
    }
    if ($h{METRIC} eq "MeanL1Norm") 
    {
        $h{COMPARE_FUNC} = sub {my ($a, $b) = @_; return [abs($a-$b)];};    
    }
    if ($h{METRIC} eq "RelativeMean") 
    {
        $h{COMPARE_FUNC} = sub {my ($a, $b) = @_; return [($a-$b)/$b] if $b;return [($a-$b)];};    
    }
    if ($h{METRIC} eq "RelativeL1Norm") 
    {
        $h{COMPARE_FUNC} = sub {my ($a, $b) = @_; return [abs($a-$b)/$b] if $b;return [abs($a-$b)];};
    }
    if ($h{METRIC} eq "RelativeMaxL1Norm") 
    {
        $h{SUMMARY_FUNC}        = sub {my ($totalMetric, $totalPoints)= @_; return $$totalMetric[0];};
        $h{ACCUMULATION_FUNC}   = sub {my ($previousTotal, $currentValue) = @_;  return $$currentValue[0] > $$previousTotal[0] ? [$$currentValue[0]] : [$$previousTotal[0]];};
        $h{COMPARE_FUNC}        = sub {my ($a, $b) = @_; return [abs(($a-$b)/$b)] if $b;return [abs($a-$b)];};
    
    }
    if ($h{METRIC} eq "MaxL1Norm") 
    {
        $h{SUMMARY_FUNC}        = sub {my ($totalMetric, $totalPoints)= @_; return $$totalMetric[0];};
        $h{ACCUMULATION_FUNC}   = sub {my ($previousTotal, $currentValue) = @_;  return $$currentValue[0] > $$previousTotal[0] ? [$$currentValue[0]] : [$$previousTotal[0]];};
        $h{COMPARE_FUNC}        = sub {my ($a, $b) = @_; return [abs($a-$b)];};
    }
    
    foreach my $key ( sort keys %$V1 ) {
        if (exists $V2->{$key}) {
            my $XVal = $V1->{$key};
            my $YVal = $V2->{$key};
            ++$numPoints;
            $totalMetric = &{$h{ACCUMULATION_FUNC}}($totalMetric, &{$h{COMPARE_FUNC}}($XVal,$YVal));
        }
    }
    return &{$h{SUMMARY_FUNC}}($totalMetric, $numPoints);
}

=head2 matchTwoHashes

Return the % of matching keys in Two hashes (VECTOR1 and VECTOR2):

=cut

sub matchTwoHashes 
{ 
    my %h = (
        VECTOR1   => undef,
        VECTOR2   => undef,
        (   parseArgs \@_, 'VECTOR1=s%', 'VECTOR2=s%'),
    );

    my $V1 = $h{VECTOR1};
    my $V2 = $h{VECTOR2}; #Two Hash references  
    my $numPoints = 0;
    my $numMatches = 0;   
    foreach my $key ( sort keys %$V1 ) {
        if (exists $V2->{$key}) {
            my $XBD = $V1->{$key};
            my $YBD = $V2->{$key};
            ++$numPoints;
            ++$numMatches if $XBD eq $YBD;
        }
    }
    return $numMatches/$numPoints if $numPoints;
    return 0 unless $numPoints;
}

=head2 generateConfusionMatrix

Generates a confusion matrix between two vectors VECTOR1 and VECTOR2
VECTOR1 being an "expected" map between keys and values
VECTOR2 being an "observed" map between keys and values

=cut

sub generateConfusionMatrix 
{ 
    my %h = (
        VECTOR1   => undef,
        VECTOR2   => undef,
        (   parseArgs \@_, 'VECTOR1=s%', 'VECTOR2=s%'),
    );

	my %r;
    my $V1 = $h{VECTOR1};
    my $V2 = $h{VECTOR2}; #Two Hash references  
    my $numPoints = 0;
    my $numMatches = 0;

    my $V2Copy = {};
    foreach my $v1Key (keys %$V1) {
        $V2Copy->{$v1Key} = $V2->{$v1Key} if defined $V2->{$v1Key} and $V2->{$v1Key} ne "";
    }
    foreach my $xVal (values %$V1 ) {
		foreach my $yVal (values %$V2Copy ) {
			$r{$xVal}{$yVal} = 0;
		}
	}
    foreach my $v1Key (keys %$V1 ) {
        if (exists $V2Copy->{$v1Key}) {
            my $xVal = $V1->{$v1Key};
            my $yVal = $V2Copy->{$v1Key};
            ++$numPoints;
			++$r{$xVal}{$yVal};
        }
    }
    return %r;
}

=head2 calculateWeightedKappaOnConfusionMatrix

Given a confusion matrix and a weight matrix,  generates a Kappa result

=cut

sub calculateWeightedKappaOnConfusionMatrix
{
    my %h = (
        CONFUSION_MATRIX   	=> undef,
        WEIGHT_MATRIX   	=> undef,
        (   parseArgs \@_, 'CONFUSION_MATRIX=s%', 'WEIGHT_MATRIX=s%'),
    );
    my $CM = $h{CONFUSION_MATRIX};
    my $WT = $h{WEIGHT_MATRIX}; #Two Hash references

	my %rowSums;
	foreach my $rowKey (keys %{$CM}) #rows
	{
		$rowSums{$rowKey} = 0 unless defined $rowSums{$rowKey};
		$rowSums{$rowKey} += $_ foreach (values %{$CM->{$rowKey}});
	}
	my @rowKeys = keys %{$CM};
	my %colSums; 
	my @colKeysList;
  	push @colKeysList, keys %{$CM->{$_}} foreach (@rowKeys);
	my %colKeys = map {$_ => 1} @colKeysList;
	foreach my $colKey (keys %colKeys) #cols
	{
		$colSums{$colKey} = 0 unless defined $colSums{$colKey};
		$colSums{$colKey} += (defined $CM->{$_}{$colKey}) ?  $CM->{$_}{$colKey} : 0 foreach (keys %{$CM});
	}
	my $numObs = 0;
	$numObs += $_ foreach (values %rowSums);
	my %ObsRandomChance;
	foreach my $rowKey (@rowKeys) 
	{
		foreach my $colKey (keys %colKeys)
		{
			$ObsRandomChance{$rowKey}{$colKey} = 0  unless defined $ObsRandomChance{$rowKey}{$colKey};
			$ObsRandomChance{$rowKey}{$colKey} = $rowSums{$rowKey} * $colSums{$colKey} / $numObs;
		}
	}
	my $CMDiagonalSum = 0;
	my $ChanceDiagonalSum = 0;
	$CMDiagonalSum 		+= defined $CM->{$_}{$_} ? $CM->{$_}{$_} : 0 foreach (keys %{$CM});
	$ChanceDiagonalSum 	+= defined $ObsRandomChance{$_}{$_} ? $ObsRandomChance{$_}{$_} : 0 foreach (keys %ObsRandomChance);
	my $deltaCorrect = $CMDiagonalSum - $ChanceDiagonalSum;
	my $kappa = $deltaCorrect / ($numObs - $ChanceDiagonalSum) unless $numObs - $ChanceDiagonalSum == 0;
	$kappa = 1 if $numObs - $ChanceDiagonalSum == 0;
	my %weightedCM;
	my %weightedObsRandomChance;
	foreach my $rowKey (@rowKeys) 
	{
		foreach my $colKey (keys %colKeys)
		{
			$weightedCM{$rowKey}{$colKey} 				=  $WT->{$rowKey}{$colKey} * $CM->{$rowKey}{$colKey};
			$weightedObsRandomChance{$rowKey}{$colKey} 	=  $WT->{$rowKey}{$colKey} * $ObsRandomChance{$rowKey}{$colKey};
		}
	} 
	my $WtCMSum = 0;
	my $WtChanceSum = 0;
	$WtCMSum 		+= sum 0, values %{$_}   foreach (values %weightedCM);
	$WtChanceSum 	+= sum 0, values %{$_}   foreach (values %weightedObsRandomChance);
	my $WtKappa = 1 - $WtCMSum / $WtChanceSum unless $WtCMSum == 0;
	$WtKappa = 1 if $WtCMSum == 0;
	return {KAPPA => $kappa, WEIGHTED_KAPPA => $WtKappa, DELTA_CORRECT => $deltaCorrect};
}

=head2 correlateTwoHashes

Given two vectors, calculates the common correlation between them

=cut

sub correlateTwoHashes
{
    my %h = (
        VECTOR1   => undef,
        VECTOR2   => undef,
        (   parseArgs \@_, 'VECTOR1=s%', 'VECTOR2=s%'),
    );

    my $V1 = $h{VECTOR1};
    my $V2 = $h{VECTOR2}; #Two Hash references
    my $numPoints = 0;
    my $XiYi = 0;
    my $Xi = 0;
    my $Yi = 0;
    my $Xi2 = 0;
    my $Yi2 = 0;
    foreach my $key ( sort keys %$V1 ) {
        my $val = $V1->{$key};
        my $val2 = $V2->{$key};
    }
    foreach my $key2 ( sort keys %$V1 ) {
        if (exists $V2->{$key2}) {
            my $XBD = $V1->{$key2};
            my $YBD = $V2->{$key2};
            ++$numPoints;
            $XiYi += $XBD * $YBD;
            $Xi += $XBD;
            $Yi += $YBD;
            $Xi2 += $XBD * $XBD;
            $Yi2 += $YBD * $YBD;
        }
    }
    my $Corr = 0;
    if ((sqrt($numPoints * $Xi2 - $Xi * $Xi)*sqrt($numPoints * $Yi2 - $Yi * $Yi)) ne 0)  {
        $Corr = $numPoints * $XiYi - $Xi * $Yi;
        $Corr = $Corr / (sqrt($numPoints * $Xi2 - $Xi * $Xi)*sqrt($numPoints * $Yi2 - $Yi * $Yi));
    }
    return $Corr;
}

=head2 linearRegression


Performs a linear regression of a CDF in Y (in a COUNT and TOTAL_Y hash)
against an X_HASH

=cut

sub linearRegression
{
    my %h = (
        COUNT   => undef,
        TOTAL_Y => undef,
        X_HASH  => undef, 
        (   parseArgs \@_, 'COUNT=s%', 'TOTAL_Y=s%', 'X_HASH=s%'),
    );

    my $Count  = $h{COUNT}; #hash reference
    my $TotalY = $h{TOTAL_Y}; #hash reference
    my $XHash  = $h{X_HASH}; #hash reference
    my $X2 = 0;
    my $XY = 0;
    my $SX = 0;
    my $SY = 0;
    my $N = scalar (keys %$XHash);
    while (my ($key, $X) = each %$XHash)
    {
        my $N = $Count->{$key};
        my $Y = $TotalY->{$key}/$N;

        $XY += $X * $Y;
        $X2 += $X * $X;
        $SX += $X;
        $SY += $Y;
    }
    my $slope = ($XY - ($SX * $SY)/$N) / ($X2 - ($SX * $SX)/$N);
    return $slope;
}

=head2 makeError

Generates an XML boost unit test V1.4.5 Error Node

=cut

sub makeError
{
    my %h = (
        ERROR => undef,
        FILE  => "None",
        LINE  => "1",
        (   parseArgs \@_, 'ERROR=s', 'FILE=s', 'LINE=i'),
    );
    return
        "<Error file=\"$h{FILE}\" line=\"$h{LINE}\">" . makeCDATA($h{ERROR}) . "</Error>\n";
}

=head2 makeInfo

Generates an XML boost unit test V1.4.5 Info Node

=cut

sub makeInfo
{
    my %h = (
        INFO => undef,
        FILE  => "None",
        LINE  => "1",
        (   parseArgs \@_, 'INFO=s', 'FILE=s', 'LINE=i'),
    );
    return "<Info file=\"$h{FILE}\" line=\"$h{LINE}\">" . makeCDATA($h{INFO}) . "</Info>\n";

}

=head2 makeCDATA

Generates an XML CDATA Node

=cut

sub makeCDATA
{
    return join('',"<![CDATA[ \n", @_, "\n ]]>\n");
}

=head2 makeComment

Generates an XML Comment Node

=cut

sub makeComment
{
    return join('',"<!-- ", @_, " -->\n");
}

=head2 makeOpenTestCase

Generates an XML boost unit test V1.4.5 Test Case open tag

=cut

sub makeOpenTestCase
{
    my %h = (
        NAME => undef,
        (   parseArgs \@_, 'NAME=s'),
    );
    return "<TestCase name=\"$h{NAME}\">\n";
}

=head2 makeCloseTestCase

Generates an XML boost unit test V1.4.5 Test Case close tag

=cut

sub makeCloseTestCase
{
    my %h = (
        TIME => '0',
        (   parseArgs \@_, 'TIME=s'),
    );
    return "<TestingTime>$h{TIME}</TestingTime>\n</TestCase>\n";
}

=head2 makeOpenTestSuite

Generates an XML boost unit test V1.4.5 Test Suite Open tag

=cut

sub makeOpenTestSuite
{
    my %h = (
        NAME => undef,
        (   parseArgs \@_, 'NAME=s'),
    );
    return "<TestSuite name=\"$h{NAME}\">\n";
}

=head2 makeCloseTestSuite

Generates an XML boost unit test V1.4.5 Test Suite Close tag

=cut

sub makeCloseTestSuite
{
    return "</TestSuite>\n";
}

=head2 makeOpenTestLog

Generates an XML boost unit test V1.4.5 Test log open tag

=cut

sub makeOpenTestLog
{
    return "<TestLog>\n";
}

=head2 makeCloseTestLog

Generates an XML boost unit test V1.4.5 Test log close tag

=cut

sub makeCloseTestLog
{
    return "</TestLog>\n";
}

=head2 compareTwoLists

Compares Two Lists with some COMPARE_CODE

Default compares for equality ignoring whitespace

=cut

sub compareTwoLists
{
    my %h = (
        FIRST => undef,
        SECOND => undef,
        COMPARE_CODE => sub {
			s/^\s*// foreach (@{$_[0]},@{$_[1]});
			s/\s*$// foreach (@{$_[0]},@{$_[1]});			
			return join('A',@{$_[0]}) eq join('A',@{$_[1]});
		},
        %{$_[0]},
    );
	return $h{COMPARE_CODE}->( $h{FIRST}, $h{SECOND} );
}


=head2 compareTwoDirecoryTrees

Compares the contents of two directory trees file by file

=cut

sub compareTwoDirecoryTrees
{
    my %h = (
        FIRST => undef,
        SECOND => undef,
		FIRST_FILE_REGEX => '.*',
		FIRST_PRUNE_REGEX => '$NeverMatch^',		
		SECOND_FILE_REGEX => '.*',
		SECOND_PRUNE_REGEX => '$NeverMatch^',		
        COMPARE_CODE => sub {
			return join('A',@{$_[0]}) eq join('A',@{$_[1]});
		},
        %{$_[0]},
    );
	my %firstMD5Hash;
	my %secondMD5Hash;
	find(sub {
				($File::Find::Prune = 1 , return) if m/$h{FIRST_PRUNE_REGEX}/; 
				if (m/$h{FIRST_FILE_REGEX}/ and -f) 
				{
					open(FILE, $_);
					binmode(FILE);
					my $hash =  Digest::MD5->new->addfile(*FILE)->hexdigest;
					$firstMD5Hash{File::Spec->abs2rel( $File::Find::name, $h{FIRST} )} = $hash;
					close(FILE);
				}
			}, $h{FIRST});
	find(sub {
				($File::Find::Prune = 1 , return) if m/$h{SECOND_PRUNE_REGEX}/; 
				if (m/$h{SECOND_FILE_REGEX}/ and -f) 
				{
					open(FILE, $_);
					binmode(FILE);
					my $hash =  Digest::MD5->new->addfile(*FILE)->hexdigest;
					$secondMD5Hash{File::Spec->abs2rel( $File::Find::name, $h{SECOND} )} = $hash;
					close(FILE);
				}
			}, $h{SECOND});
	my %firstNotInSecond;
	my %secondNotInFirst;
	foreach (keys %firstMD5Hash)
	{
		next if exists $secondMD5Hash{$_} and ( $secondMD5Hash{$_} eq $firstMD5Hash{$_});
		$firstNotInSecond{$_} = $firstMD5Hash{$_};
	}
	foreach (keys %secondMD5Hash)
	{
		next if exists $firstMD5Hash{$_} and ( $secondMD5Hash{$_} eq $firstMD5Hash{$_});
		$secondNotInFirst{$_} = $secondMD5Hash{$_};
	}
		
	return (\%firstNotInSecond, \%secondNotInFirst);
}

=head2 makeCheck

Checks a test condition and generates either
an XML boost unit test V1.4.5 Info Node
Or
an XML boost unit test V1.4.5 Error Node
=cut

sub makeCheck
{
    my %h = (
        FIRST => undef,
        SECOND => undef,
        OK => q/Condition satisfied /,
        NOT_OK => q/Condition not satisfied /,
        COMPARE_CODE => sub {return ($_[0] eq $_[1]);},
        %{$_[0]},
    );
    return makeInfo  "$h{OK}"      if (     $h{COMPARE_CODE}->( $h{FIRST}, $h{SECOND} ) );
    return makeError "$h{NOT_OK}"  unless(  $h{COMPARE_CODE}->( $h{FIRST}, $h{SECOND} ) );
}


=head2 formatList

private helper function for printing lists

=cut
sub formatList
{
    return "(" . join (", ",@_) . ")";
}

=head2 makeCheckEqual

Checks two lists for equality and generates either
an XML boost unit test V1.4.5 Info Node
Or
an XML boost unit test V1.4.5 Error Node

=cut
sub makeCheckEqual
{
    my %h = (
        FIRST => undef,
        SECOND => undef,
        OK => q/Condition satisfied /,
        NOT_OK => q/Condition not satisfied /,
        (   parseArgs \@_, 'FIRST=s@', 'SECOND=s@', 'OK=s','NOT_OK=s',),
    );
    return makeInfo  "$h{OK}\n"      . formatList( @{$h{FIRST}}) . "\nEquals\n"    .  formatList( @{$h{SECOND}})  	if (     compareTwoLists { FIRST => $h{FIRST}, SECOND => $h{SECOND} });
    return makeError "$h{NOT_OK}\n"  . formatList( @{$h{FIRST}}) . "\nNot Equal\n" .  formatList( @{$h{SECOND}}) 	unless(  compareTwoLists { FIRST => $h{FIRST}, SECOND => $h{SECOND} });
}




END { } # module clean-up code here (global destructor)


=head1 AUTHOR

Robert Haxton, C<< <robert.haxton at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-format-printutils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TestTools-BoostUnitTest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::BoostUnit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TestTools-BoostUnitTest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TestTools-BoostUnitTest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TestTools-BoostUnitTest>

=item * Search CPAN

L<http://search.cpan.org/dist/TestTools-BoostUnitTest/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robert Haxton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TestTools::BoostUnitTest
