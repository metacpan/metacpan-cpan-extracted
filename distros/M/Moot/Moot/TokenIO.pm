package Moot::TokenIO;
use Moot::TokenReader;
use Moot::TokenReader::Native;
use Moot::TokenReader::XML;
use Moot::TokenWriter;
use Moot::TokenWriter::Native;
use Moot::TokenWriter::XML;
use strict;


1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::TokenIO - libmoot : Token I/O

=head1 SYNOPSIS

  use Moot::TokenIO;

  ##--------------------------------------------------------------------
  ## Format Parsing

  $fmt  = Moot::TokenIO::parse_format_string($fmtString);
  $fmt  = Moot::TokenIO::guess_filename_format($filename);
  $bool = Moot::TokenIO::is_empty_format($fmt);
  $fmt  = Moot::TokenIO::sanitize_format($fmt, $fmt_implied, $fmt_default);
  $fmt  = Moot::TokenIO::parse_format_request($str_request, $filename, $fmt_implied, $fmt_default);
  $str  = Moot::TokenIO::format_canonical_string($fmt);

  ##--------------------------------------------------------------------
  ## I/O Constructors (NYI)

  $tr = Moot::TokenIO::new_reader($fmt);
  $tw = Moot::TokenIO::new_reader($fmt);

  $tr = Moot::TokenIO::file_reader($filename, $str_request, $fmt_implied, $fmt_default);
  $tw = Moot::TokenIO::file_writer($filename, $str_request, $fmt_implied, $fmt_default);


=head1 DESCRIPTION

The Moot::TokenIO module provides wrappers for static I/O format parsing methods
included in the libmoot library for Hidden Markov Model decoding.

=head1 SEE ALSO

Moot(3perl),
Moot::TokenReader(3perl),
Moot::TokenReader::Native(3perl),
Moot::TokenReader::XML(3perl),
Moot::TokenWriter(3perl),
Moot::TokenWriter::Native(3perl),
Moot::TokenWriter::XML(3perl),
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

