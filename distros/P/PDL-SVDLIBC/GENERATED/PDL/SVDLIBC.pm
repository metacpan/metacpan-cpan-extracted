
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::SVDLIBC;

@EXPORT_OK  = qw( PDL::PP _svdccsencode  svdlas2a PDL::PP svdlas2  svdlas2aw PDL::PP svdlas2w  svdlas2ad PDL::PP svdlas2d PDL::PP svdindexND  svdindexNDt PDL::PP svdindexccs PDL::PP svderror );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::SVDLIBC::VERSION = 0.18;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::SVDLIBC $VERSION;




=pod

=head1 NAME

PDL::SVDLIBC - PDL interface to Doug Rohde's SVD C Library

=head1 SYNOPSIS

 use PDL;
 use PDL::SVDLIBC;

 ##---------------------------------------------------------------------
 ## Input matrix (dense)
 ##---------------------------------------------------------------------
 $n = 100;                  ##-- number of columns
 $m = 50;                   ##-- number of rows
 $a = random(double,$n,$m); ##-- random matrix

 ##---------------------------------------------------------------------
 ## Output pdls
 ##---------------------------------------------------------------------
 $d  = $n;                   ##-- max number of output dimensions
 $ut = zeroes(double,$m,$d); ##-- left singular components
 $s  = zeroes(double,$d);    ##-- singular values (diagnonal vector)
 $vt = zeroes(double,$n,$d); ##-- right singular components

 ##---------------------------------------------------------------------
 ## Singular Value Decomposition (dense)
 ##---------------------------------------------------------------------
 svdlas2d($a, $maxiters, $end, $kappa, $ut, $s, $vt);

 ##---------------------------------------------------------------------
 ## Singular Value Decomposition (sparse, using direct whichND()-encoding)
 ##---------------------------------------------------------------------
 $which  = whichND($a)->qsortvec();
 $nzvals = indexND($a,$which);

 svdlas2w($which, $nzvals, $n, $m, $maxiters, $end, $kappa, $ut, $s, $vt);

 ##---------------------------------------------------------------------
 ## Singular Value Decomposition (sparse, using PDL::CCS encoding)
 ##---------------------------------------------------------------------
 use PDL::CCS;
 ($ptr,$rowids,$nzvals) = ccsencode($a);
 $ptr->reshape($ptr->nelem+1);
 $ptr->set(-1, $rowids->nelem);

 svdlas2($ptr, $rowids, $nzvals, $m, $maxiters, $end, $kappa, $ut, $s, $vt);

 ##---------------------------------------------------------------------
 ## SVD decoding (lookup)
 ##---------------------------------------------------------------------
 $vals = svdindexND ($u, $s, $v, $which);
 $vals = svdindexNDt($ut,$s,$vt, $which);
 $vals = svdindexccs($u, $s, $v, $ptr,$rowids);
 $err  = svderror   ($u, $s, $v, $ptr,$rowids,$nzvals);

=head1 DESCRIPTION

PDL::SVDLIBC provides a PDL interface to the SVDLIBC routines
for singular value decomposition of large sparse matrices.
SVDLIBC is available from http://tedlab.mit.edu/~dr/SVDLIBC/

=cut







=head1 FUNCTIONS



=cut





use strict;

=pod

=head1 SVDLIBC Globals

There are several global data structures still lurking in the
SVDLIBC code, so expect problems if you are trying to run more
than one 'las2' procedure at once (even in different processes).

PDL::SVDLIBC provides access to (some of) the SVDLIBC globals
through the following functions, which are not exported.

=cut



=pod

=head2 PDL::SVDLIBC::verbosity()

=head2 PDL::SVDLIBC::verbosity($level)

Get/set the current SVDLIBC verbosity level.
Valid values for $level are between 0 (no messages) and
2 (many messages).

=cut




=pod

=head2 PDL::SVDLIBC::svdVersion()

Returns a string representing the SVDLIBC version
this module was compiled with.

=cut




=pod

=head1 SVD Utilities

=cut





=head2 _svdccsencode

=for sig

  Signature: (double a(n,m); indx      [o]ptr(n1); indx      [o]rowids(nnz); double [o]nzvals(nnz))


=for ref

info not available


=for bad

_svdccsencode does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_svdccsencode = \&PDL::_svdccsencode;




=pod

=head2 svdlas2a

=for sig

    indx    ptr(nplus1);
    indx    rowids(nnz);
    double  nzvals(nnz);
    indx    m();          ##-- default: max($rowids)+1
    int     d();          ##-- default: max(nplus1-1,m)
    int     iterations(); ##-- default: 2*$d
    double  end(2);       ##-- default: [-1e-30,1e-30]
    double  kappa();      ##-- default: 1e-6
    double  [o]ut(m,d);   ##-- default: new
    double  [o] s(d);     ##-- default: new
    double  [o]vt(n,d);   ##-- default: new

Uses a variant of the single-vector Lanczos method (Lanczos, 1950)
to compute the singular value decomposition of a sparse matrix with
$m() rows and data encoded
in Harwell-Boeing sparse format in the input parameters $ptr(), $rowids(),
and $nzvals().  See L<"PDL::CCS"> for a way to acquire these parameters
from a dense input matrix, but note that for svdlas2(), the
column pointer $ptr() is of size ($n+1) for a dense matrix $a with
$n columns, where $ptr($n)==$nnz is the total number of nonzero
values in $a.

$iterations() is the maximum number of Lanczos iterations to perform.

$end() specifies two endpoints of an interval within which all unwanted
eigenvalues lie.

$kappa() is a double containing the relative accuracy of Ritz
values acceptable as eigenvalues.

The left singular components are returned in the matrix $ut(),
the singular values themselved in the vector $s(), and the
right singular components in the matrix $vt().  Note that
$ut() and $vt() are transposed, and must be specified explicitly
in the call, so that the degree of reduction (the size parameter $d)
can be determined.  If $d==$n, then a full decomposition
will be computed, and on return, $ut() and $vt() should be transposed
instances of the matrices $u() and $v() as returned by PDL::MatrixOps::svd().

The Lanczos method as used here seems to be consistently the
fastest. This algorithm has the drawback that the low order singular
values may be relatively imprecise, but that is not a problem for most
users who only want the higher-order values or who can tolerate some
imprecision.

See also: svdlas2aw(), svdlas2d()

=cut

## ($iters,$end,$kappa,$ut,$s,$vt) = svddefaults($n=$nrows,$m=$ncols,$d, $iters,...)
## + returns default values
## + changed calling conventions in v0.14
##   - WAS: svddefaults($nrows,$cols, $d,$iters,...) ##-- SVDLIBC-style (col-primary)
##        ~ svddefaults($m,    $n,    $d,$iters,...) ##-- SVDLIBC-style (for dense $a(n,m))
##   - NOW: svddefaults($n,    $m,    $d,$iters,...) ##-- pdl-style
sub svddefaults {
    my ($n,$m,$d, $iters,$end,$kappa,$ut,$s,$vt) = @_;
    $n     = $n->at(0) if (UNIVERSAL::isa($n,'PDL'));
    $m     = $m->at(0) if (UNIVERSAL::isa($m,'PDL'));
    $d     = ($n >= $m ? $n : $m) if (!defined($d));
    $iters = 2*$d if (!defined($iters));
    $end   = pdl(double,[-1e-30,1e-30]) if (!defined($end));
    $kappa = pdl(double,1e-6) if (!defined($kappa));
    $ut    = PDL->zeroes(double,$m,$d) if (!defined($ut));
    $s     = PDL->zeroes(double,   $d) if (!defined($s));
    $vt    = PDL->zeroes(double,$n,$d) if (!defined($vt));
    return ($iters,$end,$kappa,$ut,$s,$vt);
}

sub svdlas2a {
    my ($ptr,$rowids,$nzvals, $m,$d, @args) = @_;
    $m = $rowids->flat->max+1 if (!defined($m));
    @args  = svddefaults($ptr->dim(0)-1,$m,$d,@args);
    svdlas2($ptr,$rowids,$nzvals,$m,@args);
    return @args[3..5];
}





=head2 svdlas2

=for sig

  Signature: (
    indx   ptr(nplus1);
    indx   rowids(nnz);
    double  nzvals(nnz);
    indx   m();
    int     iterations();
    double  end(2);
    double  kappa();
    double  [o]ut(m,d);
    double  [o] s(d);
    double  [o]vt(n,d);
    )


Guts for svdlas2a().
No default instantiation, and slightly different calling conventions.


=for bad

svdlas2 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svdlas2 = \&PDL::svdlas2;




=pod

=head2 svdlas2aw

=for sig

    indx    which(nnz,2); ##-- sorted indices of non-zero values
    double  nzvals(nnz);  ##-- non-zero values
    indx    n();          ##-- default: max($indx(0,:))+1
    indx    m();          ##-- default: max($indx(1,:))+1
    int     d();          ##-- default: max(n,m)
    int     iterations(); ##-- default: 2*$d
    double  end(2);       ##-- default: [-1e-30,1e-30]
    double  kappa();      ##-- default: 1e-6
    double  [o]ut(m,d);   ##-- default: new
    double  [o] s(d);     ##-- default: new
    double  [o]vt(n,d);   ##-- default: new

As for svdlas2a(), but implicitly converts the index-encoded matrix
($which(),$nzvals()) to an internal CCS-like sparse format
before computing the decomposition.
Should be slightly more efficient than using PDL::CCS::ccsencode()
or similar if you already have $which() and $nzvals() available.
These can be attained for a dense matric $a() e.g. by:

 $which  = $a->whichND->qsortvec->xchg(0,1);
 $nzvals = $a->indexND($which->xchg(0,1));

For convenience, $which() will be implicitly transposed if it is passed
as a list-of-vectors C<$whichND(2,nnz)> such as returned by L<whichND()|PDL::Primitive/whichND>,
but it must still be lexicographically sorted.

See also: svdlas2a(), svdlas2d()

=cut

sub svdlas2aw {
    my ($which,$nzvals, $n,$m,$d, @args) = @_;
    $which = $which->xchg(0,1) if ($which->dim(1) > $which->dim(0));
    $n    = $which->slice(":,0")->max+1 if (!defined($n));
    $m    = $which->slice(":,1")->max+1 if (!defined($m));
    @args = svddefaults($n,$m,$d,@args);
    svdlas2w($which,$nzvals,$n,$m,@args);
    return @args[3..5];
}





=head2 svdlas2w

=for sig

  Signature: (
    indx   whichi(nnz,Two);
    double  nzvals(nnz);
    indx   n();
    indx   m();
    int     iterations();
    double  end(2);
    double  kappa();
    double  [o]ut(m,d);
    double  [o] s(d);
    double  [o]vt(n,d);
    )


Guts for svdlas2a().
No default instantiation, and slightly different calling conventions.


=for bad

svdlas2w does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svdlas2w = \&PDL::svdlas2w;




=pod

=head2 svdlas2ad

=for sig

    double  a(n,m);
    int     d();          ##-- default: max($n,$m)
    int     iterations(); ##-- default: 2*$d
    double  end(2);       ##-- default: [-1e-30,1e-30]
    double  kappa();      ##-- default: 1e-6
    double  [o]ut(m,d);   ##-- default: new
    double  [o] s(d);     ##-- default: new
    double  [o]vt(n,d);   ##-- default: new

As for svdlas2(), but implicitly converts the dense input matrix
$a() to sparse format before computing the decomposition.

=cut

sub svdlas2ad {
    my ($a,$d, @args) = @_;
    @args = svddefaults($a->dim(0),$a->dim(1),$d,@args);
    svdlas2d($a,@args);
    return @args[3..5];
}





=head2 svdlas2d

=for sig

  Signature: (
    double  a(n,m);
    int     iterations();
    double  end(2);
    double  kappa();
    double  [o]ut(m,d);
    double  [o] s(d);
    double  [o]vt(n,d);
    )


Guts for _svdlas2d().


=for bad

svdlas2d does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svdlas2d = \&PDL::svdlas2d;





=head2 svdindexND

=for sig

  Signature: (
     u(d,m);
     s(d);
     v(d,n);
    indx which(Two,nnz);
    [o] vals(nnz);
    )


Lookup selected values in an SVD-encoded matrix, L<indexND()|PDL::Primitive/indexND>-style.
Should be equivalent to:

 ($u x stretcher($s) x $v->xchg(0,1))->indexND($which)

or its PDL-friendlier variant:

 ($u * $s)->matmult($v->xchg(0,1))->indexND($which)

... but only computes the specified values $which(), avoiding
memory bottlenecks for large sparse matrices.
This is a pure PDL::PP method, so you can use e.g.
C<float> for the SVD-encoded matrix if you wish.



=for bad

svdindexND does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svdindexND = \&PDL::svdindexND;




=pod

=head2 svdindexNDt

=for sig

    ut(m,d); s(d); vt(n,d); indx which(Two,nnz); [o] vals(nnz);

Wrapper for L<svdindexND()|/svdindexND> accepting transposed singular components
$ut() and $vt() as returned by e.g. L<svdlas2()|/svdlas2>.

=cut

sub svdindexNDt {
   return svdindexND($_[0]->xchg(0,1),$_[1],$_[2]->xchg(0,1),@_[3..$#_]);
}





=head2 svdindexccs

=for sig

  Signature: (
     u(d,m);
     s(d);
     v(d,n);
    indx ptr(nplus1);
    indx rowids(nnz);
    [o] vals(nnz);
    )


Lookup selected values in an SVD-encoded matrix using L<PDL::CCS|/PDL::CCS>-style indexing
as for L<svdlas2a()|/svdlas2a>.



=for bad

svdindexccs does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svdindexccs = \&PDL::svdindexccs;





=head2 svderror

=for sig

  Signature: (
    u(d,m);
    s(d);
    v(d,n);
    indx ptr(nplus1);
    indx rowids(nnz);
    nzvals(nnz);
    [o]err();
    )


Compute sum of squared errors for a sparse SVD-encoded matrix.
Should be equivalent to:

 sum( ($a - ($u x stretcher($s) x $v->xchg(0,1)))**2 )

... but computes all values on-the-fly, avoiding
memory bottlenecks for large sparse matrices.
This is a pure PDL::PP method, so you can use e.g.
C<float> for the SVD-encoded matrix if you wish.

Error contributions are computed even for "missing" (zero) values,
so running time is O(n*m).
Consider using L<svdindexND()|/svdindexND> or L<svdindexccs()|/svdindexccs>
to compute error rates
only for non-missing values if you have a large sparse matrix, e.g.:

 $svdvals = svdindexccs($u,$s,$v, $ptr,$rowids);
 $err_nz  = ($nzvals-$svdvals)->pow(2)->sumover;



=for bad

svderror does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svderror = \&PDL::svderror;




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

SVDLIBC by Dough Rohde.

SVDPACKC by Michael Berry, Theresa Do, Gavin O'Brien, Vijay Krishna and Sowmini Varadhan.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Globals still lurk in the depths of SVDLIBC.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Bryan Jurish.  All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself, either version 5.20.2 or any newer version of Perl 5
you have available.

The SVDLIBC sources included in this distribution are themselves
released under a BSD-like license. See the file
F<SVDLIBC/Manual/license.html> in the PDL-SVDLIBC source distribution
for details.

=head1 SEE ALSO

perl(1), PDL(3perl), PDL::CCS(3perl), SVDLIBC documentation.

=cut



;



# Exit with OK status

1;

		   