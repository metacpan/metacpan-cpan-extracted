package Moot::TokenWriter::XML;
use strict;

our @ISA = qw(Moot::TokenWriter);

1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::TokenWriter::XML - libmoot: Token I/O: writer: built-in XML format

=head1 SYNOPSIS

  use Moot::TokenWriter::XML;

  ##=====================================================================
  ## Usage

  $tw = Moot::TokenWriter::XML->new($fmt);     ##-- constructor

  $tw->from_file($filename);		       ##-- open a named file
  $tw->put_sentence($s);		       ##-- write a sentence
  $tw->close();			               ##-- close current output stream

  #... or any other Moot::TokenWriter method

=head1 DESCRIPTION

The Moot::TokenWriter::XML module provides wrappers for XML
word- and sentence-input streams as included in the
libmoot library for Hidden Markov Model decoding.

Moot::TokenWriter::XML inherits from
L<Moot::TokenWriter|Moot::TokenWriter>
and supports all
L<Moot::TokenWriter|Moot::TokenWriter>
API methods.

=head2 File Format

See L<mootfiles(5)|mootfiles>.


=head1 SEE ALSO

Moot::TokenWriter::Native(3perl),
Moot::TokenWriter(3perl),
Moot::TokenIO(3perl),
Moot(3perl),
mootfiles(5),
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

