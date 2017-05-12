package PerlIO::excl;
use strict;
require PerlIO::Util;
1;
__END__

=encoding utf-8

=head1 NAME

PerlIO::excl - Creates a file only if it doesn't exist

=head1 SYNOPSIS

	open my $io,  '+<:excl', 'foo.txt';

=head1 DESCRIPTION

C<PerlIO::excl> appends C<O_EXCL> to the open flags.

When you'd like to create a file only if it doesn't exist before, you
can use the C<:excl> layer.

This is a pseudo layer that doesn't be pushed on the layer stack.

=head1 SEE ALSO

L<PerlIO::Util>.

L<perlfunc/sysopen>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji (at) cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji (at) cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
