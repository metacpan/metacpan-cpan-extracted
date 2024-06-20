# -*- cperl -*-
# ABSTRACT: class for Dutch localization


use strict;
use warnings;
package SpeL::I18n::nl;

use parent 'SpeL::I18n';

our %Lexicon =
  (
   '_AUTO'            => 1,
   'title'            => 'titel',
   'author'           => 'auteur',
   'part'             => 'deel',
   'chapter'          => 'hoofdstuk',
   'section'          => 'sectie',
   'subsection'       => 'subsectie',
   'subsubsection'    => 'subsectie',
   'subsubsubsection' => 'subsectie',
   'footnote'         => 'voetnoot',
   'dotdotdot'        => 'puntje-puntje-puntje',
   'pi'               => 'pi',
   'infty'            => 'oneindig',
   '+'                => 'plus',
   '-'                => '(min)', # this avoids reading it as 'minuten'
   'plusminus'        => 'plus of min',
   '%'                => 'procent',
   '*'                => 'maal',
   '='                => ',is gelijk aan,',
   'notequal'         => ',is niet gelijk aan,',
   '<'                => 'is kleiner dan',
   '>'                => 'is groter dan',
   '<='               => 'is kleiner dan of gelijk aan',
   '>='               => 'is groter dan of gelijk aan',
   '==>'              => ', en hieruit volgt',
   '<=='              => ', en dit volgt uit',
   '<=>'              => ', wat equivalent is met',
   'sin'              => 'sinus',
   'cos'              => 'cosinus',
   'tan'              => 'tangens',
   'cot'              => 'cotangens',
   'sec'              => 'secans',
   'csc'              => 'cosecans',
   'arcsin'           => 'boogsinus',
   'arccos'           => 'boogcosinus',
   'arctan'           => 'boogtangens',
   'arccot'           => 'boogcotanges',
   'sinh'             => 'hyperbolische sinus',
   'cosh'             => 'hyperbolische cosinus',
   'tanh'             => 'hyperbolische tangens',
   'coth'             => 'hyperbolische cotangens',
   'alpha'            => 'alfa',
   'beta'	      => 'beta',
   'gamma'	      => 'gamma',
   'delta'	      => 'delta',
   'epsilon'	      => 'epsilon',
   'zeta'	      => 'zeita',
   'eta'	      => 'eita',
   'theta'            => 'theita',
   'iota'	      => 'iota',
   'kappa'	      => 'kappa',
   'lambda'	      => 'lambda',
   'mu'		      => 'muu',
   'nu'		      => 'nuu',
   'xi'		      => 'xie',
   'omicron'          => 'omicron',
   'pi'		      => 'pi',
   'rho'	      => 'rho',
   'sigma'	      => 'sigma',
   'tau'	      => 'tau',
   'upsilon'	      => 'upsilon',
   'phi'	      => 'fie',
   'chi'              => 'chchi',
   'psi'              => 'psie',
   'omega'            => 'omega',
   'And'              => 'en',
   'Function'         => '[_1] van [_2]',
   'Int'              => 'de integraal',
   'Limit'            => 'de limiet',
   'Limitsexpression' => sub {
     my $lh = $_[0];
     $_[1] = $lh->maketext( $_[1] );
     # with ubound
     defined( $_[3] ) and do {
       return "$_[1] van $_[2] tot $_[3] van";
     };
     return "$_[1] voor $_[2] van";
   },
   'matrix'           => 'een matrix met elementen',
   'bmatrix'          => 'een matrix met elementen',
   'pmatrix'          => 'een matrix met elementen',
   'smallmatrix'      => 'een matrix met elementen',
   'vmatrix'          => 'de determinant van een matrix met elementen',
   'Vmatrix'          => 'de norm van een matrix met elememten',
   'Mid'              => 'waarvoor geldt:',
   'Overline'         => sub {
     my $lh = $_[0];
     return $_[1] . ' streep';
   },
   'Power'    => sub {
     my $lh = $_[0];
     ( $_[1] eq '1' ) and do { return '' };
     ( $_[1] eq '2' ) and do { return ' kwadraat' };
     ( $_[1] eq '8' ) and do { return ' tot de achtste macht' };
     ( $_[1] =~ /^1\d$/ ) and do { return " tot de $_[1]de macht" };
     return ' tot de macht ' . $_[1];
   },
   'Sum'      => ' de som',
   'Squareroot'       => sub {
     my $lh = $_[0];
     ( $_[1] eq '1' ) and do { return "$_[2]"; };
     ( $_[1] eq '2' ) and do { return "de vierkantswortel van $_[2]"; };
     ( $_[1] eq '8' ) and do { return "de achtste machtswortel van $_[2]" };
     ( $_[1] =~ /^[345679]|1\d$/ ) and do { return "de $_[1]de machtswortel van $_[2]" };
     ( $_[1] =~ /^[2-9]\d+$/ ) and do { return "de $_[1]ste machtswortel van $_[2]" };
     return "de $_[1]-de machtswortel van $_[2]";
   },
   'Div' => '[_1], gedeeld door [_2]',
   'In' => ' element van ',
   'Leadsto' => ' wordt geassocieerd met ',
   'Absval' => sub {
     my $lh = $_[0];
     return ' de absoluute waarde van ' . $_[1];
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
     return "het gesloten interval van $_[2] tot $_[3]"
       if ( $_[1] eq 'cc' );
     return "het open interval van $_[2] tot $_[3]"
       if ( $_[1] eq 'oo' );
     return "het half open interval van $_[2] (niet inbegrepen) tot $_[3]"
       if ( $_[1] eq 'oc' );
     return "het half open interval van $_[2] tot $_[3] (niet inbegrepen)"
       if ( $_[1] eq 'co' );
     return 'Error: wrong interval';
   },
   'Setenum' => 'een verzameling bestaande uit [_1]',
   'Setdesc' => 'een verzameling met elementen [_1]',
   'Arg'     => 'arg [_1]'
  );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SpeL::I18n::nl - class for Dutch localization

=head1 VERSION

version 20240619.1846

=head1 SYNOPSYS

Provides text maker for Dutch;

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
