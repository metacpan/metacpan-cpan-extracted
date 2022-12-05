package Parse::Netstat;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $DATE = '2022-12-04'; # DATE
our $VERSION = '0.150'; # VERSION

our @EXPORT_OK = qw(parse_netstat);

our %SPEC;

$SPEC{parse_netstat} = {
    v => 1.1,
    summary => 'Parse the output of "netstat" command',
    description => <<'_',

This utility support several flavors of netstat. The default flavor is `linux`.
Use `--flavor` to select which flavor you want.

Since different flavors provide different fields and same-named fields might
contain data in different format, and also not all kinds of possible output from
a single flavor are supported, please see the sample parse output for each
flavor (in corresponding `Parse::Netstat::*` per-flavor module) you want to use
and adjust accordingly.

_
    args => {
        output => {
            summary => 'Output of netstat command',
            description => <<'_',

This utility only parses program's output. You need to invoke "netstat" on your
own.

_
            schema => 'str*',
            pos => 0,
            req => 1,
            cmdline_src => 'stdin_or_files',
        },
        flavor => {
            summary => 'Flavor of netstat',
            schema  => ['str*', in => ['linux', 'solaris', 'freebsd', 'darwin', 'win32']],
            default => 'linux',
        },
        tcp => {
            summary => 'Parse TCP connections',
            'summary.alt.bool.not' => 'Do not parse TCP connections',
            schema  => [bool => default => 1],
        },
        udp => {
            summary => 'Parse UDP connections',
            'summary.alt.bool.not' => 'Do not parse UDP connections',
            schema  => [bool => default => 1],
        },
        unix => {
            summary => 'Parse Unix socket connections',
            'summary.alt.bool.not' => 'Do not parse Unix socket connections',
            schema  => [bool => default => 1],
        },
    },
    examples => [
        {
            src => 'netstat -anp | parse-netstat',
            src_plang => 'bash',
        },
    ],
};
sub parse_netstat {
    my %args = @_;

    my $output = $args{output} or return [400, "Please specify output"];
    my $tcp    = $args{tcp} // 1;
    my $udp    = $args{udp} // 1;
    my $unix   = $args{unix} // 1;
    my $flavor = $args{flavor} // 'linux';

    if ($flavor eq 'linux') {
        require Parse::Netstat::linux;
        Parse::Netstat::linux::parse_netstat(
            output=>$output, tcp=>$tcp, udp=>$udp, unix=>$unix);
    } elsif ($flavor eq 'freebsd') {
        require Parse::Netstat::freebsd;
        Parse::Netstat::freebsd::parse_netstat(
            output=>$output, tcp=>$tcp, udp=>$udp, unix=>$unix);
    } elsif ($flavor eq 'darwin') {
        require Parse::Netstat::darwin;
        Parse::Netstat::darwin::parse_netstat(
            output=>$output, tcp=>$tcp, udp=>$udp, unix=>$unix);
    } elsif ($flavor eq 'solaris') {
        require Parse::Netstat::solaris;
        Parse::Netstat::solaris::parse_netstat(
            output=>$output, tcp=>$tcp, udp=>$udp, unix=>$unix);
    } elsif ($flavor eq 'win32') {
        require Parse::Netstat::win32;
        Parse::Netstat::win32::parse_netstat(
            output=>$output, tcp=>$tcp, udp=>$udp);
    } else {
        return [400, "Unknown flavor '$flavor', please see --help"];
    }
}

1;
# ABSTRACT: Parse the output of "netstat" command

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Netstat - Parse the output of "netstat" command

=head1 VERSION

This document describes version 0.150 of Parse::Netstat (from Perl distribution Parse-Netstat), released on 2022-12-04.

=head1 SYNOPSIS

 use Parse::Netstat qw(parse_netstat);
 my $res = parse_netstat(output => join("", `netstat -anp`), flavor=>'linux');

=head1 FUNCTIONS


=head2 parse_netstat

Usage:

 parse_netstat(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse the output of "netstat" command.

This utility support several flavors of netstat. The default flavor is C<linux>.
Use C<--flavor> to select which flavor you want.

Since different flavors provide different fields and same-named fields might
contain data in different format, and also not all kinds of possible output from
a single flavor are supported, please see the sample parse output for each
flavor (in corresponding C<Parse::Netstat::*> per-flavor module) you want to use
and adjust accordingly.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<flavor> => I<str> (default: "linux")

Flavor of netstat.

=item * B<output>* => I<str>

Output of netstat command.

This utility only parses program's output. You need to invoke "netstat" on your
own.

=item * B<tcp> => I<bool> (default: 1)

Parse TCP connections.

=item * B<udp> => I<bool> (default: 1)

Parse UDP connections.

=item * B<unix> => I<bool> (default: 1)

Parse Unix socket connections.


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

Please visit the project's homepage at L<https://metacpan.org/release/Parse-Netstat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-Netstat>.

=head1 SEE ALSO

Parse::Netstat::* for per-flavor notes and sample outputs.

L<parse-netstat> from L<App::ParseNetstat> is a CLI for this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2022, 2017, 2015, 2014, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-Netstat>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
