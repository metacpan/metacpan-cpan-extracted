package PerlIO::creat;
use strict;
require PerlIO::Util;
1;
__END__

=encoding utf-8

=head1 NAME

PerlIO::creat - Creates a file if it doesn't exist

=head1 SYNOPSIS

	open my $io,  '+< :creat', 'foo.txt';

=head1 DESCRIPTION

C<PerlIO::creat> appends C<O_CREAT> to the open flags.

When you'd like to create a file but not to truncate it, you can use 
the C<:creat> layer with an open mode '<' or '+<'.

This is a pseudo layer that doesn't be pushed on the layer stack.

=head1 SEE ALSO

L<PerlIO::Util>.

L<PerlIO::excl>.

L<perlfunc/sysopen>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji (at) cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji (at) cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
