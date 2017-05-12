package PerlIO::dir;
use strict;
require PerlIO::Util;
1;
__END__

=encoding utf-8

=head1 NAME

PerlIO::dir - Reads directories

=head1 SYNOPSIS

	open my $dirh, '<:dir', '.';

	binmode $dirh, ':encoding(cp932)'; # OK

	my @dirs = <$dirh>; # added "\n" at the end of the name
	chomp @dirs; # if necessary

=head1 DESCRIPTION

C<PerlIO::dir> provides an interface to directory reading functions,
C<opendir()>, C<readdir()>, C<rewinddir> and C<closedir()>.

However, there is an important difference between C<:dir> and Perl's
C<readdir()>. This layer B<appends a newline code>, C<\n>, to the end of
the name, because C<readline()> requires input separators. Call C<chomp()>
if necessary.

You can use C<seek($dirh, 0, 0)> for C<rewinddir()>. 

=head1 SEE ALSO

L<perlfunc/opendir>, L<perlfunc/readdir>, L<perlfunc/rewinddir>,
L<perlfunc/closedir>.

L<PerlIO::Util>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji (at) cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji (at) cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
