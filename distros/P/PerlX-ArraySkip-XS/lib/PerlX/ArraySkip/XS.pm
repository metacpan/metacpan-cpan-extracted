package PerlX::ArraySkip::XS;

use 5.008000;
use strict;
use warnings;

use Exporter 'import';

our %EXPORT_TAGS = (
	all      => [qw( arrayskip )],
	default  => [qw( arrayskip )],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };
our @EXPORT    = @{ $EXPORT_TAGS{default} };

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

require XSLoader;
XSLoader::load('PerlX::ArraySkip::XS', $VERSION);

1;
__END__

=head1 NAME

PerlX::ArraySkip::XS - XS backend for PerlX::ArraySkip

=head1 SYNOPSIS

  use PerlX::ArraySkip;

=head1 DESCRIPTION

Nothing to see here; move along.

=head1 SEE ALSO

L<PerlX::ArraySkip>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

