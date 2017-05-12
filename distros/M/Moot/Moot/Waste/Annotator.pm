package Moot::Waste::Annotator;
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

Moot::Waste::Annotator - libmoot : WASTE tokenizer : pattern-based token annotator

=head1 SYNOPSIS

  use Moot::Waste::Annotator;

  ##=====================================================================
  ## Usage

  $wa = Moot::Waste::Annotator->new();  ##-- create a new annotator

  $wa->sink($writer);                   ##-- set low-level TokenWriter object (e.g. Moot::TokenWriterNative)
  $wa->sink();                          ##-- get underlying TokenWriter or undef
  $wa->close();                         ##-- close current output channel (unsets sink, clears buffer)

  $wa->put_token($tok);                 ##-- decode next token

  #... or (almost) any other Moot::TokenWriter method

  ##=====================================================================
  ## Direct Access (e.g. with no TokenWriter sink)

  $atok = $wa->annotate($tok);          ##-- returns annotated version of $tok

=head1 DESCRIPTION

The Moot::Waste::Annotator module provides an object-oriented interface to the WASTE tokenization
system's simply text-based annotation stage.

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

