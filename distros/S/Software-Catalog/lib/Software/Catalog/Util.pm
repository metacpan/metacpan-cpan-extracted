package Software::Catalog::Util;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Software-Catalog'; # DIST
our $VERSION = '1.0.8'; # VERSION

our @EXPORT_OK = qw(
                       extract_from_url
               );

$SPEC{extract_from_url} = {
    v => 1.1,
    args => {
        url => {
            schema => 'url*',
            req => 1,
            pos => 0,
        },
        re => {
            schema => 're*',
        },
        code => {
            schema => 'code*',
        },
        all => {
            schema => 'bool*',
        },
        agent => {
            schema => 'str*',
        },
    },
    args_rels => {
        req_one => [qw/re code/],
    },
};
sub extract_from_url {
    state $ua = do {
        require LWP::UserAgent;
        LWP::UserAgent->new;
    };
    state $orig_agent = $ua->agent;
    my %args = @_;

    $ua->agent( $args{agent} || $orig_agent);
    my $lwp_res = $ua->get($args{url});
    unless ($lwp_res->is_success) {
        return [$lwp_res->code, "Couldn't retrieve URL '$args{url}'" . (
            $lwp_res->message ? ": " . $lwp_res->message : "")];
    }

    my $res;
    if ($args{re}) {
        log_trace "Finding version from $args{url} using regex $args{re} ...";
        if ($args{all}) {
            my $content = $lwp_res->content;
            my %m;
            while ($content =~ /$args{re}/g) {
                $m{$1}++;
            }
            $res = [200, "OK (all)", [sort keys %m]];
        } else {
            if ($lwp_res->content =~ $args{re}) {
                $res = [200, "OK", $1];
            } else {
                $res = [543, "Couldn't match pattern $args{re} against ".
                            "content of URL '$args{url}'"];
            }
        }
    } else {
        log_trace "Finding version from $args{url} using code ...";
        $res = $args{code}->(
            content => $lwp_res->content, _lwp_res => $lwp_res);
    }
    log_trace "Result: %s", $res;
    $res;
}

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::Util - Utility routines

=head1 VERSION

This document describes version 1.0.8 of Software::Catalog::Util (from Perl distribution Software-Catalog), released on 2024-07-17.

=head1 FUNCTIONS


=head2 extract_from_url

Usage:

 extract_from_url(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<agent> => I<str>

(No description)

=item * B<all> => I<bool>

(No description)

=item * B<code> => I<code>

(No description)

=item * B<re> => I<re>

(No description)

=item * B<url>* => I<url>

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

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog>.

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2015, 2014, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
