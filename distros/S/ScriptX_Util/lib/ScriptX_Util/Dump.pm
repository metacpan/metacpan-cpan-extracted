package ScriptX_Util::Dump;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-02'; # DATE
our $DIST = 'ScriptX_Util'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(dump_scriptx_script);

our %SPEC;

$SPEC{dump_scriptx_script} = {
    v => 1.1,
    summary => 'Run a ScriptX-based script but only to '.
        'dump the import arguments',
    description => <<'_',

This function runs a CLI script that uses `ScriptX` but monkey-patches
beforehand so that `import()` will dump the import arguments and then exit. The
goal is to get the import arguments without actually running the script.

This can be used to gather information about the script and then generate
documentation about it or do other things (e.g. `App::shcompgen` to generate a
completion script for the original script).

CLI script needs to use `ScriptX`. This is detected currently by a simple regex.
If script is not detected as using `ScriptX`, status 412 is returned.

_
    args => {
        filename => {
            summary => 'Path to the script',
            req => 1,
            pos => 0,
            schema => 'str*',
            cmdline_aliases => {f=>{}},
        },
        libs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'lib',
            summary => 'Libraries to unshift to @INC when running script',
            schema  => ['array*' => of => 'str*'],
            cmdline_aliases => {I=>{}},
        },
        skip_detect => {
            schema => ['bool', is=>1],
            cmdline_aliases => {D=>{}},
        },
    },
};
sub dump_scriptx_script {
    require Capture::Tiny;

    my %args = @_;

    my $filename = $args{filename} or return [400, "Please specify filename"];
    my $detres;
    if ($args{skip_detect}) {
        $detres = [200, "OK (skip_detect)", 1, {"func.module"=>"ScriptX", "func.reason"=>"skip detect, forced"}];
    } else {
        require ScriptX_Util;
        $detres = ScriptX_Util::detect_scriptx_script(
            filename => $filename);
        return $detres if $detres->[0] != 200;
        return [412, "File '$filename' is not script using ScriptX (".
                    $detres->[3]{'func.reason'}.")"] unless $detres->[2];
    }

    my $libs = $args{libs} // [];

    my @cmd = (
        $^X, (map {"-I$_"} @$libs),
        "-MScriptX_Util::Patcher::DumpAndExit",
        $filename,
    );
    my ($stdout, $stderr, $exit) = Capture::Tiny::capture(
        sub {
            local $ENV{SCRIPTX_DUMP} = 1;
            system @cmd;
        },
    );

    my $spec;
    if ($stdout =~ /^# BEGIN DUMP ScriptX\s+(.*)^# END DUMP ScriptX/ms) {
        $spec = eval $1;
        if ($@) {
            return [500, "Script '$filename' looks like using ".
                        "ScriptX, but I got an error in eval-ing ".
                            "captured option spec: $@, raw capture: <<<$1>>>"];
        }
    } else {
        return [500, "Script '$filename' looks like using ScriptX, ".
                    "but I couldn't find capture markers (# BEGIN DUMP ScriptX .. # END DUMP ScriptX), raw capture: ".
                        "stdout=<<$stdout>>, stderr=<<$stderr>>"];
    }

    [200, "OK", $spec, {
        'func.detect_res' => $detres,
    }];
}

1;
# ABSTRACT: Run a ScriptX-based script but only to dump the import arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX_Util::Dump - Run a ScriptX-based script but only to dump the import arguments

=head1 VERSION

This document describes version 0.003 of ScriptX_Util::Dump (from Perl distribution ScriptX_Util), released on 2020-10-02.

=head1 FUNCTIONS


=head2 dump_scriptx_script

Usage:

 dump_scriptx_script(%args) -> [status, msg, payload, meta]

Run a ScriptX-based script but only to dump the import arguments.

This function runs a CLI script that uses C<ScriptX> but monkey-patches
beforehand so that C<import()> will dump the import arguments and then exit. The
goal is to get the import arguments without actually running the script.

This can be used to gather information about the script and then generate
documentation about it or do other things (e.g. C<App::shcompgen> to generate a
completion script for the original script).

CLI script needs to use C<ScriptX>. This is detected currently by a simple regex.
If script is not detected as using C<ScriptX>, status 412 is returned.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<str>

Path to the script.

=item * B<libs> => I<array[str]>

Libraries to unshift to @INC when running script.

=item * B<skip_detect> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 SCRIPTX_DUMP

Bool. Will be set to 1 when executing the script to be dumped.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX_Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX_Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX_Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
