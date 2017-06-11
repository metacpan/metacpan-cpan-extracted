
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Ngrams::Utils;

@EXPORT_OK  = qw( PDL::PP ng_delimit PDL::PP ng_undelimit );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::Ngrams::Utils::VERSION = 0.10;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ngrams::Utils $VERSION;





use strict;

=pod

=head1 NAME

PDL::Ngrams::ngutils - Basic N-Gram utilities for PDL: low-level utilities

=head1 SYNOPSIS

 use PDL;
 use PDL::Ngrams::ngutils;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut







=head1 FUNCTIONS



=cut





=pod

=head1 Delimiter Insertion and Removal

=cut





=head2 ng_delimit

=for sig

  Signature: (toks(NToks); indx boffsets(NBlocks); delims(NDelims); [o]dtoks(NDToks))

Add block-delimiters to a raw token vector

Splices the vector $delims into the vector $toks starting at each index
listed in $boffsets, returning the result as $dtoks.  Values in $boffsets
should be in the range [0..N-1].

For consistency, it should be the case that:

  $NDToks == $NToks + $NBlocks * $NDelims



=for bad

ng_delimit does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut




sub PDL::ng_delimit {
  my ($toks,$boffsets,$delims,$dtoks,$ndtoks) = @_;
  barf('Usage: ng_delimit(toks(NToks), indx boffsets(NBlocks), delims(NDelims), [o]dtoks(NDToks), ndtoks=>NDToks)')
    if (grep {!defined($_)} ($toks,$boffsets,$delims));
  ##
  ##-- basic data
  my @tokdims  = $toks->dims;
  my $NToks    = shift(@tokdims);
  my $NBlocks  = $boffsets->dim(0);
  my $NDelims  = $delims->dim(0);
  ##
  ##-- $ndtoks: maybe compute number of delimiters+tokens
  $ndtoks = $NToks + ($NBlocks * $NDelims)
    if ((!defined($dtoks) || $dtoks->isempty) && (!defined($ndtoks) || $ndtoks <= 0));
  ##
  ##-- $dtoks: maybe allocate
  $dtoks  = $toks->zeroes($toks->type, $ndtoks,@tokdims)
    if (!defined($dtoks) || $dtoks->isempty);
  ##
  ##-- underlying low-level call
  &PDL::_ng_delimit_int($toks,$boffsets,$delims,$dtoks);
  return $dtoks;
}


*ng_delimit = \&PDL::ng_delimit;





=head2 ng_undelimit

=for sig

  Signature: (dtoks(NDToks); indx boffsets(NBlocks); int NDelims(); [o]toks(NToks))

Remove block-delimiters from a delimited token vector.

Removes chunks of length $delims from the vector $toks starting at each index
listed in $boffsets, returning the result as $toks.  Values in $boffsets
should be in the range [0..N-1].



=for bad

ng_undelimit does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut




sub PDL::ng_undelimit {
  my ($dtoks,$boffsets,$NDelims,$toks) = @_;
  barf('Usage: ng_delimit(dtoks(NDToks), indx boffsets(NBlocks), NDelims(), [o]toks(NToks))')
    if (grep {!defined($_)} ($dtoks,$boffsets,$NDelims));
  ##
  ##-- $toks: maybe allocate
  if (!defined($toks) || $toks->isempty) {
    $NDelims     = PDL->topdl($NDelims);
    my @dtokdims = $dtoks->dims;
    my $NDToks   = shift(@dtokdims);
    my $NBlocks  = $boffsets->dim(0);
    my $NToks    = $NDToks - ($NDelims->max * $NBlocks);
    $toks        = zeroes($dtoks->type, $NToks,@dtokdims);
  }
  ##
  ##-- underlying low-level call
  &PDL::_ng_undelimit_int($dtoks,$boffsets,$NDelims, $toks);
  return $toks;
}


*ng_undelimit = \&PDL::ng_undelimit;




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Probably many.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2007, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl)

=cut



;



# Exit with OK status

1;

		   