package String::Strip;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	     StripLSpace
	     StripTSpace
	     StripLTSpace
	     StripSpace
);
$VERSION = '1.02';

bootstrap String::Strip $VERSION;

1;
__END__

=head1 NAME

String::Strip - Perl extension for fast, commonly used, string operations

=head1

=head1 SYNOPSIS

  use String::Strip;

  ...

  StripLTSpace($a);
  StripTSpace($a);
  StripLSpace($a);
  StripSpace($a);


=head1 DESCRIPTION

StripLTSpace - Removes Leading and Trailing spaces from given string

StripTSpace - Removes Trailing spaces from given string

StripLSpace - Removes Leading spaces from given string

StripSpace - Removes all spaces from given string

I do these things often, and these routines tend to be about 35%
faster than the corresponding regex methods.

=head1 MAINTAINER

http://search.cpan.org/~phred

=head1 AUTHOR

Brent B. Powers (B2Pi), Powers@B2Pi.com

Copyright(c) 1999,2000 Brent B. Powers. All rights reserved. This
program is free software, you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
