package Statistics::Distributions::Bartlett;

use warnings;
use strict;
use Carp;
use Statistics::Distributions qw/chisqrprob/;
use List::Util qw/sum/;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bartlett);

=head1 NAME

Statistics::Distributions::Bartlett - Bartlett's test for equal sample variances.

=cut

=head1 VERSION

This document describes Statistics::Distributions::Bartlett version 0.0.2

=cut

=head1 SYNOPSIS

    use Statistics::Distributions::Bartlett;
                           
    # Create data to pass as ARRAY/ARRAY references
    my @a = [qw/4534543  543 453 5 543 534 5 4 543 543 6 534 54 3 534  534 54 5/];
    my @b = [qw/ 546 565 65 64  5 434 65 457 67 78 6  34 2 6 57 43  2 556 7 4563/];
    my @c = [qw/ 565 44 535 6678 787 5 5/];
                             
    # Call exported sub routine on ARRAY references of data to print result to STDOUT.
    &bartlett(\@a,\@b,\@c);

    # Call in LIST-context to access results directly:
    my ($K, $p_val, $df, $k, $n_total ) = &bartlett(\@a,\@b,\@c);

=cut

=head1 DESCRIPTION

Bartlett test is used to test if k samples have equal variances. Such homogeneity is often assumed by other statistical
tests and consequently the Bartlett test should be used to verify that assumption. See http://www.itl.nist.gov/div898/handbook/eda/section3/eda357.htm.

=cut

use version; our $VERSION = qv('0.0.2');

sub bartlett {
    my @groups = @_;
    my $k = scalar @groups;
    croak qq{\nThere must be more than one group} if ($k < 2);
    my $vars = &var(\@groups);
    my $n_total = sum map { scalar @{$_} } @groups;
    #my $SS_p = sum map { print qq{\nss $_->[2] and n $_->[0] and }, ($_->[2]-1) * $_->[0] ;($_->[2]-1) * $_->[0]  } @{$SSs};
    my $var_p = sum  map { ($_->[1]-1) * $_->[0]  } @{$vars};
    $var_p /= ($n_total-$k);
    $var_p = log($var_p);
    #my $SS_sum = sum map { print qq{\nss $_->[2] and n $_->[0] and }, log($_->[0]);($_->[2]-1) * log($_->[0])  } @{$SSs};
    my $var_sum = sum map { ($_->[1]-1) * log($_->[0])  } @{$vars};
    my $n_under = sum map { 1 / ($_->[1] - 1) } @{$vars};
    my $bar_k = ( ( ($n_total-$k) * $var_p ) - $var_sum ) / (1 + ( 1 / ( 3 * ($k-1))) * ( $n_under - ( 1 / ($n_total-$k)) ) ) ;
    my $df = $k -1;
    my $pval = &chisqrprob($df,$bar_k);
    if ( !wantarray ) { print qq{\nK = $bar_k\np_val = $pval\ndf = $df\nk = $k\ntotal n = $n_total}; return; }
    else { return ($bar_k, $pval, $df, $k, $n_total) }
    return;
}

sub var { 
    my $groups = shift;
    my $result = [];
    for my $a_ref (@{$groups}) {
        # $stat->count()
        my $n = scalar(@{$a_ref});
        # $stat->sum();
        my $sum = sum @{$a_ref};
        # $stat->mean()
        my $mean = ( $sum / $n ) ;
        my $var = sum map { ($_-$mean)**2  } @{$a_ref};
        $var /= ($n-1);
        push @{$result}, [$var, $n];
    }
    return $result;
}

1; # Magic true value required at end of module

__END__

=head1 DEPENDENCIES

'Statistics::Distributions' => '1.02', 
'Carp' => '1.08',
'List::Util' => '1.19',

=cut

=head1 BUGS

Let me know.

=cut

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cantab.net> >>

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.
=CUT
