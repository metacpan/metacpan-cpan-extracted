package Perinci::CmdLine::Call;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-05-22'; # DATE
our $DIST = 'Perinci-CmdLine-Call'; # DIST
our $VERSION = '0.060'; # VERSION

our @EXPORT_OK = qw(call_cli_script);

our %SPEC;

$SPEC{call_cli_script} = {
    v => 1.1,
    summary => '"Call" a Perinci::CmdLine-based script',
    description => <<'_',

CLI scripts which use `Perinci::CmdLine` module family (e.g.
`Perinci::CmdLine::Lite` or `Perinci::CmdLine::Classic`) have some common
features, e.g. support JSON output.

This routine provides a convenience way to get a data structure from running a
CLI command. It basically just calls the script with `--json` and
`--no-naked-res` then decodes the JSON result so you get a data structure
directly. Will return error 599 if output is not valid JSON.

Other features might be added in the future, e.g. retry, custom configuration
file, etc.

_
    args => {
        script => {
            schema => 'str*',
            req => 1,
        },
        argv => {
            schema => ['array*', of=>'str*'],
            default => [],
        },
    },
};
sub call_cli_script {
    require IPC::System::Options;
    require JSON::MaybeXS;

    my %args = @_;

    my $script = $args{script};
    my $argv   = $args{argv} // [];

    my $res = IPC::System::Options::readpipe(
        {die=>0, log=>1,
         capture_stdout=>\my $stdout, capture_stderr=>\my $stderr},
        $script, "--json", "--no-naked-res", @$argv,
    );

    eval { $res = JSON::MaybeXS::decode_json($res) };
    return [599, "Can't decode JSON: $@ (res=<$res>, exit code=".($? >> 8).", stdout=<$stdout>, stderr=<$stderr>)"] if $@;

    $res;
}

1;
# ABSTRACT: "Call" a Perinci::CmdLine-based script

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Call - "Call" a Perinci::CmdLine-based script

=head1 VERSION

This document describes version 0.060 of Perinci::CmdLine::Call (from Perl distribution Perinci-CmdLine-Call), released on 2023-05-22.

=head1 SYNOPSIS

 use Perinci::CmdLine::Call qw(call_cli_script);

 # returns an enveloped response
 my $res = call_cli_script(
     script => "lcpan",
     argv   => [qw/deps -R Text::ANSI::Util/],
 );

 # sample result:
 # [200, "OK", [
 #     {author=>"PERLANCAR", module=>"Text::WideChar::Util", version=>"0.10"},
 #     {author=>"NEZUMI"   , module=>"  Unicode::GCString" , version=>"0"},
 #     {author=>"NEZUMI"   , module=>"    MIME::Charset"   , version=>"v1.6.2"},
 # ]]

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 call_cli_script

Usage:

 call_cli_script(%args) -> [$status_code, $reason, $payload, \%result_meta]

"Call" a Perinci::CmdLine-based script.

CLI scripts which use C<Perinci::CmdLine> module family (e.g.
C<Perinci::CmdLine::Lite> or C<Perinci::CmdLine::Classic>) have some common
features, e.g. support JSON output.

This routine provides a convenience way to get a data structure from running a
CLI command. It basically just calls the script with C<--json> and
C<--no-naked-res> then decodes the JSON result so you get a data structure
directly. Will return error 599 if output is not valid JSON.

Other features might be added in the future, e.g. retry, custom configuration
file, etc.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<argv> => I<array[str]> (default: [])

(No description)

=item * B<script>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Call>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Call>.

=head1 SEE ALSO

L<Perinci::CmdLine>, L<Perinci::CmdLine::Lite>, L<Perinci::CmdLine::Classic>

L<Rinci>

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

This software is copyright (c) 2023, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Call>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
