package SHARYANTO::HTTP::DetectUA::Simple;

use 5.010;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(detect_http_ua_simple);

our $VERSION = '0.77'; # VERSION

our %SPEC;

$SPEC{":package"} = {
    v => 1.1,
    summary => 'A very simple and generic browser detection library',
    description => <<'_',

I needed a simple and fast routine which can detect whether HTTP client is a GUI
browser (like Chrome or Firefox), a text browser (like Lynx or Links), or
neither (like curl, or L<LWP>). Hence, this module.

_
};

$SPEC{detect_http_ua_simple} = {
    v => 1.1,
    summary => 'Detect whether HTTP client is a GUI/TUI browser',
    description => <<'_',

This function is a simple and fast routine to detect whether HTTP client is a
GUI browser (like Chrome or Firefox), a text-based browser (like Lynx or Links),
or neither (like curl or LWP). Extra information can be provided in the future.

Currently these heuristic rules are used:

* check popular browser markers in User-Agent header (e.g. 'Chrome', 'Opera');
* check Accept header for 'image/';

It is several times faster than the other equivalent Perl modules, this is
because it does significantly less.

_
    args => {
        env => {
            pos => 0,
            summary => 'CGI-compatible environment, e.g. \%ENV or PSGI\'s $env',
        },
    },
    result => {
        description => <<'_',

* 'is_gui_browser' key will be set to true if HTTP client is a GUI browser.

* 'is_text_browser' key will be set to true if HTTP client is a text/TUI
  browser.

* 'is_browser' key will be set to true if either 'is_gui_browser' or
  'is_text_browser' is set to true.

_
        schema => 'hash*',
    },
    links => [
        {url => "pm:HTML::ParseBrowser"},
        {url => "pm:HTTP::BrowserDetect"},
        {url => "pm:HTTP::DetectUserAgent"},
        {url => "pm:Parse::HTTP::UserAgent"},
        {url => "pm:HTTP::headers::UserAgent"},
    ],
    args_as => "array",
    result_naked => 0,
};

sub detect_http_ua_simple {
    my ($env) = @_;
    my $res = {};
    my $det;

    my $ua = $env->{HTTP_USER_AGENT};
    if ($ua) {
        # check for popular browser GUI UA
        if ($ua =~ m!\b(?:Mozilla/|MSIE |Chrome/|Opera/|
                         Profile/MIDP-
                     )!x) {
            $res->{is_gui_browser} = 1;
            $det++;
        }
        # check for popular webbot UA
        if ($ua =~ m!\b(?:Links |ELinks/|Lynx/|w3m/)!) {
            $res->{is_text_browser} = 1;
            $det++;
        }
    }

    if (!$det) {
        # check for accept mime type
        my $ac = $env->{HTTP_ACCEPT};
        if ($ac) {
            if ($ac =~ m!\b(?:image/)!) {
                $res->{is_gui_browser} = 1;
                $det++;
            }
        }
    }

    $res->{is_browser} = 1 if $res->{is_gui_browser} || $res->{is_text_browser};
    $res;
}

1;
# ABSTRACT: A very simple and generic browser detection library

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::HTTP::DetectUA::Simple - A very simple and generic browser detection library

=head1 VERSION

This document describes version 0.77 of SHARYANTO::HTTP::DetectUA::Simple (from Perl distribution SHARYANTO-Utils), released on 2015-09-04.

=head1 SEE ALSO

L<SHARYANTO>

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

=head1 DESCRIPTION


I needed a simple and fast routine which can detect whether HTTP client is a GUI
browser (like Chrome or Firefox), a text browser (like Lynx or Links), or
neither (like curl, or L<LWP>). Hence, this module.

=head1 FUNCTIONS


=head2 detect_http_ua_simple($env) -> [status, msg, result, meta]

Detect whether HTTP client is a GUI/TUI browser.

This function is a simple and fast routine to detect whether HTTP client is a
GUI browser (like Chrome or Firefox), a text-based browser (like Lynx or Links),
or neither (like curl or LWP). Extra information can be provided in the future.

Currently these heuristic rules are used:

=over

=item * check popular browser markers in User-Agent header (e.g. 'Chrome', 'Opera');

=item * check Accept header for 'image/';

=back

It is several times faster than the other equivalent Perl modules, this is
because it does significantly less.

Arguments ('*' denotes required arguments):

=over 4

=item * B<env> => I<any>

CGI-compatible environment, e.g. \%ENV or PSGI's $env.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (hash)


=over

=item * 'is_gui_browser' key will be set to true if HTTP client is a GUI browser.

=item * 'is_text_browser' key will be set to true if HTTP client is a text/TUI
browser.

=item * 'is_browser' key will be set to true if either 'is_gui_browser' or
'is_text_browser' is set to true.

=back

See also:

=over

* L<HTML::ParseBrowser>

* L<HTTP::BrowserDetect>

* L<HTTP::DetectUserAgent>

* L<Parse::HTTP::UserAgent>

* L<HTTP::headers::UserAgent>

=back

=cut
