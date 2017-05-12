package Moot::Waste::Lexicon;
use Carp;
use strict;

#our @ISA = qw();

1; ##-- be happy

##---------------------------------------------------------------------
## Constructors (DISABLED to avoid ref-counting madness)

sub new {
  confess(__PACKAGE__, "::new(): ERROR: standalone objects not allowed");
}

##---------------------------------------------------------------------
## I/O

## $bool = $lx->load($filename_or_reader_or_fh);
sub load {
  my ($lx,$src) = @_;
  if (!ref($src)) {
    return $lx->_load_file($src);
  }
  elsif (UNIVERSAL::isa($src,'Moot::TokenReader')) {
    return $lx->_load_reader($src);
  }
  ##-- default: treat as filehandle
  my $tr = Moot::TokenReader::Native->new( Moot::tiofText() );
  $tr->from_fh($src);
  return $tr->opened() && $lx->_load_reader($tr);
}

##---------------------------------------------------------------------
## Batch

## $lx = $lx->from_array(\@words)
sub from_array {
  my $lx = shift;
  $lx->insert($_) foreach (map {ref($_) && ref($_) eq 'ARRAY' ? @$_ : $_} @_);
  return $lx;
}


__END__

=pod

=head1 NAME

Moot::Waste::Lexicon - libmoot : WASTE tokenizer : simple word-list lexicon

=head1 SYNOPSIS

  use Moot::Waste;

  ##=====================================================================
  ## Moot::Waste::Lexicon

  $lexer = Moot::Waste::Lexer->new();   ##-- parent lexer object
  $lex = $lexer->abbrevs();             ##-- embedded lexicon
  $lex = $lexer->stopwords();           ##-- embedded lexicon
  $lex = $lexer->conjunctions();        ##-- embedded lexicon

  ##---------------------------------------------------------------------
  ## Basic Access
 
  $lex->clear();			##-- delete all entries
  $lex->insert($str);			##-- insert a string
  $n    = $lex->size();			##-- get number of entries
  $bool = $lex->lookup($str);		##-- check for membership

  ##---------------------------------------------------------------------
  ## I/O
 
  $lex->load($reader);			##-- load from Moot::TokenReader object
  $lex->load($filename);		##-- load from named file (1 word/line)
  $lex->load($fh);			##-- load from filehandle (1 word/line)

  ##---------------------------------------------------------------------
  ## Batch Import/Export
 
  $lex   = $lex->from_array(\@words);	##-- load from perl array
  $words = $lex->to_array($isutf8=0);	##-- dump to perl array

=head1 DESCRIPTION

The Moot::Waste::Lexicon module provides an object-oriented interface to the simple word-list lexica
used by the WASTE tokenization system.  It can ONLY be accessed by means of an embedding Moot::Waste::Lexer.

=head1 SEE ALSO

Moot(3perl),
Moot::Waste(3perl),
Moot::Waste::Lexer(3perl),
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

