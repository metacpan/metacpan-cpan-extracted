package Statistics::Reproducibility;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

#use Math::Geometry::Multidimensional qw/distanceToLineN diagonalComponentsN diagonalDistancesFromOriginN/;
use Statistics::TheilSenEstimator qw/theilsen/;
use Statistics::QuickMedian qw/qmedian/;
use Statistics::Distributions;

=head1 NAME

Statistics::Reproducibility - Reproducibility measurement between multiple replicate experiments

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

This module facilitates investigation of reproducbility between multiple replicates of
quantitative experiments e.g. SILAC or microarray.  Scatter plots are great, but
only 2d.  Some people use correlation as a proxy for reproducibility, but it's not right.
This module helps you through the following items...

1) Summarize reproducibility across the replicates
2) Pick out replicates that agree more or less
3) Summarize reproducibility for individual proteins/genes/whatever
4) Set a cutoff for what you can call significant, based on precision
5) Deal with missing values (common in SILAC)

This works by going through the following steps:

(0) Choose a dataset to compare everything else to (the middlemost)
1) Put the middle of the data at (0,0,0,0...) by subtracting the median ... report the median
2) Rotate the data so the line x=y=z=... lies on a single axis.  The data should be spread along this axis.
3) Do regression on the data and work out "wrongness" of each replicate (!)
4) Calculate and report ratio variance and imprecision variance
5) Report combined ratio and error for each protein/gene/whatever

Perhaps a little code snippet.

    use Statistics::Reproducibility;

    my $r = Statistics::Reproducibility->new();
    
=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $p = shift;
    my $c = ref $p || $p;
    my $o = {
        # scalars:
        comparatorIndex  => 0,            # index of column used to compare
        k => '',                     # number of columns
        n => '',                    # number of rows
        vE => '',                  # variance of "error" (imprecision)
        vS => '',                  # variable of experimental spread
        sdE => '',                # s.d. error
        sdS => '',                # s.d. spread
        derivedFrom => '',     # the object derived from
        derivedReason => '', # the reason the object was derived (e.g. deDiagonalize)
        
        # arrays (foreach column)
        'm'  => [],                 # regression denominator 
        'c'  => [],                 # regression constant 
        # arrays (foreach row)
        pee => '',                # p-value of error 
        pss => '',                # p-value of spread
        pes => '',                # p-value of error over spread (??)
        pse => '',                # p-value of spread over error
        
        # 2D array (LoL)
        data => [],
        
        #meta info
        copyOnDerive => [qw/comparatorIndex k n vE vS sdE sdS m c pee pss pes pse copyOnDerive obs/]
    };
    bless $o, $c;
    return $o;    
}

=head2 derive

derives a new object from an old one... some fields are conserved.
Warning: references are copied, so m and c point to the same arrays!
However, if you run regression() again, they will point to new arrays.
Data is set up with k empty columns.

=cut

sub derive {
    my ($o,$reason) = @_;
    my $r = $o->new;
    foreach (@{$o->{copyOnDerive}}){
        $r->{$_} = $o->{$_};
    }
    $r->{derivedFrom} = $o;
    $r->{derivedReason} = $reason;
    $r->{data} = [map {[]} (0..$o->{k}-1)];
    return $r;
}

=head2 data

Set the data.  Should be rectangular, i.e. all columns the same length, and 
we'll check it is and croak if not... 
but can contain "empty" cells (empty string), which represent missing values
in the data.

returns the object for chaining.

=cut

sub data {
    my ($o,@columns) = @_;
    $o->{data} = [@columns];
    $o->{k} = @columns;
    $o->{n} = @{$columns[0]};
    foreach (1 .. $o->{k}-1){
        croak "columns different lengths!"
        unless @{$columns[$_]} == $o->{n};
    }
    return $o;
}

=head2 run

runs a recommended workflow.  it's a shortcut for:


    my $m = $r->subtractMedian();
    $m->middlemostColumn();
    my $d = $m->deDiagonalize();
    $d -> regression();
    my $e = $d->rotateToRegressionLine();
    $e->variances();

It returns the last object. So you could do:

    my $results = Statistics::Reproducibility
        ->new()
        ->data($mydata)
        ->run()
        ->printableTable($depth);

=cut

sub run {
    my $r = shift;
#    $r->data([qw/1 2 3 4 5 6 7 8/],[qw/0 1 2 3 4 5 6 7/],[qw/2.1 3.2 4.3 5.4 6.5 7.6 8.7 9.8/]);
        $r->countObservations();
    $r->regression();
    my $m = $r->subtractMedian();
        $m->applyMinimumObservations(2);
    $m->middlemostColumn();
    my $d = $m->deDiagonalize();
        $d->applyMinimumObservations(2);
    $d->regression();
    my $e = $d->rotateToRegressionLine();
        $e->applyMinimumObservations(2);
    $e->variances();
    return $e;
}

=head2 subtractMedian

calculates the median for each column, substracts from each column and
returns the new object.

=cut

sub subtractMedian {
    my $o = shift;
    my $r = $o->derive('subtractMedian');
    my @medians = map {qmedian([map {$_ eq '' ? () : $_} @$_])} @{$o->{data}};
    foreach my $i(0..$#medians){
        $r->{data}->[$i] = [map {$_ eq '' ? '' : $_ - $medians[$i]} @{$o->{data}->[$i]}];
    }
    $r->{medians} = \@medians;
    return $r;
}

=head2 middlemostColumn

Calculates which of the columns is middlemost and remembers it so all 
others are compared to it.  This can be done instead of using a constructed
median dataset as the comparator so that the constructed one does not add to
the spread, and does not contribute to the observation count.

Note: the method of scoring the columns involves counting which has
the most middlemost values. For two columns only, the result will always
be the one with the least missing values.  I don't think there's anything
wrong with that, but just so you know!

=cut

sub middlemostColumn {
    my $o = shift;
    # which is the middle most column? i.e. who has the most medians?
    
    my @medianCounts = map {0} (1..$o->{k}); # stash counts
    
    foreach my $i(0..$o->{n}-1){ # each row
        my @row = ();
        foreach my $j(0..$o->{k}-1){
            if(defined $o->{data}->[$j]->[$i]
                    && $o->{data}->[$j]->[$i] ne ''){
                push @row, $o->{data}->[$j]->[$i];
            }
        }
        # who's in the middle?
        foreach(medianI(@row)){
            $medianCounts[$_] ++;
        }
    }
    
    # which has the most middlemost values?
    my $imax = 0;
    my $max = 0;
    foreach my $i(0..$o->{k}-1){
        if($medianCounts[$i] > $max){
            $imax = $i;
            $max = $medianCounts[$i];
        }
    }
    
    # so now we want to put this column on the left?  Or should we just
    # store that we're going to use this one as the comparator?
    $o->{comparatorIndex} = $imax;
    return $imax;
}

=head2 constructMedianLeft

Make a median column and pop it on the left. Note that the
regular median is used here, not the Quick Median estimator.  This means
that for an even number of observations, the mean of the two middlemost is 
used, which is not the case for Quick Median.

=cut

sub constructMedianLeft {
    my $o = shift;
    my @newcol = ();
    foreach my $i(0..$o->{n}-1){
        my @row = ();
        foreach my $j(0..$o->{k}-1){
            if(defined $o->{data}->[$i]->[$j]
                    && $o->{data}->[$i]->[$j] ne ''){
                push @row, $o->{data}->[$i]->[$j];
            }
        }
        push @newcol, median(@row);
    }
    unshift @{$o->{data}}, \@newcol;
    return \@newcol;
}

=head2 deDiagonalize

Replicated data with some spread will naturally lie along the diagonal line,
y=x (in 2 dimensions, or z=y=x... in more).  This function aligns the data 
along one axis by rotation.  This is done so that (a) errors are measured
approximately perpendicular to the spread of data and (b) unspread data 
(a ball of points) gives a gradient of zero in Theil Sen estimator, which is
correct because if there's no experimental spread then there can be no
evidence that the replicates disagree.

Note: at this point, any missing values are REPLACED BY ZEROS!  This means
that these data point will not disagree with any "unchanging" data, but they
will not support the reproducibility of "changed" data (data for proteins/genes)
that are regulated).  The effect of this is that those points will not appear as
extreme in the output and will also have a larger error associated with them.

A NEW object is returned! comparatorIndex is honoured and conserved,
meaning that if you ran middlemostColumn, the result is the column used
as the Y axis in all comparisons, and the column itself will contain the
experimental variance.

=cut 

sub deDiagonalize {
    my $o = shift;
    my $r = $o->derive('deDiagonalize');
    
    my $ic = $o->{comparatorIndex};

    my $a = atan2(1,1);
    
    foreach my $i(0..$o->{k}-1){
        next if $i == $ic;
        foreach my $j(0..$o->{n}-1){
            my $y = $o->{data}->[$i]->[$j] || 0;
            my $x = $o->{data}->[$ic]->[$j] || 0;

            if($y || $x){
                my $t = atan2($y,$x) - $a;
                my $r = sqrt($x**2 + $y**2);
                ($x,$y) = ($r*cos($t), $r*sin($t));
            }

            $r->{data}->[$i]->[$j] = $y;
            $r->{data}->[$ic]->[$j] = $x;
        }

       # $r->{data}->[$i] = diagonalComponentsN(
       #     $o->{data}->[$i], $o->{data}->[$ic]
       # )
    }
    
    #$r->{data}->[$ic] = diagonalDistancesFromOriginN(
    #    $o->{k}, $o->{n}, @{$o->{data}}
    #);
    return $r;
}

=head2 countObservations

Counts the number of observations present in each point and stores in obs.
The result is used by applyMinimumObservations to check for unwanted data
before a processing event which turns empties into zeros (like deDiagonalize).

=cut

sub countObservations {
    my ($o) = @_;
    my @obs = ();
    foreach my $j(0..$o->{n}-1){
        my $c = 0;
        foreach my $i(0..$o->{k}-1){
            $c++ if defined $o->{data}->[$i]->[$j] && $o->{data}->[$i]->[$j] ne '';
        }
        push @obs, $c;
    }
    $o->{obs} = \@obs;
}

=head2 applyMinimumObservations

A method that blanks any data that does not have a minimum number of
values, e.g. if the minimum were 2, the point [2,3,undef] would be fine
but [2,undef,undef] would become [undef,undef,undef]

=cut

sub applyMinimumObservations {
    my ($o,$min) = @_;
    foreach my $j(0..$o->{n}-1){
        if($o->{obs}->[$j] < $min){
            foreach my $i(0..$o->{k}-1){
                $o->{data}->[$i]->[$j] = '';
            }
            $o->{d}->[$j] = '' if exists $o->{d};
        }
    }
}

=head2 regression

Perform Theil Sen Estimator regression on the data.  The regression is
done with the comparator on the x axis, but the symmetric parameters
are returned for the comparator on the y-axis.

=cut

sub regression {
    my $o = shift;
    my @m = map {1} (0..$o->{k}-1);
    my @c = map {0} (0..$o->{k}-1);
    foreach my $i(0..$o->{k}-1){
        next if $i == $o->{comparatorIndex};
        my ($m,$c) = theilsen(
            $o->{data}->[$i],
            $o->{data}->[$o->{comparatorIndex}]
        );
        $m[$i] = $m;
        $c[$i] = -$c; # - because we're converting to the inverse symmetric
    }
    $o->{m} = \@m;
    $o->{c} = \@c;
    return ($o->{m}, $o->{c});
}

=head2 rotateToRegressionLine

do we need this?

=cut

sub rotateToRegressionLine {
    my $o = shift;
    croak "looks like regression() has not been called on this object"
        unless defined $o->{c};
    
    # use distanceToLineN([0,0,0],...) to get middle point of line for distance :-)
    #my $O = [map {0} (1..$o->{k})]; # the origin
    #my @MC = ($o->{m},$o->{c}); # we'll be using this a lot, maybe
    
    #my ($dO,$X) = distanceToLineN($O,@MC); # $X is the "centre" of the line
    
    ####
    my $r = $o->derive('rotateToRegressionLine');
    
    my $ic = $o->{comparatorIndex};
    
    $r->{d} = [];
    
    foreach my $j(0..$o->{n}-1){
        foreach my $i(0..$o->{k}-1){
            next if $i == $ic;

            my $m = $o->{m}->[$i];
            my $c = $o->{c}->[$i];
            my $y = $o->{data}->[$i]->[$j] || $c;
            my $x = $o->{data}->[$ic]->[$j] || 0;
            $y -= $c;
            if($y || $x){
                my $a = atan2($m,1);
                my $t = atan2($y,$x) - $a;
                my $r = sqrt($x**2 + $y**2);
                ($x,$y) = ($r*cos($t), $r*sin($t));
            }

            $r->{data}->[$i]->[$j] = $y;
            $r->{data}->[$ic]->[$j] = $x;

            #my ($d,$x) = distanceToLineN(
            #    [$o->{data}->[$i]->[$j],$o->{data}->[$ic]->[$j]],
            #    [$o->{m}->[$i], $o->{m}->[$ic]],
            #    [$o->{c}->[$i], $o->{c}->[$ic]]
            #);
            #my $icv = $o->{data}->[$ic]->[$j] || 0;
            #my $iv = $o->{data}->[$i]->[$j] || 0;
            #if($icv < $iv){
            #    $d *= -1;
            #}
            #$r->{data}->[$i]->[$j] = $d;
        }
        
        my $sumOfSquares = 0;
        my $sumOfValues = 0;
        $sumOfSquares += $_ foreach map {$_ == $ic ? () : $r->{data}->[$_]->[$j] ** 2} (0..$o->{k}-1);
        $sumOfValues += $_ foreach map {$_ == $ic ? () : $r->{data}->[$_]->[$j]} (0..$o->{k}-1);
        my $rootsumsquares = sqrt($sumOfSquares);
        #my ($d,$x) = distanceToLineN(
        #    [@coords], @MC
        #);
        # give the distance a sign too!
        #my $ss = 0;
        #foreach my $i(0..$r->{k}-1){
        #    $ss += $r->{data}->[$i]->[$j] * $r->{m}->[$i];
        #}

        $rootsumsquares *= -1 if $sumOfValues < 0;

        push @{$r->{d}}, $rootsumsquares; # distance to line
        
        #my $ss = 0; # sum of squares
        #foreach my $i(0..$o->{k}-1){
        #    my $xi = $X->[$i] || 0;
        #    my $di = $o->{data}->[$i]->[$j] || 0;
        #    $ss += ($xi - $di)**2
        #}
        #
        #$r->{data}->[$ic]->[$j] = sqrt($ss); # distance to center of line
        
    }
    
    
    return $r;
}

=head2 variances

Calculate variances... i.e. distances from the origin along the line of 
regression, and distances from the line of regression.  This is just like
deDiagonalise, except that only two columns are returned.  

=cut

sub variances {
    my $o = shift;
    my $S; # experimental spread
    my $E; # imprecision
    my $df = 0;
    my $ic = $o->{comparatorIndex};
    # we can give a value for how likely a point is to be there by imprecision alone
    foreach my $j(0..$o->{n}-1){
        if($o->{d}->[$j] ne '' && $o->{data}->[$ic]->[$j] ne ''){
            $E += $o->{d}->[$j] ** 2;
            $S += $o->{data}->[$ic]->[$j] ** 2;
            $df ++;
        }
    }
    $E /= $df;
    $S /= $df;
    my $sdE = sqrt($E);
    my $sdS = sqrt($S);
    $o->{vE} = $E;
    $o->{vS} = $S;
    $o->{sdE} = $sdE;
    $o->{sdS} = $sdS;

    $o->{pee} = [];
    $o->{pss} = [];
    $o->{pes} = [];
    $o->{pse} = [];
    foreach my $j(0..$o->{n}-1){
        my ($pee,$pes,$pss,$pse) = ('','','','');
        if($o->{d}->[$j] ne '' && $o->{data}->[$ic]->[$j] ne ''){
            $pee = $sdE ?
                Statistics::Distributions::tprob ($df,$o->{d}->[$j] / $sdE)
                : 1;
            $pes = $sdS ?
                Statistics::Distributions::tprob ($df,$o->{d}->[$j] / $sdS)
                : 1;
            $pss = $sdS ?
                Statistics::Distributions::tprob ($df,$o->{data}->[$ic]->[$j] / $sdS)
                : 1;
            $pse = $sdE ?
                Statistics::Distributions::tprob ($df,$o->{data}->[$ic]->[$j] / $sdE)
                : 1;
        }
        push @{$o->{pee}}, $pee;
        push @{$o->{pes}}, $pes;
        push @{$o->{pss}}, $pss;
        push @{$o->{pse}}, $pse;
    }
    return ($S,$E);
}

=head2 printableTable, printTable

printableTable returns all available relevant info in a table
printTable prints all available relevant info in a table

the firts element returned is a list of columns.  the rest are the columns.

data stored are:

    # scalars:
    comparatorIndex             # index of column used to compare
    k
    n
    vE                          # variance of "error" (imprecision)
    vS                          # variable of experimental spread
    sdE                         # s.d. error
    sdS                         # s.d. spread
    
    # arrays (foreach column)
    m                           # regression denominator 
    c                           # regression constant 
    # arrays (foreach row)
    d                           # distance from regression line
    pee                         # p-value of error 
    pss                         # p-value of spread
    pes                         # p-value of error over spread (??)
    pse                         # p-value of spread over error
    
    # 2D array (LoL)
    data
    
    note that the distance from the center of the distribution
    is given by the values in data[comparatorIndex]

These methods take a single argumen: depth.  Every time an object is
derived from another (subtractMedian, deDiagonalize and 
rotateToRegressionLine all do this) the old object is referenced, and
you can include the last $depth objects in the output.  Set depth to -1
to include all objects.

=cut

sub printableTable {
    my ($o,$deep) = @_;
    my @header = (qw/Statistic Value/, map {"Column $_"} (1..$o->{k}));
    
    my @statistics = ();
    my @values = ();
    
    my @statkeys = qw/comparatorIndex k n vE vS sdE sdS/;
    my @statnames = qw/CompareColumn Columns Rows ErrorVariance SpreadVariance ErrorSD SpreadSD/;
    foreach (0..$#statkeys){
        my $statkey = $statkeys[$_];
        my $statname = $statnames[$_];
        if(defined $o->{$statkey} && $o->{$statkey} ne ''){
            push @statistics, $statname;
            push @values, $o->{$statkey};
            if($statkey eq 'comparatorIndex'){
                $values[$#values] ++; # 1-based!
            }
        }
    }
    
    my @printData = (\@statistics, \@values, @{$o->{data}});
    
    if(ref $o->{m} && @{$o->{m}} ){
        push @header, 'Regression','M','C';
        push @printData, [map {"Column $_"} (1..$o->{k})];
        push @printData, $o->{m}, $o->{c};
    }
    
    if(ref $o->{d}){
        push @header, 'DistanceToRegressionLine';
        push @printData, $o->{d};
    }
    
    if(ref $o->{pee}){
        push @header, 'ErrorPvalue';
        push @printData, $o->{pee};
        
        push @header, 'SpreadPvalue';
        push @printData, $o->{pss};
        
        push @header, 'ErrorOverSpreadPvalue';
        push @printData, $o->{pes};
        
        push @header, 'SpreadOverErrorPvalue';
        push @printData, $o->{pse};
    }

    if($deep && ref($o->{derivedFrom})){
        push @header, 'DerivedFrom';
        push @printData, [$o->{derivedReason}];
        my $d = $o->{derivedFrom}->printableTable($deep-1);
        my ($dh,@dcols) = @$d;
        push @header, @$dh;
        push @printData, @dcols;
    }
    
    return [\@header, @printData];
}

sub printTable {
    my ($o,$deep) = @_;
    my $pt = $o->printableTable($deep);
    # lets assume that n > number of statistics!
    my $n = $o->{n};
    my $w = @$pt;
    print join("\t", @{$pt->[0]})."\n";
    foreach my $j(0..$n-1){
        my @row = ();
        foreach my $i(1..$w-1){
            my $val = defined $pt->[$i]->[$j] ? $pt->[$i]->[$j] : '';
            push @row, $val;
        }
        print join("\t", @row)."\n";
    }
}

=head1 just some wee helper functions...

=head2 median

yes this probably exists in other modules, but I didn't want to pull in a whole
module for just one funciton.  Anyway, this is an inefficient version for small
numbers of data.  It sorts the list and then uses middle() to find the middle of
the sorted list.

=cut

sub median {
	my @r = sort {$a<=>$b} map {defined && /\d/ ? $_ : ()} @_;
	return middle(@r);
}

=head2 medianN

Like median, but for an even list is returns the two middlemost values.
This version is used in medianI.

=cut

sub medianN {
	my @r = sort {$a<=>$b} map {defined && /\d/ ? $_ : ()} @_;
	return middleN(@r);
}

=head2 medianI

This uses medianN to get the middlemost value(s) and then returns a list
of column indices indicating which columns had a middlemost value.
This is used in the medianLeft method when deciding which 
column is middlemost.

=cut

sub medianI {
    my @N = medianN(@_);
    my @I = ();
    foreach my $i(0..$#_){
        if(defined $_[$i] && $_[$i] ne ''){
            foreach my $n(@N){
                if($n == $_[$i]){
                    push @I, $i;
                }
            }
        }
    }
    return @I;
}

=head2 middle

middle returns the middlemost item in a list, or the mean average of the two
middlemost items.  It doesn't sort the list first.

=cut

sub middle {
	if(@_ % 2){
		return $_[$#_/2];
	}
	else {
		return $_[($#_+1)/2]/2 + $_[($#_-1)/2]/2;
	}
}

=head2 middleN

middleN does like middle, but for even lists, it returns the two middlemost
items as a list.  This is used by medianN.

=cut

sub middleN {
    if(@_ % 2){
		return $_[$#_/2];
    }
	else {
		return ($_[($#_+1)/2], $_[($#_-1)/2]);
	}
}


=head1 AUTHOR

Jimi Wills, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-reproducibility at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Reproducibility>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Reproducibility


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Reproducibility>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Reproducibility>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Reproducibility>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Reproducibility/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jimi Wills.

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

1; # End of Statistics::Reproducibility
