package SmotifTF::GeometricMeasurements;
use strict;
use warnings;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = "0.01";
	@ISA = qw(Exporter);

	# name of the functions to export
	@EXPORT = qw();

	# symbols to export on request
	@EXPORT_OK   = qw(recalc);
}

our @EXPORT_OK;
use List::Util qw(max maxstr min minstr);
use Math::Trig;

=head1 NAME

GeometricMeasurements

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Subroutines for Geometric Calculations using atomic coordinates obtained from
the PDB file (used in the generation of the dynamic database). 

=head1 SUBROUTINES

    getcoords 
    get_axis 
    COM2 
    calculate_axis 
    calc_I 
    calc_evec 
    projectpoint 
    find_eigsmin 
    find_roots 
    cross 
    dot 
    unit 
    norm

=cut

=head1 getcoords

    This subroutine gets the coordinates of a given type of atom from the PDB file
   
    Usage: 
    my @ca = getcoords( \@idtable, \@lm, 'CA', $ArrayRef_coordchain);   

=cut

sub getcoords {

    my ( $data, $landmarks, $string, $ArrayRef_coordchain ) = @_;
    die "getcoords data arg required"       unless $data;
    die "getcoords landmarks arg required"  unless $landmarks;
    die "getcoords string arg required"     unless $string;
    die "getcoords coordchain arg required" unless $ArrayRef_coordchain;

    # data contains pdbid, chain, start, ss1, ss2
    my $chain    = $$data[1] || undef;
    my $startres = $$data[2] || undef;
    my $endres   = $$data[8] || undef;
    
    die "getcoords chain    not defined" unless $chain;
    die "getcoords startres not defined" unless $startres;
    die "getcoords endres   not defined" unless $endres;
    
    # ss1 length, ss1+loop length, ss1+loop+ss2 length
    @$landmarks = ( $$data[3], $$data[3] + $$data[5], $$data[3] + $$data[5] + $$data[4] );
   
    my $take    = 0;
    my @coords  = ();
    my $prevres = '-';
    my $len     = length($string);
    my %ckaltloc;
    LINE: foreach my $line (@$ArrayRef_coordchain) {
        
        chomp($line);
        my $atomname = substr( $line, 12, 4 );
        $atomname =~ s/\s+//g;
        
        next LINE unless ( $atomname eq $string );
        
        my $resnum = substr( $line, 22, 4 );
        $resnum =~ s/\s+//g;
        
        my $resinst = substr( $line, 26, 1 );
        $resinst =~ s/\s+//g;
        
        # alternate location  
        my $altloc = substr( $line, 16, 1 );
        $altloc =~ s/\s+//g;
        
        my $comresnum = $resnum . $resinst;
        if ( $comresnum eq $prevres ) {
        # check to see if there is an alternate location code. 
        # if so, skip it (we already have the primary one)
            my $ck = $ckaltloc{"$comresnum"};
            if ( $ck eq 'altloc' ) {
                next LINE;
            }
            elsif ( $ck eq 'none' ) {
                my $msg = "check resnum and insertion codes\n\tresnum $resnum\tinsert $resinst\tprevious $prevres";
                print "$msg\n";
                return;
            }
            else {
                print "no value in the ckaltloc hash\n";
                print
"check resnum and insertion codes\n\tresnum $resnum\tinsert $resinst\tprevious $prevres\n";
                return;
            }
        }
        if ( $altloc ne '' ) {
            $ckaltloc{"$comresnum"} = 'altloc';
        }
        else {
            $ckaltloc{"$comresnum"} = 'none';
        }
        if ( $comresnum eq $startres ) {
            $take = 1;
        }
        if ( $take == 1 ) {
            my $x = substr( $line, 30, 8 );
            $x =~ s/\s+//g;
            
            my $y = substr( $line, 38, 8 );
            $y =~ s/\s+//g;
            
            my $z = substr( $line, 46, 8 );
            $z =~ s/\s+//g;
            push( @coords, [ $x, $y, $z ] );
        }

        if ( $comresnum eq $endres ) {
            $take = 0;
            last;
        }
        $prevres = $comresnum;
    }    #end LINE loop
    
    unless ( scalar(@coords) > 0 ) {
        print "error in getcoords\tno coordinates";
        # return;
        die "error in getcoords\tno coordinates";
    }
    return @coords;
}

=for 
  recalc
  This subroutine calculates the distance and three angles for an smotif, 
  based on Baldo Oliva's description
=cut
sub recalc {

    my ( $ArrayRef_coordchain, @idtable ) = @_;
    die "recalc ArrayRef_coordchain arg required" unless $ArrayRef_coordchain;
    die "recalc \@idtable arg required"           unless @idtable;

    my @lm;
    # read coordinates from PDB file
    my @ca = getcoords( \@idtable, \@lm, 'CA', $ArrayRef_coordchain);   
    my @n  = getcoords( \@idtable, \@lm, 'N', $ArrayRef_coordchain );
    my @c  = getcoords( \@idtable, \@lm, 'C', $ArrayRef_coordchain );
    
    my $i = 0;
    my $type = substr( $idtable[7], 0, 1 );
    # find the vector for the axis of the 1st SS
    my @e1 = get_axis( $type, 1, 0, $lm[0], \@ca, \@n, \@c );
     

    my @point = @{ $ca[ $lm[0] - 1 ] }[ 0 .. 2 ];
    my @com   = COM2( 0, $lm[0], \@ca, \@ca, \@ca );
    # projection of last C-alpha coordinate onto the SS axis
    my @p1    = projectpoint( \@point, \@e1, \@com );

    $type = substr( $idtable[7], 1, 1 );
    # find vector for the axes of the 2nd SS
    my @e2 = get_axis( $type, 2, $lm[1], $lm[2], \@ca, \@n, \@c );

    @point = @{ $ca[ $lm[1] ] }[ 0 .. 2 ];
    @com   = COM2( $lm[1], $lm[2], \@ca, \@ca, \@ca );
    
    # projection of first C-alpha coordinate onto the SS axis
    my @p2 = projectpoint( \@point, \@e2, \@com );
    my @t1   = ( $p2[0] - $p1[0], $p2[1] - $p1[1], $p2[2] - $p1[2] );
    my @lvec = unit(@t1);
    
    # d = length of vector joining the first and last projected anchor points
    my $d    = norm(@t1);

    # delta = angle between first axis and vector connecting the anchor points
    my $rad = 180 / 3.14159265;
    my $delta = ( acos( dot( @e1, @lvec ) ) ) * $rad;

    # theta = angle between the two axes
    my $theta = ( acos( dot( @e1, @e2 ) ) ) * $rad; 

    my $rho    = 0;
    my @normal = unit( cross( @lvec, @e1 ) );
    my @target = cross( @e1, @normal );
    my $check  = norm(@target);
    if ( $check ne 0 ) {
        my $proj = dot( @e1, @e2 );
        my @proj = (
            $e2[0] - $proj * $e1[0],
            $e2[1] - $proj * $e1[1],
            $e2[2] - $proj * $e1[2]
        );
        my $dproj = norm(@proj);
        if ( $dproj ne 0 ) {
             # rho = angle between the second SS axis and the plane through 
             # the first SS, perpendicular to the vector connecting the anchor points
            $rho = acos( dot( @proj, @normal ) / $dproj ) * $rad; 
            $rho = 360 - $rho if ( dot( @proj, @target ) < 0 );
        }
    }
    return ( $d, $delta, $theta, $rho );
}


=for
  Calculates the axis passing through a given SS, based on Baldo Oliva's description
  get_axis 
=cut
sub get_axis {
    my ( $type, $ss, $first, $last, $ca, $n, $c ) = @_;
    my $ang = 0;
    my @newaxis;
    my @oldaxis;
    my $j;
    my @use_ca;
    my @use_n;
    my @use_c;
    my $count = $last - $first;
    my $beg   = 0;
    my $end   = 0;
    my $lim   = 5 * 3.14159265 / 180;
    my $term  = 8;
    my $stop  = 3;

    if ( $type eq 'H' ) {
        $stop = 9;
        $term = 100;
    }
    if ( $ss == 1 ) {
        $beg = max( $last - $stop, $first );
        $end = $last;
    }
    else {
        $beg = $first;
        $end = min( $first + $stop, $last );
    }
    for ( my $aa = $beg ; $aa < $end ; $aa++ ) {
        push( @use_ca, [ ( $$ca[$aa][0], $$ca[$aa][1], $$ca[$aa][2] ) ] );

        #print "aa $aa beg $beg end $end ca @{$$ca[$aa]}\n";
        push( @use_n, [ ( $$n[$aa][0], $$n[$aa][1], $$n[$aa][2] ) ] );
        push( @use_c, [ ( $$c[$aa][0], $$c[$aa][1], $$c[$aa][2] ) ] );
    }
    @newaxis = calculate_axis( $type, \@use_ca, \@use_n, \@use_c );
    $j       = $stop;
    @oldaxis = @newaxis;
    while ( ( $j < $count ) and ( $ang < $lim ) and ( $j < $term ) ) {
        $j++;
        @use_ca = ();
        @use_n  = ();
        @use_c  = ();
        if ( $ss == 1 ) {
            $beg = max( $last - $j, $first );
            $end = $last;
        }
        else {
            $beg = $first;
            $end = min( $first + $j, $last );
        }
        for ( my $aa = $beg ; $aa < $end ; $aa++ ) {
            push( @use_ca, [ ( $$ca[$aa][0], $$ca[$aa][1], $$ca[$aa][2] ) ] );

            #print "$aa\t@{$use_ca[$aa-$beg]}\n";
            push( @use_n, [ ( $$n[$aa][0], $$n[$aa][1], $$n[$aa][2] ) ] );
            push( @use_c, [ ( $$c[$aa][0], $$c[$aa][1], $$c[$aa][2] ) ] );
        }
        @oldaxis = @newaxis;
        @newaxis = calculate_axis( $type, \@use_ca, \@use_n, \@use_c );
        $ang     = acos( dot( @newaxis, @oldaxis ) );
    }
    return @oldaxis;
}


=for
   COM2 
   Returns the centre of mass of a given set of points
=cut
sub COM2 {

    my ( $start, $end, $ca, $n, $c ) = @_;
    my @tots = ( 0, 0, 0 );
    my $count = 3 * ( $end - $start );
    
    die "COM2 VECTOR OF LENGTH 0, can't find COM"
        unless ($count);
    
    for ( my $a = $start ; $a < $end ; $a++ ) {
        unless ( defined( $$ca[$a][0] )
            && defined( $$n[$a][0] )
            && defined( $$c[$a][0] ) )
        {
            print "coordinate arrays are not defined\n";
            die "coordinate arrays are not defined\n";
            return;
        }
        $tots[0] = $tots[0] + $$ca[$a][0] + $$n[$a][0] + $$c[$a][0];
        $tots[1] = $tots[1] + $$ca[$a][1] + $$n[$a][1] + $$c[$a][1];
        $tots[2] = $tots[2] + $$ca[$a][2] + $$n[$a][2] + $$c[$a][2];
    }
    return ( $tots[0] / $count, $tots[1] / $count, $tots[2] / $count );
}

=for
    Calculates the principal axis passing through a given set of points
    calculate_axis {
=cut
sub calculate_axis {

    my ( $type, $ca, $n, $c ) = @_;
    my @ca2   = @$ca;
    my @n2    = @$n;
    my @c2    = @$c;
    my $count = 0;
    foreach (@ca2) {
        $count++;
    }
    my @com = COM2( 0, $count, \@ca2, \@n2, \@c2 );
    for ( my $a = 0 ; $a < $count ; $a++ ) {
        $ca2[$a][0] -= $com[0];
        $ca2[$a][1] -= $com[1];
        $ca2[$a][2] -= $com[2];
        $n2[$a][0]  -= $com[0];
        $n2[$a][1]  -= $com[1];
        $n2[$a][2]  -= $com[2];
        $c2[$a][0]  -= $com[0];
        $c2[$a][1]  -= $com[1];
        $c2[$a][2]  -= $com[2];
    }
    my @p = ( [@ca2], [@n2], [@c2] );

    #find moment of inertia
    my @I = calc_I( $type, $count, @p );

    #find eigenvector
    my @evec = calc_evec( find_eigsmin(@I), @I );

    #check direction of axis by looking at max eigenvec, difference
    my $i = 2;
    if (    ( abs( $evec[0] ) >= abs( $evec[1] ) )
        and ( abs( $evec[0] ) >= abs( $evec[2] ) ) )
    {    #x-coord is max
        $i = 0;
    }
    elsif ( abs( $evec[1] ) >= abs( $evec[2] ) ) {    #y-coord is max
        $i = 1;
    }
    if ( ( $evec[$i] * ( $p[0][-1][$i] - $p[0][0][$i] ) ) < 0 ) {
        return ( -$evec[0], -$evec[1], -$evec[2] );
    }
    else {
        return @evec;
    }
}

=for
    Calculates the inertia tensor of a set of poitns, used to find the principal axis
    sub calc_I {
=cut 
sub calc_I {

    my ( $type, $count, @p ) = @_;
    my @I = ( [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] );
    my @pt;
    if ( $type eq 'H' ) {    #helix, calculate based on each point
        for ( my $atom = 0 ; $atom < 3 ; $atom++ ) {
            for ( my $a = 0 ; $a < $count ; $a++ ) {
                @pt = ( $p[$atom][$a][0], $p[$atom][$a][1], $p[$atom][$a][2] );
                $I[0][0] = $I[0][0] + ( $pt[1]**2 ) + ( $pt[2]**2 );
                $I[1][1] = $I[1][1] + ( $pt[0]**2 ) + ( $pt[2]**2 );
                $I[2][2] = $I[2][2] + ( $pt[0]**2 ) + ( $pt[1]**2 );
                $I[0][1] = $I[0][1] - $pt[0] * $pt[1];
                $I[0][2] = $I[0][2] - $pt[0] * $pt[2];
                $I[1][2] = $I[1][2] - $pt[1] * $pt[2];
            }
        }
    }
    else {    #strand, calculate based on midpts
        for ( my $atom = 0 ; $atom < 3 ; $atom++ ) {
            for ( my $a = 0 ; $a < $count - 1 ; $a++ ) {
                @pt = (
                    0.5 * ( $p[$atom][$a][0] + $p[$atom][ $a + 1 ][0] ),
                    0.5 * ( $p[$atom][$a][1] + $p[$atom][ $a + 1 ][1] ),
                    0.5 * ( $p[$atom][$a][2] + $p[$atom][ $a + 1 ][2] )
                );
                $I[0][0] = $I[0][0] + ( $pt[1]**2 ) + ( $pt[2]**2 );
                $I[1][1] = $I[1][1] + ( $pt[0]**2 ) + ( $pt[2]**2 );
                $I[2][2] = $I[2][2] + ( $pt[0]**2 ) + ( $pt[1]**2 );
                $I[0][1] = $I[0][1] - $pt[0] * $pt[1];
                $I[0][2] = $I[0][2] - $pt[0] * $pt[2];
                $I[1][2] = $I[1][2] - $pt[1] * $pt[2];
            }
        }
    }
    $I[1][0] = $I[0][1];
    $I[2][0] = $I[0][2];
    $I[2][1] = $I[1][2];
    return @I;
}

=for
    calc_evec {
    Returns the eigenvector corresponding to the given eigenvalue of the input matrix
=cut
sub calc_evec {

    my ( $eval, @I ) = @_;

    #count the zeros in each row
    $I[0][0] = $I[0][0] - $eval;
    $I[1][1] = $I[1][1] - $eval;
    $I[2][2] = $I[2][2] - $eval;
    my @zs   = ( 0, 0, 0 );
    my @nz   = ( 0, 1 );
    my $z    = 2;
    my @evec = ( 0, 0, 0 );
    for ( my $aa = 0 ; $aa < 3 ; $aa++ ) {

        for ( my $bb = 0 ; $bb < 3 ; $bb++ ) {
            if ( abs( $I[$aa][$bb] ) < 10**-14 ) { $zs[$aa]++ }
        }
    }
    my $max  = 0;
    my $mloc = 0;
    if ( ( $zs[0] > $zs[1] ) and ( $zs[0] > $zs[2] ) ) {
        $max  = $zs[0];
        $mloc = 0;
        @nz   = ( 1, 2 );
    }
    elsif ( $zs[1] > $zs[2] ) {
        $max  = $zs[1];
        $mloc = 1;
        @nz   = ( 0, 2 );
    }
    else {
        $max  = $zs[2];
        $mloc = 2;
        @nz   = ( 0, 1 );
    }
    if ( $max == 3 ) {
        $evec[$mloc] = 1;
        return unit(@evec);
    }
    elsif ( $max == 2 ) {
        $evec[$mloc] = 0;
        my $a = $I[ $nz[0] ][ $nz[0] ];
        my $b = $I[ $nz[0] ][ $nz[1] ];
        $evec[ $nz[0] ] = 1;
        $evec[ $nz[1] ] = -$a / $b;
        return unit(@evec);
    }
    else {
        #set up 2x2 coeff matrix
        my $a  = $I[0][0];
        my $b  = $I[0][1];
        my $c  = $I[1][1];
        my $d  = $I[0][2];
        my $e  = $I[1][2];
        my $x2 = ( $a * $e - $b * $d ) / ( $b**2 - $a * $c );
        my $x1 = ( -$d - $b * $x2 ) / $a;
        $evec[0] = $x1;
        $evec[1] = $x2;
        $evec[2] = 1;
        return unit(@evec);
    }
}

=for
    Projects a point p onto a vector v passing through the point c
    projectpoint {
=cut
sub projectpoint {

    my ( $p, $v, $c ) = @_;
    my @newp = ( 0, 0, 0 );
    my @padj = ( $$p[0] - $$c[0], $$p[1] - $$c[1], $$p[2] - $$c[2] );
    my $proj = dot( @padj, @$v );
    $newp[0] = $proj * $$v[0] + $$c[0];
    $newp[1] = $proj * $$v[1] + $$c[1];
    $newp[2] = $proj * $$v[2] + $$c[2];
    return @newp;
}

=for
    Returns the minimum eigenvalue of the input matrix
    sub find_eigsmin {
=cut
sub find_eigsmin {

    my (@I) = @_;
    my $a = -1 * ( $I[0][0] + $I[1][1] + $I[2][2] );
    my $b =
      -( $I[0][1]**2 ) -
      ( $I[0][2]**2 ) -
      ( $I[1][2]**2 ) +
      ( $I[0][0] * $I[1][1] ) +
      ( $I[0][0] * $I[2][2] ) +
      ( $I[1][1] * $I[2][2] );
    my $c =
      -( $I[0][0] * $I[1][1] * $I[2][2] ) -
      2 * ( $I[0][1] * $I[0][2] * $I[1][2] ) +
      ( $I[0][0] * $I[1][2]**2 ) +
      ( $I[1][1] * $I[0][2]**2 ) +
      ( $I[2][2] * $I[0][1]**2 );
    my @eigs = find_roots( $a, $b, $c );
    if ( ( $eigs[0] <= $eigs[1] ) and ( $eigs[0] <= $eigs[2] ) ) {
        return $eigs[0];
    }
    elsif ( $eigs[1] <= $eigs[2] ) {
        return $eigs[1];
    }
    else {
        return $eigs[2];
    }
}

=for
    Finds the roots to a cubic equation of the form x^3+ax^2+bx+c=0
    find_roots {
=cut
sub find_roots {

    my ( $a, $b, $c ) = @_;
    my $p = $b - ( $a**2 ) / 3;
    my $q = $c + ( 2 * $a**3 - 9 * $a * $b ) / 27;
    my $urad = ( ( $q**2 ) / 4 + ( $p**3 ) / 27 );
    my $mag = sqrt( 0.25 * ( $q**2 ) - $urad );
    my $newmag = $mag**( 1 / 3 );
    my $ang    = acos( -0.5 * $q / $mag );
    my $m      = abs( cos( $ang / 3 ) );
    my $n      = abs( sin( $ang / 3 ) * ( 3**(0.5) ) );
    my $x1     = 2 * $newmag * $m - ( $a / 3 );
    my $x2     = -1 * $newmag * ( $m + $n ) - ( $a / 3 );
    my $x3     = -1 * $newmag * ( $m - $n ) - ( $a / 3 );
    return ( $x1, $x2, $x3 );
}

=for
    Returns the cross product of two input vectors
    cross {
=cut
sub cross {

    my (@v) = @_;
    my @res = ( 0, 0, 0 );
    $res[0] = $v[1] * $v[5] - $v[2] * $v[4];
    $res[1] = $v[2] * $v[3] - $v[0] * $v[5];
    $res[2] = $v[0] * $v[4] - $v[1] * $v[3];
    return @res;
}

=for
    Returns the dot product of two input vectors
    dot 
=cut
sub dot {

    my (@v) = @_;
    my $res = ( $v[0] * $v[3] + $v[1] * $v[4] + $v[2] * $v[5] );
    return $res;
}

=for
    Returns the unit vector in the direction of the input vector
    unit {
=cut
sub unit {

    my (@v) = @_;
    my $norm = norm(@v);
    for ( my $a = 0 ; $a < 3 ; $a++ ) {
        $v[$a] = $v[$a] / $norm;
    }
    return @v;
}

=for
    norm {
    Returns the length of the input vector
=cut
sub norm {

    my (@v) = @_;
    my $res = ( $v[0]**2 + $v[1]**2 + $v[2]**2 )**(0.5);
    return $res;
}

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>. 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GeometricMeasurements

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/.>

=item * Search CPAN

L<http://search.cpan.org/dist/./>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Fiserlab Members .

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

1;
