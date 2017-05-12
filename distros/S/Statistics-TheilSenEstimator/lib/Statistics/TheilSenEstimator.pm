package Statistics::TheilSenEstimator;

use 5.006;
use strict;
use Carp;
use warnings FATAL => 'all';
require Exporter;

our @ISA = qw/Exporter/;
use Statistics::QuickMedian qw/qmedian/;

our @EXPORT_OK = qw/theilsen/;

=head1 NAME

Statistics::TheilSen - Perl implementation of Theil Sen Estimator

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

This is a perl implementation of the Theil Sen Estimator, which is a method of
linear regression that uses medians.  All of the gradients of the lines between
all points are calculated, and hte median is the one reported.  Sounds trivial.  
If you have 1000s of points, then you have millions of lines, and sort-based
median methods can take ages, so Statistics::TheilSen uses the partition-based
Statistics::QuickMedian.

    # OOP...
    
    use Statistics::TheilSenEstimator;

    my $tse = Statistics::TheilSenEstimator->new(\$y_values, \$x_values);
    # which is really a shortcut for:
    my $tse = Statistics::TheilSenEstimator->new();
    $tse->addData(\@y_values, \@x_values); # listrefs of numeric scalars
    
    my $status_line = $tse->run(); # might tell if you had bad values, etc
    print "y = ", $tse->m(), "x + ", $tse->c(); # y = mx + c
    
    # or procedural...
    
    use Statistics::TheilSenEstimator qw/theilsen/;

    my ($m,$c) = theilsen(\@y_values, \@x_values);

=head1 EXPORT/SUBROUTINES

=head2 theilsen

Accepts two list refs, the lists should be the same length.  They represent y and x series
which will be the subject of the regression.  Returns a list of two 

    use Statistics::TheilSenEstimator qw/theilsen/;

    my ($m,$b) = theilsen(\$y_values, \$x_values);

=cut

sub theilsen {
    my ($y,$x) = @_;
    my $n = @$y;
    carp "y and x series are different lengths"
        unless $n == @$x;
    # all the gradients!  
    my @M = ();
    # each item from start to penultimate
    my ($x1,$x2,$y1,$y2);
    foreach my $i(0 .. $n-2){
        $y1 = $y->[$i];
        $x1 = $x->[$i];
        next unless defined $y1 && $y1 =~ /\d/ && defined $x1 && $x1 =~ /\d/;
        # each item from next to last
        foreach my $j($i+1 .. $n-1){
            $y2 = $y->[$j];
            next unless defined $y2 && $y2 =~ /\d/;
            # short cut for zero (even if dx is zero ;-)
            if($y2 == $y1){
                push @M, 0;
                next;
            }
            $x2 = $x->[$j];
            next unless defined $x2 && $x2 =~ /\d/;
            # skip any divisions by zero! (don't add to the list, if it's infinite then it's both pos and neg anyway!)
            next if $x2 == $x1;
            # otherwise, calculate the gradient and push it...
            push @M, ($y2-$y1)/($x2-$x1);
        }
    }
    # now we have @M, so what's the median?
    my $m = qmedian(\@M); # warning... this modifies the order of M!
    
	# y-intercept b to be the median of the values yi - mxi
    my @C = ();
	foreach my $i(0 .. $n-1){ 
        $y1 = $y->[$i];
        $x1 = $x->[$i];
        next unless defined $y1 && $y1 =~ /\d/ && defined $x1 && $x1 =~ /\d/;
        push @C, $y1 - $m * $x1;
	}
    # now we have @C, so what's the median?
    my $c = qmedian(\@C); # warning... this modifies the order of C!
    return ($m,$c);
}

=head1 METHODS

=head2 new

    use Statistics::TheilSenEstimator;
    my $tse = Statistics::TheilSenEstimator->new();
    #or
    my $tse = Statistics::TheilSenEstimator->new(\@y_values, \@x_values);
    
returns a new Statistics::TheilSenEstimator estimator object with the optional data added.

=cut

sub new {
    my $p = shift;
    my $c = ref $p || $p;
    my $o = {
        Y=>[], # we store y series here 
        X=>[], # and x here
        runSinceAddData=>0, # check whether a run is needed
        m=>'',
        c=>'',
    };
    bless $o, $c;
    if(@_==2){
        $o->addData(@_);
    }
    elsif(@_){
        croak "wrong number of args to Statistics::TheilSen->new, should be 0 or 2.";
    }
    return $o;
}

=head2 addData

    $tse->addData(\@y_values, \@x_values);
    
Adds data to the y and x series.  Data series should be the same length.

=cut

sub addData {
    my $o = shift;
    croak "wrong number of args to Statistics::TheilSen->new, should be 0 or 2."
        unless @_ == 2;
    my ($Y,$X) = @_;
    croak "Y and X are not equal lengths"
        unless @$Y == @$X;
    push @{$o->{Y}}, @$Y;
    push @{$o->{X}}, @$X;
    $o->{runSinceAddData} = 0;
}

=head2 run

    my $status_line = $tse->run();

Runs the estimator on the data currently in the object.  Returns any messages
about whether errors or weird things were found in the data.  Sets m and c in 
the object

=cut

sub run {
    my $o = shift;    
    # fatal:
    my $n = @{$o->{Y}};
    return "Y and X are different lengths (fatal)"
        if $n != @{$o->{X}};
        
    # "warnings" about data
    my $message;
    # count up how many of x2-x1 == 0...
    my %X = ();
    my $divZeroCounts = 0;
    foreach (@{$o->{X}}){
        if(exists $X{$_}){
            $X{$_}++;
            $divZeroCounts += $X{$_};
        }
        else {
            $X{$_} = 0;
        }
    }
    undef %X;
    if($divZeroCounts){
        $message .= "Denominator (x2-x1) is zero in $divZeroCounts cases. ";
    }
    # check missing values, etc.
    my ($y,$x);
    my $missing = 0;
    foreach my $i(0..$n-1){
        ($y,$x) = ($o->{Y}->[$i],$o->{X}->[$i]);
        if(! defined $y || $y !~ /\d/ || $y != $y+0
            || ! defined $x || $x !~ /\d/ || $x != $x+0){
                # looks like x or y is NaN
            $missing ++;
        }
    }
    if($missing){
        $message .= "Missing values on $missing rows. ";
    }
    # end of checks
    ($o->{m}, $o->{c})
        = theilsen(
            $o->{Y},
            $o->{X},
    );
    $o->{runSinceAddData} = 1;
    return $message;
}

=head2 m

    my $gradient = $tse->m();
    
Returns "m", the gradient of the model generated by run().  If run() was not
called since addData(), then run() will be called here!

=cut

sub m {
    my $o = shift;    
    $o->{runSinceAddData} || $o->run();
    return $o->{m};
}

=head2 c

    my $intersect = $tse->c();
    
Returns "c", the intersect of the model generated by run().  If run() was not
called since addData(), then run() will be called here!

=cut

sub c {
    my $o = shift;    
    $o->{runSinceAddData} || $o->run();
    return $o->{c};
}

=head1 AUTHOR

Jimi Wills, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-theilsen at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-TheilSen>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::TheilSenEstimator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-TheilSenEstimator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-TheilSenEstimator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-TheilSenEstimator>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-TheilSenEstimator/>

=back


=head1 ACKNOWLEDGEMENTS

http://en.wikipedia.org/wiki/Theil%E2%80%93Sen_estimator

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

1; # End of Statistics::TheilSen
