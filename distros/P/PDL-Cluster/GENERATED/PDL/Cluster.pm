#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Cluster;

our @EXPORT_OK = qw(cmean cmedian calculate_weights clusterdistance distancematrix getclustercentroids getclustermean getclustermedian getclustermedoids kcluster kmedoids treecluster treeclusterd cuttree somcluster pca rowdistances clusterdistances clustersizes clusterelements clusterelementmask clusterdistancematrix clusterenc clusterdec clusteroffsets clusterdistancematrixenc clusterdistancesenc getclusterwsum attachtonearest attachtonearestd checkprototypes checkpartitions randomprototypes randompartition );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '1.54.004';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Cluster $VERSION;






#line 14 "Cluster.pd"


#---------------------------------------------------------------------------
# File: PDL::Cluster.pm
# Author: Bryan Jurish <moocow@cpan.org>
# Description: PDL wrappers for the C Clustering library.
#
# Copyright (c) 2005-2021 Bryan Jurish. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
#
#---------------------------------------------------------------------------
# Based on the C clustering library for cDNA microarray data,
# Copyright (C) 2002-2005 Michiel Jan Laurens de Hoon.
#
# The C clustering library was written at the Laboratory of DNA Information
# Analysis, Human Genome Center, Institute of Medical Science, University of
# Tokyo, 4-6-1 Shirokanedai, Minato-ku, Tokyo 108-8639, Japan.
# Contact: michiel.dehoon 'AT' riken.jp
#
# See the files "cluster.c" and "cluster.h" in the PDL::Cluster distribution
# for details.
#---------------------------------------------------------------------------

=pod

=head1 NAME

PDL::Cluster - PDL interface to the C Clustering Library

=head1 SYNOPSIS

 use PDL::Cluster;

 ##-----------------------------------------------------
 ## Data Format
 $d =   42;                     ##-- number of features
 $n = 1024;                     ##-- number of data elements

 $data = random($d,$n);         ##-- data matrix
 $elt  = $data->slice(",($i)"); ##-- element data vector
 $ftr  = $data->slice("($j),"); ##-- feature vector over all elements

 $wts  = ones($d)/$d;           ##-- feature weights
 $msk  = ones($d,$n);           ##-- missing-datum mask (1=ok)

 ##-----------------------------------------------------
 ## Library Utilties

 $mean = $ftr->cmean();
 $median = $ftr->cmedian();

 calculate_weights($data,$msk,$wts, $cutoff,$expnt,
                   $weights);

 ##-----------------------------------------------------
 ## Distance Functions

 clusterdistance($data,$msk,$wts, $n1,$n2,$idx1,$idx2,
                 $dist,
                 $distFlag, $methodFlag2);

 distancematrix($data,$msk,$wts, $distmat, $distFlag);

 ##-----------------------------------------------------
 ## Partitioning Algorithms

 getclustermean($data,$msk,$clusterids,
                $ctrdata, $ctrmask);

 getclustermedian($data,$msk,$clusterids,
                  $ctrdata, $ctrmask);

 getclustermedoid($distmat,$clusterids,$centroids,
                  $errorsums);

 kcluster($k, $data,$msk,$wts, $npass,
          $clusterids, $error, $nfound,
          $distFlag, $methodFlag);

 kmedoids($k, $distmat,$npass,
          $clusterids, $error, $nfound);

 ##-----------------------------------------------------
 ## Hierarchical Algorithms

 treecluster($data,$msk,$wts,
             $tree, $lnkdist,
             $distFlag, $methodFlag);

 treeclusterd($data,$msk,$wts, $distmat,
              $tree, $lnkdist,
              $distFlag, $methodFlag);

 cuttree($tree, $nclusters,
         $clusterids);

 ##-----------------------------------------------------
 ## Self-Organizing Maps

 somcluster($data,$msk,$wts, $nx,$ny,$tau,$niter,
            $clusterids,
            $distFlag);

 ##-----------------------------------------------------
 ## Principal Component Analysis

 pca($U, $S, $V);

 ##-----------------------------------------------------
 ## Extensions

 rowdistances($data,$msk,$wts, $rowids1,$rowids2, $distvec, $distFlag);
 clusterdistances($data,$msk,$wts, $rowids, $index2,
                  $dist,
                  $distFlag, $methodFlag);

 clustersizes($clusterids, $clustersizes);
 clusterelements($clustierids, $clustersizes, $eltids);
 clusterelementmask($clusterids, $eltmask);

 clusterdistancematrix($data,$msk,$wts,
                       $rowids, $clustersizes, $eltids,
                       $dist,
                       $distFlag, $methodFlag);

 clusterenc($clusterids, $clens,$cvals,$crowids, $k);
 clusterdec($clens,$cvals,$crowids, $clusterids, $k);
 clusteroffsets($clusterids, $coffsets,$cvals,$crowids, $k);
 clusterdistancematrixenc($data,$msk,$wts,
                          $clens1,$crowids1, $clens2,$crowids2,
                          $dist,
                          $distFlag, $methodFlag);

=cut
#line 161 "Cluster.pm"






=head1 FUNCTIONS

=cut




#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 cmean

=for sig

  Signature: (double a(n); double [o]b())

=for ref

Computes arithmetic mean of the vector $a().  See also PDL::Primitive::avg().

=for bad

cmean does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 196 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*cmean = \&PDL::cmean;
#line 203 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 cmedian

=for sig

  Signature: (double a(n); double [o]b())

=for ref

Computes median of the vector $a().  See also PDL::Primitive::median().

=for bad

cmedian does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 228 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*cmedian = \&PDL::cmedian;
#line 235 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 calculate_weights

=for sig

  Signature: (
   double    data(d,n);
   int       mask(d,n);
   double    weight(d);
   double    cutoff();
   double    exponent();
   double [o]oweights(d);
   ; char *distFlag;
)


This function calculates weights for the features using the weighting scheme
proposed by Michael Eisen:

 w[i] = 1.0 / sum_{j where dist(i,j)<cutoff} (1 - dist(i,j)/cutoff)^exponent

where the cutoff and the exponent are specified by the user.


=for bad

calculate_weights does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 273 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*calculate_weights = \&PDL::calculate_weights;
#line 280 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterdistance

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    n1();
   int    n2();
   int    index1(n1);
   int    index2(n2);
   double [o]dist();
   ; 
   char *distFlag;
   char *methodFlag;
   )


Computes distance between two clusters $index1() and $index2().
Each of the $index() vectors represents a single cluster whose values
are the row-indices in the $data() matrix of the elements assigned
to the respective cluster.  $n1() and $n2() are the number of elements
in $index1() and $index2(), respectively.  Each $index$i() must have
at least $n$i() elements allocated.

B<CAVEAT:> the $methodFlag argument is interpreted differently than
by the treecluster() method, namely:

=over 4

=item a

Distance between the arithmetic means of the two clusters,
as for treecluster() "f".

=item m

Distance between the medians of the two clusters,
as for treecluster() "c".

=item s

Minimum pairwise distance between members of the two clusters,
as for treecluster() "s".

=item x

Maximum pairwise distance between members of the two clusters
as for treecluster() "m".

=item v

Average of the pairwise distances between members of the two clusters,
as for treecluster() "a".

=back



=for bad

clusterdistance does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 355 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterdistance = \&PDL::clusterdistance;
#line 362 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 distancematrix

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   double [o]dists(n,n);
   ; char *distFlag;
)

=for ref

Compute triangular distance matrix over all data points.

=for bad

distancematrix does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 393 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*distancematrix = \&PDL::distancematrix;
#line 400 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 getclustercentroids

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   int    clusterids(n);
   double [o]cdata(d,k);
   int    [o]cmask(d,k);
   ; char *ctrMethodFlag;
)

=for ref

Find cluster centroids by arithmetic mean (C<ctrMethodFlag="a">) or median over each dimension (C<ctrMethodFlag="m">).

=for bad

getclustercentroids does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 432 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*getclustercentroids = \&PDL::getclustercentroids;
#line 439 "Cluster.pm"



#line 589 "Cluster.pd"


=pod

=head2 getclustermean

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   int    clusterids(n);
   double [o]cdata(d,k);
   int    [o]cmask(d,k);
   )

Really just a wrapper for getclustercentroids(...,"a").

=cut

sub getclustermean {
  my ($data,$mask,$cids,$cdata,$cmask) = @_;
  return getclustercentroids($dat,$mask,$cids,$cdata,$cmask,'a');
}
#line 468 "Cluster.pm"



#line 620 "Cluster.pd"


=pod

=head2 getclustermedian

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   int    clusterids(n);
   double [o]cdata(d,k);
   int    [o]cmask(d,k);
   )

Really just a wrapper for getclustercentroids(...,"m").

=cut

sub getclustermedian {
  my ($data,$mask,$cids,$cdata,$cmask) = @_;
  return getclustercentroids($dat,$mask,$cids,$cdata,$cmask,'m');
}
#line 497 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 getclustermedoids

=for sig

  Signature: (
   double distance(n,n);
   int    clusterids(n);
   int    [o]centroids(k);
   double [o]errors(k);
   )

The getclustermedoid routine calculates the cluster centroids, given to which
cluster each element belongs. The centroid is defined as the element with the
smallest sum of distances to the other elements.


=for bad

getclustermedoids does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 528 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*getclustermedoids = \&PDL::getclustermedoids;
#line 535 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 kcluster

=for sig

  Signature: (
   int    nclusters();
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    npass();
   int    [o]clusterids(n);
   double [o]error();
   int    [o]nfound();
   ; 
   char *distFlag;
   char *ctrMethodFlag;
   )

K-Means clustering algorithm. The "ctrMethodFlag" determines how
clusters centroids are to be computed; see getclustercentroids() for details.

Because the C library code reads from the C<clusterids> if and only if
C<npass> is 0, before writing to it, it would be inconvenient to
set it to C<[io]>. However for efficiency reasons, as of 2.096, PDL
will not convert it (force a read-back on the conversion) for you
if you pass in the wrongly-typed data. This means that you should
be careful to pass in C<long> data of the right size if you set C<npass>
to 0.

See also: kmedoids().


=for bad

kcluster does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 582 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*kcluster = \&PDL::kcluster;
#line 589 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 kmedoids

=for sig

  Signature: (
   int    nclusters();
   double distance(n,n);
   int    npass();
   int    [o]clusterids(n);
   double [o]error();
   int    [o]nfound();
   )

K-Medoids clustering algorithm (uses distance matrix).

See also: kcluster().


=for bad

kmedoids does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 622 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*kmedoids = \&PDL::kmedoids;
#line 629 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 treecluster

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    [o]tree(2,n);
   double [o]lnkdist(n);
   ; 
   char *distFlag;
   char *methodFlag;
   )


Hierachical agglomerative clustering.

$tree(2,n) represents the clustering solution.
Each row in the matrix describes one linking event,
with the two columns containing the name of the nodes that were joined.
The original genes are numbered 0..(n-1), nodes are numbered
-1..-(n-1).
$tree(2,n) thus actually uses only (2,n-1) cells.

$lnkdist(n) represents the distance between the two subnodes that were joined.
As for $tree(), $lnkdist() uses only (n-1) cells.


=for bad

treecluster does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 673 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*treecluster = \&PDL::treecluster;
#line 680 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 treeclusterd

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   double distances(n,n);
   int    [o]tree(2,n);
   double [o]lnkdist(n);
   ; 
   char *distFlag;
   char *methodFlag;
   )


Hierachical agglomerative clustering using given distance matrix.

See distancematrix() and treecluster(), above.


=for bad

treeclusterd does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 717 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*treeclusterd = \&PDL::treeclusterd;
#line 724 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 cuttree

=for sig

  Signature: (
   int    tree(2,n);
   int    nclusters();
   int [o]clusterids(n);
   )


Cluster selection for hierarchical clustering trees.


=for bad

cuttree does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 753 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*cuttree = \&PDL::cuttree;
#line 760 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 somcluster

=for sig

  Signature: (
   double  data(d,n);
   int     mask(d,n);
   double  weight(d);
   int     nxnodes();
   int     nynodes();
   double  inittau();
   int     niter();
   int     [o]clusterids(2,n);
   ; char *distFlag;
)

=for ref

Self-Organizing Map clustering, does not return centroid data.

=for bad

somcluster does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 795 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*somcluster = \&PDL::somcluster;
#line 802 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 pca

=for sig

  Signature: (
   double  [o]U(d,n);
   double  [o]S(d);
   double  [o]V(d,d);
   )


Principal Component Analysis (SVD), operates in-place on $U() and requires ($SIZE(n) E<gt>= $SIZE(d)).


=for bad

pca does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 831 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*pca = \&PDL::pca;
#line 838 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 rowdistances

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    rowids1(ncmps);
   int    rowids2(ncmps);
   double [o]dist(ncmps);
   ; char *distFlag;
)


Computes pairwise distances between rows of $data().
$rowids1() contains the row-indices of the left (first) comparison operand,
and $rowids2() the row-indices of the right (second) comparison operand.  Since each
of these are assumed to be indices into the first dimension $data(), it should be the case that:

 0 <= $rowids1(i),rowids2(i) < $SIZE(n)    for 0 <= i < $SIZE(ncmps)

See also clusterdistance(), clusterdistances(), clusterdistancematrixenc(), distancematrix().


=for bad

rowdistances does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 878 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*rowdistances = \&PDL::rowdistances;
#line 885 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterdistances

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    rowids(nr);
   int    index2(n2);
   double [o]dist(nr);
   ; 
   char *distFlag;
   char *methodFlag;
   )


Computes pairwise distance(s) from each of $rowids() as a singleton cluster
with the cluster represented by $index2(), which should be an index
vector as for clusterdistance().  See also clusterdistancematrixenc().


=for bad

clusterdistances does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 922 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterdistances = \&PDL::clusterdistances;
#line 929 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clustersizes

=for sig

  Signature: (int clusterids(n); int [o]clustersizes(k))


Computes the size (number of elements) of each cluster in $clusterids().
Useful for allocating less than maximmal space for $clusterelements().


=for bad

The output piddle should never be marked BAD.

=cut
#line 953 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clustersizes = \&PDL::clustersizes;
#line 960 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterelements

=for sig

  Signature: (int clusterids(n); int [o]clustersizes(k); int [o]eltids(mcsize,k))


Converts the vector $clusterids() to a matrix $eltids() of element (row) indices
indexed by cluster-id.  $mcsize() is the maximum number of elements per cluster,
at most $n.  The output PDLs $clustersizes() and $eltids() can be passed to
clusterdistancematrix().


=for bad

clusterelements does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 988 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterelements = \&PDL::clusterelements;
#line 995 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterelementmask

=for sig

  Signature: (int clusterids(n); byte [o]eltmask(k,n))


Get boolean membership mask $eltmask() based on cluster assignment in $clusterids().
No value in $clusterids() may be greater than or equal to $k.
On completion, $eltmask(k,n) is a true value iff $clusterids(n)=$k.


=for bad

clusterelementmask does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1022 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterelementmask = \&PDL::clusterelementmask;
#line 1029 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterdistancematrix

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    rowids(nr);
   int    clustersizes(k);
   int    eltids(mcsize,k);
   double [o]dist(k,nr);
   ; 
   char *distFlag;
   char *methodFlag;
   )


B<DEPRECATED> in favor of clusterdistancematrixenc().
In the future, this method is expected to become a wrapper for clusterdistancematrixenc().

Computes distance between each row index in $rowids()
considered as a singleton cluster
and each of the $k clusters whose elements are given by a single row of $eltids().
$clustersizes() and $eltids() are as output by the clusterelements() method.

See also clusterdistance(), clusterdistances(), clustersizes(), clusterelements(), clusterdistancematrixenc().


=for bad

clusterdistancematrix does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1073 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterdistancematrix = \&PDL::clusterdistancematrix;
#line 1080 "Cluster.pm"



#line 1196 "Cluster.pd"


=pod

=head2 clusterenc

=for sig

  Signature: (
   int    clusterids(n);
   int [o]clusterlens(k1);
   int [o]clustervals(k1);
   int [o]clusterrows(n);
   ;
   int k1;
   )

Encodes datum-to-cluster vector $clusterids() for efficiently mapping
clusters-to-data.  Returned PDL $clusterlens() holds the lengths of each
cluster containing at least one element.  $clustervals() holds the IDs
of such clusters as they appear as values in $clusterids().  $clusterrows()
is such that:

 all( rld($clusterlens, $clustervals) == $clusterids )

... if all available cluster-ids are in use.

If specified, $k1 is a perl scalar
holding the number of clusters (maximum cluster index + 1); an
appropriate value will guessed from $clusterids() otherwise.

Really just a wrapper for some lower-level PDL and PDL::Cluster calls.

=cut

sub clusterenc {
  my ($cids, $clens,$cvals,$crows, $kmax) = @_;
  $kmax  = $cids->max+1 if (!defined($kmax));

  ##-- cluster sizes
  $clens = zeroes(long, $kmax) if (!defined($clens));
  clustersizes($cids,$clens);

  ##-- cluster-id values
  if (!defined($cvals)) { $cvals  = PDL->sequence(long,$kmax); }
  else                  { $cvals .= PDL->sequence(long,$kmax); }

  ##-- cluster-row values: handle BAD and negative values
  #if (!defined($crows)) { $crows  = $cids->qsorti->where($cids->isgood & $cids>=0); }
  #else                  { $crows .= $cids->qsorti->where($cids->isgood & $cids>=0); }

  ##-- cluster-row values: treat BAD and negative values like anything else
  if (!defined($crows)) { $crows  = $cids->qsorti; }
  else                  { $crows .= $cids->qsorti; }

  return ($clens,$cvals,$crows);
}
#line 1142 "Cluster.pm"



#line 1262 "Cluster.pd"


=pod

=head2 clusterdec

=for sig

  Signature: (
   int    clusterlens(k1);
   int    clustervals(k1);
   int    clusterrows(n);
   int [o]clusterids(n);
   )

Decodes cluster-to-datum vectors ($clusterlens,$clustervals,$clusterrows)
into a single datum-to-cluster vector $clusterids().
$(clusterlens,$clustervals,$clusterrows) are as returned by the clusterenc() method.

Un-addressed row-index values in $clusterrows() will be assigned the pseudo-cluster (-1)
in $clusterids().

Really just a wrapper for some lower-level PDL calls.

=cut

sub clusterdec {
  my ($clens,$cvals,$crows, $cids2) = @_;

  ##-- get $cids
  $cids2  = zeroes($cvals->type, $crows->dims) if (!defined($cids2));
  $cids2 .= -1;

  ##-- trim $crows
  #my $crows_good = $crows->slice("0:".($clens->sum-1)); ##-- assume bad indices are at END       of $crows (BAD,inf,...)
  my $crows_good  = $crows->slice(-$clens->sum.":-1"); ##-- assume bad indices are at BEGINNING of $crows (-1, ...)

  ##-- decode
  $clens->rld($cvals, $cids2->index($crows_good));

  return $cids2;
}
#line 1189 "Cluster.pm"



#line 1312 "Cluster.pd"


=pod

=head2 clusteroffsets

=for sig

  Signature: (
   int    clusterids(n);
   int [o]clusteroffsets(k1+1);
   int [o]clustervals(k1);
   int [o]clusterrows(n);
   ;
   int k1;
   )

Encodes datum-to-cluster vector $clusterids() for efficiently mapping
clusters-to-data. Like clusterenc(), but returns cumulative offsets
instead of lengths.

Really just a wrapper for clusterenc(), cumusumover(), and append().

=cut

sub clusteroffsets {
  my ($cids, $coffsets,$cvals,$crows, $kmax) = @_;
  my ($clens);
  ($clens,$cvals,$crows) = clusterenc($cids,undef,$cvals,$crows,$kmax);
  $coffsets = $clens->append(0)->rotate(1)->cumusumover;

  return ($coffsets,$cvals,$crows);
}
#line 1227 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterdistancematrixenc

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    clens1(k1);
   int    crowids1(nc1);
   int    clens2(k2);
   int    crowids2(nc2);
   double [o]dist(k1,k2);
   ; 
   char *distFlag;
   char *methodFlag;
   )


Computes cluster-distance between each pair of clusters in (sequence($k1) x sequence($k2)), where 'x'
is the Cartesian product.  Cluster contents are passed as pairs ($clens(),$crowids()) as returned
by the clusterenc() function (assuming that the $cvals() vector returned by clusterenc() is a flat sequence).

The deprecated method clusterdistancematrix() can be simulated by this function in the following
manner: if a clusterdistancematrix() call was:

 clustersizes   ($cids, $csizes=zeroes(long,$k));
 clusterelements($cids, $celts =zeroes(long,$csizes->max)-1);
 clusterdistancematrix($data,$msk,$wt, $rowids, $csizes,$celts,
                       $cdmat=zeroes(double,$k,$rowids->dim(0)),
                       $distFlag, $methodFlag
                      );

Then the corresponding use of clusterdistancematrixenc() would be:

 ($clens,$cvals,$crows) = clusterenc($cids);
 clusterdistancematrixenc($data,$msk,$wt,
                          $clens,        $crows,   ##-- "real" clusters in output dim 0
                          $rowids->ones, $rowids,  ##-- $rowids as singleton clusters in output dim 1
                          $cdmat=zeroes(double,$clens->dim(0),$rowids->dim(0)),
                          $distFlag, $methodFlag);

If your $cvals() are not a flat sequence, you will probably need to do some index-twiddling
to get things into the proper shape:

 if ( !all($cvals==$cvals->sequence) || $cvals->dim(0) != $k )
 {
   my $cdmat0 = $cdmat;
   my $nr     = $rowids->dim(0);
   $cdmat     = pdl(double,"inf")->slice("*$k,*$nr")->make_physical(); ##-- "missing" distances are infinite
   $cdmat->dice_axis(0,$cvals) .= $cdmat0;
 }

$distFlag and $methodFlag are interpreted as for clusterdistance().

See also clusterenc(), clusterdistancematrix().


=for bad

clusterdistancematrixenc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1300 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterdistancematrixenc = \&PDL::clusterdistancematrixenc;
#line 1307 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 clusterdistancesenc

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    coffsets1(k1);
   int    crowids1(nc1);
   int    cwhich1(ncmps);
   int    coffsets2(k2);
   int    crowids2(nc2);
   int    cwhich2(ncmps);
   double [o]dists(ncmps);
   ; 
   char *distFlag;
   char *methodFlag;
   )


Computes cluster-distance between selected pairs of co-indexed clusters in ($cwhich1,$cwhich2).
Cluster contents are passed as pairs ($coffsetsX(),$crowidsX()) as returned
by the clusteroffsets() function.

$distFlag and $methodFlag are interpreted as for clusterdistance().

See also clusterenc(), clusterdistancematrixenc().


=for bad

clusterdistancesenc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1352 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*clusterdistancesenc = \&PDL::clusterdistancesenc;
#line 1359 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 getclusterwsum

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double clusterwts(k,n);
   double [o]cdata(d,k);
   int    [o]cmask(d,k);
   )


Find cluster centroids by weighted sum.  This can be considered an
expensive generalization of the getclustermean() and getclustermedian()
functions.  Here, the input PDLs $data() and $mask(), as well as the
output PDL $cdata() are as for getclustermean().  The matrix $clusterwts()
determines the relative weight of each data row in determining the
centroid of each cluster, potentially useful for "fuzzy" clustering.
The equation used to compute cluster means is:

 $cdata(d,k) = sum_{n} $clusterwts(k,n) * $data(d,n) * $mask(d,n)

For centroids in the same range as data elements, $clusterwts()
should sum to 1 over each column (k):

 all($clusterwts->xchg(0,1)->sumover == 1)

getclustermean() can be simulated by instantiating $clusterwts() with
a uniform distribution over cluster elements:

 $clusterwts = zeroes($k,$n);
 $clusterwts->indexND(cat($clusterids, xvals($clusterids))->xchg(0,1)) .= 1;
 $clusterwts /= $clusterwts->xchg(0,1)->sumover;
 getclusterwsum($data,$mask, $clusterwts, $cdata=zeroes($d,$k));

Similarly, getclustermedian() can be simulated by setting $clusterwts() to
1 for cluster medians and otherwise to 0.  More sophisticated centroid
discovery methods can be computed by this function by setting
$clusterwts(k,n) to some estimate of the conditional probability
of the datum at row $n given the cluster with index $k:
p(Elt==n|Cluster==k).  One
way to achieve such an estimate is to use (normalized inverses of) the
singleton-row-to-cluster distances as output by clusterdistancematrix().



=for bad

getclusterwsum does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1421 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*getclusterwsum = \&PDL::getclusterwsum;
#line 1428 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 attachtonearest

=for sig

  Signature: (
   double data(d,n);
   int    mask(d,n);
   double weight(d);
   int    rowids(nr);
   double cdata(d,k);
   int    cmask(d,k);
   int    [o]clusterids(nr);
   double [o]cdist(nr);
   ; 
   char *distFlag;
   char *methodFlag;
   )


Assigns each specified data row to the nearest cluster centroid.
Data elements are given by $data() and $mask(), feature weights are
given by $weight(), as usual.  Cluster centroids are defined by
by $cdata() and $cmask(), and the indices of rows to be attached
are given in the vector $rowids().  The output vector $clusterids()
contains for each specified row index the identifier of the nearest
cluster centroid.  The vector $cdist() contains the distance to
the best clusters.

See also: clusterdistancematrix(), attachtonearestd().


=for bad

attachtonearest does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1474 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*attachtonearest = \&PDL::attachtonearest;
#line 1481 "Cluster.pm"



#line 1659 "Cluster.pd"


=pod

=head2 attachtonearestd

=for sig

  Signature: (
   double cdistmat(k,n);
   int rowids(nr);
   int [o]clusterids(nr);
   double [o]dists(nr);
   )

Assigns each specified data row to the nearest cluster centroid,
as for attachtonearest(), given the datum-to-cluster distance
matrix $cdistmat().  Currently just a wrapper for a few PDL calls.
In scalar context returns $clusterids(), in list context returns
the list ($clusterids(),$dists()).

=cut

sub attachtonearestd {
  my ($cdm,$rowids,$cids,$dists)=@_;
  $cids = zeroes(long, $rowids->dim(0))    if (!defined($cids));
  $dists = zeroes(double, $rowids->dim(0)) if (!defined($dists));

  ##-- dice matrix
  my $cdmr   = $cdm->dice_axis(1,$rowids);

  ##-- get best
  $cdmr->minimum_ind($cids);
  $dists .= $cdmr->index($cids);

  return wantarray ? ($cids,$dists) : $cids;
}
#line 1523 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 checkprototypes

=for sig

  Signature: (
   protos(k);
   [o]cprotos(k);
   byte [t]otmp(n);
   ; int nsize => n)

(Deterministic)

Ensure that the assignment $protos() from $k objects to
integer "prototype" indices in the range [0,$n( contains no repetitions of any
of the $n possible prototype values.  One use for this function is
the restriction of (randomly generated) potential clustering solutions
for $k clusters in which each cluster is represented by a
"prototypical" element from a data sample of size $n.

Requires: $n >= $k.


=for bad

checkprototypes does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1560 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*checkprototypes = \&PDL::checkprototypes;
#line 1567 "Cluster.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 checkpartitions

=for sig

  Signature: (
   part(n);
   [o]cpart(n);
   [t]ptmp(k);
   ; int ksize => k)

(Deterministic)

Ensure that the partitioning $part() of $n objects into $k bins
(identified by integer values in the range [0,$k-1])
contains at least one instance of each of the
$k possible values.  One use for this function is
the restriction of (randomly generated) potential clustering solutions
for $n elements into $k clusters to those which assign at least one
element to each cluster.

Requires: $n >= $k.


=for bad

checkpartitions does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1605 "Cluster.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*checkpartitions = \&PDL::checkpartitions;
#line 1612 "Cluster.pm"



#line 1813 "Cluster.pd"


=pod

=head2 randomprototypes

=for sig

  Signature: (int k; int n; [o]prototypes(k))

Generate a random set of $k prototype indices drawn from $n objects,
ensuring that no object is used more than once.  Calls checkprototypes().

See also: checkprototypes(), randomassign(), checkpartitions(), randompartition().

=cut

sub randomprototypes {
  my ($k,$n,$protos) = @_;
  $protos  = zeroes(long, $k) if (!defined($protos));
  $protos .= PDL->random($k)*$n;
  checkprototypes($protos->inplace, $n);
  return $protos;
}
#line 1641 "Cluster.pm"



#line 1845 "Cluster.pd"


=pod

=head2 randompartition

=for sig

  Signature: (int k; int n; [o]partition(n))

Generate a partitioning of $n objects into $k clusters,
ensuring that every cluster contains at least one object.
Calls checkpartitions().
This method is identical in functionality to randomassign(),
but may be faster if $k is significantly smaller than $n.

See also: randomassign(), checkpartitions(), checkprototypes(), randomprototypes().

=cut

sub randompartition {
  my ($k,$n,$part) = @_;
  $part  = zeroes(long, $n) if (!defined($part));
  $part .= PDL->random($n)*$k;
  checkpartitions($part->inplace, $k);
  return $part;
}
#line 1673 "Cluster.pm"



#line 1884 "Cluster.pd"



##---------------------------------------------------------------------
=pod

=head1 COMMON ARGUMENTS

Many of the functions described above require one or
more of the following parameters:

=over 4

=item d

The number of features defined for each data element.

=item n

The number of data elements to be clustered.

=item k

=item nclusters

The number of desired clusters.

=item data(d,n)

A matrix representing the data to be clustered, double-valued.

=item mask(d,n)

A matrix indicating which data values are missing. If
mask(i,j) == 0, then data(i,j) is treated as missing.

=item weights(d)

The (feature-) weights that are used to calculate the distance.

B<Warning:> Not all distance metrics make use of weights;
you must provide some nonetheless.

=item clusterids(n)

A clustering solution. $clusterids() maps data elements
(row indices in $data()) to values in the range [0,$k-1].

=back

=cut

##---------------------------------------------------------------------
=pod

=head2 Distance Metrics

Distances between data elements (and cluster centroids, where applicable)
are computed using one of a number of built-in metrics.  Which metric
is to be used for a given computation is indicated by a character
flag denoted above with $distFlag().  In the following, w[i] represents
a weighting factor in the $weights() matrix, and $W represents the total
of all weights.

Currently implemented distance
metrics and the corresponding flags are:

=over 4

=item e

Pseudo-Euclidean distance:

 dist_e(x,y) = 1/W * sum_{i=1..d} w[i] * (x[i] - y[i])^2

Note that this is not the "true" Euclidean distance, which is defined as:

 dist_E(x,y) = sqrt( sum_{i=1..d} (x[i] - y[i])^2 )


=item b

City-block ("Manhattan") distance:

 dist_b(x,y) = 1/W * sum_{i=1..d} w[i] * |x[i] - y[i]|



=item c

Pearson correlation distance:

 dist_c(x,y) = 1-r(x,y)

where r is the Pearson correlation coefficient:

 r(x,y) = 1/d * sum_{i=1..d} (x[i]-mean(x))/stddev(x) * (y[i]-mean(y))/stddev(y)

=item a

Absolute value of the correlation,

 dist_a(x,y) = 1-|r(x,y)|

where r(x,y) is the Pearson correlation coefficient.

=item u

Uncentered correlation (cosine of the angle):

 dist_u(x,y) = 1-r_u(x,y)

where:

 r_u(x,y) = 1/d * sum_{i=1..d} (x[i]/sigma0(x)) * (y[i]/sigma0(y))

and:

 sigma0(w) = sqrt( 1/d * sum_{i=1..d} w[i]^2 )

=item x

Absolute uncentered correlation,

 dist_x(x,y) = 1-|r_u(x,y)|

=item s

Spearman's rank correlation.

 dist_s(x,y) = 1-r_s(x,y) ~= dist_c(ranks(x),ranks(y))

where r_s(x,y) is the Spearman rank correlation.  Weights are ignored.

=item k

Kendall's tau (does not use weights).

 dist_k(x,y) = 1 - tau(x,y)

=item (other values)

For other values of dist, the default (Euclidean distance) is used.

=back

=cut


##---------------------------------------------------------------------
=pod

=head2 Link Methods

For hierarchical clustering, the 'link method' must be specified
by a character flag, denoted above as $methodFlag.
Known link methods are:

=over 4

=item s

Pairwise minimum-linkage ("single") clustering.

Defines the distance between two clusters as the
least distance between any two of their respective elements.

=item m

Pairwise maximum-linkage ("complete") clustering.

Defines the distance between two clusters as the
greatest distance between any two of their respective elements.

=item a

Pairwise average-linkage clustering (centroid distance using arithmetic mean).

Defines the distance between two clusters as the
distance between their respective centroids, where each
cluster centroid is defined as the arithmetic mean of
that cluster's elements.

=item c

Pairwise centroid-linkage clustering (centroid distance using median).

Identifies the distance between two clusters as the
distance between their respective centroids, where each
cluster centroid is computed as the median of
that cluster's elements.

=item (other values)

Behavior for other values is currently undefined.

=back

For the first three, either the distance matrix or the gene expression data is
sufficient to perform the clustering algorithm. For pairwise centroid-linkage
clustering, however, the gene expression data are always needed, even if the
distance matrix itself is available.

=cut

##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

C Clustering Library by
Michiel de Hoon,
Seiya Imoto,
and Satoru Miyano.

Orignal Algorithm::Cluster module by John Nolan and Michiel de Hoon.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Dimensional requirements are sometimes too strict.

Passing weights to Spearman and Kendall link methods wastes space.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt> wrote and maintains the PDL::Cluster distribution.

Michiel de Hoon wrote the underlying C clustering library for cDNA microarray data.

=head1 COPYRIGHT

PDL::Cluster is a set of wrappers around the C Clustering library for cDNA microarray data.

=over 4

=item *

The C clustering library for cDNA microarray data.
Copyright (C) 2002-2005 Michiel Jan Laurens de Hoon.

This library was written at the Laboratory of DNA Information Analysis,
Human Genome Center, Institute of Medical Science, University of Tokyo,
4-6-1 Shirokanedai, Minato-ku, Tokyo 108-8639, Japan.
Contact: michiel.dehoon 'AT' riken.jp

See the files F<REAMDE.cluster>, F<cluster.c> and F<cluster.h> in the PDL::Cluster distribution
for details.

=item *

PDL::Cluster wrappers copyright (C) Bryan Jurish 2005-2018. All rights reserved.
This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=back

=head1 SEE ALSO

perl(1), PDL(3perl), Algorithm::Cluster(3perl), cluster(1),
L<http://bonsai.hgc.jp/~mdehoon/software/cluster/software.htm|http://bonsai.hgc.jp/~mdehoon/software/cluster/software.htm>

=cut
#line 1956 "Cluster.pm"






# Exit with OK status

1;
