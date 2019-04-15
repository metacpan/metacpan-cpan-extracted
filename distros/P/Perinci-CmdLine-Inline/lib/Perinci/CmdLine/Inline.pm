package Perinci::CmdLine::Inline;

our $DATE = '2019-04-15'; # DATE
our $VERSION = '0.545'; # VERSION

# line 820, don't know how to turn off this warning?
## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
# false positive? perlcritic gives line 2333 which is way more than the number of lines of this script
## no critic (InputOutput::RequireBriefOpen)

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Data::Dmp;
use JSON::MaybeXS ();
use Module::CoreList::More;
use Module::Path::More qw(module_path);
use Perinci::Sub::Util qw(err);

use Exporter qw(import);
our @EXPORT_OK = qw(gen_inline_pericmd_script);

our %SPEC;

sub _dsah_plc {
    state $plc = do {
        require Data::Sah;
        Data::Sah->new->get_compiler('perl');
    };
    $plc;
}

sub _pack_module {
    my ($cd, $mod) = @_;
    return unless $cd->{gen_args}{pack_deps};
    return if $cd->{module_srcs}{$mod};
    log_info("Adding source code of module %s ...", $mod);
    log_warn("%s is a core module", $mod) if Module::CoreList::More->is_still_core($mod);
    my $path = module_path(module => $mod) or die "Can't load module '$mod'";
    local $/;
    open my($fh), "<", $path or die "Can't read file '$path': $!";
    $cd->{module_srcs}{$mod} = <$fh>;
}

sub _get_meta_from_url {
    no strict 'refs';

    my $url = shift;

    $url =~ m!\A(?:pl:)?((?:/[^/]+)+)/([^/]*)\z!
        or return [412, "URL scheme not supported, only local Perl ".
                       "URL currently supported"];
    my ($mod_pm, $short_func_name) = ($1, $2);
    $mod_pm =~ s!\A/!!;
    (my $mod = $mod_pm) =~ s!/!::!g;
    $mod_pm .= ".pm";
    require $mod_pm;
    my $meta = ${"$mod\::SPEC"}{length $short_func_name ? $short_func_name : ':package'};
    $meta //= {v=>1.1} if !length $short_func_name; # provide a default empty package metadata
    return [412, "Can't find meta for URL '$url'"] unless $meta;
    if (length $short_func_name) {
        defined &{"$mod\::$short_func_name"}
            or return [412, "Can't find function '$short_func_name' for URL '$url'"];
    }
    return [200, "OK", $meta, {
        'func.module' => $mod,
        'func.module_version' => ${"$mod\::VERSION"},
        'func.short_func_name' => $short_func_name,
        'func.func_name' => "$mod\::$short_func_name",
    }];
}

sub _gen_read_env {
    my ($cd) = @_;
    my @l2;

    return "" unless $cd->{gen_args}{read_env};

    _pack_module($cd, "Complete::Bash");
    _pack_module($cd, "Log::ger"); # required by Complete::Bash
    push @l2, "{\n";
    push @l2, '  last unless $_pci_r->{read_env};', "\n";
    push @l2, '  my $env = $ENV{', dmp($cd->{gen_args}{env_name}), '};', "\n";
    push @l2, '  last unless defined $env;', "\n";
    push @l2, '  require Complete::Bash;', "\n";
    push @l2, '  my ($words, undef) = @{ Complete::Bash::parse_cmdline($env, 0) };', "\n";
    push @l2, '  unshift @ARGV, @$words;', "\n";
    push @l2, "}\n";

    join("", @l2);
}

sub _gen_enable_log {
    my ($cd) = @_;

    _pack_module($cd, 'Log::ger');
    _pack_module($cd, 'Log::ger::Output');
    _pack_module($cd, 'Log::ger::Output::Screen');
    _pack_module($cd, 'Log::ger::Util');

    my @l;

    push @l, "### enable logging\n";
    push @l, 'require Log::ger::Output; Log::ger::Output->set("Screen", formatter => sub { '.dmp("$cd->{script_name}: ").' . $_[0] },);', "\n";
    push @l, 'require Log::ger; Log::ger->import;', "\n";
    push @l, "\n";

    join("", @l);
}

sub _gen_read_config {
    my ($cd) = @_;
    my @l2;

    return "" unless $cd->{gen_args}{read_config};

    push @l2, 'if ($_pci_r->{read_config}) {', "\n";
    _pack_module($cd, "Perinci::CmdLine::Util::Config");
    _pack_module($cd, "Log::ger"); # required by Perinci::CmdLine::Util::Config
    _pack_module($cd, "Config::IOD::Reader"); # required by Perinci::CmdLine::Util::Config
    _pack_module($cd, "Config::IOD::Base"); # required by Config::IOD::Reader
    _pack_module($cd, "Data::Sah::Normalize"); # required by Perinci::CmdLine::Util::Config
    _pack_module($cd, "Perinci::Sub::Normalize"); # required by Perinci::CmdLine::Util::Config
    _pack_module($cd, "Sah::Schema::rinci::function_meta"); # required by Perinci::Sub::Normalize
    push @l2, 'log_trace("Reading config file(s) ...");', "\n" if $cd->{gen_args}{log};
    push @l2, '  require Perinci::CmdLine::Util::Config;', "\n";
    push @l2, "\n";
    push @l2, '  my $res = Perinci::CmdLine::Util::Config::read_config(', "\n";
    push @l2, '    config_paths     => $_pci_r->{config_paths},', "\n";
    push @l2, '    config_filename  => ', dmp($cd->{gen_args}{config_filename}), ",\n";
    push @l2, '    config_dirs      => ', dmp($cd->{gen_args}{config_dirs}), ' // ["$ENV{HOME}/.config", $ENV{HOME}, "/etc"],', "\n";
    push @l2, '    program_name     => ', dmp($cd->{script_name}), ",\n";
    push @l2, '  );', "\n";
    push @l2, '  _pci_err($res) unless $res->[0] == 200;', "\n";
    push @l2, '  $_pci_r->{config} = $res->[2];', "\n";
    push @l2, '  $_pci_r->{read_config_files} = $res->[3]{"func.read_files"};', "\n";
    push @l2, '  $_pci_r->{_config_section_read_order} = $res->[3]{"func.section_read_order"}; # we currently dont want to publish this request key', "\n";
    push @l2, "\n";
    push @l2, '  $res = Perinci::CmdLine::Util::Config::get_args_from_config(', "\n";
    push @l2, '    r                  => $_pci_r,', "\n";
    push @l2, '    config             => $_pci_r->{config},', "\n";
    push @l2, '    args               => \%_pci_args,', "\n";
    push @l2, '    program_name       => ', dmp($cd->{script_name}), ",\n";
    push @l2, '    subcommand_name    => $_pci_r->{subcommand_name},', "\n";
    push @l2, '    config_profile     => $_pci_r->{config_profile},', "\n";
    push @l2, '    common_opts        => {},', "\n"; # XXX so currently we can't set e.g. format or
    push @l2, '    meta               => $_pci_metas->{ $_pci_r->{subcommand_name} },', "\n";
    push @l2, '    meta_is_normalized => 1,', "\n";
    push @l2, '  );', "\n";
    push @l2, '  die $res unless $res->[0] == 200;', "\n";
    push @l2, '  my $found = $res->[3]{"func.found"};', "\n";
    push @l2, '  if (defined($_pci_r->{config_profile}) && !$found && defined($_pci_r->{read_config_files}) && @{$_pci_r->{read_config_files}} && !$_pci_r->{ignore_missing_config_profile_section}) {', "\n";
    push @l2, '    _pci_err([412, "Profile \'$_pci_r->{config_profile}\' not found in configuration file"]);', "\n";
    push @l2, '  }', "\n";
    push @l2, '}', "\n"; # if read_config

    join ("", @l2);
}

sub _gen_pci_check_args {
    my ($cd) = @_;

    my @l2;
    push @l2, '    my ($args) = @_;', "\n";
    push @l2, '    my $sc_name = $_pci_r->{subcommand_name};', "\n";
    my $i = -1;
    for my $sc_name (sort keys %{$cd->{metas}}) {
        $i++;
        my $meta = $cd->{metas}{$sc_name};
        my $args_prop = $meta->{args} // {};
        push @l2, '    '.($i ? "elsif":"if").' ($sc_name eq '.dmp($sc_name).") {\n";
        push @l2, "      FILL_FROM_POS: {\n";
        push @l2, "            1;\n"; # to avoid syntax error when there is 0 args
        for my $arg (sort {
            ($args_prop->{$b}{pos} // 9999) <=>
                ($args_prop->{$a}{pos} // 9999)
            } keys %$args_prop) {
            my $arg_spec = $args_prop->{$arg};
            my $arg_opts = $cd->{ggl_res}{$sc_name}[3]{'func.opts_by_arg'}{$arg};
            next unless defined $arg_spec->{pos};
            push @l2, '            if (@ARGV > '.$arg_spec->{pos}.') {';
            push @l2, ' if (exists $args->{"'.$arg.'"}) {';
            push @l2, ' return [400, "You specified '.$arg_opts->[0].' but also argument #'.$arg_spec->{pos}.'"];';
            push @l2, " } else {";
            if ($arg_spec->{slurpy} // $arg_spec->{greedy}) {
                push @l2, ' $args->{"'.$arg.'"} = [splice(@ARGV, '.$arg_spec->{pos}.')];';
            } else {
                push @l2, ' $args->{"'.$arg.'"} = delete($ARGV['.$arg_spec->{pos}.']);';
            }
            push @l2, " }";
            push @l2, " }\n";
        }
        push @l2, "        }\n";
        push @l2, '        my @check_argv = @ARGV;', "\n";

        push @l2, '        # fill from cmdline_src', "\n";
        {
            my $stdin_seen;
            my $req_gen_iter;
            for my $arg (sort {
                my $asa = $args_prop->{$a};
                my $asb = $args_prop->{$b};
                my $csa = $asa->{cmdline_src} // '';
                my $csb = $asb->{cmdline_src} // '';
                # stdin_line is processed before stdin
                ($csa eq 'stdin_line' ? 1:2) <=>
                    ($csa eq 'stdin_line' ? 1:2)
                    ||
                    ($asa->{pos} // 9999) <=> ($asb->{pos} // 9999)
                } keys %$args_prop) {
                my $arg_spec = $args_prop->{$arg};
                my $cs = $arg_spec->{cmdline_src};
                my $sch = $arg_spec->{schema} // '';
                $sch = $sch->[1]{of} if $arg_spec->{stream} && $sch->[0] eq 'array';
                my $type = Data::Sah::Util::Type::get_type($sch);
                next unless $cs;
                if ($cs eq 'stdin_line') {
                    # XXX support stdin_line, cmdline_prompt, is_password (for disabling echo)
                    return [501, "cmdline_src=stdin_line is not yet supported"];
                } elsif ($cs eq 'stdin_or_file') {
                    return [400, "arg $arg: More than one cmdline_src=/stdin/ is found (arg=$stdin_seen)"]
                        if defined $stdin_seen;
                    $stdin_seen = $arg;
                    # XXX support - to mean stdin
                    push @l2, '        { my $fh;';
                    push @l2, ' if (exists $args->{"'.$arg.'"}) {';
                    push @l2, ' open $fh, "<", $args->{"'.$arg.'"} or _pci_err([500,"Cannot open file \'".$args->{"'.$arg.'"}."\': $!"]);';
                    push @l2, ' } else { $fh = \*STDIN }';
                    if ($arg_spec->{stream}) {
                        $req_gen_iter++;
                        push @l2, ' $args->{"'.$arg.'"} = _pci_gen_iter($fh, "'.$type.'", "'.$arg.'")';
                    } elsif ($type eq 'array') {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; [<$fh>] }';
                    } else {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; ~~<$fh> }';
                    }
                    push @l2, " }\n";
                } elsif ($cs eq 'file') {
                    # XXX support - to mean stdin
                    push @l2, '        if (!(exists $args->{"'.$arg.'"}) && '.($arg_spec->{req} ? 1:0).') { _pci_err([500,"Please specify filename for argument \''.$arg.'\'"]) }';
                    push @l2, ' if (exists $args->{"'.$arg.'"}) {';
                    push @l2, ' open my($fh), "<", $args->{"'.$arg.'"} or _pci_err([500,"Cannot open file \'".$_pci_args{"'.$arg.'"}."\': $!"]);';
                    if ($arg_spec->{stream}) {
                        $req_gen_iter++;
                        push @l2, ' $args->{"'.$arg.'"} = _pci_gen_iter($fh, "'.$type.'", "'.$arg.'")';
                    } elsif ($type eq 'array') {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; [<$fh>] }';
                    } else {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; ~~<$fh> }';
                    }
                    push @l2, " }\n";
                } elsif ($cs eq 'stdin') {
                    return [400, "arg $arg: More than one cmdline_src=/stdin/ is found (arg=$stdin_seen)"]
                        if defined $stdin_seen;
                    $stdin_seen = $arg;
                    push @l2, '        unless (exists $args->{"'.$arg.'"}) {';
                    if ($arg_spec->{stream}) {
                        $req_gen_iter++;
                        push @l2, ' $args->{"'.$arg.'"} = _pci_gen_iter(\*STDIN, "'.$type.'", "'.$arg.'")';
                    } elsif ($type eq 'array') {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; [<STDIN>] }';
                    } else {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; ~~<STDIN> }';
                    }
                    push @l2, " }\n";
                } elsif ($cs eq 'stdin_or_files') {
                    return [400, "arg $arg: More than one cmdline_src=/stdin/ is found (arg=$stdin_seen)"]
                        if defined $stdin_seen;
                    $stdin_seen = $arg;
                    push @l2, '        unless (exists $args->{"'.$arg.'"}) {';
                    push @l2, ' @check_argv = ();';
                    if ($arg_spec->{stream}) {
                        $req_gen_iter++;
                        push @l2, ' $args->{"'.$arg.'"} = _pci_gen_iter(\*ARGV, "'.$type.'", "'.$arg.'")';
                    } elsif ($type eq 'array') {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; [<>] }';
                    } else {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; ~~<> }';
                    }
                    push @l2, " }\n";
                } elsif ($cs eq 'stdin_or_args') {
                    return [400, "arg $arg: More than one cmdline_src=/stdin/ is found (arg=$stdin_seen)"]
                        if defined $stdin_seen;
                    $stdin_seen = $arg;
                    push @l2, '        unless (exists $args->{"'.$arg.'"}) {';
                    push @l2, ' @check_argv = ();';
                    if ($arg_spec->{stream}) {
                        $req_gen_iter++;
                        push @l2, ' $args->{"'.$arg.'"} = _pci_gen_iter(\*STDIN, "'.$type.'", "'.$arg.'")';
                    } elsif ($type eq 'array') {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; [map {chomp;$_} <>] }';
                    } else {
                        push @l2, ' $args->{"'.$arg.'"} = do { local $/; ~~<> }';
                    }
                    push @l2, " }\n";
                } else {
                    return [400, "arg $arg: unknown cmdline_src value '$cs'"];
                }
            }

            unless ($req_gen_iter) {
                delete $cd->{sub_srcs}{_pci_gen_iter};
                delete $cd->{module_srcs}{'Data::Sah::Util::Type'};
            }
        } # fill from cmdline_src
        push @l2, "\n";

        push @l2, '        # fill defaults from "default" property and check against schema', "\n";
      GEN_VALIDATION:
        {
            my $has_validation;
            my @l3;
            my @modules_for_all_args;
            my @req_stmts;
            for my $arg (sort keys %$args_prop) {
                my $arg_spec = $args_prop->{$arg};

                # we don't validate streaming input for now
                next if $arg_spec->{stream};

                my $arg_schema = $arg_spec->{schema};
                my $arg_term = '$args->{"'.$arg.'"}';
                if (defined $arg_spec->{default}) {
                    push @l3, "        $arg_term //= ".dmp($arg_spec->{default}).";\n";
                }

                if ($arg_schema && $cd->{gen_args}{validate_args}) {
                    $has_validation++;
                    my $dsah_cd = _dsah_plc->compile(
                        schema => $arg_schema,
                        schema_is_normalized => 1,
                        indent_level => 3,

                        data_term => $arg_term,
                        err_term => '$_sahv_err',
                        return_type => 'str',

                        core_or_pp => 1,
                        ( whitelist_modules => $cd->{gen_args}{allow_prereq} ) x !!$cd->{gen_args}{allow_prereq},
                    );
                    die "Incompatible Data::Sah version (cd v=$dsah_cd->{v}, expected 2)" unless $dsah_cd->{v} == 2;
                    # add require statements for modules needed during
                    # validation
                    for my $mod_rec (@{$dsah_cd->{modules}}) {
                        next unless $mod_rec->{phase} eq 'runtime';
                        next if grep { ($mod_rec->{use_statement} && $_->{use_statement} && $_->{use_statement} eq $mod_rec->{use_statement}) ||
                                           $_->{name} eq $mod_rec->{name} } @modules_for_all_args;
                        push @modules_for_all_args, $mod_rec;
                        if ($mod_rec->{name} =~ /\A(Scalar::Util::Numeric::PP)\z/) {
                            _pack_module($cd, $mod_rec->{name});
                        }
                        my $mod_is_core = Module::CoreList::More->is_still_core($mod_rec->{name});
                        log_warn("Validation code requires non-core module '%s'", $mod_rec->{name})
                            unless $mod_is_core && !$cd->{module_srcs}{$mod_rec->{name}} &&
                            !($cd->{gen_args}{allow_prereq} && grep { $_ eq $mod_rec->{name} } @{$cd->{gen_args}{allow_prereq}});
                        # skip modules that we already require at the
                        # beginning of script
                        next if exists $cd->{req_modules}{$mod_rec->{name}};
                        push @req_stmts, _dsah_plc->stmt_require_module($mod_rec);
                    }
                    push @l3, "        if (exists $arg_term) {\n";
                    push @l3, "            \$_sahv_dpath = [];\n";
                    push @l3, $dsah_cd->{result}, "\n";
                    push @l3, "             ; if (\$_sahv_err) { return [400, \"Argument validation failed: \$_sahv_err\"] }\n";
                    push @l3, "        } # if date arg exists\n";
                }
            }
            push @l3, "\n";

            if ($has_validation) {
                push @l2, map {"        $_\n"} @req_stmts;
                push @l2, "        my \$_sahv_dpath;\n";
                push @l2, "        my \$_sahv_err;\n";
            }

            push @l2, @l3;
        } # GEN_VALIDATION

        push @l2, '        # check required args', "\n";
        for my $arg (sort keys %$args_prop) {
            my $arg_spec = $args_prop->{$arg};
            if ($arg_spec->{req}) {
                push @l2, '        return [400, "Missing required argument: '.$arg.'"] unless exists $args->{"'.$arg.'"};', "\n";
            }
            if ($arg_spec->{schema}[1]{req}) {
                push @l2, '        return [400, "Missing required value for argument: '.$arg.'"] if exists($args->{"'.$arg.'"}) && !defined($args->{"'.$arg.'"});', "\n";
            }
        }

        push @l2, '        _pci_err([500, "Extraneous command-line argument(s): ".join(", ", @check_argv)]) if @check_argv;', "\n";
        push @l2, '        [200];', "\n";
        push @l2, '    }';
    } # for subcommand
    push @l2, ' else { _pci_err([500, "Unknown subcommand1: $sc_name"]); }', "\n";
    $cd->{module_srcs}{"Local::_pci_check_args"} = "sub _pci_check_args {\n".join('', @l2)."}\n1;\n";
}

sub _gen_common_opt_handler {
    my ($cd, $co) = @_;

    my @l;

    my $has_subcommands = $cd->{gen_args}{subcommands};

    if ($co eq 'help') {
        if ($has_subcommands) {
            push @l, 'my $sc_name = $_pci_r->{subcommand_name}; ';
            push @l, 'my $first_non_opt_arg; for (@ARGV) { next if /^-/; $first_non_opt_arg = $_; last } if (!length $sc_name && defined $first_non_opt_arg) { $sc_name = $first_non_opt_arg } ';
            push @l, 'if (!length $sc_name) { print $help_msg } ';
            for (sort keys %{ $cd->{helps} }) {
                push @l, 'elsif ($sc_name eq '.dmp($_).') { print '.dmp($cd->{helps}{$_}).' } ';
            }
            push @l, 'else { _pci_err([500, "Unknown subcommand2: $sc_name"]) } ';
            push @l, 'exit 0';
        } else {
            require Perinci::CmdLine::Help;
            my $res = Perinci::CmdLine::Help::gen_help(
                meta => $cd->{metas}{''},
                common_opts => $cd->{copts},
                program_name => $cd->{script_name},
            );
            return [500, "Can't generate help: $res->[0] - $res->[1]"]
                unless $res->[0] == 200;
            push @l, 'print ', dmp($res->[2]), '; exit 0;';
        }
    } elsif ($co eq 'version') {
        no strict 'refs';
        my $mod = $cd->{sc_mods}{''};
        push @l, "no warnings 'once'; ";
        push @l, "require $mod; " if $mod;
        push @l, 'print "', $cd->{script_name} , ' version ", ';
        if ($cd->{gen_args}{script_version_from_main_version}) {
            push @l, "\$main::VERSION // '?'", ", (\$main::DATE ? \" (\$main\::DATE)\" : '')";
        } else {
            push @l, defined($cd->{gen_args}{script_version}) ? "\"$cd->{gen_args}{script_version}\"" :
                "(\$$mod\::VERSION // '?')",
                    ", (\$$mod\::DATE ? \" (\$$mod\::DATE)\" : '')";
        }
        push @l, ', "\\n"; ';
        push @l, 'print "  Generated by ', __PACKAGE__ , ' version ',
            (${__PACKAGE__."::VERSION"} // 'dev'),
                (${__PACKAGE__."::DATE"} ? " (".${__PACKAGE__."::DATE"}.")" : ""),
                    '\n"; ';
        push @l, 'exit 0';
    } elsif ($co eq 'log_level') {
        push @l, 'if ($_[1] eq "trace") { require Log::ger::Util; Log::ger::Util::set_level("trace") } ';
        push @l, 'if ($_[1] eq "debug") { require Log::ger::Util; Log::ger::Util::set_level("debug") } ';
        push @l, 'if ($_[1] eq "info" ) { require Log::ger::Util; Log::ger::Util::set_level("info" ) } ';
        push @l, 'if ($_[1] eq "error") { require Log::ger::Util; Log::ger::Util::set_level("warn" ) } ';
        push @l, 'if ($_[1] eq "fatal") { require Log::ger::Util; Log::ger::Util::set_level("debug") } ';
        push @l, 'if ($_[1] eq "none")  { require Log::ger::Util; Log::ger::Util::set_level("off"  ) } ';
        push @l, 'if ($_[1] eq "off")   { require Log::ger::Util; Log::ger::Util::set_level("off"  ) } ';
        push @l, '$_pci_r->{log_level} = $_[1];';
    } elsif ($co eq 'trace') {
        push @l, 'require Log::ger::Util; Log::ger::Util::set_level("trace"); $_pci_r->{log_level} = "trace";';
    } elsif ($co eq 'debug') {
        push @l, 'require Log::ger::Util; Log::ger::Util::set_level("debug"); $_pci_r->{log_level} = "debug";';
    } elsif ($co eq 'verbose') {
        push @l, 'require Log::ger::Util; Log::ger::Util::set_level("info" ); $_pci_r->{log_level} = "info" ;';
    } elsif ($co eq 'quiet') {
        push @l, 'require Log::ger::Util; Log::ger::Util::set_level("error"); $_pci_r->{log_level} = "error";';
    } elsif ($co eq 'subcommands') {
        my $scs_text = "Available subcommands:\n";
        for (sort keys %{ $cd->{metas} }) {
            $scs_text .= "  $_\n";
        }
        push @l, 'print ', dmp($scs_text), '; exit 0';
    } elsif ($co eq 'cmd') {
        push @l, '$_[2]{subcommand} = [$_[1]]; '; # for Getopt::Long::Subcommand
        push @l, '$_pci_r->{subcommand_name} = $_[1];';
    } elsif ($co eq 'format') {
        push @l, '$_pci_r->{format} = $_[1];';
    } elsif ($co eq 'json') {
        push @l, '$_pci_r->{format} = (-t STDOUT) ? "json-pretty" : "json";';
    } elsif ($co eq 'naked_res') {
        push @l, '$_pci_r->{naked_res} = 1;';
    } elsif ($co eq 'no_naked_res') {
        push @l, '$_pci_r->{naked_res} = 0;';
    } elsif ($co eq 'no_config') {
        push @l, '$_pci_r->{read_config} = 0;';
    } elsif ($co eq 'config_path') {
        push @l, '$_pci_r->{config_paths} //= []; ';
        push @l, 'push @{ $_pci_r->{config_paths} }, $_[1];';
    } elsif ($co eq 'config_profile') {
        push @l, '$_pci_r->{config_profile} = $_[1];';
    } elsif ($co eq 'no_env') {
        push @l, '$_pci_r->{read_env} = 0;';
    } else {
        die "BUG: Unrecognized common_opt '$co'";
    }
    join "", @l;
}

sub _gen_get_args {
    my ($cd) = @_;

    my @l;

    push @l, 'my %mentioned_args;', "\n";

    _pack_module($cd, "Getopt::Long::EvenLess");
    push @l, "require Getopt::Long::EvenLess;\n";
    push @l, 'log_trace("Parsing command-line arguments ...");', "\n" if $cd->{gen_args}{log};

    if ($cd->{gen_args}{subcommands}) {

        _pack_module($cd, "Getopt::Long::Subcommand");
        push @l, "require Getopt::Long::Subcommand;\n";
        # we haven't added the Complete::* that Getopt::Long::Subcommand depends on

        # generate help message for all subcommands
        {
            require Perinci::CmdLine::Help;
            my %helps; # key = subcommand name
            for my $sc_name (sort keys %{ $cd->{metas} }) {
                next if $sc_name eq '';
                my $meta = $cd->{metas}{$sc_name};
                my $res = Perinci::CmdLine::Help::gen_help(
                    meta => $meta,
                    common_opts => { map {$_ => $cd->{copts}{$_}} grep { $_ !~ /\A(subcommands|cmd)\z/ } keys %{$cd->{copts}} },
                    program_name => "$cd->{script_name} $sc_name",
                );
                return [500, "Can't generate help (subcommand='$sc_name'): $res->[0] - $res->[1]"]
                    unless $res->[0] == 200;
                $helps{$sc_name} = $res->[2];
            }
            # generate help when there is no subcommand specified
            my $res = Perinci::CmdLine::Help::gen_help(
                meta => {v=>1.1},
                common_opts => $cd->{copts},
                program_name => $cd->{script_name},
                program_summary => $cd->{gen_args}{script_summary},
                subcommands => $cd->{gen_args}{subcommands},
            );
            return [500, "Can't generate help (subcommand=''): $res->[0] - $res->[1]"]
                unless $res->[0] == 200;
            $helps{''} = $res->[2];

            $cd->{helps} = \%helps;
        }

        push @l, 'my $help_msg = ', dmp($cd->{helps}{''}), ";\n";

        my @sc_names = sort keys %{ $cd->{metas} };

        for my $stage (1, 2) {
            if ($stage == 1) {
                push @l, 'my $go_spec1 = {', "\n";
            } else {
                push @l, 'my $go_spec2 = {', "\n";
                push @l, "  options => {\n";
            }

            # common options
            my $ggl_res = $cd->{ggl_res}{$sc_names[0]};
            my $specmetas = $ggl_res->[3]{'func.specmeta'};
            for my $o (sort keys %$specmetas) {
                my $specmeta = $specmetas->{$o};
                my $co = $specmeta->{common_opt};
                next unless $co;
                if ($stage == 1) {
                    push @l, "  '$o' => sub { ", _gen_common_opt_handler($cd, $co), " },\n";
                } else {
                    push @l, "    '$o' => {\n";
                    if ($co eq 'cmd') {
                        push @l, "      handler => sub { ", _gen_common_opt_handler($cd, $co), " },\n";
                    } else {
                        push @l, "      handler => sub {},\n";
                    }
                    push @l, "    },\n";
                }
            }
            if ($stage == 1) {
                push @l, "};\n"; # end of %go_spec1
            } else {
                push @l, "  },\n"; # end of options
            }

            if ($stage == 2) {
                # subcommand options
                push @l, "  subcommands => {\n";
                for my $sc_name (sort keys %{ $cd->{metas} }) {
                    my $meta = $cd->{metas}{$sc_name};
                    push @l, "    '$sc_name' => {\n";
                    push @l, "      options => {\n";
                    my $ggl_res = $cd->{ggl_res}{$sc_name};
                    my $specmetas = $ggl_res->[3]{'func.specmeta'};
                    for my $o (sort keys %$specmetas) {
                        my $specmeta = $specmetas->{$o};
                        my $argname = $specmeta->{arg}; # XXX can't handle submetadata yet
                        next unless defined $argname;
                        my $arg_spec = $meta->{args}{$argname};
                        push @l, "        '$o' => {\n";
                        push @l, "          handler => sub { ";
                        if ($specmeta->{is_alias} && $specmeta->{is_code}) {
                            my $alias_spec = $arg_spec->{cmdline_aliases}{$specmeta->{alias}};
                            if ($specmeta->{is_code}) {
                                push @l, 'my $code = ', dmp($alias_spec->{code}), '; ';
                                push @l, '$code->(\%_pci_args);';
                            } else {
                                push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = $_[1];';
                            }
                        } else {
                            if (($specmeta->{parsed}{type} // '') =~ /\@/) {
                                push @l, 'if ($mentioned_args{\'', $specmeta->{arg}, '\'}++) { push @{ $_pci_args{\'', $specmeta->{arg}, '\'} }, $_[1] } else { $_pci_args{\'', $specmeta->{arg}, '\'} = [$_[1]] }';
                            } elsif ($specmeta->{is_json}) {
                                push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = _pci_json()->decode($_[1]);';
                            } elsif ($specmeta->{is_neg}) {
                                push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = 0;';
                            } else {
                                push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = $_[1];';
                            }
                        }
                        push @l, " },\n"; # end of handler
                        push @l, "        },\n"; # end of option
                    }
                    push @l, "      },\n"; # end of options
                    push @l, "    },\n"; # end of subcommand
                }
                push @l, "  },\n"; # end of subcommands
                push @l, "  default_subcommand => ".dmp($cd->{gen_args}{default_subcommand}).",\n";

                push @l, "};\n"; # end of %go_spec2
            } # subcommand options
        } # stage

        push @l, "{\n";
        push @l, '  local @ARGV = @ARGV;', "\n";
        push @l, '  my $old_conf = Getopt::Long::EvenLess::Configure("pass_through");', "\n";
        push @l, '  Getopt::Long::EvenLess::GetOptions(%$go_spec1);', "\n";
        push @l, '  Getopt::Long::EvenLess::Configure($old_conf);', "\n";
        push @l, '  { my $first_non_opt_arg; for (@ARGV) { next if /^-/; $first_non_opt_arg = $_; last } if (!length $_pci_r->{subcommand_name} && defined $first_non_opt_arg) { $_pci_r->{subcommand_name} = $first_non_opt_arg } }', "\n";
        push @l, '  if (!length $_pci_r->{subcommand_name}) { $_pci_r->{subcommand_name} = '.dmp($cd->{gen_args}{default_subcommand}).' } ' if defined $cd->{gen_args}{default_subcommand};
        push @l, "}\n";
        push @l, _gen_read_env($cd);
        push @l, _gen_read_config($cd);
        push @l, 'my $res = Getopt::Long::Subcommand::GetOptions(%$go_spec2);', "\n";
        push @l, '_pci_debug("args after GetOptions: ", \%_pci_args);', "\n" if $cd->{gen_args}{with_debug};
        push @l, '_pci_err([500, "GetOptions failed"]) unless $res->{success};', "\n";
        push @l, 'if (!length $_pci_r->{subcommand_name}) { print $help_msg; exit 0 }', "\n";

    } else {

        my $meta = $cd->{metas}{''};
        # stage 1 is catching common options only (--help, etc)
        for my $stage (1, 2) {
            push @l, "my \$go_spec$stage = {\n";
            for my $go_spec (sort keys %{ $cd->{ggl_res}{''}[2] }) {
                my $specmeta = $cd->{ggl_res}{''}[3]{'func.specmeta'}{$go_spec};
                my $co = $specmeta->{common_opt};
                next if $stage == 1 && !$co;
                push @l, "    '$go_spec' => sub { "; # begin option handler
                if ($co) {
                    if ($stage == 1) {
                        push @l, _gen_common_opt_handler($cd, $co);
                    } else {
                        # empty, we've done handling common options in stage 1
                    }
                } else {
                    my $arg_spec = $meta->{args}{$specmeta->{arg}};
                    push @l, '        ';
                    if ($stage == 1) {
                        # in stage 1, we do not yet deal with argument options
                    } elsif ($specmeta->{is_alias} && $specmeta->{is_code}) {
                        my $alias_spec = $arg_spec->{cmdline_aliases}{$specmeta->{alias}};
                        if ($specmeta->{is_code}) {
                            push @l, 'my $code = ', dmp($alias_spec->{code}), '; ';
                            push @l, '$code->(\%_pci_args);';
                        } else {
                            push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = $_[1];';
                        }
                    } else {
                        if (($specmeta->{parsed}{type} // '') =~ /\@/) {
                            push @l, 'if ($mentioned_args{\'', $specmeta->{arg}, '\'}++) { push @{ $_pci_args{\'', $specmeta->{arg}, '\'} }, $_[1] } else { $_pci_args{\'', $specmeta->{arg}, '\'} = [$_[1]] }';
                        } elsif ($specmeta->{is_json}) {
                            push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = _pci_json()->decode($_[1]);';
                        } elsif ($specmeta->{is_neg}) {
                            push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = 0;';
                        } else {
                            push @l, '$_pci_args{\'', $specmeta->{arg}, '\'} = $_[1];';
                        }
                    }
                    push @l, "\n";
                }
                push @l, " },\n"; # end option handler
            } # options
            push @l, "};\n";
        } # stage
        push @l, 'my $old_conf = Getopt::Long::EvenLess::Configure("pass_through");', "\n";
        push @l, 'Getopt::Long::EvenLess::GetOptions(%$go_spec1);', "\n";
        push @l, 'Getopt::Long::EvenLess::Configure($old_conf);', "\n";
        push @l, _gen_read_env($cd);
        push @l, _gen_read_config($cd);
        push @l, 'my $res = Getopt::Long::EvenLess::GetOptions(%$go_spec2);', "\n";
        push @l, '_pci_err([500, "GetOptions failed"]) unless $res;', "\n";
        push @l, '_pci_debug("args after GetOptions (stage 2): ", \%_pci_args);', "\n" if $cd->{gen_args}{with_debug};

    }

    join "", @l;
}

# keep synchronize with Perinci::CmdLine::Base
my %pericmd_attrs = (

    # the currently unsupported/unused/irrelevant
    (map {(
        $_ => {
            schema => 'any*',
        },
    )} qw/actions common_opts completion
          default_format
          description exit formats
          riap_client riap_version riap_client_args
          tags
          get_subcommand_from_arg
         /),

    pass_cmdline_object => {
        summary => 'Whether to pass Perinci::CmdLine::Inline object',
        schema  => 'bool*',
        default => 0,
    },
    script_name => {
        schema => 'str*',
    },
    script_summary => {
        schema => 'str*',
    },
    script_version => {
        summary => 'Script version (otherwise will use version from url metadata)',
        schema => 'str',
    },
    script_version_from_main_version => {
        summary => "Use script's \$main::VERSION for the version",
        schema => 'bool*',
    },
    url => {
        summary => 'Program URL',
        schema => 'riap::url*',
        pos => 0,
    },
    extra_urls_for_version => {
        summary => 'More URLs to show version for --version',
        description => <<'_',

Currently not implemented in Perinci::CmdLine::Inline.

_
        schema => ['array*', of=>'str*'],
        'x.schema.element_entity' => 'riap_url',
    },
    skip_format => {
        summary => 'Assume that function returns raw text that need '.
            'no formatting, do not offer --format, --json, --naked-res',
        schema  => 'bool*',
        default => 0,
    },
    use_utf8 => {
        summary => 'Whether to set utf8 flag on output',
        schema  => 'bool*',
        default => 0,
    },
    use_cleanser => {
        summary => 'Whether to use data cleanser routine first before producing JSON',
        schema => 'bool*',
        default => 1,
        description => <<'_',

When a function returns result, and the user wants to display the result as
JSON, the result might need to be cleansed first (e.g. using <pm:Data::Clean>)
before it can be encoded to JSON, for example it might contain Perl objects or
scalar references or other stuffs. If you are sure that your function does not
produce those kinds of data, you can set this to false to produce a more
lightweight script.

_
    },
);

$SPEC{gen_inline_pericmd_script} = {
    v => 1.1,
    summary => 'Generate inline Perinci::CmdLine CLI script',
    description => <<'_',

The goal of this module is to let you create a CLI script from a Riap
function/metadata. This is like what <pm:Perinci::CmdLine::Lite> or
<pm:Perinci::CmdLine::Classic> does, except that the generated CLI script will have
the functionalities inlined so it only need core Perl modules and not any of the
`Perinci::CmdLine::*` or other modules to run (excluding what modules the Riap
function itself requires).

It's useful if you want a CLI script that is even more lightweight (in terms of
startup overhead or dependencies) than the one using <pm:Perinci::CmdLine::Lite>.

So to reiterate, the goal of this module is to create a Perinci::CmdLine-based
script which only requires core modules, and has as little startup overhead as
possible.

Currently it only supports a subset of features compared to other
`Perinci::CmdLine::*` implementations:

* Only support local Riap URL (e.g. `/Foo/bar`, not
  `http://example.org/Foo/bar`);

As an alternative to this module, if you are looking to reduce dependencies, you
might also want to try using `depak` to fatpack/datapack your
<pm:Perinci::CmdLine::Lite>-based script.

_
    args_rels => {
        'dep_any&' => [
            [meta_is_normalized => ['meta']],
            [default_subcommand => ['subcommands']],
        ],
        'req_one&' => [
            [qw/url meta/],
            [qw/url subcommands/],
        ],
        'choose_all&' => [
            [qw/meta sub_name/],
        ],
   },
    args => {
        (map {
            $_ => {
                %{ $pericmd_attrs{$_} },
                summary => $pericmd_attrs{$_}{summary} // 'Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base',
                tags => ['category:pericmd-attribute'],
            },
        } keys %pericmd_attrs),

        meta => {
            summary => 'An alternative to specifying `url`',
            schema => 'hash',
            tags => ['category:input'],
        },
        meta_is_normalized => {
            schema => 'bool',
            tags => ['category:input'],
        },
        sub_name => {
            schema => 'str*',
            tags => ['category:input'],
        },

        subcommands => {
            schema => ['hash*', of=>'hash*'],
            tags => ['category:input'],
        },
        default_subcommand => {
            schema => 'str*',
            tags => ['category:input'],
        },

        shebang => {
            summary => 'Set shebang line',
            schema  => 'str*',
        },
        validate_args => {
            summary => 'Whether the CLI script should validate arguments using schemas',
            schema  => 'bool',
            default => 1,
        },
        #validate_result => {
        #    summary => 'Whether the CLI script should validate result using schemas',
        #    schema  => 'bool',
        #    default => 1,
        #},
        read_config => {
            summary => 'Whether the CLI script should read configuration files',
            schema => 'bool*',
            default => 1,
        },
        config_filename => {
            summary => 'Configuration file name(s)',
            schema => ['any*', of=>[
                'str*',
                'hash*',
                ['array*', of=>['any*', of=>['str*','hash*']]],
            ]],
        },
        config_dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'config_dir',
            summary => 'Where to search for configuration files',
            schema => ['array*', of=>'str*'],
        },
        read_env => {
            summary => 'Whether CLI script should read environment variable that sets default options',
            schema => 'bool*',
        },
        env_name => {
            summary => 'Name of environment variable name that sets default options',
            schema => 'str*',
        },
        log => {
            summary => 'Whether to enable logging',
            schema  => 'bool*',
            default => 0,
        },

        with_debug => {
            summary => 'Generate script with debugging outputs',
            schema => 'bool',
            tags => ['category:debugging'],
        },
        include => {
            summary => 'Include extra modules',
            'summary.alt.plurality.singular' => 'Include an extra module',
            schema => ['array*', of=>'str*'],
            'x.schema.element_entity' => 'modulename',
            cmdline_aliases => {I=>{}},
        },

        code_after_shebang => {
            schema => 'str*',
            tags => ['category:extra-code'],
        },
        code_before_parse_cmdline_options => {
            schema => 'str*',
            tags => ['category:extra-code'],
        },
        code_after_end => {
            schema => 'str*',
            tags => ['category:extra-code'],
        },

        allow_prereq => {
            summary => 'A list of modules that can be depended upon',
            schema => ['array*', of=>'str*'], # XXX perl::modname
            description => <<'_',

By default, Perinci::CmdLine::Inline will strive to make the script freestanding
and require core modules. A dependency to a non-core module will cause failure
(unless `pack_deps` option is set to false). However, you can pass a list of
modules that is allowed here.

_
        },

        pack_deps => {
            summary => 'Whether to pack dependencies into the script',
            schema => ['bool*'],
            default => 1,
            description => <<'_',

By default, Perinci::CmdLine::Inline will use datapacking technique (i.e. embed
dependencies into DATA section and load it on-demand using require() hook) to
make the script freestanding. However, in some situation this is unwanted, e.g.
when we want to produce a script that can be packaged as a Debian package
(Debian policy forbids embedding convenience copy of code,
https://www.debian.org/doc/debian-policy/ch-source.html#s-embeddedfiles ).

_
        },
        pod => {
            summary => 'Whether to generate POD for the script',
            schema => ['bool*'],
            default => 1,
        },

        output_file => {
            summary => 'Set output file, defaults to stdout',
            schema => 'str*',
            'x.schema.entity' => 'filename',
            cmdline_aliases => {o=>{}},
            tags => ['category:output'],
        },
        overwrite => {
            schema => 'bool',
            tags => ['category:output'],
        },
        stripper => {
            summary => 'Whether to strip code using Perl::Stripper',
            schema => 'bool*',
            default => 0,
        },
    },
};
sub gen_inline_pericmd_script {
    require Data::Sah::Util::Type;

    my %args = @_;
    $args{url} = "$args{url}"; # stringify URI object to avoid JSON encoder croaking

    # XXX schema
    $args{validate_args} //= 1;
    #$args{validate_result} //= 1;
    $args{pack_deps} //= 1;
    $args{read_config} //= 1;
    $args{read_env} //= 1;
    $args{use_cleanser} //= 1;

    my $cd = {
        gen_args => \%args,
        script_name => $args{script_name},
        req_modules => {}, # modules which we will 'require' at the beginning of script. currently unused.
        vars => {},
        subs => {},
        module_srcs => {},
        core_deps => {}, # core modules required by the generated script. so we can specify dependencies to it, in environments where not all core modules are available.
    };

  GET_META:
    {
        my %metas; # key=subcommand name, '' if no subcommands
        my %mods; # key=module name, value={version=>..., ...}
        my %sc_mods; # key=subcommand name, value=module name
        my %func_names; # key=subcommand name, value=qualified function name
        my $script_name = $args{script_name};

        my $scs = $args{subcommands};
        if ($scs) {
            for my $sc_name (keys %$scs) {
                my $sc_spec = $scs->{$sc_name};
                my $res = _get_meta_from_url($sc_spec->{url});
                return $res if $res->[0] != 200;
                $mods{ $res->[3]{'func.module'} } = {
                    version => $res->[3]{'func.module_version'},
                };
                $metas{$sc_name} = $res->[2];
                $sc_mods{$sc_name} = $res->[3]{'func.module'};
                $func_names{$sc_name} = $res->[3]{'func.func_name'};
            }
        }

        my $url = $args{url};
        if ($url) {
            my $res = _get_meta_from_url($url);
            return $res if $res->[0] != 200;
            $mods{ $res->[3]{'func.module'} } = {
                version => $res->[3]{'func.module_version'},
            };
            $sc_mods{''} = $res->[3]{'func.module'};
            unless ($scs) {
                $metas{''} = $res->[2];
                $func_names{''} = $res->[3]{'func.func_name'};
            }
            if (length (my $sfn = $res->[3]{'func.short_func_name'})) {
                $script_name //= do {
                    local $_ = $sfn;
                    s/_/-/g;
                    $_;
                };
            }
        }

        if (!$url && !$scs) {
            $metas{''} = $args{meta};
            $func_names{''} = $args{sub_name};
            $script_name //= do {
                local $_ = $args{sub_name};
                s/_/-/g;
                $_;
            };
        }

        $script_name //= do {
            local $_ = $0;
            s!.+[/\\]!!;
            $_;
        };

        last if $args{meta_is_normalized};
        require Perinci::Sub::Normalize;
        for (keys %metas) {
            $metas{$_} = Perinci::Sub::Normalize::normalize_function_metadata($metas{$_});
        }

        $cd->{script_name} = $script_name;
        $cd->{metas} = \%metas;
        $cd->{mods} = \%mods;
        $cd->{sc_mods} = \%sc_mods;
        $cd->{func_names} = \%func_names;
    } # GET_META

    $args{config_filename} //= "$cd->{script_name}.conf";
    $args{env_name} //= do {
        my $env = uc "$cd->{script_name}_OPT";
        $env =~ s/[^A-Z0-9]+/_/g;
        $env = "_$env" if $env =~ /\A\d/;
        $env;
    };

    for (
        # required by Perinci::Result::Format::Lite. this will be removed if we
        # don't need formatting.
        "Data::Check::Structure",

        # required by _pci_gen_iter. this will be removed if we don't need
        # _pci_gen_iter
        "Data::Sah::Util::Type",

        # this will be removed if we don't need formatting
        "Perinci::Result::Format::Lite",

        # this will be removed if we don't need formatting
        "Text::Table::Tiny",

        @{ $args{include} // [] },
    ) {
        _pack_module($cd, $_);
    }

  GEN_SCRIPT:
    {
        my @l;

        {
            require Perinci::CmdLine::Base;
            no warnings 'once';
            my %copts;
            $copts{help} = $Perinci::CmdLine::Base::copts{help};
            $copts{version} = $Perinci::CmdLine::Base::copts{version};
            if ($args{log}) {
                $copts{log_level} = {
                    getopt  => "log-level=s",
                    summary => "Set logging level (trace|debug|info|warn|error|fatal|none)",
                };
                $copts{trace} = {
                    getopt  => "trace",
                    summary => "Set logging level to trace",
                };
                $copts{debug} = {
                    getopt  => "debug",
                    summary => "Set logging level to debug",
                };
                $copts{verbose} = {
                    getopt  => "verbose",
                    summary => "Set logging level to info",
                };
                $copts{quiet} = {
                    getopt  => "quiet",
                    summary => "Set logging level to error",
                };
            }
            unless ($args{skip_format}) {
                $copts{json} = $Perinci::CmdLine::Base::copts{json};
                $copts{format} = $Perinci::CmdLine::Base::copts{format};
                # "naked_res!" currently not supported by
                # Getopt::Long::EvenLess, so we split it. the downside is that
                # we don't hide the default, by default.
                $copts{naked_res} = {
                    getopt  => "naked-res",
                    summary => "When outputing as JSON, strip result envelope",
                };
                $copts{no_naked_res} = {
                    getopt  => "no-naked-res|nonaked-res",
                    summary => "When outputing as JSON, don't strip result envelope",
                };
            }
            if ($args{subcommands}) {
                $copts{subcommands} = $Perinci::CmdLine::Base::copts{subcommands};
                $copts{cmd}         = $Perinci::CmdLine::Base::copts{cmd};
            }
            if ($args{read_config}) {
                for (qw/config_path no_config config_profile/) {
                    $copts{$_} = $Perinci::CmdLine::Base::copts{$_};
                }
            }
            if ($args{read_env}) {
                for (qw/no_env/) {
                    $copts{$_} = $Perinci::CmdLine::Base::copts{$_};
                }
            }
            $cd->{copts} = \%copts;
        }

        my $shebang_line;
        {
            $shebang_line = $args{shebang} // $^X;
            $shebang_line = "#!$shebang_line" unless $shebang_line =~ /\A#!/;
            $shebang_line .= "\n" unless $shebang_line =~ /\R\z/;
        }

        # this will be removed if we don't use streaming input or read from
        # stdin
        $cd->{sub_srcs}{_pci_gen_iter} = <<'_';
    require Data::Sah::Util::Type;
    my ($fh, $type, $argname) = @_;
    if (Data::Sah::Util::Type::is_simple($type)) {
        return sub {
            # XXX this will be configurable later. currently by default reading
            # binary is per-64k while reading string is line-by-line.
            local $/ = \(64*1024) if $type eq 'buf';

            state $eof;
            return undef if $eof;
            my $l = <$fh>;
            unless (defined $l) {
                $eof++; return undef;
            }
            $l;
        };
    } else {
        my $i = -1;
        return sub {
            state $eof;
            return undef if $eof;
            $i++;
            my $l = <$fh>;
            unless (defined $l) {
                $eof++; return undef;
            }
            eval { $l = _pci_json()->decode($l) };
            if ($@) {
                die "Invalid JSON in stream argument '$argname' record #$i: $@";
            }
            $l;
        };
    }
_

        $cd->{sub_srcs}{_pci_err} = <<'_';
    my $res = shift;
    print STDERR "ERROR $res->[0]: $res->[1]\n";
    exit $res->[0]-300;
_

        if ($args{with_debug}) {
            _pack_module($cd, "Data::Dmp");
            _pack_module($cd, "Regexp::Stringify"); # needed by Data::Dmp
            $cd->{sub_srcs}{_pci_debug} = <<'_';
    require Data::Dmp;
    print "DEBUG: ", Data::Dmp::dmp(@_), "\n";
_
        }

        $cd->{sub_srcs}{_pci_json} = <<'_';
    state $json = do {
        if (eval { require JSON::XS; 1 }) { JSON::XS->new->canonical(1)->allow_nonref }
        else { require JSON::PP; JSON::PP->new->canonical(1)->allow_nonref }
    };
    $json;
_
        $cd->{sub_src_core_deps}{_pci_json}{'JSON::PP'} = 0;

        {
            last unless $args{use_cleanser};
            require Module::CoreList;
            require Data::Clean::JSON;
            my $cleanser = Data::Clean::JSON->new(
                # pick this noncore PP module instead of the default non-core XS
                # module Data::Clone. perl has core module Storable, but
                # Storable still chooses to croak on Regexp objects.
                '!clone_func' => 'Clone::PP::clone',
            );
            my $src = $cleanser->{_cd}{src};
            my $src1 = 'sub _pci_clean_json { ';
            for my $mod (keys %{ $cleanser->{_cd}{modules} }) {
                $src1 .= "require $mod; ";
                next if Module::CoreList->is_core($mod);
                _pack_module($cd, $mod);
            }
            $cd->{module_srcs}{'Local::_pci_clean_json'} = "$src1 use feature 'state'; state \$cleanser = $src; \$cleanser->(shift) }\n1;\n";
        }

        {
            require Perinci::Sub::GetArgs::Argv;
            my %ggl_res; # key = subcommand name
            my %args_as; # key = subcommand name
            for my $sc_name (keys %{ $cd->{metas} }) {
                my $meta = $cd->{metas}{$sc_name};
                my $args_as = $meta->{args_as} // 'hash';
                if ($args_as !~ /\A(hashref|hash)\z/) {
                    return [501, "args_as=$args_as currently unsupported at subcommand='$sc_name'"];
                }
                $args_as{$sc_name} = $args_as;

                my $ggl_res = Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
                    meta => $meta,
                    meta_is_normalized => 1,
                    per_arg_json => 1,
                    common_opts => $cd->{copts},
                );
                return [500, "Can't generate Getopt::Long spec from meta (subcommand='$sc_name'): ".
                            "$ggl_res->[0] - $ggl_res->[1]"]
                    unless $ggl_res->[0] == 200;
                $ggl_res{$sc_name} = $ggl_res;
            }
            $cd->{ggl_res} = \%ggl_res;
            $cd->{args_as} = \%args_as;
            _gen_pci_check_args($cd);
        }

        $cd->{vars}{'$_pci_r'} = {
            naked_res => 0,
            subcommand_name => '',
            read_config => $args{read_config},
            read_env => $args{read_env},
        };

        $cd->{vars}{'%_pci_args'} = undef;
        push @l, "### get arguments (from config file, env, command-line args\n\n";
        push @l, "{\n", _gen_get_args($cd), "}\n\n";

        # gen code to check arguments
        push @l, "### check arguments\n\n";
        push @l, "{\n";
        push @l, 'require Local::_pci_check_args; ' if $cd->{gen_args}{pack_deps};
        push @l, 'my $res = _pci_check_args(\\%_pci_args);', "\n";
        push @l, '_pci_debug("args after _pci_check_args: ", \%_pci_args);', "\n" if $cd->{gen_args}{with_debug};
        push @l, '_pci_err($res) if $res->[0] != 200;', "\n";
        push @l, '$_pci_r->{args} = \\%_pci_args;', "\n";
        push @l, "}\n\n";

        # generate code to call function
        push @l, "### call function\n\n";
        $cd->{vars}{'$_pci_meta_result_stream'} = 0;
        $cd->{vars}{'$_pci_meta_skip_format'} = 0;
        $cd->{vars}{'$_pci_meta_result_type'} = undef;
        $cd->{vars}{'$_pci_meta_result_type_is_simple'} = undef;
        push @l, "{\n";
        push @l, 'log_trace("Calling function ...");', "\n" if $cd->{gen_args}{log};
        push @l, 'my $sc_name = $_pci_r->{subcommand_name};' . "\n";
        push @l, '$_pci_args{-cmdline} = Perinci::CmdLine::Inline::Object->new(@{', dmp([%args]), '});', "\n"
            if $args{pass_cmdline_object};
        {
            my $i = -1;
            for my $sc_name (sort keys %{ $cd->{metas} }) {
                $i++;
                my $meta = $cd->{metas}{$sc_name};
                push @l, ($i ? 'elsif' : 'if').' ($sc_name eq '.dmp($sc_name).") {\n";
                push @l, '    $_pci_meta_result_stream = 1;'."\n" if $meta->{result}{stream};
                push @l, '    $_pci_meta_skip_format = 1;'."\n" if $meta->{'cmdline.skip_format'};
                push @l, '    $_pci_meta_result_type = '.dmp(Data::Sah::Util::Type::get_type($meta->{result}{schema} // '') // '').";\n";
                push @l, '    $_pci_meta_result_type_is_simple = 1;'."\n" if Data::Sah::Util::Type::is_simple($meta->{result}{schema} // '');
                push @l, "    require $cd->{sc_mods}{$sc_name};\n" if $cd->{sc_mods}{$sc_name};
                push @l, '    eval { $_pci_r->{res} = ', $cd->{func_names}{$sc_name}, ($cd->{args_as}{$sc_name} eq 'hashref' ? '(\\%_pci_args)' : '(%_pci_args)'), ' };', "\n";
                push @l, '    if ($@) { $_pci_r->{res} = [500, "Function died: $@"] }', "\n";
                if ($meta->{result_naked}) {
                    push @l, '    $_pci_r->{res} = [200, "OK (envelope added by Perinci::CmdLine::Inline)", $_pci_r->{res}];', "\n";
                }
                push @l, "}\n";
            }
        }
        push @l, "}\n\n";

        # generate code to format & display result
        push @l, "### format & display result\n\n";
        push @l, "{\n";
        push @l, 'log_trace("Displaying result ...");', "\n" if $cd->{gen_args}{log};
        push @l, 'my $fres;', "\n";
        push @l, 'my $save_res; if (exists $_pci_r->{res}[3]{"cmdline.result"}) { $save_res = $_pci_r->{res}[2]; $_pci_r->{res}[2] = $_pci_r->{res}[3]{"cmdline.result"} }', "\n";
        push @l, 'my $is_success = $_pci_r->{res}[0] =~ /\A2/ || $_pci_r->{res}[0] == 304;', "\n";
        push @l, 'my $is_stream = $_pci_r->{res}[3]{stream} // $_pci_meta_result_stream // 0;'."\n";
        push @l, 'if ($is_success && (', ($args{skip_format} ? 1:0), ' || $_pci_meta_skip_format || $_pci_r->{res}[3]{"cmdline.skip_format"})) { $fres = $_pci_r->{res}[2] }', "\n";
        push @l, 'elsif ($is_success && $is_stream) {}', "\n";
        push @l, 'else { ';
        push @l, 'require Local::_pci_clean_json; ' if $args{pack_deps} && $args{use_cleanser};
        push @l, 'require Perinci::Result::Format::Lite; $is_stream=0; ';
        push @l, '_pci_clean_json($_pci_r->{res}); ' if $args{use_cleanser};
        push @l, '$fres = Perinci::Result::Format::Lite::format($_pci_r->{res}, ($_pci_r->{format} // $_pci_r->{res}[3]{"cmdline.default_format"} // "text"), $_pci_r->{naked_res}, 0) }', "\n";
        push @l, "\n";

        push @l, 'my $use_utf8 = $_pci_r->{res}[3]{"x.hint.result_binary"} ? 0 : '.($args{use_utf8} ? 1:0).";\n";
        push @l, 'if ($use_utf8) { binmode STDOUT, ":encoding(utf8)" }', "\n";

        push @l, 'if ($is_stream) {', "\n";
        push @l, '    my $code = $_pci_r->{res}[2]; if (ref($code) ne "CODE") { die "Result is a stream but no coderef provided" } if ($_pci_meta_result_type_is_simple) { while(defined(my $l=$code->())) { print $l; print "\n" unless $_pci_meta_result_type eq "buf"; } } else { while (defined(my $rec=$code->())) { print _pci_json()->encode($rec),"\n" } }', "\n";
        push @l, '} else {', "\n";
        push @l, '    print $fres;', "\n";
        push @l, '}', "\n";
        push @l, 'if (defined $save_res) { $_pci_r->{res}[2] = $save_res }', "\n";
        push @l, "}\n\n";

        # generate code to exit with code
        push @l, "### exit\n\n";
        push @l, "{\n";
        push @l, 'my $status = $_pci_r->{res}[0];', "\n";
        push @l, 'my $exit_code = $_pci_r->{res}[3]{"cmdline.exit_code"} // ($status =~ /200|304/ ? 0 : ($status-300));', "\n";
        push @l, 'exit($exit_code);', "\n";
        push @l, "}\n\n";

        # remove unneeded modules
        if ($args{skip_format}) {
            delete $cd->{module_srcs}{'Data::Check::Structure'};
            delete $cd->{module_srcs}{'Perinci::Result::Format::Lite'};
            delete $cd->{module_srcs}{'Text::Table::Tiny'};
        }

        if ($args{pass_cmdline_object}) {
            require Class::GenSource;
            my $cl = 'Perinci::CmdLine::Inline::Object';
            $cd->{module_srcs}{$cl} =
                Class::GenSource::gen_class_source_code(
                    name => $cl,
                    attributes => {
                        map { $_ => {} } keys %pericmd_attrs,
                    },
                );
        }

        my ($dp_code1, $dp_code2, $dp_code3);
        if ($args{pack_deps}) {
            require Module::DataPack;
            my $dp_res = Module::DataPack::datapack_modules(
                module_srcs => $cd->{module_srcs},
                stripper    => $args{stripper},
            );
            return [500, "Can't datapack: $dp_res->[0] - $dp_res->[1]"]
                unless $dp_res->[0] == 200;
            $dp_code2 = "";
            ($dp_code1, $dp_code3) = $dp_res->[2] =~ /(.+?)^(__DATA__\n.+)/sm;
        } else {
            $dp_code1 = "";
            $dp_code2 = "";
            $dp_code3 = "";
            for my $pkg (sort keys %{ $cd->{module_srcs} }) {
                my $src = $cd->{module_srcs}{$pkg};
                $dp_code2 .= "# BEGIN $pkg\n$src\n# END $pkg\n\n";
            }
        }

        my $pod;
        if ($args{pod} // 1) {
            require Perinci::CmdLine::POD;
            my $res = Perinci::CmdLine::POD::gen_pod_for_pericmd_script(
                url                => $args{url},
                program_name       => $cd->{script_name},
                summary            => $args{script_summary},
                common_opts        => $cd->{copts},
                subcommands        => $args{subcommands},
                default_subcommand => $args{default_subcommand},
                per_arg_json       => 1,
                per_arg_yaml       => 0,
                read_env           => $args{read_env},
                env_name           => $args{env_name},
                read_config        => $args{read_config},
                config_filename    => $args{config_filenames},
                config_dirs        => $args{config_dirs},
                completer_script    => "_$cd->{script_name}",
            );
            return err($res, 500, "Can't generate POD") unless $res->[0] == 200;
            $pod = $res->[2];
        }

        # generate final result
        $cd->{result} = join(
            "",
            $shebang_line, "\n",

            ("### code_after_shebang\n", $args{code_after_shebang}, "\n") x !!$args{code_after_shebang},

            "# PERICMD_INLINE_SCRIPT: ", do {
                my %tmp = %args;
                # don't show the potentially long/undumpable argument values
                for (grep {/^code_/} keys %tmp) {
                    $tmp{$_} = "...";
                }
                JSON::MaybeXS->new->canonical(1)->encode(\%tmp);
            }, "\n\n",

            'my $_pci_metas = ', do {
                local $Data::Dmp::OPT_DEPARSE=0;
                dmp($cd->{metas});
            }, ";\n\n",

            "# This script is generated by ", __PACKAGE__,
            " version ", (${__PACKAGE__."::VERSION"} // 'dev'), " on ",
            scalar(localtime), ".\n\n",

            (keys %{$cd->{mods}} ? "# Rinci metadata taken from these modules: ".join(", ", map {"$_ ".($cd->{mods}{$_}{version} // "(no version)")} sort keys %{$cd->{mods}})."\n\n" : ""),

            "# You probably should not manually edit this file.\n\n",

            # for dzil
            "# DATE\n",
            "# VERSION\n",
            "# PODNAME: ", ($args{script_name} // ''), "\n",
            do {
                my $abstract = $args{script_summary} // $cd->{metas}{''}{summary};
                if ($abstract) {
                    ("# ABSTRACT: ", $abstract, "\n");
                } else {
                    ();
                }
            },
            "\n",

            $dp_code1,

            "package main;\n",
            "use 5.010001;\n",
            "use strict;\n",
            "#use warnings;\n\n",

            "# modules\n",
            (map {"require $_;\n"} sort keys %{$cd->{req_modules}}),
            "\n",

            "\n",

            $args{log} ? _gen_enable_log($cd) : '',

            "### declare global variables\n\n",
            (map { "our $_" . (defined($cd->{vars}{$_}) ? " = ".dmp($cd->{vars}{$_}) : "").";\n" } sort keys %{$cd->{vars}}),
            (keys(%{$cd->{vars}}) ? "\n" : ""),

            "### declare subroutines\n\n",
            (map {
                my $sub = $_;
                if ($cd->{sub_src_core_deps}{$sub}) {
                    for my $mod (keys %{ $cd->{sub_src_core_deps}{$sub} }) {
                        $cd->{core_deps}{$mod} //=
                            $cd->{sub_src_core_deps}{$sub}{$mod};
                    }
                }
                "sub $sub" . (ref($cd->{sub_srcs}{$sub}) eq 'ARRAY' ?
                "($cd->{sub_srcs}{$sub}[0]) {\n$cd->{sub_srcs}{$sub}[1]}\n\n" : " {\n$cd->{sub_srcs}{$sub}}\n\n")}
                sort keys %{$cd->{sub_srcs}}),

            ("### code_before_parse_cmdline_options\n", $args{code_before_parse_cmdline_options}, "\n") x !!$args{code_before_parse_cmdline_options},

            @l,

            $dp_code2,

            defined $pod ? ("=pod\n\n", "=encoding UTF-8\n\n", $pod, "\n\n=cut\n\n") : (),

            $dp_code3,

            ("### code_after_end\n", $args{code_after_end}, "\n") x !!$args{code_after_end},
        );
    }

  WRITE_OUTPUT:
    {
        my ($fh, $output_is_stdout);
        if (!defined($args{output_file}) || $args{output_file} eq '-') {
            $output_is_stdout++;
        } else {
            if (-f $args{output_file}) {
                return [412, "Output file '$args{output_file}' exists, ".
                            "won't overwrite (see --overwrite)"]
                    unless $args{overwrite};
            }
                open $fh, ">", $args{output_file}
                    or return [500, "Can't open $args{output_file}: $!"];
        }

        if ($output_is_stdout) {
            return [200, "OK", $cd->{result}, {
                'func.raw_result' => $cd,
            }];
        } else {
            print $fh $cd->{result};
            close $fh or return [500, "Can't write $args{output_file}: $!"];
            chmod 0755, $args{output_file} or do {
                warn "Can't chmod 755 $args{output_file}: $!";
            };
            return [200, "OK", undef, {
                'func.raw_result'=>$cd,
            }];
        }
    }
}

1;
# ABSTRACT: Generate inline Perinci::CmdLine CLI script

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Inline - Generate inline Perinci::CmdLine CLI script

=head1 VERSION

This document describes version 0.545 of Perinci::CmdLine::Inline (from Perl distribution Perinci-CmdLine-Inline), released on 2019-04-15.

=head1 SYNOPSIS

 % gen-inline-pericmd-script /Perinci/Examples/gen_array -o gen-array

 % ./gen-array
 ERROR 400: Missing required argument(s): len

 % ./gen-array --help
 ... help message printed ...

 % ./gen-array 3
 2
 3
 1

 % ./gen-array 3 --json
 [200,"OK",[3,1,2],{}]

=head1 DESCRIPTION

=head1 COMPILATION DATA KEYS

A hash structure, C<$cd>, is constructed and passed around between routines
during the generation process. It contains the following keys:

=over

=item * module_srcs => hash

Generated script's module source codes. To reduce startup overhead and
dependency, these modules' source codes are included in the generated script
using the datapack technique (see L<Module::DataPack>).

Among the modules are L<Getopt::Long::EvenLess> to parse command-line options,
L<Text::Table::Tiny> to produce text table output, and also a few generated
modules to modularize the generated script's structure.

=item * vars => hash

Generated script's global variables. Keys are variable names (including the
sigils) and values are initial variable values (undef means unitialized).

=item * sub_srcs => hash

Generated script's subroutine source codes. Keys are subroutines' names and
values are subroutines' source codes.

=back

=head1 FUNCTIONS


=head2 gen_inline_pericmd_script

Usage:

 gen_inline_pericmd_script(%args) -> [status, msg, payload, meta]

Generate inline Perinci::CmdLine CLI script.

The goal of this module is to let you create a CLI script from a Riap
function/metadata. This is like what L<Perinci::CmdLine::Lite> or
L<Perinci::CmdLine::Classic> does, except that the generated CLI script will have
the functionalities inlined so it only need core Perl modules and not any of the
C<Perinci::CmdLine::*> or other modules to run (excluding what modules the Riap
function itself requires).

It's useful if you want a CLI script that is even more lightweight (in terms of
startup overhead or dependencies) than the one using L<Perinci::CmdLine::Lite>.

So to reiterate, the goal of this module is to create a Perinci::CmdLine-based
script which only requires core modules, and has as little startup overhead as
possible.

Currently it only supports a subset of features compared to other
C<Perinci::CmdLine::*> implementations:

=over

=item * Only support local Riap URL (e.g. C</Foo/bar>, not
CLL<http://example.org/Foo/bar>);

=back

As an alternative to this module, if you are looking to reduce dependencies, you
might also want to try using C<depak> to fatpack/datapack your
L<Perinci::CmdLine::Lite>-based script.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<actions> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<allow_prereq> => I<array[str]>

A list of modules that can be depended upon.

By default, Perinci::CmdLine::Inline will strive to make the script freestanding
and require core modules. A dependency to a non-core module will cause failure
(unless C<pack_deps> option is set to false). However, you can pass a list of
modules that is allowed here.

=item * B<code_after_end> => I<str>

=item * B<code_after_shebang> => I<str>

=item * B<code_before_parse_cmdline_options> => I<str>

=item * B<common_opts> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<completion> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<config_dirs> => I<array[str]>

Where to search for configuration files.

=item * B<config_filename> => I<str|hash|array[str|hash]>

Configuration file name(s).

=item * B<default_format> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<default_subcommand> => I<str>

=item * B<description> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<env_name> => I<str>

Name of environment variable name that sets default options.

=item * B<exit> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<extra_urls_for_version> => I<array[str]>

More URLs to show version for --version.

Currently not implemented in Perinci::CmdLine::Inline.

=item * B<formats> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<get_subcommand_from_arg> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<include> => I<array[str]>

Include extra modules.

=item * B<log> => I<bool> (default: 0)

Whether to enable logging.

=item * B<meta> => I<hash>

An alternative to specifying `url`.

=item * B<meta_is_normalized> => I<bool>

=item * B<output_file> => I<str>

Set output file, defaults to stdout.

=item * B<overwrite> => I<bool>

=item * B<pack_deps> => I<bool> (default: 1)

Whether to pack dependencies into the script.

By default, Perinci::CmdLine::Inline will use datapacking technique (i.e. embed
dependencies into DATA section and load it on-demand using require() hook) to
make the script freestanding. However, in some situation this is unwanted, e.g.
when we want to produce a script that can be packaged as a Debian package
(Debian policy forbids embedding convenience copy of code,
https://www.debian.org/doc/debian-policy/ch-source.html#s-embeddedfiles ).

=item * B<pass_cmdline_object> => I<bool> (default: 0)

Whether to pass Perinci::CmdLine::Inline object.

=item * B<pod> => I<bool> (default: 1)

Whether to generate POD for the script.

=item * B<read_config> => I<bool> (default: 1)

Whether the CLI script should read configuration files.

=item * B<read_env> => I<bool>

Whether CLI script should read environment variable that sets default options.

=item * B<riap_client> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<riap_client_args> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<riap_version> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<script_name> => I<str>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<script_summary> => I<str>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<script_version> => I<str>

Script version (otherwise will use version from url metadata).

=item * B<script_version_from_main_version> => I<bool>

Use script's $main::VERSION for the version.

=item * B<shebang> => I<str>

Set shebang line.

=item * B<skip_format> => I<bool> (default: 0)

Assume that function returns raw text that need no formatting, do not offer --format, --json, --naked-res.

=item * B<stripper> => I<bool> (default: 0)

Whether to strip code using Perl::Stripper.

=item * B<sub_name> => I<str>

=item * B<subcommands> => I<hash>

=item * B<tags> => I<any>

Currently does nothing, provided only for compatibility with Perinci::CmdLine::Base.

=item * B<url> => I<riap::url>

Program URL.

=item * B<use_cleanser> => I<bool> (default: 1)

Whether to use data cleanser routine first before producing JSON.

When a function returns result, and the user wants to display the result as
JSON, the result might need to be cleansed first (e.g. using L<Data::Clean>)
before it can be encoded to JSON, for example it might contain Perl objects or
scalar references or other stuffs. If you are sure that your function does not
produce those kinds of data, you can set this to false to produce a more
lightweight script.

=item * B<use_utf8> => I<bool> (default: 0)

Whether to set utf8 flag on output.

=item * B<validate_args> => I<bool> (default: 1)

Whether the CLI script should validate arguments using schemas.

=item * B<with_debug> => I<bool>

Generate script with debugging outputs.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head2 What about tab completion?

Use L<App::GenPericmdCompleterScript> to generate a separate completion script.
If you use L<Dist::Zilla>, see also L<Dist::Zilla::Plugin::GenPericmdScript>
which lets you generate script (and its completion script) during build.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Inline>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Inline>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Inline>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine>, L<Perinci::CmdLine::Any>, L<Perinci::CmdLine::Lite>,
L<Perinci::CmdLine::Classic>

L<App::GenPericmdScript>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
