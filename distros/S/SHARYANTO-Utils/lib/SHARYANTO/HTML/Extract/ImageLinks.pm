package SHARYANTO::HTML::Extract::ImageLinks;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.77'; # VERSION

use 5.010;
use strict;
use warnings;

use HTML::Parser;
use URI::URL;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(extract_image_links);

our %SPEC;

$SPEC{extract_image_links} = {
    v => 1.1,
    summary => 'Extract image links from HTML document',
    description => <<'_',

Either specify either url, html.

_
    args => {
        html => {
            schema => 'str*',
            req => 1,
            summary => 'HTML document to extract from',
            cmdline_src => 'stdin_or_files',
        },
        base => {
            schema => 'str',
            summary => 'base URL for images',
        },
    },
};
sub extract_image_links {
    my %args = @_;

    my $html = $args{html};
    my $base = $args{base};

    # get base from <BASE HREF> if exists
    if (!$base) {
        if ($html =~ /<base\b[^>]*\bhref\s*=\s*(["']?)(\S+?)\1[^>]*>/is) {
            $base = $2;
        }
    }

    my %memory;
    my @res;
    my $p = HTML::Parser->new(
        api_version => 3,
        start_h => [
            sub {
                my ($tagname, $attr) = @_;
                return unless $tagname =~ /^img$/i;
                for ($attr->{src}) {
                    s/#.*//;
                    if (++$memory{$_} == 1) {
                        push @res, URI::URL->new($_, $base)->abs()->as_string;
                    }
                }
            }, "tagname, attr"],
    );
    $p->parse($html);

    [200, "OK", \@res];
}

1;
# ABSTRACT: Extract image links from HTML document

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::HTML::Extract::ImageLinks - Extract image links from HTML document

=head1 VERSION

This document describes version 0.77 of SHARYANTO::HTML::Extract::ImageLinks (from Perl distribution SHARYANTO-Utils), released on 2015-09-04.

=head1 SEE ALSO

L<SHARYANTO>

=head1 FUNCTIONS


=head2 extract_image_links(%args) -> [status, msg, result, meta]

Extract image links from HTML document.

Either specify either url, html.

Arguments ('*' denotes required arguments):

=over 4

=item * B<base> => I<str>

base URL for images.

=item * B<html>* => I<str>

HTML document to extract from.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-Utils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-Utils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-Utils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
