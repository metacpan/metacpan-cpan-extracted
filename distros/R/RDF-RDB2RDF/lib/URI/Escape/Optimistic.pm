package URI::Escape::Optimistic;

use strict;
use utf8;

use URI::Escape;
use base qw(Exporter);
our @EXPORT    = qw(uri_escape uri_unescape uri_escape_utf8 uri_escape_optimistic);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

sub uri_escape_optimistic
{
	$_[1] = '^A-Za-z0-9\\-\\._~\\x{80}-\\x{10FFFF}';
	goto \&uri_escape;
}

1;

__END__

=encoding utf8

=head1 NAME

URI::Escape::Optimistic - avoid escaping most characters and hope for the best!

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-RDB2RDF>.

=head1 SEE ALSO

L<RDF::RDB2RDF>, L<URI::Escape>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2012-2013 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

