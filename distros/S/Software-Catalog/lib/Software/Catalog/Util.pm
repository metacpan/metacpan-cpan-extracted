package Software::Catalog::Util;

our $DATE = '2020-10-02'; # DATE
our $VERSION = '1.0.7'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

use Exporter qw(import);
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
    my %args = @_;

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

$SPEC{detect_arch} = {
    v => 1.1,
};
sub detect_arch {
    require Config; Config->import;
    my $archname = do { no strict 'vars'; no warnings 'once'; $Config{archname} };
    if ($archname =~ /\Ax86-linux/) {
        return "linux-x86"; # linux i386
    } elsif ($archname =~ /\Ax86-linux/) {
    } elsif ($archname =~ /\Ax86_64-linux/) {
        return "linux-x86_64";
    } elsif ($archname =~ /\AMSWin32-x86(-|\z)/) {
        return "win32";
    } elsif ($archname =~ /\AMSWin32-x64(-|\z)/) {
        return "win64";
    } else {
        die "Unsupported arch '$archname'";
    }
}

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog::Util - Utility routines

=head1 VERSION

This document describes version 1.0.7 of Software::Catalog::Util (from Perl distribution Software-Catalog), released on 2020-10-02.

=head1 FUNCTIONS


=head2 detect_arch

Usage:

 detect_arch() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 extract_from_url

Usage:

 extract_from_url(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

=item * B<code> => I<code>

=item * B<re> => I<re>

=item * B<url>* => I<url>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
