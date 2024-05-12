#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Slices;

our @EXPORT_OK = qw(index index1d index2d indexND indexNDb rangeb rld rle rlevec rldvec rleseq rldseq rleND rldND _clump_int xchg mv using meshgrid lags splitdim rotate broadcastI unbroadcast dice dice_axis slice diagonal );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Slices ;







#line 5 "slices.pd"

=head1 NAME

PDL::Slices -- Indexing, slicing, and dicing

=head1 SYNOPSIS

  use PDL;
  $x = ones(3,3);
  $y = $x->slice('-1:0,(1)');
  $c = $x->dummy(2);

=head1 DESCRIPTION

This package provides many of the powerful PerlDL core index
manipulation routines.  These routines mostly allow two-way data flow,
so you can modify your data in the most convenient representation.
For example, you can make a 1000x1000 unit matrix with

 $x = zeroes(1000,1000);
 $x->diagonal(0,1) ++;

which is quite efficient. See L<PDL::Indexing> and L<PDL::Tips> for
more examples.

Slicing is so central to the PDL language that a special compile-time
syntax has been introduced to handle it compactly; see L<PDL::NiceSlice>
for details.

PDL indexing and slicing functions usually include two-way data flow,
so that you can separate the actions of reshaping your data structures
and modifying the data themselves.  Two special methods, L</copy> and
L</sever>, help you control the data flow connection between related
variables.

 $y = $x->slice("1:3"); # Slice maintains a link between $x and $y.
 $y += 5;               # $x is changed!

If you want to force a physical copy and no data flow, you can copy or
sever the slice expression:

 $y = $x->slice("1:3")->copy;
 $y += 5;               # $x is not changed.

 $y = $x->slice("1:3")->sever;
 $y += 5;               # $x is not changed.

The difference between C<sever> and C<copy> is that sever acts on (and
returns) its argument, while copy produces a disconnected copy.  If you
say

 $y = $x->slice("1:3");
 $c = $y->sever;

then the variables C<$y> and C<$c> point to the same object but with
C<-E<gt>copy> they would not.

=cut

use strict;
use warnings;
use PDL::Core ':Internal';
use Scalar::Util 'blessed';
#line 90 "Slices.pm"


=head1 FUNCTIONS

=cut






=head2 index

=for sig

  Signature: (a(n); indx ind(); [oca] c())

=for ref

C<index>, C<index1d>, and C<index2d> provide rudimentary index indirection.

=for example

 $c = index($source,$ind);
 $c = index1d($source,$ind);
 $c = index2d($source2,$ind1,$ind2);

use the C<$ind> variables as indices to look up values in C<$source>.
The three routines broadcast slightly differently.

=over 3

=item *

C<index> uses direct broadcasting for 1-D indexing across the 0 dim
of C<$source>.  It can broadcast over source broadcast dims or index broadcast
dims, but not (easily) both: If C<$source> has more than 1
dimension and C<$ind> has more than 0 dimensions, they must agree in
a broadcasting sense.

=item * 

C<index1d> uses a single active dim in C<$ind> to produce a list of
indexed values in the 0 dim of the output - it is useful for
collapsing C<$source> by indexing with a single row of values along
C<$source>'s 0 dimension.  The output has the same number of dims as
C<$source>.  The 0 dim of the output has size 1 if C<$ind> is a
scalar, and the same size as the 0 dim of C<$ind> if it is not. If
C<$ind> and C<$source> both have more than 1 dim, then all dims higher
than 0 must agree in a broadcasting sense.

=item * 

C<index2d> works like C<index> but uses separate ndarrays for X and Y
coordinates.  For more general N-dimensional indexing, see the
L<PDL::NiceSlice> syntax or L<PDL::Slices> (in particular C<slice>,
C<indexND>, and C<range>).

=back 

These functions are two-way, i.e. after

 $c = $x->index(pdl[0,5,8]);
 $c .= pdl [0,2,4];

the changes in C<$c> will flow back to C<$x>.

C<index> provids simple broadcasting:  multiple-dimensioned arrays are treated
as collections of 1-D arrays, so that

 $x = xvals(10,10)+10*yvals(10,10);
 $y = $x->index(3);
 $c = $x->index(9-xvals(10));

puts a single column from C<$x> into C<$y>, and puts a single element
from each column of C<$x> into C<$c>.  If you want to extract multiple
columns from an array in one operation, see L</dice> or
L</indexND>.

=for bad

index barfs if any of the index values are bad.

=cut




*index = \&PDL::index;






=head2 index1d

=for sig

  Signature: (a(n); indx ind(m); [oca] c(m))

=for ref

C<index>, C<index1d>, and C<index2d> provide rudimentary index indirection.

=for example

 $c = index($source,$ind);
 $c = index1d($source,$ind);
 $c = index2d($source2,$ind1,$ind2);

use the C<$ind> variables as indices to look up values in C<$source>.
The three routines broadcast slightly differently.

=over 3

=item *

C<index> uses direct broadcasting for 1-D indexing across the 0 dim
of C<$source>.  It can broadcast over source broadcast dims or index broadcast
dims, but not (easily) both: If C<$source> has more than 1
dimension and C<$ind> has more than 0 dimensions, they must agree in
a broadcasting sense.

=item * 

C<index1d> uses a single active dim in C<$ind> to produce a list of
indexed values in the 0 dim of the output - it is useful for
collapsing C<$source> by indexing with a single row of values along
C<$source>'s 0 dimension.  The output has the same number of dims as
C<$source>.  The 0 dim of the output has size 1 if C<$ind> is a
scalar, and the same size as the 0 dim of C<$ind> if it is not. If
C<$ind> and C<$source> both have more than 1 dim, then all dims higher
than 0 must agree in a broadcasting sense.

=item * 

C<index2d> works like C<index> but uses separate ndarrays for X and Y
coordinates.  For more general N-dimensional indexing, see the
L<PDL::NiceSlice> syntax or L<PDL::Slices> (in particular C<slice>,
C<indexND>, and C<range>).

=back 

These functions are two-way, i.e. after

 $c = $x->index(pdl[0,5,8]);
 $c .= pdl [0,2,4];

the changes in C<$c> will flow back to C<$x>.

C<index> provids simple broadcasting:  multiple-dimensioned arrays are treated
as collections of 1-D arrays, so that

 $x = xvals(10,10)+10*yvals(10,10);
 $y = $x->index(3);
 $c = $x->index(9-xvals(10));

puts a single column from C<$x> into C<$y>, and puts a single element
from each column of C<$x> into C<$c>.  If you want to extract multiple
columns from an array in one operation, see L</dice> or
L</indexND>.

=for bad

index1d propagates BAD index elements to the output variable.

=cut




*index1d = \&PDL::index1d;






=head2 index2d

=for sig

  Signature: (a(na,nb); indx inda(); indx indb(); [oca] c())

=for ref

C<index>, C<index1d>, and C<index2d> provide rudimentary index indirection.

=for example

 $c = index($source,$ind);
 $c = index1d($source,$ind);
 $c = index2d($source2,$ind1,$ind2);

use the C<$ind> variables as indices to look up values in C<$source>.
The three routines broadcast slightly differently.

=over 3

=item *

C<index> uses direct broadcasting for 1-D indexing across the 0 dim
of C<$source>.  It can broadcast over source broadcast dims or index broadcast
dims, but not (easily) both: If C<$source> has more than 1
dimension and C<$ind> has more than 0 dimensions, they must agree in
a broadcasting sense.

=item * 

C<index1d> uses a single active dim in C<$ind> to produce a list of
indexed values in the 0 dim of the output - it is useful for
collapsing C<$source> by indexing with a single row of values along
C<$source>'s 0 dimension.  The output has the same number of dims as
C<$source>.  The 0 dim of the output has size 1 if C<$ind> is a
scalar, and the same size as the 0 dim of C<$ind> if it is not. If
C<$ind> and C<$source> both have more than 1 dim, then all dims higher
than 0 must agree in a broadcasting sense.

=item * 

C<index2d> works like C<index> but uses separate ndarrays for X and Y
coordinates.  For more general N-dimensional indexing, see the
L<PDL::NiceSlice> syntax or L<PDL::Slices> (in particular C<slice>,
C<indexND>, and C<range>).

=back 

These functions are two-way, i.e. after

 $c = $x->index(pdl[0,5,8]);
 $c .= pdl [0,2,4];

the changes in C<$c> will flow back to C<$x>.

C<index> provids simple broadcasting:  multiple-dimensioned arrays are treated
as collections of 1-D arrays, so that

 $x = xvals(10,10)+10*yvals(10,10);
 $y = $x->index(3);
 $c = $x->index(9-xvals(10));

puts a single column from C<$x> into C<$y>, and puts a single element
from each column of C<$x> into C<$c>.  If you want to extract multiple
columns from an array in one operation, see L</dice> or
L</indexND>.

=for bad

index2d barfs if either of the index values are bad.

=cut




*index2d = \&PDL::index2d;





#line 230 "slices.pd"

=head2 indexNDb

=for ref

  Backwards-compatibility alias for indexND

=head2 indexND

=for ref

  Find selected elements in an N-D ndarray, with optional boundary handling

=for example

  $out = $source->indexND( $index, [$method] )

  $source = 10*xvals(10,10) + yvals(10,10);
  $index  = pdl([[2,3],[4,5]],[[6,7],[8,9]]);
  print $source->indexND( $index );

  [
   [23 45]
   [67 89]
  ]

IndexND collapses C<$index> by lookup into C<$source>.  The
0th dimension of C<$index> is treated as coordinates in C<$source>, and
the return value has the same dimensions as the rest of C<$index>.
The returned elements are looked up from C<$source>.  Dataflow
works -- propagated assignment flows back into C<$source>.

IndexND and IndexNDb were originally separate routines but they are both
now implemented as a call to L</range>, and have identical syntax to
one another.

SEE ALSO:

L<PDL::Primitive/whichND> returns N-D indices into a multidimensional
PDL, suitable for feeding to this.

=cut

sub PDL::indexND {
        my($source,$index, $boundary) = @_;
        return PDL::range($source,$index,undef,$boundary);
}

*PDL::indexNDb = \&PDL::indexND;

#line 282 "slices.pd"
sub PDL::range {
  my($source,$ind,$sz,$bound) = @_;

# Convert to indx type up front (also handled in rangeb if necessary)
  my $index = (ref $ind && UNIVERSAL::isa($ind,'PDL') && $ind->type eq 'indx') ? $ind : indx($ind);
  my $size = defined($sz) ? PDL->pdl($sz) : undef;

  # Handle empty PDL case: return a properly constructed Empty.
  if($index->isempty) {
      my @sdims= $source->dims;
      splice(@sdims, 0, $index->dim(0) + ($index->dim(0)==0)); # added term is to treat Empty[0] like a single empty coordinate
      unshift(@sdims, $size->list) if(defined($size));
      return PDL->new_from_specification(0 x ($index->ndims-1), @sdims);
  }

  $index = $index->dummy(0,1) unless $index->ndims;

  # Pack boundary string if necessary
  if(defined $bound) {
    if(ref $bound eq 'ARRAY') {
      my ($s,$el);
      foreach $el(@$bound) {
        barf "Illegal boundary value '$el' in range"
          unless( $el =~ m/^([0123fFtTeEpPmM])/ );
        $s .= $1;
      }
      $bound = $s;
    }
    elsif($bound !~ m/^[0123ftepx]+$/  && $bound =~ m/^([0123ftepx])/i ) {
      $bound = $1;
    }
  }

  no warnings; # shut up about passing undef into rangeb
  $source->rangeb($index,$size,$bound);
}
#line 441 "Slices.pm"


=head2 rangeb

=for sig

  Signature: (P(); C(); pdl *ind_pdl; SV *size_sv; SV *boundary_sv)

=for ref

Engine for L</range>

=for example

Same calling convention as L</range>, but you must supply all
parameters.  C<rangeb> is marginally faster as it makes a direct PP call,
avoiding the perl argument-parsing step.

=head2 range

=for ref

Extract selected chunks from a source ndarray, with boundary conditions

=for example

        $out = $source->range($index,[$size,[$boundary]])

Returns elements or rectangular slices of the original ndarray, indexed by
the C<$index> ndarray.  C<$source> is an N-dimensional ndarray, and C<$index> is
an ndarray whose first dimension has size up to N.  Each row of C<$index> is
treated as coordinates of a single value or chunk from C<$source>, specifying
the location(s) to extract.

If you specify a single index location, then range is essentially an expensive
slice, with controllable boundary conditions.

B<INPUTS>

C<$index> and C<$size> can be ndarrays or array refs such as you would
feed to L<zeroes|PDL::Core/zeroes> and its ilk.  If C<$index>'s 0th dimension
has size higher than the number of dimensions in C<$source>, then
C<$source> is treated as though it had trivial dummy dimensions of
size 1, up to the required size to be indexed by C<$index> -- so if
your source array is 1-D and your index array is a list of 3-vectors,
you get two dummy dimensions of size 1 on the end of your source array.

You can extract single elements or N-D rectangular ranges from C<$source>,
by setting C<$size>.  If C<$size> is undef or zero, then you get a single
sample for each row of C<$index>.  This behavior is similar to
L</indexNDb>, which is in fact implemented as a call to L</range>.

If C<$size> is positive then you get a range of values from C<$source> at
each location, and the output has extra dimensions allocated for them.
C<$size> can be a scalar, in which case it applies to all dimensions, or an
N-vector, in which case each element is applied independently to the
corresponding dimension in C<$source>.  See below for details.

C<$boundary> is a number, string, or list ref indicating the type of
boundary conditions to use when ranges reach the edge of C<$source>.  If you
specify no boundary conditions the default is to forbid boundary violations
on all axes.  If you specify exactly one boundary condition, it applies to
all axes.  If you specify more (as elements of a list ref, or as a packed
string, see below), then they apply to dimensions in the order in which they
appear, and the last one applies to all subsequent dimensions.  (This is
less difficult than it sounds; see the examples below).

=over 3

=item 0 (synonyms: 'f','forbid') B<(default)>

Ranges are not allowed to cross the boundary of the original PDL.  Disallowed
ranges throw an error.  The errors are thrown at evaluation time, not
at the time of the range call (this is the same behavior as L</slice>).

=item 1 (synonyms: 't','truncate')

Values outside the original ndarray get BAD if you've got bad value
support compiled into your PDL and set the badflag for the source PDL;
or 0 if you haven't (you must set the badflag if you want BADs for out
of bound values, otherwise you get 0).  Reverse dataflow works OK for
the portion of the child that is in-bounds.  The out-of-bounds part of
the child is reset to (BAD|0) during each dataflow operation, but
execution continues.

=item 2 (synonyms: 'e','x','extend')

Values that would be outside the original ndarray point instead to the
nearest allowed value within the ndarray.  See the CAVEAT below on
mappings that are not single valued.

=item 3 (synonyms: 'p','periodic')

Periodic boundary conditions apply: the numbers in $index are applied,
strict-modulo the corresponding dimensions of $source.  This is equivalent to
duplicating the $source ndarray throughout N-D space.  See the CAVEAT below
about mappings that are not single valued.

=item 4 (synonyms: 'm','mirror')

Mirror-reflection periodic boundary conditions apply.  See the CAVEAT
below about mappings that are not single valued.

=back

The boundary condition identifiers all begin with unique characters, so
you can feed in multiple boundary conditions as either a list ref or a
packed string.  (The packed string is marginally faster to run).  For
example, the four expressions [0,1], ['forbid','truncate'], ['f','t'],
and 'ft' all specify that violating the boundary in the 0th dimension
throws an error, and all other dimensions get truncated.

If you feed in a single string, it is interpreted as a packed boundary
array if all of its characters are valid boundary specifiers (e.g. 'pet'),
but as a single word-style specifier if they are not (e.g. 'forbid').

Where the source PDL is empty, all non-barfing boundary conditions
are changed to truncation, since there is no data to reflect, extend,
or mirror.

B<OUTPUT>

The output broadcasts over both C<$index> and C<$source>.  Because implicit
broadcasting can happen in a couple of ways, a little thought is needed.  The
returned dimension list is stacked up like this:

   (index broadcast dims), (index dims (size)), (source broadcast dims)

The first few dims of the output correspond to the extra dims of
C<$index> (beyond the 0 dim). They allow you to pick out individual
ranges from a large, broadcasted collection.

The middle few dims of the output correspond to the size dims
specified in C<$size>, and contain the range of values that is extracted
at each location in C<$source>.  Every nonzero element of C<$size> is copied to
the dimension list here, so that if you feed in (for example) C<$size
= [2,0,1]> you get an index dim list of C<(2,1)>.

The last few dims of the output correspond to extra dims of C<$source> beyond
the number of dims indexed by C<$index>.  These dims act like ordinary
broadcast dims, because adding more dims to C<$source> just tacks extra dims
on the end of the output.  Each source broadcast dim ranges over the entire
corresponding dim of C<$source>.

B<Dataflow>: Dataflow is bidirectional.

B<Examples>:
Here are basic examples of C<range> operation, showing how to get
ranges out of a small matrix.  The first few examples show extraction
and selection of individual chunks.  The last example shows
how to mark loci in the original matrix (using dataflow).

 pdl> $src = 10*xvals(10,5)+yvals(10,5)
 pdl> print $src->range([2,3])    # Cut out a single element
 23
 pdl> print $src->range([2,3],1)  # Cut out a single 1x1 block
 [
  [23]
 ]
 pdl> print $src->range([2,3], [2,1]) # Cut a 2x1 chunk
 [
  [23 33]
 ]
 pdl> print $src->range([[2,3]],[2,1]) # Trivial list of 1 chunk
 [
  [
   [23]
   [33]
  ]
 ]
 pdl> print $src->range([[2,3],[0,1]], [2,1])   # two 2x1 chunks
 [
  [
   [23  1]
   [33 11]
  ]
 ]
 pdl> # A 2x2 collection of 2x1 chunks
 pdl> print $src->range([[[1,1],[2,2]],[[2,3],[0,1]]],[2,1])
 [
  [
   [
    [11 22]
    [23  1]
   ]
   [
    [21 32]
    [33 11]
   ]
  ]
 ]
 pdl> $src = xvals(5,3)*10+yvals(5,3)
 pdl> print $src->range(3,1)  # Broadcast over y dimension in $src
 [
  [30]
  [31]
  [32]
 ]

 pdl> $src = zeroes(5,4);
 pdl> $src->range(pdl([2,3],[0,1]),pdl(2,1)) .= xvals(2,2,1) + 1
 pdl> print $src
 [
  [0 0 0 0 0]
  [2 2 0 0 0]
  [0 0 0 0 0]
  [0 0 1 1 0]
 ]

B<CAVEAT>: It's quite possible to select multiple ranges that
intersect.  In that case, modifying the ranges doesn't have a
guaranteed result in the original PDL -- the result is an arbitrary
choice among the valid values.  For some things that's OK; but for
others it's not. In particular, this doesn't work:

    pdl> $photon_list = PDL::RandVar->new->sample(500)->reshape(2,250)*10
    pdl> $histogram = zeroes(10,10)
    pdl> $histogram->range($photon_list,1)++;  #not what you wanted

The reason is that if two photons land in the same bin, then that bin
doesn't get incremented twice.  (That may get fixed in a later version...)

B<PERMISSIVE RANGING>: If C<$index> has too many dimensions compared
to C<$source>, then $source is treated as though it had dummy
dimensions of size 1, up to the required number of dimensions.  These
virtual dummy dimensions have the usual boundary conditions applied to
them.

If the 0 dimension of C<$index> is ludicrously large (if its size is
more than 5 greater than the number of dims in the source PDL) then
range will insist that you specify a size in every dimension, to make
sure that you know what you're doing.  That catches a common error with
range usage: confusing the initial dim (which is usually small) with another
index dim (perhaps of size 1000).

If the index variable is Empty, then range() always returns the Empty PDL.
If the index variable is not Empty, indexing it always yields a boundary
violation.  All non-barfing conditions are treated as truncation, since
there are no actual data to return.

B<EFFICIENCY>: Because C<range> isn't an affine transformation (it
involves lookup into a list of N-D indices), it is somewhat
memory-inefficient for long lists of ranges, and keeping dataflow open
is much slower than for affine transformations (which don't have to copy
data around).

Doing operations on small subfields of a large range is inefficient
because the engine must flow the entire range back into the original
PDL with every atomic perl operation, even if you only touch a single element.
One way to speed up such code is to sever your range, so that PDL
doesn't have to copy the data with each operation, then copy the
elements explicitly at the end of your loop.  Here's an example that
labels each region in a range sequentially, using many small
operations rather than a single xvals assignment:

  ### How to make a collection of small ops run fast with range...
  $x =  $data->range($index, $sizes, $bound)->sever;
  $aa = $data->range($index, $sizes, $bound);
  $x($_ - 1) .= $_ for 1..$x->nelem;    # Lots of little ops
  $aa .= $x;

C<range> is a perl front-end to a PP function, C<rangeb>.  Calling
C<rangeb> is marginally faster but requires that you include all arguments.

DEVEL NOTES

* index broadcast dimensions are effectively clumped internally.  This
makes it easier to loop over the index array but a little more brain-bending
to tease out the algorithm.

=for bad

rangeb processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rangeb = \&PDL::rangeb;






=head2 rld

=for sig

  Signature: (indx a(n); b(n); [o]c(m); IV sumover_max => m)

=for ref

Run-length decode a vector

Given a vector C<$x> of the numbers of instances of values C<$y>, run-length
decode to C<$c>.

=for example

 rld($x,$y,$c=null);

=for bad

rld does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 1040 "slices.pd"
sub PDL::rld {
  my ($x,$y) = @_;
  my ($c,$sm) = @_ == 3 ? ($_[2], $_[2]->dim(0)) : (PDL->null, $x->sumover->max->sclr);
  PDL::_rld_int($x,$y,$c,$sm);
  $c;
}
#line 764 "Slices.pm"

*rld = \&PDL::rld;






=head2 rle

=for sig

  Signature: (c(n); indx [o]a(m=CALC($SIZE(n))); [o]b(m))

=for ref

Run-length encode a vector

Given vector C<$c>, generate a vector C<$x> with the number of each
element, and a vector C<$y> of the unique values.  New in PDL 2.017,
only the elements up to the first instance of C<0> in C<$x> are
returned, which makes the common use case of a 1-dimensional C<$c> simpler.
For broadcast operation, C<$x> and C<$y> will be large enough
to hold the largest row of C<$y>, and only the elements up to the
first instance of C<0> in each row of C<$x> should be considered.

=for example

 $c = floor(4*random(10));
 rle($c,$x=null,$y=null);
 #or
 ($x,$y) = rle($c);

 #for $c of shape [10, 4]:
 $c = floor(4*random(10,4));
 ($x,$y) = rle($c);

 #to see the results of each row one at a time:
 foreach (0..$c->dim(1)-1){
  my ($as,$bs) = ($x(:,($_)),$y(:,($_)));
  my ($ta,$tb) = where($as,$bs,$as!=0); #only the non-zero elements of $x
  print $c(:,($_)) . " rle==> " , ($ta,$tb) , "\trld==> " . rld($ta,$tb) . "\n";
 }

 # the inverse of (chance of all 6 3d6 rolls being >= each possible sum)
 ($nrolls, $ndice, $dmax) = (6, 3, 6);
 ($x, $x1) = (allaxisvals(($dmax) x $ndice)+1)->sumover->flat->qsort->rle;
 $y = $x->cumusumover;
 $yprob1x = $y->slice('-1:0')->double / $y->slice('(-1)');
 $z = cat($x1, 1 / $yprob1x**$nrolls)->transpose;

=for bad

rle does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 1081 "slices.pd"
sub PDL::rle {
  my $c = shift;
  my ($x,$y) = @_==2 ? @_ : (null,null);
  PDL::_rle_int($c,$x,$y);
  my $max_ind = ($c->ndims<2) ? ($x!=0)->sumover-1 :
                                ($x!=0)->clump(1..$x->ndims-1)->sumover->max->sclr-1;
  return ($x->slice("0:$max_ind"),$y->slice("0:$max_ind"));
}
#line 836 "Slices.pm"

*rle = \&PDL::rle;






=head2 rlevec

=for sig

  Signature: (c(M,N); indx [o]a(N); [o]b(M,N))

=for ref

Run-length encode a set of vectors.

Higher-order rle(), for use with qsortvec().

Given set of vectors $c, generate a vector $a with the number of occurrences of each element
(where an "element" is a vector of length $M occurring in $c),
and a set of vectors $b containing the unique values.
As for rle(), only the elements up to the first instance of 0 in $a should be considered.

Can be used together with clump() to run-length encode "values" of arbitrary dimensions.
Can be used together with rotate(), cat(), append(), and qsortvec() to count N-grams
over a 1d PDL.

See also: L</rle>, L<PDL::Ufunc/qsortvec>, L<PDL::Primitive/uniqvec>
Contributed by Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=for bad

rlevec does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rlevec = \&PDL::rlevec;






=head2 rldvec

=for sig

  Signature: (indx a(uniqvals); b(M,uniqvals); [o]c(M,decodedvals); IV sumover_max => decodedvals)

=for ref

Run-length decode a set of vectors, akin to a higher-order rld().

Given a vector $a() of the number of occurrences of each row, and a set $b()
of row-vectors each of length $M, run-length decode to $c().

Can be used together with clump() to run-length decode "values" of arbitrary dimensions.

See also: L</rld>.
Contributed by Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=for bad

rldvec does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 1206 "slices.pd"
sub PDL::rldvec {
  my ($a,$b,$c) = @_;
  ($c,my $sm) = defined($c) ? ($c,$c->dim(1)) : (PDL->null,$a->sumover->max->sclr);
  PDL::_rldvec_int($a,$b,$c,$sm);
  return $c;
}
#line 922 "Slices.pm"

*rldvec = \&PDL::rldvec;






=head2 rleseq

=for sig

  Signature: (c(N); indx [o]a(N); [o]b(N))

=for ref

Run-length encode a vector of subsequences.

Given a vector of $c() of concatenated variable-length, variable-offset subsequences,
generate a vector $a containing the length of each subsequence
and a vector $b containing the subsequence offsets.
As for rle(), only the elements up to the first instance of 0 in $a should be considered.

See also L</rle>.
Contributed by Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=for bad

rleseq does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rleseq = \&PDL::rleseq;






=head2 rldseq

=for sig

  Signature: (indx a(N); b(N); [o]c(M); IV sumover_max => M)

=for ref

Run-length decode a subsequence vector.

Given a vector $a() of sequence lengths
and a vector $b() of corresponding offsets,
decode concatenation of subsequences to $c(),
as for:

 $c = null;
 $c = $c->append($b($_)+sequence($a->type,$a($_))) foreach (0..($N-1));

See also: L</rld>.
Contributed by Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=for bad

rldseq does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 1279 "slices.pd"
sub PDL::rldseq {
  my ($a,$b,$c) = @_;
  ($c,my $sm) = defined($c) ? ($c,$c->dim(1)) : (PDL->null,$a->sumover->max->sclr);
  PDL::_rldseq_int($a,$b,$c,$sm);
  return $c;
}
#line 1005 "Slices.pm"

*rldseq = \&PDL::rldseq;





#line 1314 "slices.pd"

=head2 rleND

=for sig

  Signature: (data(@vdims,N); int [o]counts(N); [o]elts(@vdims,N))

=for ref

Run-length encode a set of (sorted) n-dimensional values.

Generalization of rle() and vv_rlevec():
given set of values $data, generate a vector $counts with the number of occurrences of each element
(where an "element" is a matrix of dimensions @vdims occurring as a sequential run over the
final dimension in $data), and a set of vectors $elts containing the elements which begin a run.
Really just a wrapper for clump() and rlevec().

See also: L</rle>, L</rlevec>.
Contributed by Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=cut

*PDL::rleND = \&rleND;
sub rleND {
  my $data   = shift;
  my @vdimsN = $data->dims;

  ##-- construct output pdls
  my $counts = $#_ >= 0 ? $_[0] : PDL->null;
  my $elts   = $#_ >= 1 ? $_[1] : zeroes($data->type, @vdimsN);

  ##-- guts: call rlevec()
  rlevec($data->clump($#vdimsN), $counts, $elts->clump($#vdimsN));

  return ($counts,$elts);
}

=head2 rldND

=for sig

  Signature: (int counts(N); elts(@vdims,N); [o]data(@vdims,N);)

=for ref

Run-length decode a set of (sorted) n-dimensional values.

Generalization of rld() and rldvec():
given a vector $counts() of the number of occurrences of each @vdims-dimensioned element,
and a set $elts() of @vdims-dimensioned elements, run-length decode to $data().

Really just a wrapper for clump() and rldvec().

See also: L</rld>, L</rldvec>.
Contributed by Bryan Jurish E<lt>moocow@cpan.orgE<gt>.

=cut

*PDL::rldND = \&rldND;
sub rldND {
  my ($counts,$elts) = (shift,shift);
  my @vdimsN        = $elts->dims;

  ##-- construct output pdl
  my ($data);
  if ($#_ >= 0) { $data = $_[0]; }
  else {
    my $size      = $counts->sumover->max; ##-- get maximum size for Nth-dimension for small encodings
    my @countdims = $counts->dims;
    shift(@countdims);
    $data         = zeroes($elts->type, @vdimsN, @countdims);
  }

  ##-- guts: call rldvec()
  rldvec($counts, $elts->clump($#vdimsN), $data->clump($#vdimsN));

  return $data;
}
#line 1092 "Slices.pm"

*_clump_int = \&PDL::_clump_int;






=head2 xchg

=for sig

  Signature: (P(); C(); PDL_Indx n1; PDL_Indx n2)

=for ref

exchange two dimensions

Negative dimension indices count from the end.

The command

=for example

 $y = $x->xchg(2,3);

creates C<$y> to be like C<$x> except that the dimensions 2 and 3
are exchanged with each other i.e.

 $y->at(5,3,2,8) == $x->at(5,3,8,2)

=for bad

xchg does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*xchg = \&PDL::xchg;





#line 1473 "slices.pd"

=head2 reorder

=for ref

Re-orders the dimensions of a PDL based on the supplied list.

Similar to the L</xchg> method, this method re-orders the dimensions
of a PDL. While the L</xchg> method swaps the position of two dimensions,
the reorder method can change the positions of many dimensions at
once.

=for usage

 # Completely reverse the dimension order of a 6-Dim array.
 $reOrderedPDL = $pdl->reorder(5,4,3,2,1,0);

The argument to reorder is an array representing where the current dimensions
should go in the new array. In the above usage, the argument to reorder
C<(5,4,3,2,1,0)>
indicates that the old dimensions (C<$pdl>'s dims) should be re-arranged to make the
new pdl (C<$reOrderPDL>) according to the following:

   Old Position   New Position
   ------------   ------------
   5              0
   4              1
   3              2
   2              3
   1              4
   0              5

You do not need to specify all dimensions, only a complete set
starting at position 0.  (Extra dimensions are left where they are).
This means, for example, that you can reorder() the X and Y dimensions of
an image, and not care whether it is an RGB image with a third dimension running
across color plane.

=for example

Example:

 pdl> $x = sequence(5,3,2);       # Create a 3-d Array
 pdl> p $x
 [
  [
   [ 0  1  2  3  4]
   [ 5  6  7  8  9]
   [10 11 12 13 14]
  ]
  [
   [15 16 17 18 19]
   [20 21 22 23 24]
   [25 26 27 28 29]
  ]
 ]
 pdl> p $x->reorder(2,1,0); # Reverse the order of the 3-D PDL
 [
  [
   [ 0 15]
   [ 5 20]
   [10 25]
  ]
  [
   [ 1 16]
   [ 6 21]
   [11 26]
  ]
  [
   [ 2 17]
   [ 7 22]
   [12 27]
  ]
  [
   [ 3 18]
   [ 8 23]
   [13 28]
  ]
  [
   [ 4 19]
   [ 9 24]
   [14 29]
  ]
 ]

The above is a simple example that could be duplicated by calling
C<$x-E<gt>xchg(0,2)>, but it demonstrates the basic functionality of reorder.

As this is an index function, any modifications to the
result PDL will change the parent.

=cut

sub PDL::reorder {
        my ($pdl,@newDimOrder) = @_;

        my $arrayMax = $#newDimOrder;

        #Error Checking:
        if( $pdl->getndims < scalar(@newDimOrder) ){
                my $errString = "PDL::reorder: Number of elements (".scalar(@newDimOrder).") in newDimOrder array exceeds\n";
                $errString .= "the number of dims in the supplied PDL (".$pdl->getndims.")";
                barf($errString);
        }

        # Check to make sure all the dims are within bounds
        for my $i(0..$#newDimOrder) {
          my $dim = $newDimOrder[$i];
          if($dim < 0 || $dim > $#newDimOrder) {
              my $errString = "PDL::reorder: Dim index $newDimOrder[$i] out of range in position $i\n(range is 0-$#newDimOrder)";
              barf($errString);
          }
        }

        # Checking that they are all present and also not duplicated is done by broadcast() [I think]

        # a quicker way to do the reorder
        return $pdl->broadcast(@newDimOrder)->unbroadcast(0);
}
#line 1260 "Slices.pm"


=head2 mv

=for sig

  Signature: (P(); C(); PDL_Indx n1; PDL_Indx n2)

=for ref

move a dimension to another position

The command

=for example

 $y = $x->mv(4,1);

creates C<$y> to be like C<$x> except that the dimension 4 is moved to the
place 1, so:

 $y->at(1,2,3,4,5,6) == $x->at(1,5,2,3,4,6);

The other dimensions are moved accordingly.
Negative dimension indices count from the end.

=for bad

mv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mv = \&PDL::mv;





#line 1646 "slices.pd"

=head2 using

=for ref

Returns list of columns requested

=for usage

 line $pdl->using(1,2);

Plot, as a line, column 1 of C<$pdl> vs. column 2

=for example

 pdl> $pdl = rcols("file");
 pdl> line $pdl->using(1,2);

=cut

*using = \&PDL::using;
sub PDL::using {
  my ($x,@ind)=@_;
  @ind = list $ind[0] if (blessed($ind[0]) && $ind[0]->isa('PDL'));
  foreach (@ind) {
    $_ = $x->slice("($_)");
  }
  @ind;
}

=head2 meshgrid

=for ref

Returns list of given 1-D vectors, but each expanded to match dims using
L<PDL::Core/dummy>.

=for usage

  meshgrid($vec1, $vec2, $vec3);

=for example

  print map $_->info, meshgrid(xvals(3), xvals(4), xvals(2));
  # PDL: Double D [3,4,2] PDL: Double D [3,4,2] PDL: Double D [3,4,2]

=cut

*meshgrid = \&PDL::meshgrid;
sub PDL::meshgrid {
  barf "meshgrid: only 1-dimensional inputs" if grep $_->ndims != 1, @_;
  return @_ if @_ == 1;
  my @dims = map $_->dims, @_;
  my @out;
  for my $ind (0..$#_) {
    push @out, $_[$ind]->slice(join ',', map $_==$ind ? '' : "*$dims[$_]", 0..$#_);
  }
  @out;
}
#line 1363 "Slices.pm"


=head2 lags

=for sig

  Signature: (P(); C(); PDL_Indx nthdim;PDL_Indx step;PDL_Indx n)

=for ref

Returns an ndarray of lags to parent.

Usage:

=for usage

  $lags = $x->lags($nthdim,$step,$nlags);

I.e. if C<$x> contains

 [0,1,2,3,4,5,6,7]

then

=for example

 $y = $x->lags(0,2,2);

is a (5,2) matrix

 [2,3,4,5,6,7]
 [0,1,2,3,4,5]

This order of returned indices is kept because the function is
called "lags" i.e. the nth lag is n steps behind the original.

C<$step> and C<$nlags> must be positive. C<$nthdim> can be
negative and will then be counted from the last dim backwards
in the usual way (-1 = last dim).

=for bad

lags does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*lags = \&PDL::lags;






=head2 splitdim

=for sig

  Signature: (P(); C(); PDL_Indx nthdim;PDL_Indx nsp)

=for ref

Splits a dimension in the parent ndarray (opposite of L<clump|PDL::Core/clump>).
As of 2.076, throws exception if non-divisible C<nsp> given, and can
give negative C<nthdim> which then counts backwards.

=for example

After

 $y = $x->splitdim(2,3);

the expression

 $y->at(6,4,m,n,3,6) == $x->at(6,4,m+3*n)

is always true (C<m> has to be less than 3).

=for bad

splitdim does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*splitdim = \&PDL::splitdim;






=head2 rotate

=for sig

  Signature: (x(n); indx shift(); [oca]y(n))

=for ref

Shift vector elements along with wrap. Flows data back&forth.

=for bad

rotate does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rotate = \&PDL::rotate;






=head2 broadcastI

=for sig

  Signature: (P(); C(); PDL_Indx id; PDL_Indx whichdims[])

=for ref

internal

Put some dimensions to a broadcastid.

=for example

 $y = $x->broadcastI(0,1,5); # broadcast over dims 1,5 in id 1

=for bad

broadcastI does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*broadcastI = \&PDL::broadcastI;






=head2 unbroadcast

=for sig

  Signature: (P(); C(); PDL_Indx atind)

=for ref

All broadcasted dimensions are made real again.

See [TBD Doc] for details and examples.

=for bad

unbroadcast does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*unbroadcast = \&PDL::unbroadcast;





#line 1996 "slices.pd"

=head2 dice

=for ref

Dice rows/columns/planes out of a PDL using indexes for
each dimension.

This function can be used to extract irregular subsets
along many dimension of a PDL, e.g. only certain rows in an image,
or planes in a cube. This can of course be done with
the usual dimension tricks but this saves having to
figure it out each time!

This method is similar in functionality to the L</slice>
method, but L</slice> requires that contiguous ranges or ranges
with constant offset be extracted. ( i.e. L</slice> requires
ranges of the form C<1,2,3,4,5> or C<2,4,6,8,10>). Because of this
restriction, L</slice> is more memory efficient and slightly faster
than dice

=for usage

 $slice = $data->dice([0,2,6],[2,1,6]); # Dicing a 2-D array

The arguments to dice are arrays (or 1D PDLs) for each dimension
in the PDL. These arrays are used as indexes to which rows/columns/cubes,etc
to dice-out (or extract) from the C<$data> PDL.

Use C<X> to select all indices along a given dimension (compare also
L<mslice|PDL::Core/mslice>). As usual (in slicing methods) trailing
dimensions can be omitted implying C<X>'es for those.

=for example

 pdl> $x = sequence(10,4)
 pdl> p $x
 [
  [ 0  1  2  3  4  5  6  7  8  9]
  [10 11 12 13 14 15 16 17 18 19]
  [20 21 22 23 24 25 26 27 28 29]
  [30 31 32 33 34 35 36 37 38 39]
 ]
 pdl> p $x->dice([1,2],[0,3]) # Select columns 1,2 and rows 0,3
 [
  [ 1  2]
  [31 32]
 ]
 pdl> p $x->dice(X,[0,3])
 [
  [ 0  1  2  3  4  5  6  7  8  9]
  [30 31 32 33 34 35 36 37 38 39]
 ]
 pdl> p $x->dice([0,2,5])
 [
  [ 0  2  5]
  [10 12 15]
  [20 22 25]
  [30 32 35]
 ]

As this is an index function, any modifications to the
slice will change the parent (use the C<.=> operator).

=cut

sub PDL::dice {

        my $self = shift;
        my @dim_indexes = @_;  # array of dimension indexes

        # Check that the number of dim indexes <=
        #    number of dimensions in the PDL
        my $no_indexes = scalar(@dim_indexes);
        my $noDims = $self->getndims;
        barf("PDL::dice: Number of index arrays ($no_indexes) not equal to the dimensions of the PDL ($noDims")
                         if $no_indexes > $noDims;
        my $index;
        my $pdlIndex;
        my $outputPDL=$self;
        my $indexNo = 0;

        # Go thru each index array and dice the input PDL:
        foreach $index(@dim_indexes){
                $outputPDL = $outputPDL->dice_axis($indexNo,$index)
                        unless !ref $index && $index eq 'X';

                $indexNo++;
        }

        return $outputPDL;
}
*dice = \&PDL::dice;

=head2 dice_axis

=for ref

Dice rows/columns/planes from a single PDL axis (dimension)
using index along a specified axis

This function can be used to extract irregular subsets
along any dimension, e.g. only certain rows in an image,
or planes in a cube. This can of course be done with
the usual dimension tricks but this saves having to
figure it out each time!

=for usage

 $slice = $data->dice_axis($axis,$index);

=for example

 pdl> $x = sequence(10,4)
 pdl> $idx = pdl(1,2)
 pdl> p $x->dice_axis(0,$idx) # Select columns
 [
  [ 1  2]
  [11 12]
  [21 22]
  [31 32]
 ]
 pdl> $t = $x->dice_axis(1,$idx) # Select rows
 pdl> $t.=0
 pdl> p $x
 [
  [ 0  1  2  3  4  5  6  7  8  9]
  [ 0  0  0  0  0  0  0  0  0  0]
  [ 0  0  0  0  0  0  0  0  0  0]
  [30 31 32 33 34 35 36 37 38 39]
 ]

The trick to using this is that the index selects
elements along the dimensions specified, so if you
have a 2D image C<axis=0> will select certain C<X> values
- i.e. extract columns

As this is an index function, any modifications to the
slice will change the parent.

=cut

sub PDL::dice_axis {
  my($self,$axis,$idx) = @_;
  my $ix = PDL->topdl($idx);
  barf("dice_axis: index must be <=1D") if $ix->getndims > 1;
  return $self->mv($axis,0)->index1d($ix)->mv(0,$axis);
}
*dice_axis = \&PDL::dice_axis;
#line 1700 "Slices.pm"


=head2 slice

=for sig

  Signature: (P(); C(); pdl_slice_args *arglist)

=for usage

  $slice = $data->slice([2,3],'x',[2,2,0],"-1:1:-1", "*3");

=for ref

Extract rectangular slices of an ndarray, from a string specifier,
an array ref specifier, or a combination.

C<slice> is the main method for extracting regions of PDLs and
manipulating their dimensionality.  You can call it directly or
via the L<NiceSlice|PDL::NiceSlice> source prefilter that extends
Perl syntax to include array slicing.

C<slice> can extract regions along each dimension of a source PDL,
subsample or reverse those regions, dice each dimension by selecting a
list of locations along it, or basic PDL indexing routine.  The
selected subfield remains connected to the original PDL via dataflow.
In most cases this neither allocates more memory nor slows down
subsequent operations on either of the two connected PDLs.

You pass in a list of arguments.  Each term in the list controls
the disposition of one axis of the source PDL and/or returned PDL.
Each term can be a string-format cut specifier, a list ref that
gives the same information without recourse to string manipulation,
or a PDL with up to 1 dimension giving indices along that axis that
should be selected.

If you want to pass in a single string specifier for the entire
operation, you can pass in a comma-delimited list as the first
argument.  C<slice> detects this condition and splits the string
into a regular argument list.  This calling style is fully
backwards compatible with C<slice> calls from before PDL 2.006.

B<STRING SYNTAX>

If a particular argument to C<slice> is a string, it is parsed as a
selection, an affine slice, or a dummy dimension depending on the
form.  Leading or trailing whitespace in any part of each specifier is
ignored (though it is not ignored within numbers).

=over 3

=item C<< '' >>, C<< : >>, or C<< X >> -- keep

The empty string, C<:>, or C<X> cause the entire corresponding
dimension to be kept unchanged.

=item C<< <n> >> -- selection

A single number alone causes a single index to be selected from the
corresponding dimension.  The dimension is kept (and reduced to size
1) in the output.

=item C<< (<n>) >> -- selection and collapse

A single number in parenthesis causes a single index to be selected
from the corresponding dimension.  The dimension is discarded
(completely eliminated) in the output.

=item C<< <n>:<m> >> -- select an inclusive range

Two numbers separated by a colon selects a range of values from the
corresponding axis, e.g. C<< 3:4 >> selects elements 3 and 4 along the
corresponding axis, and reduces that axis to size 2 in the output.
Both numbers are regularized so that you can address the last element
of the axis with an index of C< -1 >.  If, after regularization, the
two numbers are the same, then exactly one element gets selected (just
like the C<< <n> >> case).  If, after regulariation, the second number
is lower than the first, then the resulting slice counts down rather
than up -- e.g. C<-1:0> will return the entire axis, in reversed
order.

=item C<< <n>:<m>:<s> >> -- select a range with explicit step

If you include a third parameter, it is the stride of the extracted
range.  For example, C<< 0:-1:2 >> will sample every other element
across the complete dimension.  Specifying a stride of 1 prevents
autoreversal -- so to ensure that your slice is *always* forward
you can specify, e.g., C<< 2:$n:1 >>.  In that case, an "impossible"
slice gets an Empty PDL (with 0 elements along the corresponding
dimension), so you can generate an Empty PDL with a slice of the
form C<< 2:1:1 >>.

=item C<< *<n> >> -- insert a dummy dimension

Dummy dimensions aren't present in the original source and are
"mocked up" to match dimensional slots, by repeating the data
in the original PDL some number of times.  An asterisk followed
by a number produces a dummy dimension in the output, for
example C<< *2 >> will generate a dimension of size 2 at
the corresponding location in the output dim list.  Omitting
the number (and using just an asterisk) inserts a dummy dimension
of size 1.

=back

B<ARRAY REF SYNTAX>

If you feed in an ARRAY ref as a slice term, then it can have
0-3 elements.  The first element is the start of the slice along
the corresponding dim; the second is the end; and the third is
the stepsize.  Different combinations of inputs give the same
flexibility as the string syntax.

=over 3

=item C<< [] >> - keep dim intact

An empty ARRAY ref keeps the entire corresponding dim

=item C<< [ 'X' ] >> - keep dim intact

=item C<< [ '*',$n ] >> - generate a dummy dim of size $n

If $n is missing, you get a dummy dim of size 1.

=item C<< [ $dex, , 0 ] >> - collapse and discard dim

C<$dex> must be a single value.  It is used to index
the source, and the corresponding dimension is discarded.

=item C<< [ $start, $end ] >> - collect inclusive slice

In the simple two-number case, you get a slice that runs
up or down (as appropriate) to connect $start and $end.

=item C<< [ $start, $end, $inc ] >> - collect inclusive slice

The three-number case works exactly like the three-number
string case above.

=back

B<PDL args for dicing>

If you pass in a 0- or 1-D PDL as a slicing argument, the
corresponding dimension is "diced" -- you get one position
along the corresponding dim, per element of the indexing PDL,
e.g. C<< $x->slice( pdl(3,4,9)) >> gives you elements 3, 4, and
9 along the 0 dim of C<< $x >>.

Because dicing is not an affine transformation, it is slower than
direct slicing even though the syntax is convenient.

=for example

 $x->slice('1:3');  #  return the second to fourth elements of $x
 $x->slice('3:1');  #  reverse the above
 $x->slice('-2:1'); #  return last-but-one to second elements of $x

 $x->slice([1,3]);  # Same as above three calls, but using array ref syntax
 $x->slice([3,1]);
 $x->slice([-2,1]);

=for bad

slice does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 2315 "slices.pd"
sub PDL::slice {
    my ($source, @others) = @_;
    for my $i(0..$#others) {
      my $idx = $others[$i];
      if (ref $idx eq 'ARRAY') {
        my @arr = map UNIVERSAL::isa($_, 'PDL') ? $_->flat->at(0) : $_, @{$others[$i]};
        $others[$i] = \@arr;
        next;
      }
      next if !( blessed($idx) && $idx->isa('PDL') );
      # Deal with dicing.  This is lame and slow compared to the
      # faster slicing, but works okay.  We loop over each argument,
      # and if it's a PDL we dispatch it in the most straightforward
      # way.  Single-element and zero-element PDLs are trivial and get
      # converted into slices for faster handling later.
      barf("slice: dicing parameters must be at most 1D (arg $i)\n")
        if $idx->ndims > 1;
      my $nlm = $idx->nelem;
      if($nlm > 1) {
         #### More than one element - we have to dice (darn it).
         $source = $source->mv($i,0)->index1d($idx)->mv(0,$i);
         $others[$i] = '';
      }
      elsif($nlm) {
         #### One element - convert to a regular slice.
         $others[$i] = $idx->flat->at(0);
      }
      else {
         #### Zero elements -- force an extended empty.
         $others[$i] = "1:0:1";
      }
    }
    PDL::_slice_int($source,my $o=$source->initialize,\@others);
    $o;
}
#line 1911 "Slices.pm"

*slice = \&PDL::slice;






=head2 diagonal

=for sig

  Signature: (P(); C(); PDL_Indx whichdims[])

=for ref

Returns the multidimensional diagonal over the specified dimensions.

The diagonal is placed at the first (by number) dimension that is
diagonalized.
The other diagonalized dimensions are removed. So if C<$x> has dimensions
C<(5,3,5,4,6,5)> then after

=for usage

 $d = $x->diagonal(dim1, dim2,...)

=for example

 $y = $x->diagonal(0,2,5);

the ndarray C<$y> has dimensions C<(5,3,4,6)> and
C<$y-E<gt>at(2,1,0,1)> refers
to C<$x-E<gt>at(2,1,2,0,1,2)>.

NOTE: diagonal doesn't handle broadcastids correctly. XXX FIX

 pdl> $x = zeroes(3,3,3);
 pdl> ($y = $x->diagonal(0,1))++;
 pdl> p $x
 [
  [
   [1 0 0]
   [0 1 0]
   [0 0 1]
  ]
  [
   [1 0 0]
   [0 1 0]
   [0 0 1]
  ]
  [
   [1 0 0]
   [0 1 0]
   [0 0 1]
  ]
 ]

=for bad

diagonal does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 2535 "slices.pd"
sub PDL::diagonal { shift->_diagonal_int(my $o=PDL->null, \@_); $o }
#line 1983 "Slices.pm"

*diagonal = \&PDL::diagonal;







#line 2585 "slices.pd"

=head1 BUGS

For the moment, you can't slice one of the zero-length dims of an
empty ndarray.  It is not clear how to implement this in a way that makes
sense.

Many types of index errors are reported far from the indexing
operation that caused them.  This is caused by the underlying architecture:
slice() sets up a mapping between variables, but that mapping isn't
tested for correctness until it is used (potentially much later).

=head1 AUTHOR

Copyright (C) 1997 Tuomas J. Lukka.  Contributions by
Craig DeForest, deforest@boulder.swri.edu.
Documentation contributions by David Mertens.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut
#line 2018 "Slices.pm"

# Exit with OK status

1;
