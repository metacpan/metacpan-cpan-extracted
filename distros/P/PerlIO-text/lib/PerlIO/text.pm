package PerlIO::text;
{
  $PerlIO::text::VERSION = '0.007';
}
use 5.008;
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;



=pod

=head1 NAME

PerlIO::text

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 open my $fh, '<:text(UTF-16LE)', $filename;

=head1 DESCRIPTION

This module provides a textual pseudo-layer. Instead of pushing itself, it pushes the right layers to open text files in the specified encoding.

=encoding utf8

=head1 SYNTAX

This modules does not have to be loaded explicitly, it will be loaded automatically by using it in an open mode.  The module has the following general syntax: C<:text(charset)>. C<charset> is mandatory and without it this module will give an error. Any character-set known to L<Encode> may be given as an argument.

=head1 PHILOSPHY

This modules tried to Do The Right Thing™. That means that it won't do the same on all platforms, and that it may do something smarter in the future (such as Unicode normalization).

=head1 RATIONALE

At first sight this module may seem merely a wrapper around C<:encoding>, and in fact on unix it pretty much is. Its main reason of existence is that many multibyte encodings are not crlf safe, resulting is issues on Windows. A mode of C<< >:encoding(UTF-16LE) >> does the wrong thing by doing crlf translation B<after> the UTF-16 encoding, this causes an output that is not valid UTF-16. Instead this module does something along these lines on Windows: C<< >:raw:encoding(UTF-16-LE):crlf >>, which is correct but horrible from a huffmanization point of view and it adds complexity to your code because now the correct open mode depends on the platform. This module abstracts that complication.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

#ABSTRACT: Open a text file portably

