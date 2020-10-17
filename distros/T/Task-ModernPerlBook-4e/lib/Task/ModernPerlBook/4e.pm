package Task::ModernPerlBook::4e;
use 5.008001;
use strict;
use warnings;

our $VERSION = "1.00";

1;
__END__

=encoding utf-8

=head1 NAME

Task::ModernPerlBook::4e - Install CPAN modules for the Modern Perl book, 4e

=head1 SYNOPSIS

    use Task::ModernPerlBook::4e;

=head1 DESCRIPTION

Task::ModernPerlBook::4e is a bundle of useful CPAN modules mentioned in the
first edition of the Modern Perl book
(L<http://modernperlbooks.com/books/modern_perl/>). Installing this will
install all of them for you.

Note that C<perl5i> is _not_ included, because it's experimental and difficult
to install and C<UNIVERSAL::ref> is excluded, because it currently does not build after Perl 5.25.1.

For the latest edition of the book, see L<http://modernperlbooks.com/>.

=head1 LICENSE

Copyright (C) chromatic.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

chromatic E<lt>chromatic@wgz.orgE<gt>

=cut
