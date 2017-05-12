package Moot::Waste::Lexer;
use Moot::TokenReader;
use Moot::Waste::Lexicon;
use Carp;
use strict;

our @ISA = qw(Moot::TokenReader);

1; ##-- be happy

##======================================================================
## constructors etc

sub DESTROY {
  $_[0]->close();
  $_[0]->SUPER::DESTROY();
}

sub scanner {
  my $lexer = shift;
  $lexer->_set_scanner(@_) if (@_);
  return $lexer->_get_scanner();
}

sub get_sentence {
  confess(__PACKAGE__, "::get_sentence() method not supported");
}

__END__

=pod

=head1 NAME

Moot::Waste::Lexer - libmoot : WASTE tokenizer : mid-level lexer

=head1 SYNOPSIS

  use Moot::Waste::Lexer;

  ##=====================================================================
  ## Usage

  $wl = Moot::Waste::Lexer->new();    ##-- create a new lexer

  $wl->scanner($scanner);	      ##-- set low-level TokenReader object (e.g. Moot::WasteScanner)
  $wl->scanner();	              ##-- get underlying scanner or undef
  $wl->close();                       ##-- close current input source (unsets scanner)

  $wl->dehyphenate($bool);	      ##-- enable/disable automatic dehyhpenation

  $tok = $wl->get_token();            ##-- read next token
  $buf = $wl->get_sentence();         ##-- read all remaining tokens as a list

  #... or (almost) any other Moot::TokenReader method

  ##=====================================================================
  ## Lexica (see Moot::Waste::Lexicon)

  $lex = $wl->stopwords();
  $lex = $wl->abbrevs();
  $lex = $wl->conjunctions();

=head1 DESCRIPTION

The Moot::Waste::Lexer module provides an object-oriented interface to the WASTE tokenization
system's mid-level rule-based segment classification stage.

=head1 SEE ALSO

Moot(3perl),
Moot::Waste(3perl),
Moot::Waste::Scanner(3perl),
waste(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

