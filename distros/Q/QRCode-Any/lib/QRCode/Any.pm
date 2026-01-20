package QRCode::Any;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter::Rinci qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-01-20'; # DATE
our $DIST = 'QRCode-Any'; # DIST
our $VERSION = '0.003'; # VERSION

my $known_formats = [qw/png/]; # TODO: html, txt
my $sch_format = ['str', in=>$known_formats, default=>'png'];
our %argspecopt_format = (
    format => {
        summary => 'Format of QRCode to generate',
        schema => $sch_format,
        description => <<'MARKDOWN',

The default, when left undef, is `png`.

MARKDOWN
        cmdline_aliases => {f=>{}},
    },
);
our %argspecopt_format_args = (
    format_args => {
        schema => 'hash*',
        description => <<'MARKDOWN',

Format-specific arguments.

MARKDOWN
    },
);
our %argspecs_format = (
    %argspecopt_format,
    %argspecopt_format_args,
);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Common interface to QRCode functions',
    description => <<'MARKDOWN',


MARKDOWN
};

$SPEC{'encode_qrcode'} = {
    v => 1.1,
    summary => 'Encode a text into QR Code (in one of several supported formats)',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %argspecs_format,
        text => {
            schema => 'str*',
            req => 1,
        },
        filename => {
            schema => 'filename*',
            req => 1,
        },
        level => {
            summary => 'Error correction level',
            schema => ['str*', in=>[qw/L M Q H/]],
            default => 'M',
        },
    },
};
sub encode_qrcode {
    my %args = @_;
    my $format = $args{format} // 'png';
    my $level  = $args{level} // 'M';

    if ($format eq 'png') {
        require Imager;
        require Imager::QRCode;
        my $qrcode = Imager::QRCode->new(
            size          => 5,
            margin        => 2,
            version       => 1,
            level         => $level,
            casesensitive => 1,
            lightcolor    => Imager::Color->new(255, 255, 255),
            darkcolor     => Imager::Color->new(0, 0, 0),
        );

        # generates rub-through image
        my $img = $qrcode->plot($args{text});

        my $conv_img = $img->to_rgb8
            or die "converting with to_rgb8() failed: " . Imager->errstr;

        my $filename = $args{filename};
        $filename .= ".png" unless $filename =~ /\.png\z/;
        $conv_img->write(file => $filename)
            or return [500,  "Failed to write to file `$filename`: " . $conv_img->errstr];
        [200, "OK", undef, {"func.filename"=>$filename}];
    } else {
        [501, "Unsupported format '$format'"];
    }
}

1;
# ABSTRACT: Common interface to QRCode functions

__END__

=pod

=encoding UTF-8

=head1 NAME

QRCode::Any - Common interface to QRCode functions

=head1 VERSION

This document describes version 0.003 of QRCode::Any (from Perl distribution QRCode-Any), released on 2026-01-20.

=head1 DESCRIPTION

This module provides a common interface to QRCode functions.

=head1 FUNCTIONS


=head2 encode_qrcode

Usage:

 encode_qrcode(%args) -> [$status_code, $reason, $payload, \%result_meta]

Encode a text into QR Code (in one of several supported formats).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

(No description)

=item * B<format> => I<str> (default: "png")

Format of QRCode to generate.

The default, when left undef, is C<png>.

=item * B<format_args> => I<hash>

Format-specific arguments.

=item * B<level> => I<str> (default: "M")

Error correction level.

=item * B<text>* => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/QRCode-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-QRCode-Any>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=QRCode-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
