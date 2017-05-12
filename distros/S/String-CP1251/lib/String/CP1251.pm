package String::CP1251;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(lc uc);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('String::CP1251', $VERSION);

# Preloaded methods go here.

1;
__END__
=head1 NAME

String::CP1251 - Perl extension for processing CP1251-encoded string

=head1 SYNOPSIS

  use String::CP1251 qw(lc uc);

=head1 DESCRIPTION

  This module provides several string functions that can be called directly
  or used as importable drop-in replacements for CORE string functions with
  same name. With limitations described below, all functions should act same
  as their "parents" from CORE.

=head1 EXPORT

None by default, all functions are exportable on request.

=head1 LIMITATIONS AND FEATURES

  This module priorities speed, implementing all functions in XS and sacrificing
  universal functionality to process CP1251 with maximum speed. Because of that
  and because this module is specifically target at CP1251 all functions do
  not respect C<use locale> and do not work with Unicode strings.
  Unicode is always returned unchanged and non-Unicode strings
  are always processed as CP1251 codepoints regardless of C<locale> settings.
  All functions only work on 26 Latin letters (English alphabet) and 33 Cyrillic
  letters (Russian alphabet) for now, everything else is returned unchanged as well.
  Support for the rest of Cyrillic from CP1251 will be added if there is enough
  demand for it.

=head1 SEE ALSO

L<perlfunc> documentation for functions with same name.

=head1 AUTHOR

Oleg V. Volkov, E<lt>rowaasr13@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Oleg V. Volkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut