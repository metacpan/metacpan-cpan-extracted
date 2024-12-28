#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::CCS::Ops;

our @EXPORT_OK = qw(ccs_binop_align_block_mia );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '1.23.29';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::CCS::Ops $VERSION;






#line 13 "ccsops.pd"


#use PDL::CCS::Version;
use strict;

=pod

=head1 NAME

PDL::CCS::Ops - Low-level binary operations for compressed storage sparse PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Utils;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut
#line 46 "Ops.pm"






=head1 FUNCTIONS

=cut




#line 51 "ccsops.pd"

*ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices
#line 63 "Ops.pm"



#line 949 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"



=head2 ccs_binop_align_block_mia

=for sig

  Signature: (
    indx ixa(Ndims,NnzA); indx ixb(Ndims,NnzB); indx    istate(State);
    indx [o]nzai(NnzC);   indx [o]nzbi(NnzC);   indx [o]ostate(State);
    )


Partially aligns a pair of lexicographically sorted index-vector lists C<$ixa()> and C<$ixb()>,
e.g. for block-wise incremental computation of binary operations over sparse index-encoded PDLs,
assuming missing indices correspond to annihilators.

On return, the vectors C<$nzai> and C<$nzbi> hold indices into C<NnzA> and C<NnzB>
respectively, and are constructed such that:

 ($ixa(,$nzai->slice("0:$nzci_max")) == $ixb(,$nzbi->slice("0:$nzci_max"))

At most C<NnzC> alignments are performed, and alignment ceases
as soon as any of the PDLs C<$ixa()>, C<$ixb()>, C<$nzai()>, or C<$nzbi()>
has been exhausted.

The parameters C<$istate()> and C<$ostate()> hold the state of the algorithm,
for incremental block-wise computation at the perl level.  Each state PDL
is a 7-element PDL containing the following values:

 INDEX LABEL       DESCRIPTION
 -----------------------------------------------------------------------
   0   nnzai       minimum offset in NnzA of current $ixa() value
   1   nnzai_nxt   minimum offset in NnzA of next $ixa() value
   2   nnzbi       minimum offset in NnzB of current $ixb() value
   3   nnzbi_nxt   minimum offset in NnzB of next $ixb() value
   4   nnzci       minimum offset in NnzC of current ($ixa(),$ixb()) value pair
   5   nnzci_nxt   minimum offset in NnzC of next ($ixa(),$ixb()) value pair
   6   cmpval      3-way comparison value for current ($ixa(),$ixb()) value pair

For computation of the first block, $istate() can be safely set to C<zeroes(long,7)>.

Repetitions may occur in input index PDLs C<$ixa()> and C<$ixb()>.
If an index-match occurs on such a "run", I<all pairs> of matching values are
added to the output PDLs.

All alignments have been performed if:

 $ostate(0)==$NnzA && $ostate(1)==$NnzB

B<WARNING:> this alignment method ignores index-vectors which are not present
in I<both> C<$ixa()> and C<$ixb()>, which is a Good Thing if your are feeding
the aligned values into an operation for which missing values are annihilators:

 $missinga * $bval     == ($missinga * $missingb)  for each $bval \in $b, and
 $aval     * $missingb == ($missinga * $missingb)  for each $aval \in $a

This ought to be the case for all operations if missing values are C<BAD> (see L<PDL::Bad>),
but might cause unexpected results if e.g. missing values are zero and the operation
in question is addition.



=for bad

ccs_binop_align_block_mia does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 138 "Ops.pm"



#line 951 "/usr/lib/x86_64-linux-gnu/perl5/5.36/PDL/PP.pm"

*ccs_binop_align_block_mia = \&PDL::ccs_binop_align_block_mia;
#line 145 "Ops.pm"



#line 220 "ccsops.pd"


##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

No support for (pseudo)-threading.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

All other parts Copyright (C) 2007-2024, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl)

=cut
#line 193 "Ops.pm"






# Exit with OK status

1;
