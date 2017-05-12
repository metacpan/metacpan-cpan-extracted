package PerlIO::locale;

use 5.008;
use strict;
use XSLoader;
use PerlIO::encoding;
our $VERSION = '0.10';

XSLoader::load('PerlIO::locale', $VERSION);

1;

__END__

=head1 NAME

PerlIO::locale - PerlIO layer to use the encoding of the current locale

=head1 VERSION

0.07

=head1 SYNOPSIS

    use PerlIO::locale;
    open my $filehandle, '<:locale', $filename or die $!;

=head1 DESCRIPTION

This is mostly a per-filehandle version of the C<open> pragma, when
used under the form

    use open ':locale';

The encoding for the opened file will be set to the encoding corresponding
to the locale currently in effect, if perl can guess it.

=head1 AUTHOR

Copyright (c) 2004, 2005, 2007, 2008, 2011, 2014 Rafael Garcia-Suarez <rgs@consttype.org>,
rewritten by Leon Timmermans <leont@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SOURCE

A git repository for the sources is at L<https://github.com/rgs/PerlIO-locale>.

=head1 SEE ALSO

=over 4

=item * L<open>

=item * L<PerlIO::encoding>

=item * L<I18N::Langinfo>

=back

=cut
