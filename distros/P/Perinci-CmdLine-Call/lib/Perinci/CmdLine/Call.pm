package Perinci::CmdLine::Call;

our $DATE = '2016-03-16'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
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
directly. Will die if output is not valid JSON.

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

    my $res = IPC::System::Options::backtick(
        {die=>0, log=>1},
        $script, "--json", "--no-naked-res", @$argv,
    );

    eval { $res = JSON::MaybeXS::decode_json($res) };
    die if $@;

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

This document describes version 0.05 of Perinci::CmdLine::Call (from Perl distribution Perinci-CmdLine-Call), released on 2016-03-16.

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


=head2 call_cli_script(%args) -> [status, msg, result, meta]

"Call" a Perinci::CmdLine-based script.

CLI scripts which use C<Perinci::CmdLine> module family (e.g.
C<Perinci::CmdLine::Lite> or C<Perinci::CmdLine::Classic>) have some common
features, e.g. support JSON output.

This routine provides a convenience way to get a data structure from running a
CLI command. It basically just calls the script with C<--json> and
C<--no-naked-res> then decodes the JSON result so you get a data structure
directly. Will die if output is not valid JSON.

Other features might be added in the future, e.g. retry, custom configuration
file, etc.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<argv> => I<array[str]> (default: [])

=item * B<script>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Call>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Call>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Call>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine>, L<Perinci::CmdLine::Lite>, L<Perinci::CmdLine::Classic>

L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
