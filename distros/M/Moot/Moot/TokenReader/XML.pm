package Moot::TokenReader::XML;
use strict;

our @ISA = qw(Moot::TokenReader);

1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::TokenReader::XML - libmoot: Token I/O: reader: built-in XML format

=head1 SYNOPSIS

  use Moot::TokenReader::XML;

  ##=====================================================================
  ## Usage

  $tr = Moot::TokenReader::XML->new($fmt);     ##-- constructor

  $tr->from_file($filename);		       ##-- open a named file
  $sent = $tr->get_sentence();		       ##-- read next sentence
  $tr->close();			               ##-- close current input source

  #... or any other Moot::TokenReader method

=head1 DESCRIPTION

The Moot::TokenReader::XML module provides wrappers for XML
word- and sentence-input streams as included in the
libmoot library for Hidden Markov Model decoding.

Moot::TokenReader::XML inherits from
L<Moot::TokenReader|Moot::TokenReader>
and supports all
L<Moot::TokenReader|Moot::TokenReader>
API methods.

=head2 File Format

See L<mootfiles(5)|mootfiles>.


=head1 SEE ALSO

Moot::TokenReader::Native(3perl),
Moot::TokenReader(3perl),
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

