package Statistics::RatioVariance;

use Statistics::Basic qw(:all);
use Statistics::Zed;

our $VERSION = '1.00';

sub calc{
    
    # This variables must be references to arrays.
    my($self, $xvector, $yvector, $xvariance, $yvariance) = @_;   
    
    # Calculates ·
    my $kxvector    = 0;
    my $kyvector    = 0;
    my $kxvariance  = 0;
    my $kyvariance  = 0;
    
    #my $counter = 0;
    #print "X-Vector lenght: ".$#{$xvector}." - ".${$xvector}[0]."\n";
    #print "Y-Vector lenght: ".$#{$yvector}."\n";
    #print "X-Var lenght: ".$#{$xvariance}."\n";
    #print "Y-Var lenght: ".$#{$yvariance}."\n";
    
    for(my $i=0;$i<$#{$xvector};$i++){
        
            $kxvector   = $kxvector + ${$xvector}[$i] if ${$xvector}[$i] ;
            $kyvector   = $kyvector + ${$yvector}[$i] if ${$yvector}[$i] ;
            $kxvariance = $kxvariance + ${$xvariance}[$i] if ${$xvariance}[$i] ;
            $kyvariance = $kyvariance + ${$yvariance}[$i] if ${$yvariance}[$i] ;
            
            #print "$counter:kxvector: $kxvector\n";
            #print "$counter:kyvector: $kyvector\n";
            #print "$counter:kxvariance: $kxvariance\n";
            #print "$counter:kyvariance: $kyvariance\n";
            
            #$counter++;
            
    }
    
    # Calculates ^x and ^y (means)
    my $xmean = $kxvector;
    my $ymean = $kyvector;
    
    # Calculates correlation coefficent
    my $correlation = correlation($xvector, $yvector);
    
    # Calculates the cocient
    my $cocient = $xmean/$ymean;  
    
    # Calculates the variance (STEP-BY-STEP)
    my $first_term = 1/($ymean*$ymean);
    
    my $second_term_first_term = $kxvariance;
    my $second_term_second_term = ($cocient*$cocient)*$kyvariance;
    my $second_term_third_term = 2*$cocient*$correlation*(sqrt($kxvariance))*(sqrt($kyvariance));
    my $second_term = $second_term_first_term + $second_term_second_term - $second_term_third_term;
    
    my $cocient_variance = $first_term*$second_term;
    
    # Wanna debug?
    #print "Correlation: $correlation\n";
    #print "First term: 1/$ymean $first_term\n";
    #print "Second term - First term: $second_term_first_term\n";
    #print "Second term - Second term: $second_term_second_term\n";
    #print "Second term - Third term: $second_term_third_term\n";
    #print "Second term: $second_term\n";
    #print "Cocient variance: $cocient_variance\n";
    
    # ..Fiu!
    
    # It seems a zero-value for variance is not allowed in function $zed->score 
    #$cocient_variance == 0 ? $cocient_variance = 0.000001 : $cocient_variance;
    
    # Creates the ztest obj with default values (see perldoc Statistics::Zed to settings this values)
    my $zed = Statistics::Zed->new();
    my ($z_value, $p_value, $observed_deviation, $standar_deviation) = $zed->score(observed => $cocient, expected => 1, variance => $cocient_variance);

    # Create a hash for the returning value with all the calculated params
    my %hash = ();
    
    $hash{xsum}               = $kxvector;
    $hash{ysum}               = $kyvector;
    $hash{x_var_sum}          = $kxvariance;
    $hash{y_var_sum}          = $kyvariance;
    $hash{cocient}            = $cocient;
    $hash{correlation}        = $correlation;
    $hash{cocient_variance}   = $cocient_variance;
    $hash{z_value}            = $z_value;
    $hash{p_value}            = $p_value;
    $hash{observed_deviation} = $observed_deviation;
    $hash{standar_deviation}  = $standar_deviation;

    
    return %hash;
    
}

1;

__END__

=head1 NAME

Statistics::RatioVariance - Ratio and associated variance calculation. 

=head1 SINOPSIS

    my %zdNResults = RatioVariance->calc(\@x,\@y,\@x_var,\@y_var);

    foreach my $key (keys %result){
    print "$key = $result{$key}\n";

=head1 DESCRIPTION

For two vectors of means (X and Y) and its associated sets of variances (V[X] and V[Y]),
this function calculates the rate (R) as:

    R = sum(X)/sum(Y)
    
being sum(X) and sum(Y) the sum of all elements in the set, respectively. Also, it
estimates the associated variance for R using Taylor expansion and taking into
account the correlation between X and Y.

Furthermore, the function run a Z-Test to evaluate if R shifts from the unit
significatively.

=head1 VERSION

    Version 1.00
    
=head1 FUNCTIONS

=head2 calc

Launch the complete algorithm.

=head1 AUTHOR

Hector Valverde, C<< <hvalverde at uma.es> >>

=head1 CONTRIBUTORS

Juan Carlos Aledo, C<< <caledo@uma.es> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-ratiovariance at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-RatioVariance>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::RatioVariance

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-RatioVariance>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-RatioVariance>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-RatioVariance>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-RatioVariance/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Hector Valverde.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Statistics::RatioVariance