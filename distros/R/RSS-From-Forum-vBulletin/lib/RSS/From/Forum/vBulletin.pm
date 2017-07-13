package RSS::From::Forum::vBulletin;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.11'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Date::Parse;
use LWP::UserAgent;
use Mojo::DOM;
use POSIX;
use URI::URL;

use Exporter qw(import);
our @EXPORT_OK = qw(get_rss_from_forum);

our %SPEC;

sub _strip_session_param {
    my $url = shift;
    $url =~ s/([?&])s=[0-9a-f]{32}(&|$)/
        ($1 eq '?' ? '?' : '') /e;
    $url;
}

$SPEC{get_rss_from_forum} = {
    v => 1.1,
    summary => 'Generate an RSS page by parsing vBulletin forum display page',
    description => <<'_',

Many vBulletin forums do not turn on RSS feeds. This function parses vBulletin
forum display page and create a simple RSS page so you can subscribe to it using
RSS.

_
    args    => {
        url => {
            summary     => 'Forum URL (the forum display page)',
            schema      => 'str*',
            description => <<'_',

Usually it's of the form: http://host/path/forumdisplay.php?f=XXX

_
            pos         => 0,
            req         => 1,
        },
        ua => {
            summary     => 'Supply a custom LWP::UserAgent object',
            schema      => 'obj*',
            description => <<'_',

If supplied, will be used instead of the default LWP::UserAgent object.

_
        },
    },
};
sub get_rss_from_forum {
    my %args = @_;

    my $datefmt = "%a, %d %b %Y %H:%M:%S %z";
    state $default_ua = LWP::UserAgent->new;

    my $url = $args{url} or return [400, "Please specify url"];
    my $ua = $args{ua} // $default_ua;

    my $uares;
    eval { $uares = $ua->get($url) };
    return [500, "Can't download URL `$url`: $@"] if $@;
    return [$uares->code, "Can't download URL: " . $uares->message]
        unless $uares->is_success;

    my $dom;
    eval { $dom = Mojo::DOM->new($uares->content) };
    return [500, "Can't create DOM from read URL: $@"] if $@;

    my $gen = "RSS::From::Forum::vBulletin " .
        ($RSS::From::Forum::vBulletin::VERSION // "?"). " (Perl module)";

    my @rss;

    push @rss, '<?xml version="1.0" encoding="UTF-8">',"\n";
    push @rss, "<!-- generator=$gen -->\n";
    push @rss, ('<rss version="2.0"',
                ' xmlns:content="http://purl.org/rss/1.0/modules/content/"',
                ' xmlns:wfw="http://wellformedweb.org/CommentAPI/"',
                ' xmlns:dc="http://purl.org/dc/elements/1.1/"',
                ' xmlns:atom="http://www.w3.org/2005/Atom"',
                ' xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"',
                ' xmlns:slash="http://purl.org/rss/1.0/modules/slash/"',
                ">\n");
    push @rss, "<channel>\n";

    my $els = $dom->find("title");
    push @rss, "<title>",
        ($els->[0] ? $els->[0]->text : "(untitled)"), "</title>\n";
    push @rss, "<link>$url</link>\n";
    push @rss, "<generator>$gen</generator>\n";
    push @rss, "<lastBuildDate>",
        POSIX::strftime($datefmt, gmtime),
              "</lastBuildDate>\n";
    # find all table rows containing show thread url
    my $rows = $dom->find("tr");
    for my $row (@$rows) {
        my $a = $row->find(qq{a[href*="showthread.php"]});
        next unless @$a;
        push @rss, "<item>\n";
        push @rss, "<title>", $a->[0]->text, "</title>\n";
        my $iurl = URI::URL->new($a->[0]->attrs->{href})->abs($url);
        $iurl = _strip_session_param("$iurl");
        push @rss, "<link>$iurl</link>\n";
        my $row_s = "$row";

        {
            $row_s =~ m! \s ([0-9/-]+) \s
                         <span\sclass="time">
                         (\d+:\d+(?:\s[AP]M)?)</span>!x;
            if (!$1) {
                log_warn("No date found in entry $iurl");
                last;
            }

            my $date_s = "$1 $2";
            my $date   = str2time $date_s;
            if (!$date) {
                log_warn("Can't parse date `$date_s` in entry $iurl");
                last;
            }
            push @rss, "<pubDate>", strftime($datefmt, gmtime($date)),
                "</pubDate>\n";
        }

        # TODO: description
        push @rss, "</item>\n\n";
    }

    push @rss, "</channel>\n";
    push @rss, "</rss>\n";

    [200, "OK", join("", @rss)];
}

1;
# ABSTRACT: Generate an RSS page by parsing vBulletin forum display page

__END__

=pod

=encoding UTF-8

=head1 NAME

RSS::From::Forum::vBulletin - Generate an RSS page by parsing vBulletin forum display page

=head1 VERSION

This document describes version 0.11 of RSS::From::Forum::vBulletin (from Perl distribution RSS-From-Forum-vBulletin), released on 2017-07-10.

=head1 SYNOPSIS

 # See get-rss-from-forum for command-line usage

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 get_rss_from_forum

Usage:

 get_rss_from_forum(%args) -> [status, msg, result, meta]

Generate an RSS page by parsing vBulletin forum display page.

Many vBulletin forums do not turn on RSS feeds. This function parses vBulletin
forum display page and create a simple RSS page so you can subscribe to it using
RSS.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ua> => I<obj>

Supply a custom LWP::UserAgent object.

If supplied, will be used instead of the default LWP::UserAgent object.

=item * B<url>* => I<str>

Forum URL (the forum display page).

Usually it's of the form: http://host/path/forumdisplay.php?f=XXX

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

Please visit the project's homepage at L<https://metacpan.org/release/RSS-From-Forum-vBulletin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RSS-From-Forum-vBulletin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=RSS-From-Forum-vBulletin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
