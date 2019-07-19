package Perinci::Examples::CLI;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.814'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

# package metadata
$SPEC{':package'} = {
    v => 1.1,
    summary => 'Example for CLI help/usage generation',
    "summary.alt.lang.id_ID" => 'Contoh saat menghasilkan pesan bantuan CLI',
    description => <<'_',

The example(s) in this package are for demonstrating how the function metadata
is converted into CLI help example (produced by `--help` or `--help --verbose`).
Also for testing how it is converted into POD for scripts (i.e. the `OPTIONS`
section).

_
};

$SPEC{demo_cli_opts} = {
    v => 1.1,
    summary => "Summary for `demo_cli_opts`",
    description => <<'_',

Description for `demo_cli_opts`.

This is another paragraph from the description. Description by default is
assumed to be marked up in *Markdown* (currently referring to CommonMark).

    This paragraph should be set in verbatim.

_
    args => {
        flag1 => {
            summary => 'A flag option',
            schema  => [bool => is=>1],
            cmdline_aliases => {f=>{}},
            tags => ['category:cat1'],
            description => <<'_',

A flag option is a bool option with the value of 1 (true). It is meant to
activate something if specified and there is no notion of disabling by
specifying the opposite. Thus the CLI framework should not generate a
`--noflag1` option.

This flag has an alias `-f` with no summary/description nor code. So the CLI
framework should display the alias along with the option. Note that short
(single-letter) options/aliases do not get `--noX`.

_
        },
        bool1 => {
            summary => 'A bool option',
            schema => 'bool',
            cmdline_aliases => {
                z => {
                    summary => 'This is summary for option `-z`',
                    description => <<'_',

This is description for option `-z` (actually a command-line alias). Since this
alias has its own summary/description, this

_
                },
            },
            tags => ['category:cat1'],
            description => <<'_',

CLI framework should generate `--nobool1` (and `--nobool1`) automatically.

This option has an alias, `-z`. Because the alias has its own
summary/description, it will be displayed separately.

_
        },

        full => {
            summary => 'Turn on full processing',
            'summary.alt.bool.not' => 'Turn off full processing',
            schema => 'bool',
            default => 1,
            tags => ['category:cat1'],
            description => <<'_',

Another bool option with on default.

CLI framework should perhaps show `--nobool2` instead of `--bool2` because
`--bool2` is active by default. And if it does so, it should also show the
negative summary in the `summary.alt.bool.not` attribute instead of the normal
`summary` property.

_
        },
        full2 => {
            summary => 'Use full processing (2)',
            schema => ['bool', default=>1],
            tags => ['category:cat2'],
            description => <<'_',

Another bool option with on default. Because this option does not have
`summary.alt.bool.not`, CLI framework should not show any summary, despite the
existence of `summary`.

_
        },
        int1 => {
            # without any summary, required
            schema => ['int*', min=>1, max=>100],
            cmdline_aliases => {i=>{}},
            req => 1,
            description => <<'_',

Demonstrate an option with no summary. And a required option.

_
        },
        int2 => {
            summary => 'Another int option',
            schema => ['int*', min=>-100, max=>100],
            default => 10,
            description => <<'_',

Demonstrate a scalar/simple default value.

_
        },
        str1 => {
            summary => 'A required option as well as positional argument',
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        pass => {
            schema => 'str*',
            is_password => 1,
            cmdline_aliases => {p=>{}},
        },
        with_foo => {
            summary => 'This demonstrate negation of '.
                '--with-foo to --without-foo',
            schema => 'bool*',
            cmdline_aliases => {wf=>{}},
            tags => ['category:negation'],
        },
        is_bar => {
            summary => 'This demonstrate negation of '.
                '--is-foo to --isnt-foo',
            schema => 'bool*',
            tags => ['category:negation'],
        },
        are_baz => {
            summary => 'This demonstrate negation of '.
                '--are-foo to --arent-foo',
            schema => 'bool*',
            tags => ['category:negation'],
        },
        array1 => {
            summary => 'Positional, slurpy, and plural',
            'summary.alt.plurality.singular' => 'Positional, slurpy, and singular',
            schema => ['array*', of => 'str*'],
            req => 1,
            pos => 1,
            slurpy => 1,
            description => <<'_',

Argument with non-scalar types (like array or hash) can be specified in the CLI
using `--ARG-json` or `--ARG-yaml`. Arguments with type of array of string can
also be specified using multiple `--ARG` options.

This option also links to another option.

_
            links => ['hash1'],
        },
        hash1 => {
            summary => 'Demonstrate hash argument with '.
                'default value from schema',
            schema => ['hash*', default=>{default=>1}],
            links => [
                {url=>'array1', summary=>'Another non-scalar option'},
                {url=>'http://example.com/', summary=>'Absolute link'},
            ],
        },
        gender => {
            summary => 'A string option',
            schema => ['str*', in=>['M','F']],
            cmdline_aliases => {
                F      => {
                    is_flag => 1,
                    summary => 'Alias for `--female`',
                    code    => sub { $_[0]{args}{gender} = 'F' },
                },
                female => {
                    is_flag => 1,
                    summary => 'Alias for `--gender=F`',
                    code    => sub { $_[0]{args}{gender} = 'M' },
                },
                M      => {
                    is_flag => 1,
                    summary => 'Alias for `--male`',
                    code    => sub { $_[0]{args}{gender} = 'M' },
                },
                male   => {
                    is_flag => 1,
                    summary => 'Alias for `--gender=M`',
                    code    => sub { $_[0]{args}{gender} = 'M' },
                },
            },
            description => <<'_',

This option contains flag aliases that have code.

_
        },
        output => {
            summary => 'Specify output filename',
            schema => 'str*',
            "x.schema.entity" => "filename",
            description => <<'_',

This option demonstrates how the option would be displayed in the help/usage.
Due to the `x.schema.entity` attribute giving hint about what the value is, CLI
framework can show:

    --output=file

instead of the plain and less informative:

    --output=s

_
        },
        input => {
            summary => 'Specify input',
            cmdline_src => 'stdin_or_files',
            schema => 'buf*',
            description => <<'_',

This option demonstrates the `cmdline_src` property. Also, since schema type is
`buf`, we know that the value is binary data. CLI framework will provide
`--input-base64` to allow specifying binary data encoded in base64.

_
        },
    },
    examples => [
        {
            argv => ['--int1', '10', 'a value', 'elem1', 'elem2'],
            summary => 'Summary for an example',
            test => 0,
        },
        {
            argv => ['--int1', '20', '--str1', 'x', '--array1-json', '[1,2]'],
            summary => 'A second example',
            test => 0,
        },
    ],
};
sub demo_cli_opts {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", \%args];
}

# Originally used in Perinci::Sub::To::CLIDocData's Synopsis
$SPEC{demo_cli_opts_shorter} = {
    v => 1.1,
    summary => "Function summary",
    args => {
        flag1 => {
            schema  => [bool => is=>1],
            cmdline_aliases => {f=>{}},
            tags => ['category:cat1'],
        },
        bool1 => {
            summary => 'Another bool option',
            schema => 'bool',
            cmdline_aliases => {
                z => {
                    summary => 'This is summary for option `-z`',
                },
            },
            tags => ['category:cat1'],
        },
        str1 => {
            summary => 'A required option as well as positional argument',
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            argv => ['a value', '--bool1'],
            summary => 'Summary for an example',
            test => 0,
        },
    ],
};
sub demo_cli_opts_shorter {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", \%args];
}

1;
# ABSTRACT: Example for CLI help/usage generation

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Examples::CLI - Example for CLI help/usage generation

=head1 VERSION

This document describes version 0.814 of Perinci::Examples::CLI (from Perl distribution Perinci-Examples), released on 2019-06-29.

=head1 DESCRIPTION


The example(s) in this package are for demonstrating how the function metadata
is converted into CLI help example (produced by C<--help> or C<--help --verbose>).
Also for testing how it is converted into POD for scripts (i.e. the C<OPTIONS>
section).

=head1 FUNCTIONS


=head2 demo_cli_opts

Usage:

 demo_cli_opts(%args) -> [status, msg, payload, meta]

Summary for `demo_cli_opts`.

Examples:

=over

=item * Summary for an example:

 demo_cli_opts( str1 => "a value", array1 => ["elem1", "elem2"], int1 => 10);

Result:

 {
   array1 => ["elem1", "elem2"],
   full   => 1,
   full2  => 1,
   hash1  => { default => 1 },
   int1   => 10,
   int2   => 10,
   str1   => "a value",
 }

=item * A second example:

 demo_cli_opts( str1 => "x", array1 => [1, 2], int1 => 20); # -> undef

=back

Description for C<demo_cli_opts>.

This is another paragraph from the description. Description by default is
assumed to be marked up in I<Markdown> (currently referring to CommonMark).

 This paragraph should be set in verbatim.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<are_baz> => I<bool>

This demonstrate negation of --are-foo to --arent-foo.

=item * B<array1>* => I<array[str]>

Positional, slurpy, and plural.

Argument with non-scalar types (like array or hash) can be specified in the CLI
using C<--ARG-json> or C<--ARG-yaml>. Arguments with type of array of string can
also be specified using multiple C<--ARG> options.

This option also links to another option.

=item * B<bool1> => I<bool>

A bool option.

CLI framework should generate C<--nobool1> (and C<--nobool1>) automatically.

This option has an alias, C<-z>. Because the alias has its own
summary/description, it will be displayed separately.

=item * B<flag1> => I<bool>

A flag option.

A flag option is a bool option with the value of 1 (true). It is meant to
activate something if specified and there is no notion of disabling by
specifying the opposite. Thus the CLI framework should not generate a
C<--noflag1> option.

This flag has an alias C<-f> with no summary/description nor code. So the CLI
framework should display the alias along with the option. Note that short
(single-letter) options/aliases do not get C<--noX>.

=item * B<full> => I<bool> (default: 1)

Turn on full processing.

Another bool option with on default.

CLI framework should perhaps show C<--nobool2> instead of C<--bool2> because
C<--bool2> is active by default. And if it does so, it should also show the
negative summary in the C<summary.alt.bool.not> attribute instead of the normal
C<summary> property.

=item * B<full2> => I<bool> (default: 1)

Use full processing (2).

Another bool option with on default. Because this option does not have
C<summary.alt.bool.not>, CLI framework should not show any summary, despite the
existence of C<summary>.

=item * B<gender> => I<str>

A string option.

This option contains flag aliases that have code.

=item * B<hash1> => I<hash> (default: {default=>1})

Demonstrate hash argument with default value from schema.

=item * B<input> => I<buf>

Specify input.

This option demonstrates the C<cmdline_src> property. Also, since schema type is
C<buf>, we know that the value is binary data. CLI framework will provide
C<--input-base64> to allow specifying binary data encoded in base64.

=item * B<int1>* => I<int>

Demonstrate an option with no summary. And a required option.

=item * B<int2> => I<int> (default: 10)

Another int option.

Demonstrate a scalar/simple default value.

=item * B<is_bar> => I<bool>

This demonstrate negation of --is-foo to --isnt-foo.

=item * B<output> => I<str>

Specify output filename.

This option demonstrates how the option would be displayed in the help/usage.
Due to the C<x.schema.entity> attribute giving hint about what the value is, CLI
framework can show:

 --output=file

instead of the plain and less informative:

 --output=s

=item * B<pass> => I<str>

=item * B<str1>* => I<str>

A required option as well as positional argument.

=item * B<with_foo> => I<bool>

This demonstrate negation of --with-foo to --without-foo.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 demo_cli_opts_shorter

Usage:

 demo_cli_opts_shorter(%args) -> [status, msg, payload, meta]

Function summary.

Examples:

=over

=item * Summary for an example:

 demo_cli_opts_shorter( str1 => "a value", bool1 => 1); # -> { bool1 => 1, str1 => "a value" }

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bool1> => I<bool>

Another bool option.

=item * B<flag1> => I<bool>

=item * B<str1>* => I<str>

A required option as well as positional argument.

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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci>

L<Perinci::Examples>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
