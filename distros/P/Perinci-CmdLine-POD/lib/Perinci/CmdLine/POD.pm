package Perinci::CmdLine::POD;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Data::Dmp;
use IPC::System::Options qw(system);
use Proc::ChildError qw(explain_child_error);
use String::ShellQuote;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Perinci-CmdLine-POD'; # DIST
our $VERSION = '0.039'; # VERSION

our @EXPORT_OK = qw(gen_pod_for_pericmd_script);

our $pa = do {
    require Perinci::Access::Perl;
    Perinci::Access::Perl->new;
};

our %SPEC;

sub _fmt_opt {
    my ($opt, $ospec) = @_;

    my @res;

    my $has_text;

    my $arg_spec = $ospec->{arg_spec};
    my $is_bool = $arg_spec->{schema} &&
        $arg_spec->{schema}[0] eq 'bool';
    my $show_default = exists($ospec->{default}) &&
        !$is_bool && !$ospec->{main_opt} && !$ospec->{is_alias};

    my $add_sum = '';
    if ($ospec->{is_base64}) {
        $add_sum = " (base64-encoded)";
    } elsif ($ospec->{is_json}) {
        $add_sum = " (JSON-encoded)";
    } elsif ($ospec->{is_yaml}) {
        $add_sum = " (YAML-encoded)";
    }

    $opt =~ s/(?P<name>--?.+?)(?P<val>=(?P<dest>[\w@-]+)|,|\z)/"B<" . $+{name} . ">" . ($+{dest} ? "=I<".$+{dest}.">" : $+{val})/eg;

    push @res, "=item $opt\n\n";

    if ($ospec->{summary}) {
        push @res, "$ospec->{summary}$add_sum.\n\n";
        $has_text++;
    }

    if ($show_default) {
        push @res, "Default value:\n\n ", dmp($ospec->{default}), "\n\n";
        $has_text++;
    }

    if ($arg_spec->{schema} && !$ospec->{is_alias}) {
        if ($arg_spec->{schema}[1]{in}) {
            push @res, "Valid values:\n\n ", dmp($arg_spec->{schema}[1]{in}), "\n\n";
            $has_text++;
        } elsif ($arg_spec->{schema}[1]{examples}) {
            push @res, "Example valid values:\n\n ", dmp($arg_spec->{schema}[1]{examples}), "\n\n";
            $has_text++;
        }
    }

    if ($ospec->{main_opt}) {
        my $main_opt = $ospec->{main_opt};
        $main_opt =~ s/\s*,.+//;
        $main_opt =~ s/=.+//;
        push @res, "See C<$main_opt>.\n\n";
        $has_text++;
    } else {
        require Markdown::To::POD;

        my $description = $ospec->{description};
        $description = '(No description)' if !defined $description && !$has_text;
        push @res, Markdown::To::POD::markdown_to_pod($description), "\n\n"
            if $description;
    }

    if (defined $arg_spec->{pos}) {
        require Lingua::EN::Numbers::Ordinate;
        my $ord = Lingua::EN::Numbers::Ordinate::ordinate($arg_spec->{pos} + 1);
        if ($arg_spec->{slurpy} ||
                $arg_spec->{greedy} # old name
            ) {
            push @res, "Can also be specified as the $ord command-line argument and onwards.\n\n";
        } else {
            push @res, "Can also be specified as the $ord command-line argument.\n\n";
        }
    }

    if (($ospec->{orig_opt} // '') =~ /\@/) {
        push @res, "Can be specified multiple times.\n\n";
    } elsif (($ospec->{orig_opt} // '') =~ /\%/) {
        push @res, "Each value is a name-value pair, use I<key=value> syntax. Can be specified multiple times.\n\n";
    }

    join "", @res;
}

sub _list_config_params {
    my ($clidocdata, $filter) = @_;

    my $opts = $clidocdata->{opts};
    my %param2opts;
    for (keys %$opts) {
        my $ospec = $opts->{$_};
        next unless $ospec->{common_opt} && $ospec->{common_opt_spec}{is_settable_via_config};
        next if $filter && !$filter->($ospec);
        my $oname = $ospec->{opt_parsed}{opts}[0];
        $oname = length($oname) > 1 ? "--$oname" : "-$oname";
        $param2opts{ $ospec->{common_opt} } = $oname;
    }
    for (keys %$opts) {
        my $ospec = $opts->{$_};
        next unless $ospec->{arg};
        next if $ospec->{main_opt};
        next if $filter && !$filter->($ospec);
        my $oname = $ospec->{opt_parsed}{opts}[0];
        $oname = length($oname) > 1 ? "--$oname" : "-$oname";
        my $confname = $param2opts{$_} ?
            "$ospec->{arg}.arg" : $ospec->{arg};
        $param2opts{$confname} = $oname;
    }
    \%param2opts;
}

$SPEC{gen_pod_for_pericmd_script} = {
    v => 1.1,
    summary => 'Generate POD for Perinci::CmdLine-based CLI script',
    description => <<'_',

This utility can accept either a path to a <pm:Perinci::CmdLine>-based CLI
script, upon which the arguments to Perinci::CmdLine constructor will be
extracted using a script dumper (<pm:Perinci::CmdLine::Dump>), or a set of
arguments to specify Perinci::CmdLine constructor arguments directly (e.g.
`url`, `summary`, `subcommands`, etc).

_
    args => {
        script => {
            summary => 'Path to script',
            schema => 'filename*',
            tags => ['category:script-source'],
        },
        libs => {
            summary => 'Extra libraries to pass to perl via -I',
            schema => ['array*', of=>'dirname*'],
        },

        url => {
            summary => 'Set `url` attribute, see Perinci::CmdLine::Base for more details',
            schema => 'str*',
            tags => ['category:script-specification'],
        },
        program_name => {
            summary => 'Set `program_name` attribute, see Perinci::CmdLine::Base',
            schema => 'str*',
            tags => ['category:script-specification'],
        },
        summary => {
            summary => 'Set `summary` attribute, see Perinci::CmdLine::Base',
            schema => 'str*',
            tags => ['category:script-specification'],
        },
        common_opts => {
            summary => 'Set `common_opts` attribute, see Perinci::CmdLine::Base',
            schema => 'hash*',
            tags => ['category:script-specification'],
        },
        subcommands => {
            summary => 'Set `subcommands` attribute, see Perinci::CmdLine::Base',
            schema => ['hash*', of=>'hash*'],
            tags => ['category:script-specification'],
        },
        default_subcommand => {
            summary => 'Set `default_subcommand` attribute, see Perinci::CmdLine::Base',
            schema => 'str*',
            tags => ['category:script-specification'],
        },
        per_arg_json => {
            summary => 'Set `per_arg_json` attribute, see Perinci::CmdLine::Base',
            schema => ['bool*', is=>1],
            default => 1,
            tags => ['category:script-specification'],
        },
        per_arg_yaml => {
            summary => 'Set `per_arg_yaml` attribute, see Perinci::CmdLine::Base',
            schema => ['bool*', is=>1],
            default => 1,
            tags => ['category:script-specification'],
        },
        read_env => {
            summary => 'Set `read_env` attribute, see Perinci::CmdLine::Base',
            schema => ['bool*', is=>1],
            default => 1,
            tags => ['category:script-specification'],
        },
        env_name => {
            summary => 'Set `env_name` attribute, see Perinci::CmdLine::Base',
            schema => 'str*',
            tags => ['category:script-specification'],
        },
        read_config => {
            summary => 'Set `read_config` attribute, see Perinci::CmdLine::Base',
            schema => ['bool*', is=>1],
            default => 1,
            tags => ['category:script-specification'],
        },
        config_filename => {
            summary => 'Set `config_filename` attribute, see Perinci::CmdLine::Base',
            schema => ['any*', of=>[
                'str*',
                ['array*', of=>'str*'],
                ['array*', of=>'hash*'],
            ]],
            tags => ['category:script-specification'],
        },
        config_dirs => {
            summary => 'Set `config_dirs` attribute, see Perinci::CmdLine::Base',
            schema => ['array*', of=>'dirname*'],
            tags => ['category:script-specification'],
        },

        completer_script => {
            summary => 'Script name for shell completion',
            schema => ['str*'],
            description => <<'_',

A special value of `:self` means this script can complete itself.

Without specifying this option, the COMPLETION POD section will not be
generated.

_
            tags => ['category:completion-specification'],
        },

        gen_subcommands => {
            summary => 'Whether to generate POD for subcommands',
            'summary.alt.bool.not' => "Do not generate POD for subcommands",
            schema => 'bool*',
            default => 1,
            description => <<'_',

If you want to generate separate POD/manpage for each subcommand, you can use
this option for the main CLI POD, then generate each subcommand's POD with the
`--gen-subcommand=SUBCOMMAND_NAME` option.

_
            tags => ['category:output'],
        },
        gen_subcommand => {
            summary => 'Only generate POD for this subcommand',
            schema => 'str*',
            description => <<'_',

See `--gen-subcommands`.

_
            tags => ['category:output'],
        },

    },
    args_rels => {
        req_one => [qw/script url/],
        choose_all => [qw/url common_opts/],
    },
};
sub gen_pod_for_pericmd_script {
    no warnings 'once';
    require Text::Wrap;

    my %args = @_;

    my %metas; # key = subcommand name

    my ($cli, $dump_res);
    if (defined $args{script}) {
        require Perinci::CmdLine::Dump;
        $dump_res = Perinci::CmdLine::Dump::dump_pericmd_script(
            filename => $args{script},
            libs => $args{libs},
        );
        return $dump_res unless $dump_res->[0] == 200;
        $cli = $dump_res->[2];
        $cli->{program_name} = $args{program_name} if defined $args{program_name};
        $cli->{env_name}     = $args{env_name}     if defined $args{env_name};
        # XXX override other aspects
        %metas = %{ $dump_res->[3]{'func.pericmd_inline_metas'} }
            if $dump_res->[3]{'func.pericmd_inline_metas'};
    } else {
        require Perinci::CmdLine::Lite;
        $cli = Perinci::CmdLine::Lite->new(
            url                => $args{url},
            program_name       => $args{program_name},
            summary            => $args{summary},
            common_opts        => $args{common_opts},
            subcommands        => $args{subcommands},
            default_subcommand => $args{default_subcommand},
            per_arg_json       => $args{per_arg_json},
            per_arg_yaml       => $args{per_arg_yaml},
            read_env           => $args{read_env},
            env_name           => $args{env_name},
            read_config        => $args{read_config},
            config_filename    => $args{config_filenames},
            config_dirs        => $args{config_dirs},
        );
    }

    # script has its metadata in its main:: instead of from a module, so let's
    # put it there
    local %main::SPEC = %{ $dump_res->[3]{'func.meta'} }
        if $dump_res->[3]{'func.meta'};

    # generate clidocdata(for all subcommands; if there is no subcommand then it
    # is stored in key '')
    my %clidocdata; # key = subcommand name
    my %urls; # key = subcommand name

    {
        require Perinci::Sub::To::CLIDocData;

        my $url = $cli->{url};
        $urls{''} = $url;
        my $res = $pa->request(meta => $url);
        die "Can't meta $url: $res->[0] - $res->[1]"
            unless $res->[0] == 200;
        $metas{''} = $res->[2];

        $res = Perinci::Sub::To::CLIDocData::gen_cli_doc_data_from_meta(
            meta => $metas{''},
            meta_is_normalized => 0, # because riap client is specifically set not to normalize
            common_opts  => $cli->{common_opts},
            per_arg_json => $cli->{per_arg_json},
            per_arg_yaml => $cli->{per_arg_yaml},
        );
        die "Can't gen_cli_doc_data_from_meta: $res->[0] - $res->[1]"
            unless $res->[0] == 200;
        $clidocdata{''} = $res->[2];

        if ($cli->{subcommands}) {
            if (ref($cli->{subcommands}) eq 'CODE') {
                die "Script '$args{script}': sorry, coderef 'subcommands' not ".
                    "supported yet";
            }
            for my $sc_name (keys %{ $cli->{subcommands} }) {
                my $sc_spec = $cli->{subcommands}{$sc_name};
                my $url = $sc_spec->{url};
                $urls{$sc_name} = $url;
                unless ($metas{$sc_name}) {
                    my $res = $pa->request(meta => $url);
                    die "Can't meta $url (subcommand $sc_name): $res->[0] - $res->[1]"
                        unless $res->[0] == 200;
                    $metas{$sc_name} = $res->[2];
                }
                $res = Perinci::Sub::To::CLIDocData::gen_cli_doc_data_from_meta(
                    meta => $metas{$sc_name},
                    meta_is_normalized => 0, # because riap client is specifically set not to normalize
                    common_opts => $cli->{common_opts},
                    per_arg_json => $cli->{per_arg_json},
                    per_arg_yaml => $cli->{per_arg_yaml},
                );
                die "Can't gen_cli_doc_data_from_meta (subcommand $sc_name): $res->[0] - $res->[1]"
                    unless $res->[0] == 200;
                $clidocdata{$sc_name} = $res->[2];
            }
        }
    }

    my $gen_sc = $args{gen_subcommand};
    if (defined $gen_sc) {
        return [400, "Unknown subcommand '$gen_sc'"]
            unless $metas{$gen_sc};
    }
    my $gen_scs = $args{gen_subcommands} // 1;

    my $resmeta = {
        'func.sections' => [],
    };
    my @pod;

    my $program_name = $args{program_name} // $cli->{program_name};
    if (!$program_name && defined $args{script}) {
        $program_name = $args{script};
        $program_name =~ s!.+/!!;
    }
    if (!$program_name && defined $args{url} && $args{url} =~ m!.+/([^/]+)\z!) {
        $program_name = $1;
    }
    $program_name //= "PROGRAM";
    my $summary = $args{summary} // $cli->{summary} //
        $metas{''}{summary} // '(no summary)';

    # section: NAME
    {
        my @sectpod;
        if (defined $gen_sc) {
            my $sc_summary = $metas{$gen_sc}{summary} // '(no summary)';
            push @sectpod, "$program_name-$gen_sc - $sc_summary\n\n";
        } else {
            push @sectpod, "$program_name - $summary\n\n";
        }
        push @{ $resmeta->{'func.sections'} }, {name=>'NAME', content=>join("", @sectpod), ignore=>1};
        push @pod, "=head1 NAME\n\n", @sectpod;
    }

    my $version = $metas{''}{entity_v} // '(dev)';

    # section: VERSION
    {
        my @sectpod;
        if (defined $args{gen_subcommand}) {
            push @sectpod, "Part of L<$program_name> version $version\n\n";
        } else {
            push @sectpod, "$version\n\n";
        }
        $resmeta->{'func.section.version'} = \@sectpod;
        push @{ $resmeta->{'func.sections'} }, {name=>'VERSION', content=>join("", @sectpod), ignore=>1};
        push @pod, "=head1 VERSION\n\n", @sectpod;
    }

    # section: EXAMPLES
    my $has_examples;
    {
        my @sectpod;

        my @examples;
        for my $sc_name (sort keys %clidocdata) {
            if ($cli->{subcommands}) {
                next unless length $sc_name;
                if (defined $gen_sc) { next unless $sc_name eq $gen_sc }
            }
            my $i = 1;
            for my $eg (@{ $clidocdata{$sc_name}{examples} }) {
                # add pointer to subcommand, we need it later to show result
                $eg->{_sc_name} = $sc_name;
                $eg->{_i} = $i;
                push @examples, $eg;
                $i++;
            }
        }
        if (@examples) {
            $has_examples++;
            my $num = 0;
            for my $eg (@examples) {
                $num++;
                my $url = $urls{ $eg->{_sc_name} };
                my $meta = $metas{ $eg->{_sc_name} };
                my $title = $eg->{summary} ? $eg->{summary} : "Example #$num";
                push @sectpod, "=head2 $title\n\n";
                my $cmdline = $eg->{cmdline};
                $cmdline =~ s/\[\[prog\]\]/$cli->{subcommands} ? "$program_name $eg->{_sc_name}" : $program_name/eg;
                push @sectpod, " % $cmdline\n";

                my $show_result;
              SHOW_RESULT:
                {
                    my $fres;
                    last unless $eg->{example_spec}{'x.doc.show_result'} // 1;

                    if ($eg->{example_spec}{src}) {
                        if ($eg->{example_spec}{src_plang} =~ /\A(bash)\z/) {
                            # execute script and get its output
                            if (defined $args{script}) {
                                my $cmdline = $eg->{cmdline};
                                $cmdline =~ s/\[\[prog\]\]/shell_quote($^X, (map {"-I$_"} @{ $args{libs} || [] }), $args{script}, ($cli->{subcommands} ? ($eg->{_sc_name}) : ()))/eg;
                                system(
                                    {log=>1, shell => 0, capture_stdout => \$fres},
                                    "bash", "-c", $cmdline);
                                if ($?) {
                                    die sprintf("Example #%d (subcommand %s): cmdline %s: failed: %s", $eg->{_i}, $eg->{_sc_name}, $cmdline, explain_child_error());
                                }
                            }
                            #$self->log_debug(["fres: %s", $fres]);
                        } else {
                            warn sprintf("Example #%d (subcommand %s) has src with unsupported src_plang ($eg->{srg_plang}), skipped showing result", $eg->{_i}, $eg->{_sc_name});
                            last SHOW_RESULT;
                        }
                    } else {
                        my $res;
                        if (exists $eg->{example_spec}{result}) {
                            $res = $eg->{example_spec}{result};
                            $res = [200, "OK", $res] if $meta->{_orig_result_naked};
                        } else {
                            my %extra;
                            if ($eg->{example_spec}{argv}) {
                                $extra{argv} = $eg->{example_spec}{argv};
                            } elsif ($eg->{example_spec}{args}) {
                                $extra{args} = $eg->{example_spec}{args};
                            } else {
                                #$self->log_debug(["Example #%d (subcommand %s) doesn't provide args/argv, skipped showing result", $eg->{_i}, $eg->{_sc_name}]);
                                last SHOW_RESULT;
                            }
                            $res = $pa->request(call => $url, \%extra);
                        }
                        my $format = $res->[3]{'cmdline.default_format'} // $cli->{default_format} // 'text-pretty';
                        require Perinci::Result::Format::Lite;
                        $fres = Perinci::Result::Format::Lite::format($res, $format);
                    }

                    if (my $max_lines = $eg->{example_spec}{'x.doc.max_result_lines'}) {
                        my @lines = split /^/, $fres;
                        if (@lines > $max_lines) {
                            my $n = int($max_lines/2);
                            my $num_remove = @lines - $max_lines + 1;
                            splice @lines, $n, $num_remove, "... ".($num_remove > 1 ? "$num_remove more lines" : "1 more line")." ...\n";
                            $fres = join("", @lines);
                        }
                    }

                    $fres =~ s/^/ /gm;
                    push @sectpod, $fres;
                    push @sectpod, "\n";
                    $show_result = 1;
                } # SHOW_RESULT

                unless ($show_result) {
                    push @sectpod, "\n";
                }

                if ($eg->{description}) {
                    require Markdown::To::POD;

                    push @sectpod, Markdown::To::POD::markdown_to_pod($eg->{description}), "\n\n";
                }

            } # for example
        } # if @examples

        push @{ $resmeta->{'func.sections'} }, {name=>'EXAMPLES', content=>join("", @sectpod), ignore=>1};
        push @pod, "=head1 EXAMPLES\n\n", @sectpod;
    } # section: EXAMPLES

    # section: SYNOPSIS
    {
        my @sectpod;

        # 1. show usage that comes from common options

        my @usage;
        for my $opt (sort keys %{ $cli->{common_opts} || {} }) {
            my $co_spec = $cli->{common_opts}{$opt};
            if (defined $co_spec->{'usage.alt.fmt.pod'}) {
                push @usage, "B<$program_name> ".$co_spec->{'usage.alt.fmt.pod'}."\n\n";
            } elsif (defined $co_spec->{usage}) {
                # text format, the next best thing
                require String::PodQuote;
                push @usage, "B<$program_name> ".String::PodQuote::pod_escape($co_spec->{usage})."\n\n";
            }
        }

        if ($cli->{subcommands}) {
            # 2a. show per-subcommand usage lines, if there are subcommands
            if ($gen_scs) {
                for my $sc_name (sort keys %clidocdata) {
                    next unless length $sc_name;
                    if (defined $gen_sc) { next unless $sc_name eq $gen_sc }
                    my $subcmd_usage = $clidocdata{$sc_name}->{'usage_line.alt.fmt.pod'};
                    $subcmd_usage =~ s/\[\[prog\]\]/$program_name $sc_name/g;
                    push @usage, "$subcmd_usage\n\n";
                }
            } else {
                push @usage, "B<$program_name> [I<options>] [I<subcommand>] [I<arg>]...\n\n";
            }
            push @usage, "\n\n";
        } else {
            # 2b. show main usage line
            my $main_usage = $clidocdata{''}->{'usage_line.alt.fmt.pod'};
            $main_usage =~ s/\[\[prog\]\]/$program_name/g;
            push @usage, "$main_usage\n\n";
        }

        $resmeta->{'func.usage'} = join('', @usage);
        push @sectpod, @usage;

        # point to examples in Examples section, if any
        push @sectpod, "\n\nSee examples in the L</EXAMPLES> section.\n\n" if $has_examples;

        push @{ $resmeta->{'func.sections'} }, {name=>'SYNOPSIS', content=>join("", @sectpod), ignore=>1};
        push @pod, "=head1 SYNOPSIS\n\n", @sectpod;
    }

    # section: DESCRIPTION
    {
        my $k = defined $gen_sc ? $gen_sc : '';
        # XXX proper .alt search
        my $desc = $metas{$k}{'description.alt.env.cmdline'} //
            $metas{$k}{description};
        last unless $desc;

        require Markdown::To::POD;

        my @sectpod;
        push @sectpod,
            Markdown::To::POD::markdown_to_pod($desc);
        push @sectpod, "\n\n";

        push @{ $resmeta->{'func.sections'} }, {name=>'DESCRIPTION', content=>join("", @sectpod), ignore=>1};
        push @pod, "=head1 DESCRIPTION\n\n", @sectpod;
    }

    # section: SUBCOMMANDS
    {
        last unless $cli->{subcommands};
        last if defined $gen_sc;

        my @sectpod;
        my %sc_spec_refs; # key=ref address, val=first subcommand name

        my $i = -1;
        for my $sc_name (sort keys %clidocdata) {
            next unless length $sc_name;
            $i++;
            my $sc_spec = $cli->{subcommands}{$sc_name};

            my $spec_same_as;
            if (defined $sc_spec_refs{"$sc_spec"}) {
                $spec_same_as = $sc_spec_refs{"$sc_spec"};
            } else {
                $sc_spec_refs{"$sc_spec"} = $sc_name;
            }

            if ($gen_scs) {
                my $meta = $metas{$sc_name};
                push @sectpod, "=head2 B<$sc_name>\n\n";

                # assumed alias because spec has been seen before
                if ($spec_same_as) {
                    push @sectpod, "Alias for C<$spec_same_as>.\n\n";
                    next;
                }

                my $summary = $sc_spec->{summary} // $meta->{summary};
                push @sectpod, "$summary.\n\n" if $summary;

                next if $sc_spec->{is_alias};

                my $description = $sc_spec->{description} // $meta->{description};
                if ($description) {
                    require Markdown::To::POD;
                    push @sectpod,
                        Markdown::To::POD::markdown_to_pod($description);
                    push @sectpod, "\n\n";
                }
            } else {
                unless ($i) {
                    push @sectpod, "See each subcommand's documentation for more details, e.g. for the C<$sc_name> subcommand see L<$program_name-$sc_name>.\n\n";
                    push @sectpod, "=over\n\n";
                }
                push @sectpod, "=item * $sc_name\n\n";
            }
        } # for $sc_name
        push @sectpod, "=back\n\n" unless $gen_scs;

        push @{ $resmeta->{'func.sections'} }, {name=>'SUBCOMMANDS', content=>join("", @sectpod), ignore=>1};
        push @pod, "=head1 SUBCOMMANDS\n\n", @sectpod;
    }

    my @sc_names = grep { length } sort keys %clidocdata;

    # section: OPTIONS
    {
        my @sectpod;
        push @sectpod, "C<*> marks required options.\n\n";
        unless ($gen_scs) {
            push @sectpod, "Each subcommand might accept additional options. See each subcommand's documentation for more details.\n\n";
        }
        if ($cli->{subcommands} && !defined $gen_sc) {
            # currently categorize by subcommand instead of category

            my $check_common_arg = sub {
                my ($opts, $name) = @_;
                return 1 if grep { $_ eq 'common' } @{ $opts->{$name}{tags} // []};
                return 1 if !$opts->{$name}{arg};
                0;
            };

            # first display options tagged with 'common' as well as common
            # option (non-function argument option, like --format or
            # --log-level). these are supposed to be the same across
            # subcommands.
            {
                my $opts = $clidocdata{ $sc_names[0] }{opts};
                my @opts = sort {
                    (my $a_without_dash = $a) =~ s/^-+//;
                    (my $b_without_dash = $b) =~ s/^-+//;
                    lc($a) cmp lc($b);
                } grep {$check_common_arg->($opts, $_)} keys %$opts;
                push @sectpod, "=head2 Common options\n\n" if $gen_scs;
                push @sectpod, "=over\n\n";
                for (@opts) {
                    push @sectpod, _fmt_opt($_, $opts->{$_});
                }
                push @sectpod, "=back\n\n";
            }

            if ($gen_scs) {
                # display each subcommand's options (without the options tagged as
                # 'common')
                my %sc_spec_refs;
                for my $sc_name (@sc_names) {
                    my $sc_spec = $cli->{subcommands}{$sc_name};

                    my $spec_same_as;
                    if (defined $sc_spec_refs{"$sc_spec"}) {
                        $spec_same_as = $sc_spec_refs{"$sc_spec"};
                    } else {
                        $sc_spec_refs{"$sc_spec"} = $sc_name;
                    }
                    next if defined $spec_same_as;
                    next if $sc_spec->{is_alias};

                    my $opts = $clidocdata{$sc_name}{opts};
                    my @opts = sort {
                        (my $a_without_dash = $a) =~ s/^-+//;
                        (my $b_without_dash = $b) =~ s/^-+//;
                        lc($a) cmp lc($b);
                    } grep {!$check_common_arg->($opts, $_)} keys %$opts;
                    next unless @opts;
                    my $sc_name_e = $sc_name =~ /\A\S+\z/ ? $sc_name : "'$sc_name'";
                    push @sectpod, "=head2 Options for subcommand $sc_name_e\n\n";
                    push @sectpod, "=over\n\n";
                    for (@opts) {
                        push @sectpod, _fmt_opt($_, $opts->{$_});
                    }
                    push @sectpod, "=back\n\n";
                }
            }
        } else {
            my $k = defined $gen_sc ? $gen_sc : '';
            my $opts = $clidocdata{$k}{opts};
            # find all the categories
            my %options_by_cat; # val=[options...]
            for my $optkey (keys %$opts) {
                for my $cat (@{ $opts->{$optkey}{categories} }) {
                    push @{ $options_by_cat{$cat} }, $optkey;
                }
            }
            my $cats_spec = $clidocdata{$k}{option_categories};
            for my $cat (sort {
                ($cats_spec->{$a}{order} // 50) <=> ($cats_spec->{$b}{order} // 50)
                    || $a cmp $b }
                             keys %options_by_cat) {
                push @sectpod, "=head2 $cat\n\n"
                    unless keys(%options_by_cat) == 1;

                my @opts = sort {
                    (my $a_without_dash = $a) =~ s/^-+//;
                    (my $b_without_dash = $b) =~ s/^-+//;
                    lc($a) cmp lc($b);
                } @{ $options_by_cat{$cat} };
                push @sectpod, "=over\n\n";
                for (@opts) {
                    push @sectpod, _fmt_opt($_, $opts->{$_});
                }
                push @sectpod, "=back\n\n";
            }
        }

        push @{ $resmeta->{'func.sections'} }, {name=>'OPTIONS', content=>join("", @sectpod)};
        push @pod, "=head1 OPTIONS\n\n", @sectpod;
    }

    # section: COMPLETION
    {
        my $completer_name = $args{completer_script};
        last unless defined $completer_name;
        my $self_completing;
        if ($completer_name eq ':self' || $completer_name eq $program_name) {
            $self_completing = 1;
            $completer_name = $program_name;
        }

        my @sectpod;

        my $h2 = "=head2"; # to avoid confusing Pod::Weaver

        if ($self_completing) {
            push @sectpod, <<_;
This script has shell tab completion capability with support for several
shells.

_
        } else {
            push @sectpod, <<_;
The script comes with a companion shell completer script (L<$completer_name>)
for this script.

_
        }

        push @sectpod, <<_;
$h2 bash

To activate bash completion for this script, put:

 complete -C $completer_name $program_name

in your bash startup (e.g. F<~/.bashrc>). Your next shell session will then
recognize tab completion for the command. Or, you can also directly execute the
line above in your shell to activate immediately.

It is recommended, however, that you install modules using L<cpanm-shcompgen>
which can activate shell completion for scripts immediately.

$h2 tcsh

To activate tcsh completion for this script, put:

 complete $program_name 'p/*/`$program_name`/'

in your tcsh startup (e.g. F<~/.tcshrc>). Your next shell session will then
recognize tab completion for the command. Or, you can also directly execute the
line above in your shell to activate immediately.

It is also recommended to install L<shcompgen> (see above).

$h2 other shells

For fish and zsh, install L<shcompgen> as described above.

_

        push @{ $resmeta->{'func.sections'} }, {name=>'COMPLETION', content=>join("", @sectpod)};
        push @pod, "=head1 COMPLETION\n\n", @sectpod;
    }

    # sections: CONFIGURATION FILE & FILES
    {
        last if defined $gen_sc;

        # workaround because currently the dumped object does not contain all
        # attributes in the hash (Moo/Mo issue?), we need to access the
        # attribute accessor method first to get them recorded in the hash. this
        # will be fixed in the dump module in the future.
        local $0 = $program_name;
        local @INC = ("lib", @INC);
        eval "use " . ref($cli) . "()"; ## no critic: BuiltinFunctions::ProhibitStringyEval
        die if $@;

        last unless $cli->read_config;

        my $config_filenames = [];
        my $config_dirs;
        my @files;
        my @sections;

        # section: FILES
        my @files_sectpod;
        {
            if (my $cfns = $cli->config_filename) {
                for my $cfn (ref($cfns) eq 'ARRAY' ? @$cfns : $cfns) {
                    if (ref($cfn) eq 'HASH') {
                        push @$config_filenames, $cfn;
                    } else {
                        push @$config_filenames, {filename=>$cfn};
                    }
                }
            } elsif ($cli->program_name) {
                push @$config_filenames,
                    {filename => $cli->program_name . ".conf"};
            } else {
                push @$config_filenames,
                    {filename => $program_name . ".conf"};
            }
            $config_dirs = $cli->{config_dirs} // ['~/.config', '~', '/etc'];

            for my $config_dir (@$config_dirs) {
                for my $cfn (@$config_filenames) {
                    my $p = "$config_dir/$cfn->{filename}";
                    push @files, $p;
                    push @files_sectpod, $cfn->{section} // '';
                    push @files_sectpod, "=head2 $p\n\n";
                }
            }
        }

        # section: CONFIGURATION FILE
        {
            last if defined $gen_sc;

            my @sectpod;

            push @sectpod, (
                "This script can read configuration files. Configuration files are in the format of L<IOD>, which is basically INI with some extra features.\n\n",

                "By default, these names are searched for configuration filenames (can be changed using C<--config-path>): ",
                (map {(
                    # add those pesky comma's/'or's (for two items: A or B, for
                    # >2 items: A, B, or C)
                    (@files == 2 && $_ == 1 ? " or" : ""),
                    (@files >  2 && $_ == $#files ? ", or" : ""),
                    (@files >  2 && $_ >  0 && $_ < $#files ? "," : ""),
                    ($_ > 0 ? " " : ""),
                    "F<$files[$_]>",
                    (defined($sections[$_]) ? " (under the section C<$sections[$_]>)" : ""),
                )} 0..$#files), ".\n\n",

                "All found files will be read and merged.", "\n\n",

                "To disable searching for configuration files, pass C<--no-config>.\n\n",

                ($cli->{subcommands} ? ("To put configuration for a certain subcommand only, use a section name like C<[subcommand=NAME]> or C<[SOMESECTION subcommand=NAME]>.\n\n") : ()),

                "You can put multiple profiles in a single file by using section names like C<[profile=SOMENAME]> or C<[SOMESECTION profile=SOMENAME]>",
                ($cli->{subcommands} ? " or C<[subcommand=SUBCOMMAND_NAME profile=SOMENAME]> or C<[SOMESECTION subcommand=SUBCOMMAND_NAME profile=SOMENAME]>":""), ". ",
                "Those sections will only be read if you specify the matching C<--config-profile SOMENAME>.", "\n\n",

                "You can also put configuration for multiple programs inside a single file, and use filter C<program=NAME> in section names, e.g. C<[program=NAME ...]> or C<[SOMESECTION program=NAME]>. ",
                "The section will then only be used when the reading program matches.\n\n",

                "You can also filter a section by environment variable using the filter C<env=CONDITION> in section names. ",
                "For example if you only want a section to be read if a certain environment variable is true: C<[env=SOMEVAR ...]> or C<[SOMESECTION env=SOMEVAR ...]>. ",
                "If you only want a section to be read when the value of an environment variable equals some string: C<[env=HOSTNAME=blink ...]> or C<[SOMESECTION env=HOSTNAME=blink ...]>. ",
                "If you only want a section to be read when the value of an environment variable does not equal some string: C<[env=HOSTNAME!=blink ...]> or C<[SOMESECTION env=HOSTNAME!=blink ...]>. ",
                "If you only want a section to be read when the value of an environment variable includes some string: C<[env=HOSTNAME*=server ...]> or C<[SOMESECTION env=HOSTNAME*=server ...]>. ",
                "If you only want a section to be read when the value of an environment variable does not include some string: C<[env=HOSTNAME!*=server ...]> or C<[SOMESECTION env=HOSTNAME!*=server ...]>. ",
                "Note that currently due to simplistic parsing, there must not be any whitespace in the value being compared because it marks the beginning of a new section filter or section name.\n\n",

                "To load and configure plugins, you can use either the C<-plugins> parameter (e.g. C<< -plugins=DumpArgs >> or C<< -plugins=DumpArgs\@before_validate_args >>), ",
                "or use the C<[plugin=NAME ...]> sections, for example:\n\n",
                " [plugin=DumpArgs]\n",
                " -event=before_validate_args\n",
                " -prio=99\n",
                " \n",
                " [plugin=Foo]\n",
                " -event=after_validate_args\n",
                " arg1=val1\n",
                " arg2=val2\n\n",
                " \n\n",
                "which is equivalent to setting C<< -plugins=-DumpArgs\@before_validate_args\@99,-Foo\@after_validate_args,arg1,val1,arg2,val2 >>.\n\n",

                "List of available configuration parameters", ($gen_scs ? "" : " (note that each subcommand might have additional configuration parameter, refer to each subcommand's documentation for more details)"), ":\n\n",
            );

            if ($cli->{subcommands}) {
                # first list the options tagged with 'common' and common options
                # (non-function argument options, like --format or --log-level)
                # which are supposed to be the same across subcommands.
                push @sectpod, "=head2 Common for all subcommands\n\n" if $gen_scs;
                my $param2opts = _list_config_params(
                    $clidocdata{$sc_names[0]},
                    sub { grep { $_ eq 'common' } @{ $_[0]->{tags} // []} || !$_[0]->{arg} });
                for (sort keys %$param2opts) {
                    push @sectpod, " $_ (see $param2opts->{$_})\n";
                }
                push @sectpod, "\n";

                if ($gen_scs) {
                    # now list the options for each subcommand
                    for my $sc_name (@sc_names) {
                        my $sc_spec = $cli->{subcommands}{$sc_name};
                        next if $sc_spec->{is_alias};
                        my $sc_name_e = $sc_name =~ /\A\S+\z/ ? $sc_name : "'$sc_name'";
                        push @sectpod, "=head2 Configuration for subcommand $sc_name_e\n\n";
                        $param2opts = _list_config_params(
                            $clidocdata{$sc_name},
                            sub { !(grep { $_ eq 'common' } @{ $_[0]->{tags} // []}) && $_[0]->{arg} });
                        for (sort keys %$param2opts) {
                            push @sectpod, " $_ (see $param2opts->{$_})\n";
                        }
                        push @sectpod, "\n";
                    }
                }
            } else {
                my $param2opts = _list_config_params($clidocdata{''});
                for (sort keys %$param2opts) {
                    push @sectpod, " $_ (see $param2opts->{$_})\n";
                }
                push @sectpod, "\n";
            }

            push @{ $resmeta->{'func.sections'} }, {name=>'CONFIGURATION FILE', content=>join("", @sectpod), ignore=>1};
            push @pod, "=head1 CONFIGURATION FILE\n\n", @sectpod;
        }

        push @{ $resmeta->{'func.sections'} }, {name=>'FILES', content=>join("", @files_sectpod)};
        push @pod, "=head1 FILES\n\n", @files_sectpod;
    }

    # section: ENVIRONMENT
    {
        my @sectpod;

      FOO_OPT: {
            last if defined $gen_sc;

            # workaround because currently the dumped object does not contain
            # all attributes in the hash (Moo/Mo issue?), we need to access the
            # attribute accessor method first to get them recorded in the hash.
            # this will be fixed in the dump module in the future.
            local $0 = $program_name;
            local @INC = ("lib", @INC);
            eval "use " . ref($cli) . "()"; ## no critic: BuiltinFunctions::ProhibitStringyEval
            die if $@;

            last unless $cli->read_env;
            #$self->log_debug(["skipped file %s (script does not read env)", $filename]);

            my $env_name = $cli->env_name;
            log_trace "env_name=%s (1)", $env_name;
            if (!$env_name) {
                $env_name = uc($program_name);
                $env_name =~ s/\W+/_/g;
                log_trace "env_name=%s (2)", $env_name;
            }

            push @sectpod, "=head2 ", $env_name, "\n\n";
            push @sectpod, "String. Specify additional command-line options.\n\n";
        }

      X_ENVS: {
            my $meta = $metas{ defined $gen_sc ? $gen_sc : '' };
            last unless $meta->{'x.envs'};
            for my $envname (sort keys %{ $meta->{'x.envs'} }) {
                my $envspec = $meta->{'x.envs'}{$envname};
                push @sectpod, "=head2 ", $envname, "\n\n";

                if ($envspec->{schema}) {
                    require Data::Sah::Terse;
                    push @sectpod, Data::Sah::Terse::terse_schema($envspec->{schema}), ". ";
                }
                if ($envspec->{summary}) {
                    push @sectpod, $envspec->{summary}, ".";
                }
                push @sectpod, "\n\n";

                if ($envspec->{description}) {
                    require Markdown::To::POD;
                    push @sectpod, Markdown::To::POD::markdown_to_pod($envspec->{description}), "\n\n";
                }
            }
        } # X_ENVS

        push @{ $resmeta->{'func.sections'} }, {name=>'ENVIRONMENT', content=>join("", @sectpod)};
        push @pod, "=head1 ENVIRONMENT\n\n", @sectpod;
    }


  X_DOC_FAQ: {
        my @sectpod;

        my $meta = $metas{ defined $gen_sc ? $gen_sc : '' };
        last unless $meta->{'x.doc.faq'};

        require Markdown::To::POD;
        push @sectpod, Markdown::To::POD::markdown_to_pod($meta->{'x.doc.faq'}), "\n\n";

        push @{ $resmeta->{'func.sections'} }, {name=>'FAQ', content=>join("", @sectpod)};
        push @pod, "=head1 FAQ\n\n", @sectpod;
    }

    # section: SEE ALSO
    {
        my @sectpod;

        my %seen_urls;
        for my $sc_name (sort keys %clidocdata) {
            my $meta = $metas{$sc_name};
            next unless $meta->{links};
            for my $link0 (@{ $meta->{links} }) {
                my $link = ref($link0) ? $link0 : {url=>$link0};
                my $url = $link->{url};
                next if $seen_urls{$url}++;
                if ($url =~ s!^(pm|pod|prog):(//?)?!!) {
                    push @sectpod, "L<$url>.";
                } else {
                    push @sectpod, "L<$url>.";
                }
                if ($link->{summary}) {
                    push @sectpod, " $link->{summary}";
                    push @sectpod, "." unless $link->{summary} =~ /\.$/;
                }
                require Markdown::To::POD;
                push @sectpod, " " .
                    Markdown::To::POD::markdown_to_pod($link->{description})
                      if $link->{description};
                push @sectpod, "\n\n";
            }
        }

        last unless @sectpod;

        push @{ $resmeta->{'func.sections'} }, {name=>'SEE ALSO', content=>join("", @sectpod)};
        push @pod, "=head1 SEE ALSO\n\n", @sectpod;
    }

    [200, "OK", join("", @pod), $resmeta];
}

1;
# ABSTRACT: Generate POD for Perinci::CmdLine-based CLI script

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::POD - Generate POD for Perinci::CmdLine-based CLI script

=head1 VERSION

This document describes version 0.039 of Perinci::CmdLine::POD (from Perl distribution Perinci-CmdLine-POD), released on 2023-07-09.

=head1 SYNOPSIS

Please see the included CLI script L<gen-pod-for-pericmd-script>.

=for Pod::Coverage ^(new)$

=head1 FUNCTIONS


=head2 gen_pod_for_pericmd_script

Usage:

 gen_pod_for_pericmd_script(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate POD for Perinci::CmdLine-based CLI script.

This utility can accept either a path to a L<Perinci::CmdLine>-based CLI
script, upon which the arguments to Perinci::CmdLine constructor will be
extracted using a script dumper (L<Perinci::CmdLine::Dump>), or a set of
arguments to specify Perinci::CmdLine constructor arguments directly (e.g.
C<url>, C<summary>, C<subcommands>, etc).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<common_opts> => I<hash>

Set `common_opts` attribute, see Perinci::CmdLine::Base.

=item * B<completer_script> => I<str>

Script name for shell completion.

A special value of C<:self> means this script can complete itself.

Without specifying this option, the COMPLETION POD section will not be
generated.

=item * B<config_dirs> => I<array[dirname]>

Set `config_dirs` attribute, see Perinci::CmdLine::Base.

=item * B<config_filename> => I<str|array[str]|array[hash]>

Set `config_filename` attribute, see Perinci::CmdLine::Base.

=item * B<default_subcommand> => I<str>

Set `default_subcommand` attribute, see Perinci::CmdLine::Base.

=item * B<env_name> => I<str>

Set `env_name` attribute, see Perinci::CmdLine::Base.

=item * B<gen_subcommand> => I<str>

Only generate POD for this subcommand.

See C<--gen-subcommands>.

=item * B<gen_subcommands> => I<bool> (default: 1)

Whether to generate POD for subcommands.

If you want to generate separate POD/manpage for each subcommand, you can use
this option for the main CLI POD, then generate each subcommand's POD with the
C<--gen-subcommand=SUBCOMMAND_NAME> option.

=item * B<libs> => I<array[dirname]>

Extra libraries to pass to perl via -I.

=item * B<per_arg_json> => I<bool> (default: 1)

Set `per_arg_json` attribute, see Perinci::CmdLine::Base.

=item * B<per_arg_yaml> => I<bool> (default: 1)

Set `per_arg_yaml` attribute, see Perinci::CmdLine::Base.

=item * B<program_name> => I<str>

Set `program_name` attribute, see Perinci::CmdLine::Base.

=item * B<read_config> => I<bool> (default: 1)

Set `read_config` attribute, see Perinci::CmdLine::Base.

=item * B<read_env> => I<bool> (default: 1)

Set `read_env` attribute, see Perinci::CmdLine::Base.

=item * B<script> => I<filename>

Path to script.

=item * B<subcommands> => I<hash>

Set `subcommands` attribute, see Perinci::CmdLine::Base.

=item * B<summary> => I<str>

Set `summary` attribute, see Perinci::CmdLine::Base.

=item * B<url> => I<str>

Set `url` attribute, see Perinci::CmdLine::Base for more details.


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

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-POD>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-POD>.

=head1 SEE ALSO

L<Perinci::CmdLine>

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-POD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
