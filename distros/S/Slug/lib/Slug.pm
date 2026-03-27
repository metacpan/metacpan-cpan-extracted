package Slug;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(
    slug
    slug_ascii
    slug_custom
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

require XSLoader;
XSLoader::load('Slug', $VERSION);

sub include_dir {
    my $dir = $INC{'Slug.pm'};
    $dir =~ s{Slug\.pm$}{Slug/include};
    return $dir;
}

1;

__END__

=encoding utf8

=head1 NAME

Slug - XS URL slug generator with custom ops

=head1 SYNOPSIS

    use Slug qw(slug slug_ascii slug_custom);

    my $s = slug("Hello World!");                  # "hello-world"
    my $u = slug("Привет мир", "_");               # "privet-mir"
    my $a = slug_ascii("naive cafe");              # "naive cafe"
    my $c = slug_custom("My Title", {              # "my-title"
        separator  => '-',
        max_length => 50,
        lowercase  => 1,
    });

=head1 DESCRIPTION

Slug is a fast XS URL slug generator. It converts arbitrary UTF-8 strings into
URL-safe, SEO-friendly slugs. Uses custom ops on Perl 5.14+ for zero-overhead
dispatch.

=head1 FUNCTIONS

=head2 slug($string)

=head2 slug($string, $separator)

Generate a URL slug from the input string. Transliterates Unicode to ASCII,
lowercases, and replaces non-alphanumeric characters with the separator
(default: C<->).

=head2 slug_ascii($string)

Transliterate Unicode characters to their ASCII equivalents without slugifying.
Preserves spaces, punctuation, and case.

=head2 slug_custom($string, \%options)

Generate a slug with full control over the process.

=head2 include_dir()

Returns the path to the installed C header files.

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
