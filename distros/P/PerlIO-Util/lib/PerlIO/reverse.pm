package PerlIO::reverse;
use strict;
require PerlIO::Util;
1;
__END__

=encoding utf-8

=head1 NAME

PerlIO::reverse - Reads lines backward

=head1 SYNOPSIS

	open my $rev, '<:reverse', 'foo.txt';
	print while <$rev>; # print contents reversely

=head1 DESCRIPTION

The C<:reverse> layer reads lines backward like C<tac(1)>.

=head1 EXAMPLE

Here is a minimal implementation of C<tac(1)>.

	#!/usr/bin/perl -w
	# Usage: $0 files...
	use open IN => ':reverse';
	print while <>;
	__END__

=head1 NOTE

=over 4

=item *

This layer cannot deal with unseekable filehandles and layers: tty,
C<:gzip>, C<:dir>, etc.

=item *

This layer is partly incompatible with Win32 system. You have to call
B<binmode($fh)> before pushing it dynamically.

=back

=head1 SEE ALSO

L<PerlIO::Util>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji (at) cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji (at) cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
