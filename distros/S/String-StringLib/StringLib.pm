package String::StringLib;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use String::Strip;

require Exporter;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	     StripLSpace
	     StripTSpace
	     StripLTSpace
	     StripSpace
);
$VERSION = '1.02';

1;

sub StripLSpace ( $ ) { String::Strip::StripLSpace($_[0]); }

sub StripTSpace ( $ ) { String::Strip::StripTSpace($_[0]); }

sub StripLTSpace ( $ ) { String::Strip::StripLTSpace($_[0]); }

sub StripSpace ( $ ) { String::Strip::StripSpace($_[0]); }

__END__

=head1 NAME

String::StringLib - Perl extension for fast, commonly used, string
operations

Use of String::StringLib is deprecated as of version 1.01. Please see
String::Strip (version 1.01 or better) instead.

=head1 AUTHOR

Brent B. Powers (B2Pi), Powers@B2Pi.com

Copyright(c) 1999,2000 Brent B. Powers. All rights reserved. This
program is free software, you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), String::Strip

=cut
