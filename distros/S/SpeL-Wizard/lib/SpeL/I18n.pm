# -*- cperl -*-
# ABSTRACT: Base class for localizations


use strict;
use warnings;
package SpeL::I18n;

use parent 'Locale::Maketext';

our %Lexicon =
  (
   '_AUTO'            => 1,
   'title'            => 'title',
   'author'           => 'author',
   'page'             => 'page',
   'part'             => 'part',
   'chapter'          => 'chapter', 
   'appendix'         => 'appendix', 
   'section'          => 'section',
   'subsection'       => 'subsection',
   'subsubsection'    => 'subsection',
   'subsubsubsection' => 'subsection',
   'footnote'         => 'footnote',
   'figure'           => 'figure',
   'table'            => 'table',
   'equation'         => 'equation',
   'exercise'         => 'exercise',
   'listing'          => 'listing',
   'dotdotdot'        => 'and so on until',
   'pi'               => 'pie',
   'infty'            => 'infinity',
   '+'                => 'plus',
   '-'                => 'minus',
   'plusminus'        => 'plus or minus',
   '%'                => 'percent',
   '*'                => 'times',
   '='                => ',equals,',
   'approx'           => ',approximately equals,',
   'notequal'         => ',not equal to,',
   'equivalent'       => 'is equivalent with',
   '<'                => 'is smaller than',
   '<<'               => 'is much smaller than',
   '>'                => 'is greater than',
   '>>'               => 'is much greater than',
   '<='               => 'is smaller than or equal to',
   '>='               => 'is greater than or equal to',
   '==>'              => ',resulting in',
   '<=='              => ',and this results from',
   '<=>'              => ',and this is equivalent with',
   'log'              => 'the logarithm',
   'logn'             => 'the base [_1] logarithm',
   'ln'               => 'the natural logarithm',
   'sin'              => 'sine' ,
   'cos'              => 'cosine',
   'tan'              => 'tangent',
   'cot'              => 'cotangent',
   'sec'              => 'secant',
   'csc'              => 'cosecant',
   'arcsin'           => 'arcsine',
   'arccos'           => 'arccosine',
   'arctan'           => 'arctangent',
   'arccot'           => 'arccotangent',
   'sinh'             => 'hyperbolic sine',
   'cosh'             => 'hyperbolic cosine',
   'tanh'             => 'hyperbolic tangent',
   'coth'             => 'hyperbolic cotangent',
   'alpha'            => 'α',
   'beta'	      => 'β',
   'gamma'	      => 'γ',
   'delta'	      => 'δ',
   'epsilon'	      => 'ε',
   'zeta'	      => 'ζ',
   'eta'	      => 'η', 
   'theta'            => 'θ', 
   'iota'	      => 'ι',
   'kappa'	      => 'κ', 
   'lambda'	      => 'λ', 
   'mu'		      => 'μ',
   'nu'		      => 'ν',
   'xi'		      => 'ξ',
   'omicron'          => 'ο', 
   'pi'		      => 'π',
   'rho'	      => 'ρ',
   'sigma'	      => 'σ',
   'tau'	      => 'τ',
   'upsilon'	      => 'υ', 
   'phi'	      => 'φ',
   'chi'              => 'χ',
   'psi'              => 'ψ',
   'omega'            => 'ω',
   'And'              => 'and',
   'Function'         => '[_1] of [_2]',
   'Int'              => 'the integral',
   'Limit'            => 'the limit',
   'Max'              => 'the maximum',
   'Min'              => 'the minimum',
   'Limitsexpression' => sub {
     my $lh = $_[0];
     $_[1] = $lh->maketext( $_[1] );
     # with ubound
     defined( $_[3] ) and do {
       return "$_[1] from $_[2] to $_[3], of:";
     };
     return "$_[1] for $_[2], of:";
   },
   'Overbrace'        => '[_1]',
   'Underbrace'       => '[_1]',
   'matrix'           => 'a matrix with elements',
   'bmatrix'          => 'a matrix with elements',
   'pmatrix'          => 'a matrix with elements',
   'smallmatrix'      => 'a matrix with elements',
   'vmatrix'          => 'the determinant of a matrix with elements',
   'Vmatrix'          => 'the norm of a matrix with elements',
   'Mid'              => 'for which:',
   'Overline'         => sub {
     my $lh = $_[0];
     return $_[1] . ' bar';
   },
   'Intpower'         => 'to the power of',
   'Faculty'          => 'faculty',
   'Power'            => sub {
     my $lh = $_[0];
     ( $_[1] eq '1' ) and do { return '' };
     ( $_[1] eq '2' ) and do { return ' square' };
     ( $_[1] eq '3' ) and do { return ' cube' };
     return ' to the power of ' . $_[1];
   },
   'Transposed'       => 'transposed',
   'Cancels'          => 'which cancels',
   'Sum'              => 'the summation',
   'Squareroot'       => sub {
     my $lh = $_[0];
     ( $_[1] eq '2' ) and do { return "the square root of $_[2]"; };
     ( $_[1] eq '3' ) and do { return "the 3rd root of $_[2]"; };
     return "the $_[1]th root of $_[2]";
   },
   'Div' => '[_1], over [_2]',
   'In' => ' element of ',
   'Leadsto' => ' is associated with ',
   'To' => ' going to ',
   'Absval' => sub {
     # my $lh = $_[0];
     return ' the absolute value of ' . $_[1];
   },
   'Norm' => sub {
     return ' the norm of ' . $_[1];
   },
   'Subjectto' => sub {
     return $_[1] . " subject to ";
   },
   'Re' => sub {
     # my $lh = $_[0];
     return ' Re ' . $_[1];
   },
   'Im' => sub {
     # my $lh = $_[0];
     return ' Im ' . $_[1];
   },
   'Interval' => sub {
     # my $lh = $_[0];
     return "the closed interval from $_[2] to $_[3]"
       if ( $_[1] eq 'cc' );
     return "the open interval from $_[2] to $_[3]"
       if ( $_[1] eq 'oo' );
     return "the half open interval from $_[2] (not included) to $_[3]"
       if ( $_[1] eq 'oc' );
     return "the half open interval from $_[2] to $_[3] (not included)"
       if ( $_[1] eq 'co' );
     return 'Error: wrong interval';
   },
   'Setenum' => 'a set consisting of [_1]',
   'Setdesc' => 'a set containing elements [_1]',
   'Arg'     => 'arg [_1]',
   'Unitof'  => 'the unit of [_1]',
   'Sim'     => 'is proportional to',
  );

our $lh;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SpeL::I18n - Base class for localizations

=head1 VERSION

version 20250511.1428

=head1 SYNOPSYS

Provides text maker for different languages; This is the default one, that is used for English

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
