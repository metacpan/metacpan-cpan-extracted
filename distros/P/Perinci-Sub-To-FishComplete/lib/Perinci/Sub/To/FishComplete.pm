package Perinci::Sub::To::FishComplete;

our $DATE = '2015-09-04'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use String::ShellQuote;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_fish_complete_from_meta);

$SPEC{gen_fish_complete_from_meta} = {
    v => 1.1,
    summary => 'From Rinci function metadata, generate tab completion '.
        'commands for the fish shell',
    description => <<'_',


_
    args => {
        meta => {
            schema => 'hash*', # XXX rifunc
            req => 1,
            pos => 0,
        },
        meta_is_normalized => {
            schema => 'bool*',
        },
        common_opts => {
            summary => 'Will be passed to gen_getopt_long_spec_from_meta()',
            schema  => 'hash*',
        },
        gcd_res => {
            summary => 'Full result from gen_cli_doc_data_from_meta()',
            schema  => 'array*', # XXX envres
            description => <<'_',

If you already call `Perinci::Sub::To::CLIDocData`'s
`gen_cli_opt_spec_from_meta()`, you can pass the _full_ enveloped result here,
to avoid calculating twice.

_
        },
        per_arg_json => {
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
            schema => 'bool',
        },
        per_arg_yaml => {
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
            schema => 'bool',
        },
        lang => {
            schema => 'str*',
        },

        cmdname => {
            summary => 'Command name',
            schema => 'str*',
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_meta {
    my %args = @_;

    my $lang = $args{lang};
    my $meta = $args{meta} or return [400, 'Please specify meta'];
    my $common_opts = $args{common_opts};
    unless ($args{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }
    my $gcd_res = $args{gcd_res} // do {
        require Perinci::Sub::To::CLIDocData;
        Perinci::Sub::To::CLIDocData::gen_cli_doc_data_from_meta(
            meta=>$meta, meta_is_normalized=>1, common_opts=>$common_opts,
            per_arg_json => $args{per_arg_json},
            per_arg_yaml => $args{per_arg_yaml},
        );
    };
    $gcd_res->[0] == 200 or return $gcd_res;
    my $clidocdata = $gcd_res->[2];

    my $cmdname = $args{cmdname};
    if (!$cmdname) {
        ($cmdname = $0) =~ s!.+/!!;
    }

    my @cmds;
    my $prefix = "complete -c ".shell_quote($cmdname);
    push @cmds, "$prefix -e"; # currently does not work (fish bug)
    for my $opt0 (sort keys %{ $clidocdata->{opts} }) {
        my $ospec = $clidocdata->{opts}{$opt0};
        my $req_arg;
        for my $opt (split /, /, $opt0) {
            $opt =~ s/^--?//;
            $opt =~ s/=(.+)// and $req_arg = $1;

            my $cmd = $prefix;
            $cmd .= length($opt) > 1 ? " -l '$opt'" : " -s '$opt'";
            $cmd .= " -d ".shell_quote($ospec->{summary}) if $ospec->{summary};

          COMP_ARG_VAL:
            {
                last unless $req_arg;
                $cmd .= " -r -f";
                # check if completion is static, if yes then we can directly
                # specify the entries to the shell
                {
                    require Perinci::Sub::Complete;

                    my $compres;
                    last if $ospec->{is_json} || $ospec->{is_yaml} ||
                        $ospec->{is_base64};
                    #say "D:Checking if $opt has static completion ...";
                    if ($ospec->{arg}) {
                        if ($req_arg =~ /\@/) {
                            $compres =
                                Perinci::Sub::Complete::complete_arg_elem(
                                    arg=>$ospec->{arg}, ci=>1, index=>0,
                                    meta=>$meta,
                                );
                        } else {
                            $compres =
                                Perinci::Sub::Complete::complete_arg_val(
                                    arg=>$ospec->{arg}, ci=>1, meta=>$meta,
                                );
                        }
                    } elsif ($ospec->{is_alias} &&
                                 $ospec->{alias_spec}{schema}) {
                        # cmdline alias which has schema
                        require Data::Sah::Normalize;
                        $compres = Perinci::Sub::Complete::complete_from_schema(
                            ci=>1,
                            schema=>Data::Sah::Normalize::normalize_schema($ospec->{alias_spec}{schema}),
                        );
                    } elsif ($ospec->{schema}) {
                        # common opt which has schema
                        require Data::Sah::Normalize;
                        $compres = Perinci::Sub::Complete::complete_from_schema(
                            ci=>1,
                            schema=>Data::Sah::Normalize::normalize_schema($ospec->{schema}),
                        );
                    }

                    last unless $compres;
                    if ($compres->{static}) {
                        # XXX description
                        # XXX escape space
                        my @words = map {ref($_) ? $_->{word}:$_}
                            @{$compres->{words}};
                        $cmd .= " -a ".shell_quote(join(" ", @words));
                        last COMP_ARG_VAL;
                    }
                } # COMP_ARG_VAL
                # completion is not static, delegate to the program when
                # completing
                $cmd .= " -a ".shell_quote("(begin; set -lx COMP_SHELL fish; set -lx COMP_LINE (commandline); set -lx COMP_POINT (commandline -C); ".shell_quote($cmdname)."; end)");
            }
            push @cmds, $cmd;
        } # for opt
    } # for opt0

    [200, "OK", join("", map {"$_\n"} @cmds)];
}

1;
# ABSTRACT: From Rinci function metadata, generate tab completion commands for the fish shell

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::To::FishComplete - From Rinci function metadata, generate tab completion commands for the fish shell

=head1 VERSION

This document describes version 0.03 of Perinci::Sub::To::FishComplete (from Perl distribution Perinci-Sub-To-FishComplete), released on 2015-09-04.

=head1 SYNOPSIS

 use Perinci::Sub::To::FishComplete qw(gen_fish_complete_from_meta);
 my $res = gen_fish_complete_from_meta(meta => $meta);
 die "Failed: $res->[0] - $res->[1]" unless $res->[0] == 200;
 say $res->[2];

=head1 SEE ALSO

This module is used by L<Perinci::CmdLine>.

L<Complete::Fish::Gen::FromGetoptLong>.

=head1 FUNCTIONS


=head2 gen_fish_complete_from_meta(%args) -> [status, msg, result, meta]

From Rinci function metadata, generate tab completion commands for the fish shell.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdname> => I<str>

Command name.

=item * B<common_opts> => I<hash>

Will be passed to gen_getopt_long_spec_from_meta().

=item * B<gcd_res> => I<array>

Full result from gen_cli_doc_data_from_meta().

If you already call C<Perinci::Sub::To::CLIDocData>'s
C<gen_cli_opt_spec_from_meta()>, you can pass the I<full> enveloped result here,
to avoid calculating twice.

=item * B<lang> => I<str>

=item * B<meta>* => I<hash>

=item * B<meta_is_normalized> => I<bool>

=item * B<per_arg_json> => I<bool>

Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv.

=item * B<per_arg_yaml> => I<bool>

Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A script that can be fed to the fish shell (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-To-FishComplete>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-To-FishComplete>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-To-FishComplete>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
