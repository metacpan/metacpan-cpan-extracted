package Moot::TokenReader;
use Carp;
use strict;

##=====================================================================
## TokenReader: Constructors etc.

sub new {
  confess(__PACKAGE__, "::new(): abstract method called");
}

1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::TokenReader - libmoot: Token I/O: reader

=head1 SYNOPSIS

  use Moot::TokenReader;

  ##=====================================================================
  ## Constructors etc

  $tr = $CLASS->new($fmt)	      ##-- constructor, given TokenIOFormat
  $tr->reset();                       ##-- reset reader data

  ##=====================================================================
  ## Input Selection

  $tr->close();			     ##-- close current input source
  $bool = $tr->opened();             ##-- true iff opened

  $tr->from_file($filename);         ##-- input from named file
  $tr->from_fh($fh);                 ##-- input from filehandle
  $tr->from_string($buffer);         ##-- input from string buffer

  ##=====================================================================
  ## Token-Stream Access

  $token = $tr->get_token();         ##-- get next token or undef on EOF
  $sent  = $tr->get_sentence();      ##-- get next sentence or undef on EOF

  ##=====================================================================
  ## Accessors

  $fmt = $tr->format();              ##-- get/set bitmask of I/O format flags
  $fmt = $tr->format($fmt);

  $name = $tr->name();               ##-- get/set reader (class) name
  $name = $tr->name($name);

  $n = $tr->line_number();           ##-- get/set line number
  $n = $tr->line_number($n);

  $n = $tr->column_number();         ##-- get/set column number
  $n = $tr->column_number($n);

  $n = $tr->byte_number();           ##-- get/set byte offset
  $n = $tr->byte_number($n);


=head1 DESCRIPTION

The Moot::TokenReader module provides wrappers for word- and sentence-oriented input
stream objects included in the libmoot library for Hidden Markov Model decoding.

=head1 SEE ALSO

Moot::TokenReader::Native(3perl),
Moot::TokenWriter(3perl),
Moot::TokenIO(3perl),
Moot(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

