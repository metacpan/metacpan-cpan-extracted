## -*- Mode: CPerl -*-
##  + CPerl pukes on '/esg'-modifiers.... bummer
##
## $Id$
##
## File: PDL::VectorValued::Dev.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Vector utilities for PDL: development
##======================================================================

package PDL::VectorValued::Dev;
use PDL::Types;
use strict;

##======================================================================
## Export hacks
#use PDL::PP; ##-- do NOT do this!
use Exporter;

our $VERSION = '1.0.17'; ##-- v1.0.4: use perl-reversion from Perl::Version instead
our @ISA = qw(Exporter);
our @EXPORT_OK =
  (
   ##
   ##-- High-level macro expansion
   qw(vvpp_def vvpp_expand),
   ##
   ##-- Type utilities
   qw(vv_indx_sig vv_indx_typedef),
   ##
   ##-- Macro expansion subs
   qw(vvpp_pdlvar_basename),
   qw(vvpp_expand_cmpvec vvpp_cmpvec_code),
   qw(vvpp_expand_cmpval vvpp_cmpval_code),
  );
our %EXPORT_TAGS =
  (
   all     => [@EXPORT_OK],
   default => [@EXPORT_OK],
  );
our @EXPORT    = @{$EXPORT_TAGS{default}};

##======================================================================
## pod: header
=pod

=head1 NAME

PDL::VectorValued::Dev - development utilities for vector-valued PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::VectorValued::Dev;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

PDL::VectorValued::Dev provides some developer utilities for
vector-valued PDLs.  It produces code for processing with PDL::PP.

=cut

##======================================================================
## PP Utiltiies
=pod

=head1 PDL::PP Utilities

=cut

##--------------------------------------------------------------
## undef = vvpp_def($name,%args)
=pod

=head2 vvpp_def($funcName,%args)

Wrapper for pp_def() which calls vvpp_expand() on 'Code' and 'BadCode'
values in %args.

=cut
our @_REAL_TYPES =
	  map { $_->{ppsym} }
	  # Older PDLs:
	  # - no native complex types, did not have real key
	  # Newer PDLs:
	  # - native complex types, have real key
	  grep { ! exists $_->{real} || $_->{real} }
	  @PDL::Types::typehash{PDL::Types::typesrtkeys()};
sub vvpp_def {
  my ($name,%args) = @_;
  foreach (qw(Code BadCode)) {
    $args{$_} = vvpp_expand($args{$_}) if (defined($args{$_}));
  }
  $args{GenericTypes} = \@_REAL_TYPES unless exists $args{GenericTypes};
  PDL::PP::pp_def($name,%args);
}



##--------------------------------------------------------------
## $pp_code = vvpp_expand($vvpp_code)
=pod

=head2 $pp_code = vvpp_expand($vvpp_code)

Expand PDL::VectorValued macros in $vvpp_code.
Currently known PDL::VectorValued macros include:

  MACRO_NAME            EXPANSION_SUBROUTINE
  ----------------------------------------------------------------------
  $CMPVEC(...)          vvpp_expand_cmpvec(...)
  $CMPVAL(...)          vvpp_expand_cmpval(...)
  $LB(...)              vvpp_expand_lb(...)

See the documentation of the individual expansion subroutines
for details on calling conventions.

You can add your own expansion macros by pushing an expansion
manipulating the array

 @PDL::VectorValued::Dev::MACROS

which is just a list of expansion subroutines which take a single
argument (string for Code or BadCode) and should return the expanded
string.

=cut

our @MACROS =
    (
     \&vvpp_expand_cmpvec,
     \&vvpp_expand_cmpval,
     \&vvpp_expand_lb,
     ##
     ## ... more macros here
     );
sub vvpp_expand {
  my $str = shift;
  my ($macro_sub);
  foreach $macro_sub (@MACROS) {
      $str = $macro_sub->($str);
  }
  $str;
}


##--------------------------------------------------------------
## $pp_code = vvpp_expand_cmpvec($vvpp_code)
sub vvpp_expand_cmpvec {
  my $str = shift;
  #$str =~ s{\$CMPVEC\s*\(([^\)]*)\)}{vvpp_cmpvec_code(eval($1))}esg; ##-- nope
  $str =~ s{\$CMPVEC\s*\((.*)\)}{vvpp_cmpvec_code(eval($1))}emg; ##-- single-line macros ONLY
  return $str;
}

##--------------------------------------------------------------
## $pp_code = vvpp_expand_cmpval($vvpp_code)
sub vvpp_expand_cmpval {
  my $str = shift;
  $str =~ s{\$CMPVAL\s*\((.*)\)}{vvpp_cmpval_code(eval($1))}emg; ##-- single-line macros ONLY
  return $str;
}

##--------------------------------------------------------------
## $pp_code = vvpp_expand_lb($vvpp_code)
sub vvpp_expand_lb {
  my $str = shift;
  $str =~ s{\$LB\s*\((.*)\)}{vvpp_lb_code(eval($1))}emg; ##-- single-line macros ONLY
  return $str;
}

##======================================================================
## PP Utilities: Types
=pod

=head1 Type Utilities

=cut

##--------------------------------------------------------------
## $sigtype = vv_indx_sig()
=pod

=head2 vv_indx_sig()

Returns a signature type for representing PDL indices.
For PDL E<gt>= v2.007 this should be C<PDL_Indx>, otherwise it will be C<int>.

=cut

sub vv_indx_sig {
  require PDL::Core;
  return defined(&PDL::indx) ? 'indx' : 'int';
}

##--------------------------------------------------------------
## $sigtype = vv_indx_typedef()
=pod

=head2 vv_indx_typedef()

Returns a C typedef for the C<PDL_Indx> type if running under
PDL E<lt>= v2.007, otherwise just a comment.  You can call this
from client PDL::PP modules as

 pp_addhdr(PDL::VectorValued::Dev::vv_indx_typedef);

=cut

sub vv_indx_typedef {
  require PDL::Core;
  if (defined(&PDL::indx)) {
    return "/*-- PDL_Indx built-in for PDL >= v2.007 --*/\n";
  }
  return "typedef int PDL_Indx; /*-- PDL_Indx typedef for PDL <= v2.007 --*/\n";
}


##======================================================================
## PP Utilities: Macro Expansion
=pod

=head1 Macro Expansion Utilities

=cut

##--------------------------------------------------------------
## vvpp_pdlvar_basename()
=pod

=head2 vvpp_pdlvar_basename($pdlVarString)

Gets basename of a PDL::PP variable by removing leading '$'
and anything at or following the first open parenthesis:

 $base = vvpp_pdlvar_basename('$a(n=>0)'); ##-- $base is now 'a'

=cut

sub vvpp_pdlvar_basename {
  my $varname = shift;
  $varname =~ s/^\s*\$\s*//;
  $varname =~ s/\s*\(.*//;
  return $varname;
}

##--------------------------------------------------------------
## vvpp_cmpvec_code()
=pod

=head2 vvpp_cmpvec_code($vec1,$vec2,$dimName,$retvar,%options)

Returns PDL::PP code for lexicographically comparing two vectors
C<$vec1> and C<$vec2> along the dimension named C<$dim>, storing the
comparison result in the C variable C<$retvar>,
similar to what:

 $retvar = ($vec1 <=> $vec2);

"ought to" do.

Parameters:

=over 4

=item $vec1

=item $vec2

PDL::PP string forms of vector PDLs to be compared.
Need not be physical.

=item $dimName

Name of the dimension along which vectors should be compared.

=item $retvar

Name of a C variable to store the comparison result.

=item $options{cvar1}

=item $options{cvar2}

If specified, temporary values for C<$vec1> (rsp. C<$vec2>)
will be stored in the C variable $options{cvar1} (rsp. C<$options{cvar2}>).
If unspecified, a new locally scoped C variable
C<_vvpp_cmpvec_val1> (rsp. C<_vvpp_cmpvec_val2>) will be declared and used.

=back

=for example

The PDL::PP code for cmpvec() looks something like this:

 use PDL::VectorValued::Dev;
 pp_def('cmpvec',
        Pars => 'a(n); b(n); int [o]cmp()',
        Code => (
                 'int cmpval;'
                 .vvpp_cmpvec_code( '$a()', '$b()', 'n', 'cmpval' )
                 .$cmp() = cmpval'
                );
        );

=cut

sub vvpp_cmpvec_code {
  my ($vec1,$vec2,$dimName,$retvar,%opts) = @_;
  ##
  ##-- sanity checks
  my $USAGE = 'vvpp_cmpvec_code($vec1,$vec2,$dimName,$retvar,%opts)';
  die ("Usage: $USAGE") if (grep {!defined($_)} @_[0,1,2,3]);
  ##
  ##-- get PDL variable basenames
  my $vec1Name = vvpp_pdlvar_basename($vec1);
  my $vec2Name = vvpp_pdlvar_basename($vec2);
  my $ppcode = "\n{ /*-- BEGIN vvpp_cmpvec_code --*/\n";
  ##
  ##-- get C variables
  my ($cvar1,$cvar2);
  if (!defined($cvar1=$opts{var1})) {
      $cvar1   = '_vvpp_cmpvec_val1';
      $ppcode .= " \$GENERIC(${vec1Name}) ${cvar1};\n";
  }
  if (!defined($cvar2=$opts{var2})) {
      $cvar2   = '_vvpp_cmpvec_val2';
      $ppcode .= " \$GENERIC(${vec2Name}) ${cvar2};\n";
  }
  ##
  ##-- generate comparison code
  $ppcode .= (''
	      ." ${retvar}=0;\n"
	      ." loop (${dimName}) %{\n"
	      ."  ${cvar1}=$vec1;\n"
	      ."  ${cvar2}=$vec2;\n"
	      ."  if      (${cvar1} < ${cvar2}) { ${retvar}=-1; break; }\n"
	      ."  else if (${cvar1} > ${cvar2}) { ${retvar}= 1; break; }\n"
	      ." %}\n"
	      ."} /*-- END vvpp_cmpvec_code --*/\n"
	     );
  ##
  ##-- ... and return
  return $ppcode;
}

##--------------------------------------------------------------
## vvpp_cmpval_code()
=pod

=head2 vvpp_cmpval_code($val1,$val2)

Returns PDL::PP expression code for lexicographically comparing two values
C<$val1> and C<$val2>, storing the
comparison result in the C variable C<$retvar>,
similar to what:

 ($vec1 <=> $vec2);

"ought to" do.

Parameters:

=over 4

=item $val1

=item $val2

PDL::PP string forms of values to be compared.
Need not be physical.

=back

=cut

sub vvpp_cmpval_code {
  my ($val1,$val2) = @_;
  ##
  ##-- sanity checks
  my $USAGE = 'vvpp_cmpval_code($val1,$val2)';
  die ("Usage: $USAGE") if (grep {!defined($_)} @_[0,1]);
  ##
  ##-- generate comparison code
  my $ppcode = (''
		."/*-- BEGIN vvpp_cmpval_code --*/ "
		." (($val1) < ($val2) ? -1 : (($val1) > ($val2) ? 1 : 0)) "
		." /*-- END vvpp_cmpvec_code --*/"
	       );
  ##
  ##-- ... and return
  return $ppcode;
}

##--------------------------------------------------------------
## vvpp_lb_code()
=pod

=head2 vvpp_lb_code($find,$vals, $imin,$imax, $retvar, %options)

Returns PDL::PP code for binary lower-bound search for the value $find() in the sorted pdl $vals($imin:$imax-1).
Parameters:

=over 4

=item $find

Value to search for or PDL::PP string form of such a value.

=item $vals

PDL::PP string form of PDL to be searched. $vals should contain a placeholder C<$_>
representing the dimension to be searched.

=item $retvar

Name of a C variable to store the result.
On return, C<$retvar> holds the maximum value for C<$_> in C<$vals($imin:$imax-1)> such that
C<$vals($_=$retvar) E<lt>= $find> and C<$vals($_=$j) E<lt> $find> for all
C<$j> with C<$imin E<lt>= $j E<lt> $retvar>, or C<$imin> if no such value for C<$retvar> exists,
C<$imin E<lt>= $retvar E<lt> $imax>.
In other words,
returns the least index $_ of a match for $find in $vals($imin:$imax-1) whenever a match exists,
otherwise the greatest index whose value in $vals($imin:$imax-1) is strictly less than $find if that exists,
and $imin if all values in $vals($imin:$imax-1) are strictly greater than $find.

=item $options{lovar}

=item $options{hivar}

=item $options{midvar}

=item $options{cmpvar}

If specified, temporary indices and comparison values will be stored in
in the C variables $options{lovar}, $options{hivar}, $options{midvar}, and $options{cmpvar}.
If unspecified, new locally scoped C variables
C<_vvpp_lb_loval> etc. will be declared and used.

=item $options{ubmaxvar}

If specified, should be a C variable to hold the index of the last inspected value for $_
in $vals($imin:$imax-1) strictly greater than $find.

=back

=cut

sub vvpp_lb_code {
  my ($find,$vals,$imin,$imax,$retvar,%opts) = @_;
  ##
  ##-- sanity checks
  my $USAGE = 'vvpp_lb_code($find,$vals,$imin,$imax,$retvar,%opts)';
  die ("Usage: $USAGE") if (grep {!defined($_)} @_[0..4]);
  ##
  ##-- get PDL variable basenames
  my $ppcode = "\n{ /*-- BEGIN vvpp_lb_code --*/\n";
  ##
  ##-- get C variables
  my ($lovar,$hivar,$midvar,$cmpvar);
  if (!defined($lovar=$opts{lovar})) {
      $lovar   = '_vvpp_lb_loval';
      $ppcode .= " long $lovar;";
  }
  if (!defined($hivar=$opts{hivar})) {
      $hivar   = '_vvpp_lb_hival';
      $ppcode .= " long $hivar;";
  }
  if (!defined($midvar=$opts{midvar})) {
      $midvar  = '_vvpp_lb_midval';
      $ppcode .= " long $midvar;";
  }
  if (!defined($cmpvar=$opts{cmpvar})) {
      $cmpvar  = '_vvpp_lb_cmpval';
      $ppcode .= " int $cmpvar;";
  }
  my $ubmaxvar = $opts{ubmaxvar};
  ##
  ##-- generate search code
  (my $val_mid = $vals) =~ s/\$_/${midvar}/;
  (my $val_lo  = $vals) =~ s/\$_/${lovar}/;
  (my $val_hi  = $vals) =~ s/\$_/${hivar}/;
  $ppcode .= join("\n",
		  " $lovar = $imin;",
		  " $hivar = $imax;",
		  #($ubmaxvar ? " $ubmaxvar = -1;" : qw()),
		  " while ($hivar - $lovar > 1) {",
		  "   $midvar = ($hivar + $lovar) >> 1;",
		  "   $cmpvar = ".vvpp_cmpval_code($find, $val_mid).";",
		  "   if ($cmpvar > 0) { $lovar = $midvar; }",
		  ($ubmaxvar
		   ? "   else if ($cmpvar < 0) { $hivar = $midvar; $ubmaxvar = $midvar; }"
		   : qw()),
		  "   else             { $hivar = $midvar; }",
		  " }",
		  " if      (                   $val_lo == $find) $retvar = $lovar;",
		  " else if ($hivar <  $imax && $val_hi == $find) $retvar = $hivar;",
		  " else if ($lovar >= $imin && $val_lo <  $find) $retvar = $lovar;",
		  " else                                          $retvar = $imin;",
		  "} /*-- END vvpp_lb_code --*/\n",
		 );
  ##
  ##-- ... and return
  return $ppcode;
}


1; ##-- make perl happy


##======================================================================
## pod: Functions: low-level
=pod

=head2 Low-Level Functions

Some additional low-level functions are provided in the
PDL::Ngrams::ngutils
package.
See L<PDL::Ngrams::ngutils> for details.

=cut

##======================================================================
## pod: Bugs
=pod

=head1 KNOWN BUGS

=head2 Why not PDL::PP macros?

All of these functions would be more intuitive if implemented directly
as PDL::PP macros, and thus expanded directly by pp_def() rather
than requiring vvpp_def().

Unfortunately, I don't currently have the time to figure out how to
use the (undocumented) PDL::PP macro expansion mechanism.
Feel free to add real macro support.

=cut

##======================================================================
## pod: Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=head1 COPYRIGHT

Copyright (c) 2007-2021, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), PDL::PP(3perl).

=cut
