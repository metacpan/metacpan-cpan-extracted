package Statistics::QuickMedian;

use 5.006;
use strict;
use warnings FATAL => 'all';
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/qmedian/;

=head1 NAME

Statistics::QuickMedian - Parition-based median estimator

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

CAR Hoare's partition-based Quick Median Estimator in perl


    use Statistics::QuickMedian qw/qmedian/;
    my $median = qmedian(\$array);

    #or
    use Statistics::QuickMedian;
    my $qm = Statistics::QuickMedian->new();
    my $median = $qm->qmedian(\$array);
    
   
=head1 EXPORT

=over

=item qmedian

    use Statistics::QuickMedian qw/qmedian/;

=back

=head1 SUBROUTINES/METHODS

=head2 new

Makes a new Statistics::QuickMedian object...

    use Statistics::QuickMedian;
    my $qm = Statistics::QuickMedian->new();

=head2 qmedian(arrayref)

Partitions the data in referenced array and returns the median.

    my $median = $qm->qmedian(\$array);
    # or
    my $median = qmedian(\$array);

=cut

sub qmedian {
	my $a = pop; # leave object intact if it's there... total cheat!
	my $n = @$a;
	my $L = 0;
	my $R = $n-1;
	my $k = int($n / 2);
	my ($i, $j);
	while ($L < $R){
		my $x = $a->[$k];
		$i = $L; $j = $R;
		qsplit($n, $x, \$i, \$j, $a);
		if ($j < $k){  $L = $i; }
		if ($k < $i){  $R = $j; }
	}
	return $a->[$k];
}

=head2 qsplit

Used by qmedian.

=cut

sub qsplit {
	my ($n, $x, $i, $j, $a) = @_;
	do {
		while ($a->[$$i] < $x){ $$i++; }
		while ($x < $a->[$$j]){ $$j--; }
		if ($$i <= $$j){
			($a->[$$i], $a->[$$j]) = ($a->[$$j], $a->[$$i]);
			$$i++; $$j--;
		}
	}
	while ($$i <= $$j);
}

=head1 AUTHOR

Jimi Wills, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-quickmedian at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-QuickMedian>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::QuickMedian


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-QuickMedian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-QuickMedian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-QuickMedian>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-QuickMedian/>

=back


=head1 ACKNOWLEDGEMENTS

L<http://www.i-programmer.info/babbages-bag/505-quick-median.html>

C.A.R. Hoare.

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

1; # End of Statistics::QuickMedian
