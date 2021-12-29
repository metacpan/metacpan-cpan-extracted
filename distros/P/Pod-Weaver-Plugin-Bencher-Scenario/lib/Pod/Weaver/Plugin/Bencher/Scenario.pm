package Pod::Weaver::Plugin::Bencher::Scenario;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Bencher-Scenario'; # DIST
our $VERSION = '0.250'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

has include_module => (is=>'rw');
has exclude_module => (is=>'rw');
has gen_scenarior_include_module => (is=>'rw');
has gen_scenarior_exclude_module => (is=>'rw');
has bench => (is=>'rw', default=>sub{1});
has bench_startup => (is=>'rw', default=>sub{1});
has sample_bench => (is=>'rw');
has gen_html_tables => (is=>'rw', default=>sub{0});
has result_split_fields => (is=>'rw');
has chart => (is=>'rw', default=>sub{0});

sub mvp_multivalue_args { qw(
                                sample_bench
                                include_module exclude_module
                                gen_scenarior_include_module gen_scenarior_exclude_module
                        ) }

use Bencher::Backend;
use Data::Dmp;
use File::Slurper qw(read_text);
use File::Temp;
use JSON::MaybeXS;
use Perinci::Result::Format::Lite;
use Perinci::Sub::Normalize qw(normalize_function_metadata);
use Perinci::Sub::ConvertArgs::Argv qw(convert_args_to_argv);
use String::ShellQuote;

sub __ver_or_vers {
    my $v = shift;
    if (ref($v) eq 'ARRAY') {
        return join(", ", @$v);
    } else {
        return $v;
    }
}

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub __html_result {
    my ($bench_res, $num) = @_;
    $bench_res = Bencher::Backend::format_result(
        $bench_res, undef, {render_as_text_table=>0},
    );
    $bench_res->[3]{'table.html_class'} = 'sortable-theme-bootstrap';
    my $fres = Perinci::Result::Format::Lite::format($bench_res, "html");
    $fres =~ s/(<table)/$1 data-sortable/
        or die "Can't insert 'data-sortable' to table element";
    my @res;

    push @res, "=begin HTML\n\n";
    if ($num == 1) {
        push @res, join(
            "",
            '<script src="https://code.jquery.com/jquery-3.0.0.min.js"></script>', "\n",
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/sortable/0.8.0/js/sortable.min.js"></script>', "\n",
            '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/sortable/0.8.0/css/sortable-theme-bootstrap.min.css" />', "\n",
        );
    }
    push @res, "\n$fres\n";
    push @res, q|<script>$(document).ready(function () { $("pre:contains('#table|.$num.q|#')").remove() })</script>|, "\n";
    push @res, "\n=end HTML\n\n";
    join('', @res);
}

sub _gen_chart {
    my ($self, $tempdir, $input, $pod, $envres, $table_num) = @_;

    my $zilla = $input->{zilla};

    return unless $self->chart;

    $self->log_debug(["Generating chart (table%d) ...", $table_num]);
    my $output_file = "$tempdir/bencher-result-$table_num.png";
    my $build_file  = "share/images/bencher-result-$table_num.png";
    my $chart_res = Bencher::Backend::chart_result(
        envres      => $envres,
        title       => "table$table_num",
        output_file => $output_file,
        overwrite   => 1,
    );
    if ($chart_res->[0] != 200) {
        $self->log(["Skipped generating chart (table%d): %s", $table_num, $chart_res]);
    } else {
        $self->log(["Generated chart (table%d, output file=%s)",
                    $table_num, $output_file]);
    }

    push @$pod, "The above result presented as chart:\n\n";
    push @$pod, "#IMAGE: $build_file|$output_file\n\n";

    # this is very very dirty. we mark that we have created some chart files in
    # a temp dir, so Dist::Zilla::Plugin::Bencher::Scenario can add them to the
    # build
    $input->{zilla}->{_pwp_bs_tempdir} = $tempdir;
}

sub __render_run_on {
    my $bench_res = shift;
    my $num_cores = $bench_res->[3]{'func.cpu_info'}[0]{number_of_cores};
    join(
        "",
        "Run on: ",
        "perl: I<< ", __ver_or_vers($bench_res->[3]{'func.module_versions'}{perl}), " >>, ",
        "CPU: I<< ", $bench_res->[3]{'func.cpu_info'}[0]{name}, " ($num_cores cores) >>, ",
        "OS: I<< ", $bench_res->[3]{'func.platform_info'}{osname}, " ", $bench_res->[3]{'func.platform_info'}{oslabel}, " version ", $bench_res->[3]{'func.platform_info'}{osvers}, " >>, ",
        "OS kernel: I<< ", $bench_res->[3]{'func.platform_info'}{kname}, " version ", $bench_res->[3]{'func.platform_info'}{kvers}, " >>",
        ".",
    );
}

sub _process_bencher_scenario_or_acme_cpanmodules_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $zilla = $input->{zilla};

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $tempdir = File::Temp::tempdir(CLEANUP=>1);

    my ($raw_scenario, $scenario, $scenario_name, $is_cpanmodules, $cpanmodules_name);
    if ($package =~ /\ABencher::Scenario::/) {
        ($scenario_name = $package) =~ s/\ABencher::Scenario:://;
        $raw_scenario = ${"$package\::scenario"};
        $scenario = Bencher::Backend::parse_scenario(
            scenario => ${"$package\::scenario"});
    } else {
        # Acme::CPANModules
        require Acme::CPANModulesUtil::Bencher;
        $is_cpanmodules = 1;
        ($cpanmodules_name = $package) =~ s/\AAcme::CPANModules:://;
        my $res = Acme::CPANModulesUtil::Bencher::gen_bencher_scenario(
            cpanmodule => $cpanmodules_name);
        $self->log_fatal(["Can't extract scenario from %s: %s", $package, $res])
            unless $res->[0] == 200;
        $raw_scenario = $res->[2];
        $scenario = Bencher::Backend::parse_scenario(
            scenario => $res->[2]);
    }

    # add Synopsis section
    {
        my @pod;
        push @pod, "To run benchmark with default option:\n\n",
            $is_cpanmodules ?
            " % bencher --cpanmodules-module $cpanmodules_name\n\n" :
            " % bencher -m $scenario_name\n\n"
            ;
        my @pmodules = Bencher::Backend::_get_participant_modules($scenario);
        if (@pmodules && !$scenario->{module_startup}) {
            push @pod, "To run module startup overhead benchmark:\n\n",
                $is_cpanmodules ?
                " % bencher --module-startup --cpanmodules-module $cpanmodules_name\n\n" :
                " % bencher --module-startup -m $scenario_name\n\n"
            }
        push @pod, "For more options (dump scenario, list/include/exclude/add ",
            "participants, list/include/exclude/add datasets, etc), ",
            "see L<bencher> or run C<bencher --help>.\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    }

    # add Description section
    {
        last if $is_cpanmodules;

        my @pod;

        push @pod, $self->_md2pod($scenario->{description})
            if $scenario->{description};

        # blurb about Bencher
        push @pod, "Packaging a benchmark script as a Bencher scenario makes ",
            "it convenient to include/exclude/add participants/datasets (either ",
            "via CLI or Perl code), send the result to a central repository, ",
            "among others . See L<Bencher> and L<bencher> (CLI) ",
            "for more details.\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
                ignore => 1,
            });
    }

    my @modules = Bencher::Backend::_get_participant_modules($scenario);

    # add Benchmark Sample Results section
    my @bench_res;
    my $table_num = 0;
    {
        my $fres;
        my @pod;

        my $sample_benches;
        if (!$self->bench) {
            $sample_benches = [];
        } elsif ($self->sample_bench && @{ $self->sample_bench }) {
            $sample_benches = [];
            my $i = -1;
            for (@{ $self->sample_bench }) {
                $i++;
                my $res = eval $_;
                $self->log_fatal(["Invalid sample_bench[$i] specification: %s", $@]) if $@;

                if ($res->{args}) {
                    my $meta = normalize_function_metadata($Bencher::Backend::SPEC{bencher});
                    my $cres = convert_args_to_argv(args => $res->{args}, meta => $meta);
                    $self->log_fatal(["Invalid sample_bench[$i] specification: invalid args: %s - %s", $cres->[0], $cres->[1]])
                        unless $cres->[0] == 200;
                    my $cmd = "C<< bencher ".($is_cpanmodules ? "--cpanmodules-module $cpanmodules_name" : "-m $scenario_name")." ".join(" ", map {shell_quote($_)} @{$cres->[2]})." >>";
                    $res->{cmdline} = $cmd;
                } elsif ($res->{file}) {
                    $res->{result} = decode_json(read_text($res->{file}));
                } else {
                    $self->log_fatal(["Invalid sample_bench[$i] specification: no args/file specified"]);
                }

                push @$sample_benches, $res;
            }
        } else {
            $sample_benches = [
                {
                    cmdline => "bencher ".($is_cpanmodules ? "--cpanmodules-module $cpanmodules_name" : "-m $scenario_name"),
                    cmdline_comment => 'default options',
                    args=>{},
                },
            ];
        }

        last unless @$sample_benches;

        my $i = -1;
        my $first_run_on;
        for my $bench (@$sample_benches) {
            $i++;

            my $bench_res;
            if ($bench->{result}) {
                $bench_res = $bench->{result};
                if ($i > 0) {
                    my $run_on = __render_run_on($bench_res);
                    if ($run_on ne $first_run_on) {
                        $bench->{cmdline_comment} = $run_on;
                    }
                }
            } else {
                $self->log(["Running benchmark of scenario $package with args %s", $bench->{args}]);
                $bench_res = Bencher::Backend::bencher(
                    action => 'bench',
                    scenario => $scenario,
                    note => 'Run by '.__PACKAGE__,
                    %{ $bench->{args} },
                );
            }

            if ($i == 0) {
                $first_run_on = __render_run_on($bench_res);
                push @pod, $first_run_on, "\n\n";
            }

            if ($self->result_split_fields) {
                my $split_bench_res = Bencher::Backend::split_result(
                    $bench_res, [split /\s*[,;]\s*|\s+/, $self->result_split_fields]);
                for my $k (0..$#{$split_bench_res}) {
                    my $split_item = $split_bench_res->[$k];
                    if ($k == 0) { push @pod, "Benchmark command".($bench->{cmdline_comment} ? " ($bench->{cmdline_comment})" : "").":\n\n % $bench->{cmdline}\n\n" }
                    my $fres = Bencher::Backend::format_result($split_item->[1]);
                    $fres =~ s/^/ /gm;
                    $table_num++;
                    my $split_note = @$split_bench_res > 1 ? " (split, part ".($k+1)." of ".(@$split_bench_res+0).")" : "";
                    push @pod, "Result formatted as table$split_note:\n\n";
                    push @pod, " #table$table_num#\n", " ", dmp($split_item->[0]), "\n$fres\n";
                    {
                        $fres = Bencher::Backend::format_result($split_item->[1], undef, {render_as_benchmark_pm=>1});
                        $fres =~ s/^/ /gm;
                        push @pod, "The above result formatted in L<Benchmark.pm|Benchmark> style:\n\n$fres\n";
                    }
                    push @pod, __html_result($bench_res, $table_num) if $self->gen_html_tables;
                    $self->_gen_chart($tempdir, $input, \@pod, $split_item->[1], $table_num);
                    push @bench_res, $split_item->[1];
                }
                push @pod, "\n";
            } else {
                my $fres = Bencher::Backend::format_result($bench_res);
                $fres =~ s/^/ /gm;
                $table_num++;
                push @pod, "Benchmark command".($bench->{cmdline_comment} ? " ($bench->{cmdline_comment})" : "").":\n\n % $bench->{cmdline}\n\n";
                push @pod, "Result formatted as table:\n\n";
                push @pod, " #table$table_num#\n$fres\n\n";
                {
                    $fres = Bencher::Backend::format_result($bench_res, undef, {render_as_benchmark_pm=>1});
                    $fres =~ s/^/ /gm;
                    push @pod, "The above result formatted in L<Benchmark.pm|Benchmark> style:\n\n$fres\n";
                }
                push @pod, __html_result($bench_res, $table_num) if $self->gen_html_tables;
                $self->_gen_chart($tempdir, $input, \@pod, $bench_res, $table_num);
                push @bench_res, $bench_res;
            }
        } # for sample_benches

        if ($self->bench_startup && @modules && !$scenario->{module_startup}) {
            $self->log(["Running module_startup benchmark of scenario $package"]);
            my $bench_res2 = Bencher::Backend::bencher(
                action => 'bench',
                module_startup => 1,
                scenario => $scenario,
                note => 'Run by '.__PACKAGE__,
            );
            $fres = Bencher::Backend::format_result($bench_res2);
            $fres =~ s/^/ /gm;
            $table_num++;
            push @pod, "Benchmark module startup overhead (C<< bencher ".($is_cpanmodules ? "--cpanmodules-module $cpanmodules_name" : "-m $scenario_name")." --module-startup >>):\n\n";
            push @pod, "Result formatted as table:\n\n";
            push @pod, " #table$table_num#\n", $fres, "\n\n";
            {
                $fres = Bencher::Backend::format_result($bench_res2, undef, {render_as_benchmark_pm=>1});
                $fres =~ s/^/ /gm;
                push @pod, "The above result formatted in L<Benchmark.pm|Benchmark> style:\n\n$fres\n";
            }
            push @pod, __html_result($bench_res2, $table_num) if $self->gen_html_tables;
            $self->_gen_chart($tempdir, $input, \@pod, $bench_res2, $table_num);
        }

        if ($table_num) {
            push @pod, "To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.\n\n";
        }

        $self->add_text_to_section(
            $document, join("", @pod), 'BENCHMARK SAMPLE RESULTS',
            {
                after_section => ['BENCHMARKED MODULES', 'SYNOPSIS'],
                before_section => 'DESCRIPTION',
            });
    }

    # add Benchmarked Modules section
    {
        my @modules = @modules;
        # add from scenario's modules property
        if ($scenario->{modules}) {
            for my $mod (keys %{ $scenario->{modules} }) {
                push @modules, $mod unless grep {$mod eq $_} @modules;
            }
            @modules = sort @modules;
        }

        last unless @modules;
        my @pod;

        push @pod, qq(Version numbers shown below are the versions used when running the sample benchmark.\n\n);

        for my $mod (@modules) {
            push @pod, "L<$mod>";
            my $v;
            for (@bench_res) {
                if (defined $_->[3]{'func.module_versions'}{$mod}) {
                    $v = $_->[3]{'func.module_versions'}{$mod};
                    last;
                }
            }
            if (defined $v) {
                push @pod, " ", __ver_or_vers($v);
            }
            push @pod, "\n\n";
        }

        $self->add_text_to_section(
            $document, join("", @pod), 'BENCHMARKED MODULES',
            {
                after_section => 'SYNOPSIS',
                before_section => ['BENCHMARK SAMPLE RESULTS', 'DESCRIPTION'],
            });
    }

    # add Benchmark Participants section
    {
        my @pod;
        my $res = Bencher::Backend::bencher(
            action => 'list-participants',
            scenario => $scenario,
            detail => 1,
        );
        push @pod, "=over\n\n";
        my $i = -1;
        for my $p (@{ $res->[2] }) {
            $i++;
            my $p0 = $scenario->{participants}[$i];
            push @pod, "=item * ", ($p->{name} // ''), " ($p->{type})",
                ($p->{include_by_default} ? "" : " (not included by default)");
            push @pod, " [".join(", ", @{$p0->{tags}})."]" if $p0->{tags};
            push @pod, "\n\n";
            if ($p0->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($p0->{summary}), ".\n\n";
            }

            if ($p->{cmdline}) {
                push @pod, "Command line:\n\n", " $p->{cmdline}\n\n";
            } elsif ($p0->{cmdline_template}) {
                my $c = $p0->{cmdline_template}; $c = dmp($c) if ref($c) eq 'ARRAY';
                push @pod, "Command line template:\n\n", " $c\n\n";
            } elsif ($p0->{fcall_template}) {
                my $val = $p0->{fcall_template}; $val =~ s/^/ /gm;
                push @pod, "Function call template:\n\n", $val, "\n\n";
            } elsif ($p0->{code_template}) {
                my $val = $p0->{code_template}; $val =~ s/^/ /gm;
                push @pod, "Code template:\n\n", $val, "\n\n";
            } elsif ($p->{module}) {
                push @pod, "L<$p->{module}>";
                if ($p->{function}) {
                    push @pod, "::$p->{function}";
                }
                push @pod, "\n\n";
            }

            if ($p0->{description}) {
                require Markdown::To::POD;
                my $pod = Markdown::To::POD::markdown_to_pod(
                    $p0->{description});
                push @pod, $pod, "\n\n";
            }

            push @pod, "\n\n";
        }
        push @pod, "=back\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'BENCHMARK PARTICIPANTS',
            {
                after_section => ['BENCHMARKED MODULES'],
                before_section => ['BENCHMARK SAMPLE RESULTS'],
            });
    }

    # add Benchmarked Datasets section
    {
        last unless $scenario->{datasets} && @{ $scenario->{datasets} };
        my @pod;

        push @pod, "=over\n\n";

        for my $ds (@{ $scenario->{datasets} }) {
            push @pod, "=item * $ds->{name}";
            push @pod, " [".join(", ", @{$ds->{tags}})."]" if $ds->{tags};
            push @pod, "\n\n";
            if (defined $ds->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($ds->{summary}), ".\n\n";
            }
            if ($ds->{description}) {
                require Markdown::To::POD;
                my $pod = Markdown::To::POD::markdown_to_pod(
                    $ds->{description});
                push @pod, $pod, "\n\n";
            }
        }

        # also mentions datasets not included by default. get it from the raw
        # scenario as this is trimmed from the parsed scenario (as to why, i
        # didn't remember).
        for my $ds (@{ $raw_scenario->{datasets} }) {
            next unless defined $ds->{include_by_default} && !$ds->{include_by_default};
            next unless defined $ds->{name};
            push @pod, "=item * $ds->{name} (not included by default)\n\n";
        }

        push @pod, "=back\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'BENCHMARK DATASETS',
            {
                after_section => 'BENCHMARK PARTICIPANTS',
            });
    }

    # create Bencher::ScenarioR::* modules
  GEN_SCENARIOR:
    {
        require Dist::Zilla::File::InMemory;
        my ($rname, $rpkg, $nsname);
        if ($is_cpanmodules) {
            $rname = $input->{filename}; $rname =~ s!CPANModules/!CPANModules_ScenarioR/!;
            $rpkg = "Acme::CPANModules_ScenarioR::$cpanmodules_name";
            $nsname = "Acme::CPANModules_ScenarioR::*";
        } else {
            $rname = $input->{filename}; $rname =~ s!Scenario/!ScenarioR/!;
            $rpkg = "Bencher::ScenarioR::$scenario_name";
            $nsname = "Bencher::ScenarioR::*";
        }

        if ($self->gen_scenarior_include_module && @{ $self->gen_scenarior_include_module }) {
            #$self->log_debug(["TMP:dist has gen_scenarior_include_module config, rpkg=%s, includes=%s", $rpkg, $self->gen_scenarior_include_module]);
            last GEN_SCENARIOR unless grep {$_ eq $rpkg || "Acme::CPANModules_ScenarioR::$_" eq $rpkg || "Bencher::ScenarioR::$_" eq $rpkg} @{ $self->gen_scenarior_include_module };
        }
        if ($self->gen_scenarior_exclude_module && @{ $self->gen_scenarior_exclude_module }) {
            #$self->log_debug(["TMP:dist has gen_scenarior_exclude_module config, rpkg=%s, excludes=%s", $rpkg, $self->gen_scenarior_exclude_module]);
            last GEN_SCENARIOR if grep {$_ eq $rpkg || "Acme::CPANModules_ScenarioR::$_" eq $rpkg || "Bencher::ScenarioR::$_" eq $rpkg} @{ $self->gen_scenarior_exclude_module };
        }

        my $file = Dist::Zilla::File::InMemory->new(
            name => $rname,
            content => join(
                "",
                "## no critic\n",
                "package $rpkg;\n",
                "\n",

                #"# DATE\n",
                #"# VERSION\n",
                "our \$VERSION = ", dmp($zilla->version), "; # VERSION\n", # workaround for being late to add file

                "\n",

                "our \$results = ", dmp(\@bench_res), ";\n",
                "\n",

                "1;\n",
                "# ABSTRACT: $scenario->{summary}\n",
                "\n",

                "=head1 DESCRIPTION\n\n",
                "This module is automatically generated by ".__PACKAGE__." during distribution build.\n\n",
                "A $nsname module contains the raw result of sample benchmark and might be useful for some stuffs later.\n\n",
            ),
        );
        my @caller = caller();
        $file->_set_added_by(
            sprintf("%s (%s line %s)", __PACKAGE__, __PACKAGE__, __LINE__),
        );
        if (grep { $_->name eq $rname } @{ $zilla->files }) {
            $self->log("File $rname already exists (probably by another instance of ".__PACKAGE__.", not adding another one");
        } else {
            $self->log(["Creating file '%s'", $rname]);
            push @{ $zilla->files }, $file;
        }
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub _list_my_scenario_modules {
    my ($self, $input) = @_;

    my @res;
    for my $file (@{ $input->{zilla}->files }) {
        my $name = $file->name;
        next unless $name =~ m!^lib/Bencher/Scenario/!;
        $name =~ s!^lib/!!; $name =~ s/\.pm$//; $name =~ s!/!::!g;
        push @res, $name;
    }
    @res;
}

sub _process_bencher_scenarios_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    # add list of Bencher::Scenario::* modules to Description
    {
        my @pod;
        my @scenario_mods = $self->_list_my_scenario_modules($input);
        push @pod, "This distribution contains the following L<Bencher> scenario modules:\n\n";
        push @pod, "=over\n\n";
        push @pod, "=item * L<$_>\n\n" for @scenario_mods;
        push @pod, "=back\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
                top => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(?:(Acme/CPANModules/.+)|(Bencher/Scenario/.+))\.pm$!) {
        {
            $package = $1 // $2;
            $package =~ s!/!::!g;
            if ($self->include_module && @{ $self->include_module }) {
                last unless grep {$_ eq $package || "Bencher::Scenario::$_" eq $package || "Acme::CPANModules::$_" eq $package} @{ $self->include_module };
            }
            if ($self->exclude_module && @{ $self->exclude_module }) {
                last if grep {$_ eq $package || "Bencher::Scenario::$_" eq $package || "Acme::CPANModules::$_" eq $package} @{ $self->exclude_module };
            }
            $self->_process_bencher_scenario_or_acme_cpanmodules_module($document, $input, $package);
        }
    }
    if ($filename =~ m!^lib/(Bencher/Scenarios/.+)\.pm$!) {
        {
            # since Bencher::Scenario PW plugin might be called more than once,
            # we avoid duplicate processing via a state variable
            state %mem;
            last if $mem{$filename}++;
            $package = $1;
            $package =~ s!/!::!g;
            $self->_process_bencher_scenarios_module($document, $input, $package);
        }
    }
}

1;
# ABSTRACT: Plugin to use when building Bencher::Scenario::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Bencher::Scenario - Plugin to use when building Bencher::Scenario::* distribution

=head1 VERSION

This document describes version 0.250 of Pod::Weaver::Plugin::Bencher::Scenario (from Perl distribution Pod-Weaver-Plugin-Bencher-Scenario), released on 2021-07-31.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Bencher::Scenario]
 ;exclude_module=Foo

=head1 DESCRIPTION

This plugin is to be used when building C<Bencher::Scenario::*> distribution. It
can also be used for C<Acme::CPANModules::*> distribution which contain
benchmarking information. Currently it does the following:

For each C<lib/Bencher/Scenario/*> or C<lib/Acme/CPANModules/*> module file:

=over

=item * Add a Synopsis section (if doesn't already exist) containing a few examples on how to benchmark using the scenario

=item * Add a description about Bencher in the Description section

Only for C<lib/Bencher/Scenario/*> module files.

=item * Add a Benchmark Participants section containing list of participants from the scenario

=item * Add a Benchmark Sample Results containing result from a bencher run

Both normal benchmark and a separate module startup benchmark (if eligible) are
run and shown.

=item * Add a Benchmarked Modules section containing list of benchmarked modules (if any) from the scenario and their versions

=item * Create C<lib/Bencher/ScenarioR/*> or C<lib/Acme/CPANModules_ScenarioR/*> module files that contain sample benchmark result data

These module files contain the raw data, while the Benchmark Sample Results POD
section of the scenario module contains the formatted result. The raw data might
be useful later. For example I'm thinking of adding a utility later, perhaps in
the form of an L<lcpan> subcommand, that can guess whether a module is
relatively fast or slow (compared to similar implementations, which are other
participants on benchmark scenarios). The utility can then suggest faster
alternatives.

=back

For each C<lib/Bencher/Scenarios/*> module file:

=over

=item * Add list of scenario modules at the beginning of Description section

=back

=for Pod::Coverage .*

=head1 CONFIGURATION

=head2 include_module+ => str

Filter only certain scenario modules that get processed. Can be specified
multiple times.

=head2 exclude_module+ => str

Exclude certain scenario modules from being processed. Can be specified multiple
times.

=head2 gen_scenarior_include_module+ => str

Filter only certain scenario modules that we create Bencher::ScenarioR::*
modules for. Can be specified multiple times.

Note that modules excluded using C<include_module> and/or C<exclude_module> are
already excluded.

=head2 gen_scenarior_exclude_module+ => str

Exclude certain scenario modules from getting their Bencher::ScenarioR::*
modules created. Can be specified multiple times.

Note that modules excluded using C<include_module> and/or C<exclude_module> are
already excluded.

=head2 sample_bench+ => hash

Add a sample benchmark. Value is a hash which can contain these keys: C<title>
(specify title for the benchmark), C<args> (hash arguments for bencher()) or
C<file> (instead of running bencher(), use the result from JSON file). Can be
specified multiple times.

=head2 bench => bool (default: 1)

Set to 0 if you do not want to produce any sample benchmarks (including module
startup benchmark).

=head2 bench_startup => bool (default: 1)

Set to 0 if you do not want to produce module startup sample benchmark.

=head2 gen_html_tables => bool (default: 0)

=head2 result_split_fields => str

If specified, will split result table into multiple tables using the specified
fields (comma-separated). For example:

 result_split_fields = dataset

or:

 result_split_fields = participant

Note that module startup benchmark result is not split.

=head2 chart => bool (default: 0)

Whether to produce chart or not. The chart files will be stored in
F<share/images/bencher-result-N.png> where I<N> is the table number.

Note that this plugin will produce this snippets:

 # IMAGE: share/images/bencher-result-N.png

and you'll need to add the plugin L<Dist::Zilla::Plugin::InsertDistImage> to
convert it to actual HTML.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Bencher-Scenario>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Bencher-Scenario>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Bencher-Scenario>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher>

L<Dist::Zilla::Plugin::Bencher::Scenario>

L<Acme::CPANModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
