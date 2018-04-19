
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::SVDSLEPc;

@EXPORT_OK  = qw(  slepc_svd_help  slepc_svd  _slepc_svd_int PDL::PP _slepc_svd_int );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::SVDSLEPc::VERSION = 0.005;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::SVDSLEPc $VERSION;





use Carp qw(confess);
use strict;




=pod

=head1 NAME

PDL::SVDSLEPc - PDL interface to SLEPc sparse singular value decomposition

=head1 SYNOPSIS

 use PDL;
 use PDL::SVDSLEPc;

 ##---------------------------------------------------------------------
 ## Input matrix (dense)
 
 $m = 100;                    ##-- number of rows
 $n = 50;                     ##-- number of columns
 $a = random(double,$m,$n);   ##-- random matrix

 ##---------------------------------------------------------------------
 ## Input matrix (sparse)
 
 use PDL::CCS;
 $a  *= ($a->random>0.9);      ##-- make sparse
 $ccs = $a->toccs();           ##-- encode as PDL::CCS::Nd object
 
 ##-- get Harwell-Boeing encoding triple
 $ptr    = $ccs->ptr(0);
 $colids = $ccs->_whichND->slice("(1),");
 $nzvals = $cccs->_nzvals;

 ##---------------------------------------------------------------------
 ## SLEPc Singular Value Decomposition
 
 slepc_svd_help();            ##-- print available options to STDOUT
 
 ($u,$s,$v) = slepc_svd($ccs, ['-svd_nsv'=>32]);                 ##-- from PDL::CCS::Nd object
 ($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, ['-svd_nsv'=>32]); ##-- from Harwell-Boeing encoding


=head1 DESCRIPTION

PDL::SVDSLEPc provides a PDL interface to the SLEPc singular value decomposition solver(s).
SLEPc itself is available from L<http://slepc.upv.es/>.

=cut







=head1 FUNCTIONS



=cut




END { _svdslepc_END(); }



use strict;

=pod

=head1 CONSTANTS

PDL::SVDSLEPc provides access to the following SLEPc constants:





=pod

=head2 PDL::SVDSLEPc::slepc_version()

Returns a string representing the SLEPc library version
this module was compiled with.

=cut




=pod

=head2 PDL::SVDSLEPc::petsc_version()

Returns a string representing the PETSc library version
this module was compiled with.

=cut




=pod

=head2 PDL::SVDSLEPc::library_version()

In list context returns a pair C<(slepc_version(),petsc_version())>,
in scalar context returns a string with both versions separated
with a semicolon.

=cut

sub library_version {
  my @v = (slepc_version(),petsc_version());
  return wantarray ? @v : join('; ', @v);
}




=pod

=head2 PDL::SVDSLEPc::MPI_Comm_size()

Returns the number of MPI processes available.
Using multiple MPI processes with mpiexec behaves strangely with perl at the moment,
so this should generally return 1.

=cut




=pod

=head1 SVD UTILITIES

The following functions are provided as quick and dirty wrappers
for the SLEPc L<SVD|http://slepc.upv.es/documentation/current/docs/manualpages/SVD/index.html>
solver class.

=cut




=pod

=head2 slepc_svd_help

Prints a help message with all supported SLEPc SVD options to STDOUT.
Really just a wrapper for

 slepc_svd(null,null,null, 0,0,0, ['-help']);

=cut

sub slepc_svd_help {
  slepc_svd(null,null,null, 0,0,0, ['-help']);
}




=pod

=head2 slepc_svd

=for sig

  Signature: (
	      int  rowptr(mplus1);
	      int  colids(nnz);
	      double nzvals(nnz);
	      double [o]u(d,n);         # optional
	      double [o]s(d);           # optional
	      double [o]v(d,m);         # optional
              int    M=>d;              # optional
              int    N=>n;              # optional
              int    D=>d;              # optional
              \@options;                # optional
             )



Compute the (truncated) singular value decomposition of a sparse matrix
using a L<SLEPc SVD solver|http://slepc.upv.es/documentation/current/docs/manualpages/SVD/>.
The sparse input matrix with logical (row-primary) dimensions ($m,$n)
is passed in encoded in Harwell-Boeing sparse format in the input parameters
$rowptr(), $colids(), and $nzvals().  See L<PDL::CCS> for a way to acquire these parameters
from a dense input matrix, but note that for this function, the
row-pointer $rowptr() is of size ($m+1)
for a dense matrix $a with $m rows,
where $rowptr($m)==$nnz is the total number of nonzero
values in $a.
As an alternative, a single L<PDL::CCS::Nd|PDL::CCS::Nd> object can be passed
in place of of $rowptr, $colids, and $nzvals.

The left singular components are returned in the matrix $u(),
the singular values themselved in the vector $s(), and the
right singular components in the matrix $v().
These output piddles, as well as the
logical dimensions ($m,$n) of the input matrix and the
size $d of the truncated SVD to be computed may be specified explicitly in the call,
but otherwise will be estimated from $rowptr(), $colids(), and/or \@options.
If $d==min($m,$n) [the default], then a full decomposition
will be computed, and on return, $u() and $v() should be
variants (up to sign and specified error tolerance)
of the matrices returned by L<PDL::MatrixOps::svd()|PDL::MatrixOps/svd>.

Additional options to the underlying SLEPc and PETSc code can be passed
command-line style in the ARRAY-ref C<\@options>; see the output of
L<slepc_svd_help()|/slepc_svd_help> for a list of available options.
In particular, the option C<-svd_nsv> can be used to specify the
number of singular values to be returned ($d) if you choose to omit
both the $d paramter and nontrivial output piddles.
For example, in order to compute a truncated SVD using with 32 singular values using
the Thick-restart Lanczos method with at
most 128 iterations and a tolerance of 1e-5, you could call:

 ($u,$s,$v) = slepc_svd($rowptr,$colids,$nzvals,
                        [qw(-svd_type trlanczos
                            -svd_nsv 32
                            -svd_max_it 128
                            -svd_tol 1e-5)]);

... or if you already have a L<PDL::CCS::Nd|PDL::CCS::Nd> object $ccs handy:

  ($u,$s,$v) = $ccs->slepc_svd([-svd_type=>'trlanczos', -svd_nsv=>32, -svd_max_it=>128, -svd_tol=>1e-5]);

=cut

BEGIN { *PDL::CCS::Nd::slepc_svd = \&slepc_svd; }
sub slepc_svd {
  my ($rowptr,$colids,$nzvals, @usv,@dims,@opts);
  if (UNIVERSAL::isa($_[0],"PDL::CCS::Nd")) {
    my $ccs = shift->to_physically_indexed();
    $rowptr = $ccs->ptr(0);
    $colids = $ccs->_whichND->slice("(1),");
    $nzvals = $ccs->_nzvals;
    @dims   = $ccs->dims;
  } else {
    ($rowptr,$colids,$nzvals) = splice(@_,0,3);
  }

  ##-- parse arguments into @pdls=($u,$s,$v), @dims=($m,$n,$d), @opts=(...)
  foreach my $arg (@_) {
    if (@usv < 3 && UNIVERSAL::isa($arg,'PDL')) {
      ##-- output pdl
      push(@usv,$arg);
    }
    elsif (@dims < 3 && ((UNIVERSAL::isa($arg,'PDL') && $arg->nelem==1) || !ref($arg))) {
      ##-- dimension argument
      push(@dims, UNIVERSAL::isa($arg,'PDL') ? $arg->sclr : $arg);
    }
    elsif (UNIVERSAL::isa($arg,'ARRAY')) {
      ##-- option array
      push(@opts,@$arg);
    }
    elsif (UNIVERSAL::isa($arg,'HASH')) {
      ##-- option hash: pass boolean flags as ("-FLAG"=>undef), e.g. "-svd_view"=>undef
      push(@opts, map {((/^\-/ ? $_ : "-$_"),(defined($arg->{$_}) ? $arg->{$_} : qw()))} keys %$arg);
    }
    else {
      ##-- extra parameter: warn
      warn(__PACKAGE__ . "::slepc_svd(): ignoring extra parameter '$arg'");
    }
  }

  ##-- extract -svd_nsv ($d) option
  my $nsv = undef;
  foreach (0..($#opts-1)) {
    $nsv = $opts[$_+1] if ($opts[$_] eq '-svd_nsv');
  }

  ##-- extract arguments
  my ($u,$s,$v) = @usv;
  my ($m,$n,$d) = @dims;
  $m = defined($v) && !$v->isempty ? $v->dim(1) : $rowptr->nelem-1  if (!defined($m));
  $n = defined($u) && !$u->isempty ? $u->dim(1) : $colids->max+1 if (!defined($n));
  $d = (defined($u) && !$u->isempty ? $u->dim(0)
	: (defined($s) && !$s->isempty ? $s->dim(0)
	   : (defined($v) && !$v->isempty ? $v->dim(0)
	      : (defined($nsv) ? $nsv
		 : $m < $n ? $m : $n))))
    if (!defined($d));

  ##-- create output piddles
  $u = zeroes(double, $d,$n) if (!defined($u) || $u->isempty);
  $s = zeroes(double, $d)    if (!defined($s) || $s->isempty);
  $v = zeroes(double, $d,$m) if (!defined($v) || $v->isempty);

  ##-- call guts
  _slepc_svd_int($rowptr,$colids,$nzvals, $u,$s,$v, $m,$n,$d, \@opts);
  return ($u,$s,$v);
}





=head2 _slepc_svd_int

=for sig

  Signature: (
    int  rowptr(mplus1);
    int  colids(nnz);
    double nzvals(nnz);
    double [o]u(d,n);
    double [o]s(d);
    double [o]v(d,m);
    ; 
    int M=>m;
    int N=>n;
    int D=>d;
    IV optsArray;
    )


Guts for L<slepc_svd()|/slepc_svd> with stricter calling conventions:
The input matrix must be passed as a Harwell-Boeing triple
C<($rowptr,$colids,$nzvals)>,
and the size parameters C<M>, C<N>, and C<D> and options array C<optsArray> are all mandatory.


=for bad

_slepc_svd_int does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_slepc_svd_int = \&PDL::_slepc_svd_int;




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

SLEPc by Carmen Campos, Jose E. Roman, Eloy Romero, and Andres Tomas.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

=head2 no abstract interface

There should really be a more general and abstract PDL interface to SLEPc/PETsc.


=head2 OpenMPI Errors "mca: base: component find: unable to open ..."

You might see OpenMPI errors such as the following when trying to use this module:

 mca: base: component find: unable to open /usr/lib/openmpi/lib/openmpi/mca_paffinity_hwloc: perhaps a missing symbol, or compiled for a different version of Open MPI? (ignored)

If you do, you probably need to configure your runtime linker to pre-load the OpenMPI libraries, e.g. with

 export LD_PRELOAD=/usr/lib/libmpi.so

or similar.  An alternative is to build OpenMPI with the C<--disable-dlopen> option.
See L<http://www.open-mpi.org/faq/?category=troubleshooting#missing-symbols> for details.

=head2 OpenMPI warnings "... unable to find any relevant network interfaces ... (openib)"

This OpenMPI warning has been observed on Ubuntu 14.04; it can be suppressed by setting the OpenMPI
MCA C<btl> ("byte transfer layer") parameter to exclude the C<openib> module.
This can be
accomplished in various ways, e.g.:

=over 4

=item via command-line parameters to C<mpiexec>:

Call your program as:

 $ mpiexec --mca btl ^openib PROGRAM...

=item via environment variables

You can set the OpenMPI MCA paramters via environment variables, e.g.:

 $ export OMPI_MCA_btl="^openib"
 $ PROGRAM...

=item via configuration files

You can set OpenMPI MCA parameters via F<$HOME/.openmpi/mac-params.conf>:

 ##-- suppress annoying warnings about missing openib
 btl = ^openib

=back

See L<http://www.open-mpi.de/faq/?category=tuning#setting-mca-params> for more details.


=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Bryan Jurish.  All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself, either version 5.20.2 or any newer version of Perl 5
you have available.

=head1 SEE ALSO

L<perl(1)|perl>,
L<PDL(3perl)|PDL>,
L<PDL::CCS(3perl)|PDL::CCS>,
L<PDL::SVDLIBC(3perl)|PDL::SVDLIBC>,
the SLEPc documentation at L<http://slepc.upv.es/documentation/current/docs/index.html>.

=cut



;



# Exit with OK status

1;

		   