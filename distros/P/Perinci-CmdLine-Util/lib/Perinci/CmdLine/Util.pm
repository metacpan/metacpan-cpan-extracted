package Perinci::CmdLine::Util;

our $DATE = '2017-01-12'; # DATE
our $VERSION = '0.15'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       detect_pericmd_script
                       detect_perinci_cmdline_script
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utility routines related to Perinci::CmdLine',
};

$SPEC{detect_pericmd_script} = {
    v => 1.1,
    summary => 'Detect whether a file is a Perinci::CmdLine-based CLI script',
    description => <<'_',

The criteria are:

* the file must exist and readable;

* (optional, if `include_noexec` is false) file must have its executable mode
  bit set;

* content must start with a shebang C<#!>;

* either: must be perl script (shebang line contains 'perl') and must contain
  something like `use Perinci::CmdLine`;

_
    args_rels => {
        req_one => [qw/filename string/],
    },
    args => {
        filename => {
            summary => 'Path to file to be checked',
            schema => 'str*',
            description => <<'_',

Either `filename` or `string` must be specified.

_
            pos => 0,
        },
        string => {
            summary => 'Path to file to be checked',
            schema => 'buf*',
            description => <<'_',

Either `file` or `string` must be specified.

_
        },
        include_noexec => {
            summary => 'Include scripts that do not have +x mode bit set',
            schema  => 'bool*',
            default => 1,
        },
    },
};
sub detect_pericmd_script {
    my %args = @_;

    (defined($args{filename}) xor defined($args{string}))
        or return [400, "Please specify either filename or string"];
    my $include_noexec  = $args{include_noexec}  // 1;

    my $yesno = 0;
    my $reason = "";

    my $meta = {};

    my $str = $args{string};
  DETECT:
    {
        if (defined $args{filename}) {
            my $fn = $args{filename};
            unless (-f $fn) {
                $reason = "'$fn' is not a file";
                last;
            };
            if (!$include_noexec && !(-x _)) {
                $reason = "'$fn' is not an executable";
                last;
            }
            my $fh;
            unless (open $fh, "<", $fn) {
                $reason = "Can't be read";
                last;
            }
            # for efficiency, we read a bit only here
            read $fh, $str, 2;
            unless ($str eq '#!') {
                $reason = "Does not start with a shebang (#!) sequence";
                last;
            }
            my $shebang = <$fh>;
            unless ($shebang =~ /perl/) {
                $reason = "Does not have 'perl' in the shebang line";
                last;
            }
            seek $fh, 0, 0;
            {
                local $/;
                $str = <$fh>;
            }
        }
        unless ($str =~ /\A#!/) {
            $reason = "Does not start with a shebang (#!) sequence";
            last;
        }
        unless ($str =~ /\A#!.*perl/) {
            $reason = "Does not have 'perl' in the shebang line";
            last;
        }
        if ($str =~ /^#\s*NO_PERINCI_CMDLINE_SCRIPT\s*$/m) {
            $reason = "Marked with # NO_PERINCI_CMDLINE_SCRIPT directive";
            last;
        }

        # NOTE: the presence of \s* pattern after ^ causes massive slowdown of
        # the regex when we reach many thousands of lines, so we use split()

        #if ($str =~ /^\s*(use|require)\s+
        #    (Perinci::CmdLine(|::Any|::Lite|::Classic))/mx) {

        if ($str =~ /^# PERICMD_INLINE_SCRIPT: (.+)/m) {
            $yesno = 1;
            $meta->{'func.module'} = 'Perinci::CmdLine::Inline';
            $meta->{'func.is_inline'} = 1;

            my $pericmd_inline_attrs = $1;
            my ($pericmd_inline_version) =
                $str =~ /Perinci::CmdLine::Inline version ([0-9._]+)/;
            $meta->{'func.notes'} //= [];
            $meta->{'func.pericmd_inline_version'} = $pericmd_inline_version;
            if (!$pericmd_inline_version) {
                push @{ $meta->{'func.notes'} },
                    "Can't detect version of Perinci::CmdLine::Inline version";
            }
            if ($pericmd_inline_version < 0.17) {
                push @{ $meta->{'func.notes'} }, join(
                    "",
                    "Won't parse # PERICMD_INLINE_SCRIPT attributes ",
                    "because prior to Perinci::CmdLine::Inline 0.17, ",
                    "the attributes are dumped as Perl instead of JSON ",
                    "so it's unsafe to parse",
                );
            } else {
                require JSON::MaybeXS;
                eval { $pericmd_inline_attrs =
                           JSON::MaybeXS::decode_json($pericmd_inline_attrs) };
                if ($@) {
                    push @{ $meta->{'func.notes'} },
                        "Can't parse # PERICMD_INLINE_SCRIPT line: $@";
                } else {
                    $meta->{'func.pericmd_inline_attrs'} =
                        $pericmd_inline_attrs;
                }
            }

            if ($str =~ /^my \$_pci_metas = (.+);/m) {
                my $pericmd_inline_metas = $1;
                eval "\$pericmd_inline_metas = $1";
                if ($@) {
                    push @{ $meta->{'func.notes'} },
                        "Can't parse 'my \$_pci_metas = ...' line: $@";
                } else {
                    $meta->{'func.pericmd_inline_metas'} =
                        $pericmd_inline_metas;
                }
            }

            last DETECT;
        }

        for (split /^/, $str) {
            if (/^\s*(use|require)\s+(Perinci::CmdLine(|::Any|::Lite|::Classic))\b/) {
                $yesno = 1;
                $meta->{'func.module'} = $2;
                last DETECT;
            }
        }

        $reason = "Can't find any statement requiring Perinci::CmdLine".
            " module family";
    } # DETECT

    $meta->{'func.reason'} = $reason;

    [200, "OK", $yesno, $meta];
}

{
    no strict 'refs';
    # old name, deprecated
    *detect_perinci_cmdline_script = \&detect_pericmd_script;
}

1;
# ABSTRACT: Utility routines related to Perinci::CmdLine

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Util - Utility routines related to Perinci::CmdLine

=head1 VERSION

This document describes version 0.15 of Perinci::CmdLine::Util (from Perl distribution Perinci-CmdLine-Util), released on 2017-01-12.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 detect_pericmd_script(%args) -> [status, msg, result, meta]

Detect whether a file is a Perinci::CmdLine-based CLI script.

The criteria are:

=over

=item * the file must exist and readable;

=item * (optional, if C<include_noexec> is false) file must have its executable mode
bit set;

=item * content must start with a shebang C<#!>;

=item * either: must be perl script (shebang line contains 'perl') and must contain
something like C<use Perinci::CmdLine>;

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<str>

Path to file to be checked.

Either C<filename> or C<string> must be specified.

=item * B<include_noexec> => I<bool> (default: 1)

Include scripts that do not have +x mode bit set.

=item * B<string> => I<buf>

Path to file to be checked.

Either C<file> or C<string> must be specified.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(detect_perinci_cmdline_script)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
