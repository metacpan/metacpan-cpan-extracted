# RNA::HairpinFigure
# Maintained by Wei Shen <shenwei356@gmail.com>

package RNA::HairpinFigure;

use 5.10.0;
use strict;
use warnings FATAL => 'all';
no if $] >= 5.018, warnings => "experimental";

# use Carp;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(draw make_pair_table make_pair_table_deleting_multi_loops);

=head1 NAME

RNA::HairpinFigure - Draw hairpin-like text figure from RNA 
sequence and its secondary structure in dot-bracket notation.

=head1 DESCRIPTION 

miRNA database miRBase maintains miRNAs and their precursors --
pre-miRNAs which have hairpin-like secondary structures. They
provide the hairpin-like text figure along with sequences and 
secondary structures in dot-bracket notation which could produced
by ViennaRNA package.

However, neither miRBase nor ViennaRNA provide any scripts or
programs to transfrom dot-bracket notation to hairpin-like text
figure, which was needed in our miRNA prediction project.

RNA::HairpinFigure draws hairpin-like text figure from RNA 
sequence and its secondary structure in dot-bracket notation.
If the hairpin have multi loops, they will be deleted and 
treated as a big loop, the longest stem will be the final stem.

This module is part of the FOMmiR miRNA predictor on
http://bioinf.shenwei.me or http://bioinf.xnyy.cn/.

May this module be helpful for you.

=head1 VERSION

Version 0.141212 released at 12th Dec. 2014.

=cut

our $VERSION = '0.141212';

=head1 SYNOPSIS

Usage:

    use RNA::HairpinFigure qw/draw/;

    my $name   = 'hsa-mir-92a-1 MI0000093 Homo sapiens miR-92a-1 stem-loop';
    my $seq    = 'CUUUCUACACAGGUUGGGAUCGGUUGCAAUGCUGUGUUUCUGUAUGGUAUUGCACUUGUCCCGGCCUGUUGAGUUUGG';
    my $struct = '..(((...((((((((((((.(((.(((((((((((......)))))))))))))).)))))))))))).))).....';
       
    my $figure = draw( $seq, $struct );

    print ">$name\n$seq\n$struct\n$figure\n";

Output:

    >hsa-mir-92a-1 MI0000093 Homo sapiens miR-92a-1 stem-loop
    CUUUCUACACAGGUUGGGAUCGGUUGCAAUGCUGUGUUUCUGUAUGGUAUUGCACUUGUCCCGGCCUGUUGAGUUUGG
    ..(((...((((((((((((.(((.(((((((((((......)))))))))))))).)))))))))))).))).....
    ---CU   UAC            C   U           UU 
         UUC   ACAGGUUGGGAU GGU GCAAUGCUGUG  U
         |||   |||||||||||| ||| |||||||||||   
         GAG   UGUCCGGCCCUG UCA CGUUAUGGUAU  G
    GGUUU   --U            U   -           GU 


=head1 EXPORT

draw make_pair_table make_pair_table_deleting_multi_loops

=head1 SUBROUTINES/METHODS

=head2 draw SCALAR SCALAR

Returns the hairpin-like text figures. Sequence and 
its secondary structure in dot-bracket notation are
both required as arguments.

When a hairpin has multi-loops, only the longest stem
remains according to miRBase's practice.

=cut

sub draw($$) {
    my ( $seq, $struct ) = @_;

    return 'Missing sequence or structure'
        unless length $seq > 0 and length $struct > 0;
    return 'Missmatch length of sequence and structure'
        unless length $seq == length $struct;
    return 'Illegal character in dot-bracket notation'
        if $struct =~ /[^\.\(\)]/;

    my ( @l1, @l2, @l3, @l4, @l5 );

    my $len = length $struct;
    my $table;

    if ( $struct =~ /(\)\.*\()/ ) {
        $table = make_pair_table_deleting_multi_loops($struct);
    }
    else {
        $table = make_pair_table($struct);
    }

    my @left  = sort { $a <=> $b } keys %$table;
    my @right = map  { $$table{$_} } @left;

    # ssRNA
    my $overhang_len_5p = $left[0] - 1;
    my $overhang_len_3p = $len - $right[0];
    if ( $overhang_len_3p >= $overhang_len_5p ) {
        for ( 1 .. ( $overhang_len_3p - $overhang_len_5p ) ) {
            push @l1, '-';
            push @l2, ' ';
            push @l3, ' ';
            push @l4, ' ';
            push @l5, substr( $seq, $len - $_, 1 );
        }
        for ( 1 .. $overhang_len_5p ) {
            push @l1, substr( $seq, $_ - 1, 1 );
            push @l2, ' ';
            push @l3, ' ';
            push @l4, ' ';
            push @l5,
                substr( $seq,
                $len - ( $overhang_len_3p - $overhang_len_5p ) - $_, 1 );
        }
    }
    else {
        for ( 1 .. ( $overhang_len_5p - $overhang_len_3p ) ) {
            push @l1, substr( $seq, $_ - 1, 1 );
            push @l2, ' ';
            push @l3, ' ';
            push @l4, ' ';
            push @l5, '-';
        }
        for ( 1 .. ( $len - $right[0] ) ) {
            push @l1, substr( $seq, $overhang_len_5p - $overhang_len_3p + $_ - 1,        1 );
            push @l2, ' ';
            push @l3, ' ';
            push @l4, ' ';
            push @l5, substr( $seq, $len - $_, 1 );
        }
    }

    # stem region
    my $next5 = $left[0];
    my $next3 = $right[0];
    my ( $n5, $n3, $asy );
    while ( $next5 <= $left[-1] ) {

        # stem
        if ( $next5 ~~ @left and $next3 ~~ @right ) {
            while ( $next5 ~~ @left and $next3 ~~ @right ) {
                push @l1, ' ';
                push @l2, substr( $seq, $next5 - 1, 1 );
                push @l3, '|';
                push @l4, substr( $seq, $$table{$next5} - 1, 1 );
                push @l5, ' ';
                $next5++;
                $next3--;
            }
        }

        # 5' gap
        elsif ( $next5 !~ @left and $next3 ~~ @right ) {

            # print "[5' gap],$next5,$next3\n";
            $n5 = 0;
            $n5++ until ( $next5 + $n5 ) ~~ @left;
            for ( 1 .. $n5 ) {
                push @l1, substr( $seq, $next5 + $_ - 2, 1 );
                push @l2, ' ';
                push @l3, ' ';
                push @l4, ' ';
                push @l5, '-';
            }
            $next5 += $n5;
        }

        # 3' gap
        elsif ( $next5 ~~ @left and $next3 !~ @right ) {

            # print "[3' gap], $next5,$next3\n";
            $n3 = 0;
            $n3++ until ( $next3 - $n3 ) ~~ @right;
            for ( 1 .. $n3 ) {
                push @l1, '-';
                push @l2, ' ';
                push @l3, ' ';
                push @l4, ' ';
                push @l5, substr( $seq, $next3 - $_, 1 );
            }
            $next3 -= $n3;
        }

        # bulge
        else {
            $n5 = 0;
            $n5++ until ( $next5 + $n5 ) ~~ @left;
            $n3 = 0;
            $n3++ until ( $next3 - $n3 ) ~~ @right;

            if ( $n5 > $n3 ) {
                for ( 1 .. ( $n5 - $n3 ) ) {
                    push @l1, substr( $seq, $next5 + $_ - 2, 1 );
                    push @l2, ' ';
                    push @l3, ' ';
                    push @l4, ' ';
                    push @l5, '-';
                }
                for ( 1 .. $n3 ) {
                    push @l1, substr( $seq, $next5 + $n5 - $n3 + $_ - 2,, 1 );
                    push @l2, ' ';
                    push @l3, ' ';
                    push @l4, ' ';
                    push @l5, substr( $seq, $next3 - $_,                  1 );
                }
            }
            elsif ( $n5 < $n3 ) {
                for ( 1 .. ( $n3 - $n5 ) ) {
                    push @l1, '-';
                    push @l2, ' ';
                    push @l3, ' ';
                    push @l4, ' ';
                    push @l5, substr( $seq, $next3 - $_, 1 );
                }
                for ( 1 .. $n5 ) {
                    push @l1, substr( $seq, $next5 + $_ - 2, 1 );
                    push @l2, ' ';
                    push @l3, ' ';
                    push @l4, ' ';
                    push @l5, substr( $seq, $next3 - ( $n3 - $n5 ) - $_, 1 );
                }
            }
            else {
                for ( 1 .. $n5 ) {
                    push @l1, substr( $seq, $next5 + $_ - 2, 1 );
                    push @l2, ' ';
                    push @l3, ' ';
                    push @l4, ' ';
                    push @l5, substr( $seq, $next3 - $_,     1 );
                }
            }
            $next5 += $n5;
            $next3 -= $n3;
        }
    }

    # terminal loop
    my $loop = $right[-1] - $left[-1] - 1;
    my $n = int( ( $loop - 2 ) / 2 );

    if ( $n > 0 ) {
        for ( 1 .. $n ) {
            push @l1, substr( $seq, $next5 + $_ - 2, 1 );
            push @l2, ' ';
            push @l3, ' ';
            push @l4, ' ';
            push @l5, substr( $seq, $next3 - $_,     1 );
        }
        $next5 += $n;
        $next3 -= $n;

        push @l1, ' ';
        push @l2, substr( $seq, $next5 - 1, 1 );
        push @l3, $loop - 2 * ( $n + 1 ) > 0
            ? substr( $seq, $next5, 1 )
            : ' ';
        push @l4, substr( $seq, $next3 + 1, 1 );
        push @l5, ' ';
    }
    elsif ( $loop == 3 or $loop == 2 ) {
        push @l1, ' ';
        push @l2, substr( $seq, $next5 - 1, 1 );
        push @l3, ' ';
        push @l4, substr( $seq, $next3 + 1, 1 );
        push @l5, ' ';

        if ( $loop == 3 ) {
            push @l1, ' ';
            push @l2, ' ';
            push @l3, substr( $seq, $next5, 1 );
            push @l4, ' ';
            push @l5, ' ';
        }
    }

    # out put
    my $s1 = join '', @l1;
    my $s2 = join '', @l2;
    my $s3 = join '', @l3;
    my $s4 = join '', @l4;
    my $s5 = join '', @l5;

    my $figure = '';
    $figure .= $s1 . "\n" . $s2 . "\n" . $s3 . "\n" . $s4 . "\n" . $s5;

    return $figure;
}

=head2 make_pair_table SCALAR

Returns hash reference which represent the dot-bracket notation.
Table{i} is j if (i, j) pair.

Secondary structure in dot-bracket notation is required.

=cut

sub make_pair_table ($) {
    my ($struct) = @_;
    my ( $i, $j, $length, $table, $stack );
    $length = length $struct;
    my @struct_data = split "", $struct;
    for ( $i = 1; $i <= $length; $i++ ) {
        if ( $struct_data[ $i - 1 ] eq '(' ) {
            unshift @$stack, $i;
        }
        elsif ( $struct_data[ $i - 1 ] eq ')' ) {
            if ( @$stack == 0 ) {
                die "unbalanced brackets $struct\n";
                return undef;
            }
            $j = shift @$stack;
            $$table{$j} = $i;
        }
    }
    if ( @$stack != 0 ) {
        die "unbalanced brackets $struct\n";
        return undef;
    }
    undef @$stack;
    return $table;
}

=head2 make_pair_table_deleting_multi_loops SCALAR

It makes pair table for dot-bracket notation with multi loops,
which will be deleted and treated as a big loop, the longest
stem will be the final stem.

Returns hash reference which represent the dot-bracket notation.
Table{i} is j if (i, j) pair. 

Secondary structure in dot-bracket notation is required.

=cut

sub make_pair_table_deleting_multi_loops($) {
    my ($struct) = @_;
    my $len = length $struct;
    my @struct_data = split '', $struct;

    #==============[ find minor loops ]==============================
    my (@minor_loop_sites);
    my $site;
    while ( $struct =~ /\((\.*)\)/g ) {
        $site = pos $struct;
        push @minor_loop_sites,
            {
            'start'  => $site - length $1,
            'end'    => $site - 1,
            'length' => length $1
            };
        pos $struct = $site;
    }

    # print "$$_{start}, $$_{end}, $$_{length}\n" for @minor_loop_sites;

    #============[ make pair table for minor loops ]=================
    my @tables          = ();
    my @visited_sites_i = ();
    my @visited_sites_j = ();
    my ( $i, $j );
    for (@minor_loop_sites) {

        # find stem
        # print "site: $_\n";
        $i = $$_{start} - 1;
        $j = $$_{end} + 1;

        # print "$i, $j, len: $len\n";

        my $table = {};
        my $stop;
        while ( $i >= 1 and $j <= $len ) {

            # print "->$i, $j\n";
            $stop = 0;
            while ( $i >= 1 ) {

                # print "i->$i, $j\n";
                if ( $struct_data[ $i - 1 ] eq '(' ) {
                    last;
                }
                elsif ( $struct_data[ $i - 1 ] eq ')' ) {
                    $stop = 1;
                    last;
                }
                else {
                    $i--;
                }
            }
            last if $stop;
            while ( $j <= $len ) {

                # print "j->$i, $j\n";
                if ( $struct_data[ $j - 1 ] eq ')' ) {
                    last;
                }
                elsif ( $struct_data[ $j - 1 ] eq '(' ) {
                    $stop = 1;
                    last;
                }
                else {
                    $j++;
                }

            }
            last if $stop;
            $$table{$i} = $j;

            ####### for find the last stem#######
            push @visited_sites_i, $i;
            push @visited_sites_j, $j;
            ####### for find the last stem#######

            $i--;
            $j++;
        }
        push @tables, $table;
    }

    $struct_data[ $_ - 1 ] = '.' for @visited_sites_i;
    $struct_data[ $_ - 1 ] = '.' for @visited_sites_j;
    $struct = join '', @struct_data;

    # print "$struct\n";

    #============[ make pair table for the major stem ]==============
    if ( $struct =~ /\(\.*\)/ ) {
        my $table = make_pair_table($struct);

        # delete the weird stem
        my @left  = sort { $a <=> $b } keys %$table;
        my @right = map  { $$table{$_} } @left;
        my ( @delete_i, @delete_j );
        my ( $a, $b, $i, $j );

        foreach $b (@right) {
            foreach $j (@visited_sites_j) {
                if ( $b < $j ) {
                    push @delete_j, $b;
                    last;
                }
            }
        }

        foreach $a (@left) {
            foreach $i (@visited_sites_i) {
                if ( $a > $i ) {
                    push @delete_i, $a;
                }
            }
        }
        delete $$table{$_} for @delete_i;
        for ( keys %$table ) {
            if ( $$table{$_} ~~ @delete_j ) {
                delete $$table{$_};
            }
        }

        push @tables, $table;
    }

    #
    # print "sites of every stems\n";
    # for (@tables) {
    # my $table = $_;
    # my @left  = sort{ $a <=> $b } keys %$table;
    # my @right = map { $$table{$_} } @left;
    # print "@left\n";
    # print "@right\n";
    # }

    #============[ find the longest stem ]===========================
    my $stem_length_max = 0;
    my $longest_table;
    my $n;
    for (@tables) {
        $n = scalar keys %$_;

        # print "length: $n\n";
        if ( $n > $stem_length_max ) {
            $stem_length_max = $n;
            $longest_table   = $_;
        }
    }
    return $longest_table;
}

=head1 AUTHOR

Wei Shen, C<< <shenwei356 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rna-hairpinfigure at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RNA-HairpinFigure>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RNA::HairpinFigure


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RNA-HairpinFigure>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RNA-HairpinFigure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RNA-HairpinFigure>

=item * Search CPAN

L<http://search.cpan.org/dist/RNA-HairpinFigure/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Wei Shen.

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

1;    # End of RNA::HairpinFigure
