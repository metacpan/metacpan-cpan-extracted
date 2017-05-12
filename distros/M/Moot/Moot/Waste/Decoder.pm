package Moot::Waste::Decoder;
use Moot::TokenWriter;
use Carp;
use strict;

our @ISA = qw(Moot::TokenWriter);

1; ##-- be happy

##======================================================================
## constructors etc

sub DESTROY {
  $_[0]->close();
  $_[0]->SUPER::DESTROY();
}

sub sink {
  my $wd = shift;
  $wd->_set_sink(@_) if (@_);
  return $wd->_get_sink();
}

__END__

=pod

=head1 NAME

Moot::Waste::Decoder - libmoot : WASTE tokenizer : post-Viterbi decoder

=head1 SYNOPSIS

  use Moot::Waste::Decoder;

  ##=====================================================================
  ## Usage

  $wd = Moot::Waste::Decoder->new();    ##-- create a new decoder

  $wd->sink($writer);                   ##-- set low-level TokenWriter object (e.g. Moot::TokenWriterNative)
  $wd->sink();                          ##-- get underlying TokenWriter or undef
  $wd->close();                         ##-- close current output channel (unsets sink, clears buffer)

  $wd->put_token($tok);                 ##-- decode next token

  #... or (almost) any other Moot::TokenWriter method

  ##=====================================================================
  ## Buffer Access (e.g. with no TokenWriter sink)

  $bool = $wd->buffer_empty();          ##-- check whether token-buffer is empty
  $size = $wd->buffer_size();           ##-- number of buffered tokens, O(N)

  $tok  = $wd->buffer_peek();           ##-- peek at first token of buffer
  $bool = $wd->buffer_can_shift();      ##-- true iff first token is safe to shift
  undef = $wd->buffer_shift();          ##-- shifts first element off of buffer
  $toks = $wd->buffer_flush($force=0);  ##-- get all (safe) tokens from buffer

=head1 DESCRIPTION

The Moot::Waste::Decoder module provides an object-oriented interface to the WASTE tokenization
system's rule-based post-Viterbi decoder stage.

=head1 SEE ALSO

Moot(3perl),
Moot::Waste(3perl),
Moot::Waste::Scanner(3perl),
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

