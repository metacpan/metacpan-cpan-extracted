#
# GENERATED WITH PDL::PP from lib/PDL/Stats/Kmeans.pd! Don't modify!
#
package PDL::Stats::Kmeans;

our @EXPORT_OK = qw(random_cluster iv_cluster _random_cluster which_cluster assign centroid _d_p2l );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Stats::Kmeans ;








#line 8 "lib/PDL/Stats/Kmeans.pd"

use strict;
use warnings;
use Carp;
use PDL::LiteF;
use PDL::Stats::Basic;

=head1 NAME

PDL::Stats::Kmeans -- classic k-means cluster analysis

=head1 DESCRIPTION

Assumes that we have data pdl dim [observation, variable] and the goal is to put observations into clusters based on their values on the variables. The terms "observation" and "variable" are quite arbitrary but serve as a reminder for "that which is being clustered" and "that which is used to cluster".

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are broadcastable and methods that are non-broadcastable, respectively.

=head1 SYNOPSIS

Implement a basic k-means procedure,

    use PDL::LiteF;
    use PDL::Stats;

    my ($data, $idv, $ido) = rtable( $file );
    # or generate random data:
    $data = grandom(200, 2); # two vars as below

    my ($cluster, $centroid, $ss_centroid, $cluster_last);

      # start out with 8 random clusters
    $cluster = random_cluster( $data->dim(0), 8 );
      # iterate to minimize total ss
      # stop when no more changes in cluster membership
    do {
      $cluster_last = $cluster;
      ($centroid, $ss_centroid) = $data->centroid( $cluster );
      $cluster = $data->assign( $centroid );
    } while sum(abs($cluster - $cluster_last)) > 0;

or, use the B<kmeans> function provided here,

    my %k = $data->kmeans( \%opt );
    print "$_\t$k{$_}\n" for sort keys %k;

plot the clusters if there are only 2 vars in $data,

    use PDL::Graphics::Simple;

    my ($win, $c);
    $win = pgswin();
    $win->plot(map +(with=>'points', $data->dice_axis(0,which($k{cluster}->(,$_)))->dog), 0 .. $k{cluster}->dim(1)-1);

=cut
#line 82 "lib/PDL/Stats/Kmeans.pm"


=head1 FUNCTIONS

=cut





#line 75 "lib/PDL/Stats/Kmeans.pd"

#line 76 "lib/PDL/Stats/Kmeans.pd"

=head2 random_cluster

=for ref

Creates masks for random mutually exclusive clusters. Accepts two
parameters, num_obs and num_cluster. Extra parameter turns into extra
dim in mask. May loop a long time if num_cluster approaches num_obs
because empty cluster is not allowed.

=for usage

    my $cluster = random_cluster( $num_obs, $num_cluster );

=cut

  # can't be called on pdl
sub random_cluster {
  my ($obs, $clu, @extra) = @_;
    # extra param in @_ made into extra dim
  my $cluster = zeroes short(), @_;
  do {
    (random($obs, @extra) * $obs)->_random_cluster($cluster);
  } while (PDL::any $cluster->sumover == 0 );
  $cluster;
}
#line 122 "lib/PDL/Stats/Kmeans.pm"

*_random_cluster = \&PDL::_random_cluster;






=head2 which_cluster

=for sig

 Signature: (short a(o,c); indx [o]b(o))
 Types: (ushort long)

=for usage

 $b = which_cluster($a);
 which_cluster($a, $b);  # all arguments given
 $b = $a->which_cluster; # method call
 $a->which_cluster($b);

Given cluster mask dim [obs x clu], returns the cluster index to which an obs belong.

Does not support overlapping clusters. If an obs has TRUE value for multiple clusters, the returned index is the first cluster the obs belongs to. If an obs has no TRUE value for any cluster, the return val is set to -1 or BAD if the input mask has badflag set.

Usage:

      # create a cluster mask dim [obs x clu]
    pdl> p $c_mask = iv_cluster [qw(a a b b c c)]
    [
     [1 1 0 0 0 0]
     [0 0 1 1 0 0]
     [0 0 0 0 1 1]
    ]
      # get cluster membership list dim [obs]
    pdl> p $ic = $c_mask->which_cluster
    [0 0 1 1 2 2]

=pod

Broadcasts over its inputs.

=for bad

C<which_cluster> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*which_cluster = \&PDL::which_cluster;






=head2 assign

=for sig

 Signature: (data(o,v); centroid(c,v); short [o]cluster(o,c))
 Types: (float double)

=for ref

Takes data pdl dim [obs x var] and centroid pdl dim [cluster x var] and returns mask dim [obs x cluster] to cluster membership. An obs is assigned to the first cluster with the smallest distance (ie sum squared error) to cluster centroid. With bad value, obs is assigned by smallest mean squared error across variables.

=for usage

    pdl> p $centroid = xvals 2, 3
    [
     [0 1]
     [0 1]
     [0 1]
    ]

    pdl> p $b = qsort( random 4, 3 )
    [
     [0.022774068 0.032513883  0.13890034  0.30942479]
     [ 0.16943853  0.50262636  0.56251531   0.7152271]
     [ 0.23964483  0.59932745  0.60967495  0.78452117]
    ]
      # notice that 1st 3 obs in $b are on average closer to 0
      # and last obs closer to 1
    pdl> p $b->assign( $centroid )
    [
     [1 1 1 0]    # cluster 0 membership
     [0 0 0 1]    # cluster 1 membership
    ]

=pod

Broadcasts over its inputs.

=for bad

C<assign> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*assign = \&PDL::assign;






=head2 centroid

=for sig

 Signature: (data(o,v); cluster(o,c); [o]m(c,v); [o]ss(c,v))
 Types: (float double)

=for ref

Takes data dim [obs x var] and mask dim [obs x cluster], returns mean and ss (ms when data contains bad values) dim [cluster x var], using data where mask == 1. Multiple cluster membership for an obs is okay. If a cluster is empty all means and ss are set to zero for that cluster.

=for usage

      # data is 10 obs x 3 var
    pdl> p $d = sequence 10, 3
    [
     [ 0  1  2  3  4  5  6  7  8  9]
     [10 11 12 13 14 15 16 17 18 19]
     [20 21 22 23 24 25 26 27 28 29]
    ]
      # create two clusters by value on 1st var
    pdl> p $a = $d( ,(0)) <= 5
    [1 1 1 1 1 1 0 0 0 0]

    pdl> p $b = $d( ,(0)) > 5
    [0 0 0 0 0 0 1 1 1 1]

    pdl> p $c = cat $a, $b
    [
     [1 1 1 1 1 1 0 0 0 0]
     [0 0 0 0 0 0 1 1 1 1]
    ]

    pdl> p $d->centroid($c)
      # mean for 2 cluster x 3 var
    [
     [ 2.5  7.5]
     [12.5 17.5]
     [22.5 27.5]
    ]
      # ss for 2 cluster x 3 var
    [
     [17.5    5]
     [17.5    5]
     [17.5    5]
    ]
  

=pod

Broadcasts over its inputs.

=for bad

C<centroid> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*centroid = \&PDL::centroid;





#line 307 "lib/PDL/Stats/Kmeans.pd"

#line 308 "lib/PDL/Stats/Kmeans.pd"

sub _scree_ind {
  # use as scree cutoff the point with max distance to the line formed
  # by the 1st and last points in $self
  # it's a heuristic--whether we can get "good" results depends on
  # the number of components in $self.

  my ($self) = @_;

  $self = $self->squeeze;
  $self->ndims > 1 and
    croak "1D pdl only please";

  my $a = zeroes 2, $self->nelem;
  $a->slice('(0)') .= sequence $self->nelem;
  $a->slice('(1)') .= $self;

  my $d = _d_point2line( $a, $a->slice(':,(0)'), $a->slice(':,(-1)') );

  return $d->maximum_ind;
}

sub _d_point2line {
  my ($self, $p1, $p2) = @_;

  for ($self, $p1, $p2) {
    $_->dim(0) != 2 and
      carp "point pdl dim(0) != 2";
  }

  return _d_p2l( $self->mv(0,-1)->dog, $p1->mv(0,-1)->dog, $p2->mv(0,-1)->dog );
}
#line 341 "lib/PDL/Stats/Kmeans.pm"

*_d_p2l = \&PDL::_d_p2l;





#line 358 "lib/PDL/Stats/Kmeans.pd"

#line 359 "lib/PDL/Stats/Kmeans.pd"
=head2 kmeans

=for ref

Implements classic k-means cluster analysis.

=for example

  $data = grandom(200, 2); # two rows = two dimensions
  %k = $data->kmeans; # use default of 3 clusters
  print "$_\t$k{$_}\n" for sort keys %k;
  $w->plot(
    (map +(with=>'points', style=>$_+1, ke=>"Cluster ".($_+1),
      $data->dice_axis(0,which($k{cluster}->slice(",$_")))->dog),
      0 .. $k{cluster}->dim(1)-1),
    (map +(with=>'circles', style=>$_+1, ke=>"Centroid ".($_+1), $k{centroid}->slice($_)->dog, 0.1),
      0 .. $k{centroid}->dim(0)-1),
    {le=>'tr'},
  );

Given a number of observations with values on a set of variables,
kmeans puts the observations into clusters that maximizes within-cluster
similarity with respect to the variables. Tries several different random
seeding and clustering in parallel. Stops when cluster assignment of the
observations no longer changes. Returns the best result in terms of R2
from the random-seeding trials.

Instead of random seeding, kmeans also accepts manual seeding. This is
done by providing a centroid to the function, in which case clustering
will proceed from the centroid and there is no multiple tries.

There are two distinct advantages from seeding with a centroid compared to
seeding with predefined cluster membership of a subset of the observations
ie "seeds":

=over

=item *

a centroid could come from a previous study with a different set of observations;

=item *

a centroid could even be "fictional", or in more proper parlance,
an idealized prototype with respect to the actual data. For example,
if there are 10 person's ratings of 1 to 5 on 4 movies, ie a ratings
pdl of dim [10 obs x 4 var], providing a centroid like

  [
   [5 0 0 0]
   [0 5 0 0]
   [0 0 5 0]
   [0 0 0 5]
  ]

will produce 4 clusters of people with each cluster favoring a different
one of the 4 movies. Clusters from an idealized centroid may not give the
best result in terms of R2, but they sure are a lot more interpretable.

=back

If clustering has to be done from predefined clusters of seeds, simply
calculate the centroid using the B<centroid> function and feed it
to kmeans,

  my ($centroid, $ss) = $rating($iseeds, )->centroid( $seeds_cluster );
  my %k = $rating->kmeans( { CNTRD=>$centroid } );

kmeans supports bad value*.

=for options

Default options (case insensitive):

  V     => 1,         # prints simple status
  FULL  => 0,         # returns results for all seeding trials

  CNTRD => PDL->null, # optional. pdl [clu x var]. disables next 3 opts

  NTRY  => 5,         # num of random seeding trials
  NSEED => 1000,      # num of initial seeds, use NSEED up to max obs
  NCLUS => 3,         # num of clusters

=for usage

Usage:

  # suppose we have 4 person's ratings on 5 movies

  pdl> p $rating = ceil( random(4, 5) * 5 )
  [
   [3 2 2 3]
   [2 4 5 4]
   [5 3 2 3]
   [3 3 1 5]
   [4 3 3 2]
  ]

  # we want to put the 4 persons into 2 groups

  pdl> %k = $rating->kmeans( {NCLUS=>2} )

  # by default prints back options used
  # as well as info for all tries and iterations

  CNTRD	=> Null
  FULL	=> 0
  NCLUS	=> 3
  NSEED	=> 4
  NTRY	=> 5
  V     => 1
  ss total:	20.5
  iter 0 R2 [0.024390244 0.024390244 0.26829268  0.4796748  0.4796748]
  iter 1 R2 [0.46341463 0.46341463  0.4796748  0.4796748  0.4796748]

  pdl> p "$_\t$k{$_}\n" for sort keys %k

  R2      0.479674796747968
  centroid       # mean ratings for 2 group x 5 movies
  [
   [         3  2.3333333]
   [         2  4.3333333]
   [         5  2.6666667]
   [         3          3]
   [         4  2.6666667]
  ]

  cluster        # 4 persons' membership in two groups
  [
   [1 0 0 0]
   [0 1 1 1]
  ]

  n       [1 3]  # cluster size
  ss
  [
   [         0 0.66666667]
   [         0 0.66666667]
   [         0 0.66666667]
   [         0          8]
   [         0 0.66666667]
  ]

Now, for the valiant, kmeans is broadcastable. Say you gathered 10
persons' ratings on 5 movies from 2 countries, so the data is dim
[10,5,2], and you want to put the 10 persons from each country into
3 clusters, just specify NCLUS => [3,1], and there you have it. The
key is for NCLUS to include $data->ndims - 1 numbers. The 1 in [3,1]
turns into a dummy dim, so the 3-cluster operation is repeated on both
countries. Similarly, when seeding, CNTRD needs to have ndims that at
least match the data ndims. Extra dims in CNTRD will lead to broadcasting
(convenient if you want to try out different centroid locations,
for example, but you will have to hand pick the best result). See
F<t/kmeans.t> for examples w 3D and 4D data.

*With bad value, R2 is based on average of variances instead of sum squared error.

=cut

*kmeans = \&PDL::kmeans;
sub PDL::kmeans {
  my ($self, $opt) = @_;
  my %opt = (
    V     => 1,         # prints simple status
    FULL  => 0,         # returns results for all seeding trials

    CNTRD => PDL->null, # optional. pdl [clu x var]. disables next 3 opts

    NTRY  => 5,         # num of random seeding trials
    NSEED => 1000,      # num of initial seeds, use NSEED up to max obs
    NCLUS => 3,         # num of clusters
  );
  if ($opt) { $opt{uc $_} = $opt->{$_} for keys %$opt; }
  if (defined($opt{CNTRD}) and $opt{CNTRD}->nelem) {
    $opt{NTRY}  = 1;
    $opt{NSEED} = $self->dim(0);
    $opt{NCLUS} = $opt{CNTRD}->dim(0);
  }
  else {
    $opt{NSEED} = pdl($self->dim(0), $opt{NSEED})->min->sclr;
  }
  $opt{V} and print "$_\t=> $opt{$_}\n" for sort keys %opt;

  my $ss_ms = $self->badflag?  'ms' : 'ss';
  my $ss_total
    = $self->badflag?  $self->var->average : $self->ss->sumover;
  $opt{V} and print "overall $ss_ms:\t$ss_total\n";

  my ($centroid, $ss_cv, $R2, $clus_this, $clus_last);

    # NTRY made into extra dim in $cluster for broadcasting
  my @nclus = (ref $opt{NCLUS} eq 'ARRAY')? @{$opt{NCLUS}} : ($opt{NCLUS});
  $clus_this
    = (defined($opt{CNTRD}) and $opt{CNTRD}->nelem) ?
      $self->assign( $opt{CNTRD}->dummy(-1) )  # put dummy(-1) to match NTRY
    : random_cluster($opt{NSEED}, @nclus, $opt{NTRY} )
    ;

  ($centroid, $ss_cv) = $self->slice([0,$opt{NSEED} - 1])->centroid( $clus_this );
    # now obs in $clus_this matches $self
  $clus_this = $self->assign( $centroid );
  ($centroid, $ss_cv) = $self->centroid( $clus_this );

  my $iter = 0;
  do {
    $R2 = $self->badflag? 1 - $ss_cv->average->average / $ss_total
        :                 1 - $ss_cv->sumover->sumover / $ss_total
        ;
    $opt{V} and print join(' ',('iter', $iter++, 'R2', $R2)) . "\n";

    $clus_last = $clus_this;

    $clus_this = $self->assign( $centroid );
    ($centroid, $ss_cv) = $self->centroid( $clus_this );
  }
  while ( any long(abs($clus_this - $clus_last))->sumover->sumover > 0 );

  $opt{FULL} and
    return (
      centroid => PDL::squeeze( $centroid ),
      cluster  => PDL::squeeze( $clus_this ),
      n        => PDL::squeeze( $clus_this )->sumover,
      R2       => PDL::squeeze( $R2 ),
      $ss_ms   => PDL::squeeze( $ss_cv ),
    );

    # xchg/mv(-1,0) leaves it as was if single dim--unlike transpose
  my $i_best = $R2->mv(-1,0)->maximum_ind;

  $R2->getndims == 1 and
    return (
      centroid => $centroid->dice_axis(-1,$i_best)->sever->squeeze,
      cluster  => $clus_this->dice_axis(-1,$i_best)->sever->squeeze,
      n        => $clus_this->dice_axis(-1,$i_best)->sever->squeeze->sumover,
      R2       => $R2->dice_axis(-1,$i_best)->sever->squeeze,
      $ss_ms   => $ss_cv->dice_axis(-1,$i_best)->sever->squeeze,
    );

  # now for broadcasting beyond 2D data

  # can't believe i'm using a perl loop :P

  $i_best = $i_best->flat->sever;
  my @i_best = map { $opt{NTRY} * $_ + $i_best->slice("($_)") }
               0 .. $i_best->nelem - 1;

  my @shapes;
  for ($centroid, $clus_this, $R2) {
    my @dims = $_->dims;
    pop @dims;
    push @shapes, \@dims;
  }

  $clus_this = $clus_this->mv(-1,2)->clump(2..$clus_this->ndims-1)->dice_axis(2,\@i_best)->sever->reshape( @{ $shapes[1] } )->sever,

  return (
    centroid =>
$centroid->mv(-1,2)->clump(2..$centroid->ndims-1)->dice_axis(2,\@i_best)->sever->reshape( @{ $shapes[0] } )->sever,

    cluster  => $clus_this,
    n        => $clus_this->sumover,

    R2       =>
$R2->mv(-1,0)->clump(0..$R2->ndims-1)->dice_axis(0,\@i_best)->sever->reshape( @{ $shapes[2] } )->sever,

    $ss_ms   =>
$ss_cv->mv(-1,2)->clump(2..$ss_cv->ndims-1)->dice_axis(2,\@i_best)->sever->reshape( @{ $shapes[0] } )->sever,
  );
}

=head1 METHODS

=head2 iv_cluster

=for ref

Turns an independent variable into a cluster pdl. Returns cluster pdl and level-to-pdl_index mapping in list context and cluster pdl only in scalar context.

This is the method used for mean and var in anova. The difference between iv_cluster and dummy_code is that iv_cluster returns pdl dim [obs x level] whereas dummy_code returns pdl dim [obs x (level - 1)].

=for usage

Usage:

    pdl> @bake = qw( y y y n n n )

    # accepts @ ref or 1d pdl

    pdl> p $bake = iv_cluster( \@bake )
    [
     [1 1 1 0 0 0]
     [0 0 0 1 1 1]
    ]

    pdl> p $rating = sequence 6
    [0 1 2 3 4 5]

    pdl> p $rating->centroid( $bake )
    # mean for each iv level
    [
     [1 4]
    ]
    # ss
    [
     [2 2]
    ]

=cut

*iv_cluster = \&PDL::iv_cluster;
sub PDL::iv_cluster {
  my ($var_ref) = @_;
  my ($var, $map_ref) = PDL::Stats::Basic::code_ivs( $var_ref );
  my $var_a = yvals( short, $var->nelem, $var->max->sclr + 1 ) == $var;
  $var_a = $var_a->setbadif( $var->isbad ) if $var->badflag;
  wantarray ? ($var_a, $map_ref) : $var_a;
}

=head2 pca_cluster

Assign variables to components ie clusters based on pca loadings or
scores. One way to seed kmeans (see Ding & He, 2004, and Su & Dy, 2004
for other ways of using pca with kmeans). Variables are assigned to
their most associated component. Note that some components may not have
any variable that is most associated with them, so the returned number
of clusters may be smaller than NCOMP.

Default options (case insensitive):

  V     => 1,
  ABS   => 1,     # high pos and neg loadings on a comp in same cluster
  NCOMP => undef, # max number of components to consider. determined by
                  # scree plot black magic if not specified
  PLOT  => 0,     # pca scree plot with cutoff at NCOMP
  WIN   => undef, # pass pgswin object for more plotting control

Usage:

    # say we need to cluster a group of documents
    # $data is pdl dim [word x doc]
  ($data, $idd, $idw) = get_data 'doc_word_info.txt';

  pdl> %p = $data->pca;
    # $cluster is pdl mask dim [doc x ncomp]
  pdl> $cluster  = $p{loading}->pca_cluster;

    # pca clusters var while kmeans clusters obs. hence transpose
  pdl> ($m, $ss) = $data->transpose->centroid( $cluster );
  pdl> %k = $data->transpose->kmeans( { cntrd=>$m } );

    # take a look at cluster 0 doc ids
  pdl> p join("\n", @$idd[ list which $k{cluster}->( ,0) ]);

=cut

*pca_cluster = \&PDL::pca_cluster;
sub PDL::pca_cluster {
  my ($self, $opt) = @_;

  my %opt = (
    V     => 1,
    ABS   => 1,     # high pos and neg loadings on a comp in same cluster
    NCOMP => undef, # max number of components to consider. determined by
                    # scree plot black magic if not specified
    PLOT  => 0,     # pca scree plot with cutoff at NCOMP
    WIN   => undef, # pass pgswin object for more plotting control
  );
  if ($opt) { $opt{uc $_} = $opt->{$_} for keys %$opt; }

  my $var = sumover($self ** 2) / $self->dim(0);
  if (!$opt{NCOMP}) {
      # here's the black magic part
    my $comps = ($self->dim(1) > 300)? int($self->dim(1) * .1)
              :                        pdl($self->dim(1), 30)->min
              ;
    $var = $var->slice([0,$comps-1])->sever;
    $opt{NCOMP} = _scree_ind( $var );
  }
  $opt{PLOT} and do {
    require PDL::Stats::GLM;
    $var->plot_screes({NCOMP=>$var->dim(0), CUT=>$opt{NCOMP}, WIN=>$opt{WIN}});
  };

  my $c = $self->slice(':',[0,$opt{NCOMP}-1])->transpose->abs->maximum_ind;

  if ($opt{ABS}) {
    $c = $c->iv_cluster;
  }
  else {
    my @c = map { ($self->slice($_,$c->slice($_)) >= 0)? $c->slice($_)*2 : $c->slice($_)*2 + 1 }
                ( 0 .. $c->dim(0)-1 );
    $c = iv_cluster( \@c );
  }
  $opt{V} and print "cluster membership mask as " . $c->info . "\n";

  return $c;
}

=head1 	REFERENCES

Ding, C., & He, X. (2004). K-means clustering via principal component analysis. Proceedings of the 21st International Conference on Machine Learning, 69, 29.

Su, T., & Dy, J. (2004). A deterministic method for initializing K-means clustering. 16th IEEE International Conference on Tools with Artificial Intelligence, 784-786.

Romesburg, H.C. (1984). Cluster Analysis for Researchers. NC: Lulu Press.

Wikipedia (retrieved June, 2009). K-means clustering. http://en.wikipedia.org/wiki/K-means_algorithm

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 767 "lib/PDL/Stats/Kmeans.pm"

# Exit with OK status

1;
