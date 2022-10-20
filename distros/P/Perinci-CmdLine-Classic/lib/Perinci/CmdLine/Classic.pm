package Perinci::CmdLine::Classic;

use 5.010001;
#use strict; # enabled by Moo
#use warnings; # enabled by Moo
use Log::ger;

use Moo;
use experimental 'smartmatch'; # must be after Moo
use Locale::TextDomain::UTF8 'Perinci-CmdLine-Classic';
use Perinci::Object;
use Scalar::Util qw(blessed);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Perinci-CmdLine-Classic'; # DIST
our $VERSION = '1.817'; # VERSION

our $REQ_VERSION = 0; # version requested by user

extends 'Perinci::CmdLine::Base';

with 'Perinci::CmdLine::Classic::Role::Help' unless $ENV{COMP_LINE};
with 'Term::App::Role::Attrs' unless $ENV{COMP_LINE};

has color_theme => (
    is => 'rw',
    trigger => sub {
        require Module::Load::Util;
        require Role::Tiny;

        my ($self, $val) = @_;
        my $obj =
            Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefix=>'ColorTheme'}, $val);
        Role::Tiny->apply_roles_to_object($obj, 'ColorThemeRole::ANSI');
        $self->{color_theme_obj} = $obj;
    },
);

has undo => (is=>'rw', default=>sub{0});
has undo_dir => (
    is => 'rw',
    lazy => 1,
    default => sub {
        require File::HomeDir;

        my $self = shift;
        my $dir = File::HomeDir->my_home . "/." . $self->program_name;
        mkdir $dir unless -d $dir;
        $dir .= "/.undo";
        mkdir $dir unless -d $dir;
        $dir;
    }
);
has riap_client => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;

        require Perinci::Access;
        require Perinci::Access::Perl;
        require Perinci::Access::Schemeless;
        my %args = (
            riap_version => $self->riap_version,
            %{$self->riap_client_args // {}},
        );
        my %opts;
        if ($self->undo) {
            $opts{use_tx} = 1;
            $opts{custom_tx_manager} = sub {
                my $pa = shift;
                require Perinci::Tx::Manager;
                state $txm = Perinci::Tx::Manager->new(
                    data_dir => $self->undo_dir,
                    pa => $pa,
                );
                $txm;
           };
        }
        $args{handlers} = {
            pl => Perinci::Access::Perl->new(%opts),
            '' => Perinci::Access::Schemeless->new(%opts),
        };
        #$log->tracef("Creating Perinci::Access object with args: %s", \%args);
        Perinci::Access->new(%args);
    }
);
has action_metadata => (
    is => 'rw',
    default => sub {
        return {
            clear_history => {
            },
            help => {
                use_utf8 => 1,
            },
            history => {
            },
            subcommands => {
                use_utf8 => 1,
            },
            redo => {
            },
            call => {
            },
            undo => {
            },
            version => {
                use_utf8 => 1,
            },
        },
    },
);
has default_prompt_template => (is=>'rw');

sub VERSION {
    my ($pkg, $req) = @_;
    $REQ_VERSION = $req;
    $pkg->SUPER::VERSION(@_);
}

sub BUILD {
    my ($self, $args) = @_;

    my $formats = [qw(
                         text text-simple text-pretty
                         json json-pretty yaml perl
                         ruby phpserialization)];

    if (!$self->{default_prompt_template}) {
        $self->{default_prompt_template} = N__("Enter %s:") . " ";
    }

    if (!$self->{actions}) {
        $self->{actions} = {
            version => {
                use_utf8 => 1,
            },
            help => {
                use_utf8 => 1,
            },
            subcommands => {
                use_utf8 => 1,
            },
            call => {},

            history => {},
            clear_history => {},
            redo => {},
            undo => {},
        };
    }

    # translate summary & usage
    my $_t = sub {
        no warnings;
        my $co_name = shift;
        my $copt = $Perinci::CmdLine::Base::copts{$co_name};
        my %res;
        for (keys %$copt) {
            if ($_ eq 'summary' || $_ eq 'usage') {
                $res{$_} = N__($copt->{$_});
            } else {
                $res{$_} = $copt->{$_};
            }
        }
        %res;
    };

    if (!$self->{common_opts}) {
        my $copts = {};

        $copts->{version} = {
            $_t->('version'),
            show_in_options => sub { $ENV{VERBOSE} },
        };
        $copts->{help} = {
            $_t->('help'),
            show_in_options => sub { $ENV{VERBOSE} },
        };

        unless ($self->skip_format) {
            $copts->{format} = {
                $_t->('format'),
                schema => ['str*' => in => $formats],
            };
            $copts->{json} = {
                $_t->('json'),
                summary => N__("Equivalent to --format=json-pretty"),
            };
            $copts->{naked_res} = {
                $_t->('naked_res'),
                summary => N__("When outputing as JSON, strip result envelope"),
            };
            $copts->{format_options} = {
                getopt  => "format-options=s",
                summary => N__("Pass options to formatter"),
                handler => sub {
                    my ($go, $val, $r) = @_;
                    $r->{format_options} = __json_decode($val);
                },
                is_settable_via_config => 1,
                tags => ['category:output'],
            };
        }

        if ($self->subcommands) {
            $copts->{subcommands} = {
                $_t->('subcommands'),
                show_in_options => sub {
                    my ($self, $r) = @_;
                    $ENV{VERBOSE} && !$r->{subcommand_name};
                },
                show_in_help => 0,
            };
        }

        if (defined $self->default_subcommand) {
            $copts->{cmd} = { $_t->('cmd') };
        }

        if ($self->read_config) {
            $copts->{config_path}    = { $_t->('config_path') };
            $copts->{no_config}      = { $_t->('no_config') };
            $copts->{config_profile} = { $_t->('config_profile') };
        }

        if ($self->read_env) {
            $copts->{no_env} = { $_t->('no_env') };
        }

        if ($self->log) {
            $copts->{log_level} = { $_t->('log_level'), };
            $copts->{trace}     = { $_t->('trace'), };
            $copts->{debug}     = { $_t->('debug'), };
            $copts->{verbose}   = { $_t->('verbose'), };
            $copts->{quiet}     = { $_t->('quiet'), };
        }

        if ($self->undo) {
            $copts->{history} = {
                getopt  => 'history',
                summary => N__('List actions history'),
                handler => sub {
                    my ($go, $val, $r) = @_;
                    $r->{action} = 'history';
                    $r->{skip_parse_subcommand_argv} = 1;
                },
                tags => ['category:undo'],
                key => 'action',
            };
            $copts->{clear_history} = {
                getopt  => "clear-history",
                summary => N__('Clear actions history'),
                handler => sub {
                    my ($go, $val, $r) = @_;
                    $r->{action} = 'clear_history';
                    $r->{skip_parse_subcommand_argv} = 1;
                },
                tags => ['category:undo'],
                key => 'action',
            };
            $copts->{undo} = {
                getopt  => 'undo',
                summary => N__('Undo previous action'),
                handler => sub {
                    my ($go, $val, $r) = @_;
                    $r->{action} = 'undo';
                    $r->{skip_parse_subcommand_argv} = 1;
                },
                tags => ['category:undo'],
                key => 'action',
            };
            $copts->{redo} = {
                getopt  => 'redo',
                summary => N__('Redo previous undone action'),
                handler => sub {
                    my ($go, $val, $r) = @_;
                    $r->{action} = 'redo';
                    $r->{skip_parse_subcommand_argv} = 1;
                },
                tags => ['category:undo'],
                key => 'action',
            };
        }
        $self->{common_opts} = $copts;
    }

    $self->{formats} //= $formats;
    $self->{per_arg_json} //= 1;

    unless ($ENV{COMP_LINE}) {
        my $ct = $self->{color_theme} // $ENV{PERINCI_CMDLINE_COLOR_THEME};
        if (!$ct) {
            if ($self->use_color) {
                my $bg = $self->detect_terminal->{default_bgcolor} // '';
                $ct = 'Perinci::CmdLine::Classic::Default' .
                    ($bg eq 'ffffff' ? 'WhiteBG' : '');
            } else {
                $ct = 'NoColor';
            }
        }
        $self->color_theme($ct);
    }
}

sub __json_decode {
    require JSON::MaybeXS;
    state $json = do { JSON::MaybeXS->new->allow_nonref };
    $json->decode(shift);
}

sub __json_encode {
    require JSON::MaybeXS;
    state $json = do { JSON::MaybeXS->new->allow_nonref };
    $json->encode(shift);
}

sub _color {
    my ($self, $item_name, $text) = @_;
    my $color_code = $item_name ?
        $self->{color_theme_obj}->get_item_color_as_ansi($item_name) : "";
    my $reset_code = $color_code ? "\e[0m" : "";
    "$color_code$text$reset_code";
}

#NOW UNUSED
#sub err {
#    my ($self, $msg) = @_;
#    $msg .= "\n" unless $msg =~ /\n\z/;
#    $self->_color('error_label', "ERROR: ") . $msg;
#}

# format array item as row
sub hook_format_row {
    state $dfpc = do {
        require Data::Format::Pretty::Console;
        Data::Format::Pretty::Console->new({interactive=>0});
    };

    my ($self, $r, $row) = @_;
    my $ref = ref($row);
    # we catch common cases to be faster (avoid dfpc's structure identification)
    if (!$ref) {
        # simple scalar
        return ($row // "") . "\n";
    } elsif ($ref eq 'ARRAY' && !(grep {ref($_)} @$row)) {
        # an array of scalars
        return join("\t", map { $dfpc->_format_cell($_) } @$row) . "\n";
    } else {
        # otherwise, just feed it to dfpc
        return $dfpc->_format($row);
    }
}

sub hook_after_get_meta {
    my ($self, $r) = @_;

    my $metao = risub($r->{meta});
    if ($metao->can_dry_run) {
        my $default_dry_run = $metao->default_dry_run // $self->default_dry_run;
        $r->{dry_run} = 1 if $default_dry_run;
        $r->{dry_run} = ($ENV{DRY_RUN} ? 1:0) if defined $ENV{DRY_RUN};
        $self->common_opts->{dry_run} = {
            getopt  => $default_dry_run ? 'dry-run!' : 'dry-run',
            summary => $default_dry_run ?
                N__("Disable simulation mode (also via DRY_RUN=0)") :
                N__("Run in simulation mode (also via DRY_RUN=1)"),
            handler => sub {
                my ($go, $val, $r) = @_;
                if ($val) {
                    log_debug("[pericmd] Dry-run mode is activated");
                    $r->{dry_run} = 1;
                    #$ENV{VERBOSE} = 1;
                } else {
                    log_debug("[pericmd] Dry-run mode is deactivated");
                    $r->{dry_run} = 0;
                }
            },
        };
    }
}

my ($ph1, $ph2); # patch handles
my $setup_progress;
sub _setup_progress_output {
    my $self = shift;

    if ($ENV{PROGRESS} // (-t STDOUT)) { ## no critic: InputOutput::ProhibitInteractiveTest
        require Progress::Any::Output;
        my $out = Progress::Any::Output->set("TermProgressBarColor");
        $setup_progress = 1;
        # we need to patch the logger adapters so it won't interfere with
        # progress meter's output
        require Monkey::Patch::Action;
        $ph1 = Monkey::Patch::Action::patch_package(
            'Log::Log4perl::Appender::Screen', 'log',
            'replace', sub {
                my ($self, %params) = @_;

                my $msg = $params{message};
                $msg =~ s/\n//g;

                # clean currently displayed progress bar first
                if ($out->{lastlen}) {
                    print
                        "\b" x $out->{lastlen},
                            " " x $out->{lastlen},
                                "\b" x $out->{lastlen};
                    undef $out->{lastlen};
                }

                # force output update so progress bar is displayed again
                # immediately
                $Progress::Any::output_data{"$out"}{force_update} = 1;

                say $msg;
            },
        ) if defined &{"Log::Log4perl::Appender::Screen::log"};
        $ph2 = Monkey::Patch::Action::patch_package(
            'Log::Log4perl::Appender::ScreenColoredLevels', 'log',
            'replace', sub {
                my ($self, %params) = @_;
                # BEGIN copy-paste'ish from ScreenColoredLevels.pm
                my $msg = $params{message};
                $msg =~ s/\n//g;
                if (my $color=$self->{color}->{$params{log4p_level}}) {
                    $msg = Term::ANSIColor::colored($msg, $color);
                }
                # END copy-paste'ish

                # clean currently displayed progress bar first
                if ($out->{lastlen}) {
                    print
                        "\b" x $out->{lastlen},
                            " " x $out->{lastlen},
                                "\b" x $out->{lastlen};
                    undef $out->{lastlen};
                }

                # force output update so progress bar is displayed again
                # immediately
                $Progress::Any::output_data{"$out"}{force_update} = 1;

                # XXX duplicated code above, perhaps move this to
                # TermProgressBarColor's clean_bar() or something

                say $msg;
            }
        ) if defined &{"Log::Log4perl::Appender::ScreenColoredLevels::log"};
    }
}

sub _unsetup_progress_output {
    my $self = shift;

    return unless $setup_progress;
    no warnings 'once';
    my $out = $Progress::Any::outputs{''}[0];
    $out->cleanup if $out->can("cleanup");
    undef $ph1;
    undef $ph2;
    $setup_progress = 0;
}

# this hook is called at the start of run(), can be used to initialize stuffs
sub hook_before_run {
    my ($self, $r) = @_;

    log_trace("Start of CLI run");

    # save, for showing in history, among others
    $r->{orig_argv} = [@ARGV];
}

sub hook_before_parse_argv {
}

sub hook_after_parse_argv {
}

sub hook_format_result {
    # save startup time under completion
    return if $ENV{COMP_LINE};

    my ($self, $r) = @_;

    my $res    = $r->{res};
    my $format = $r->{format} // 'text';
    my $meta   = $r->{meta};

    require Perinci::Result::Format;

    unless ($format ~~ @{ $self->formats }) {
        warn "Unknown output format '$format'";
        $format = 'text';
    }

    $res->[3]{format_options} = $r->{format_options} if $r->{format_options};

    my $fres;
    if ($res->[3]{is_stream}) {
        log_trace("Result is a stream");
        return;
    } elsif ($res->[3]{'x.hint.result_binary'} && $format =~ /text/) {
        $fres = $res->[2];
    } else {
        log_trace("Formatting output with %s", $format);
        $fres = Perinci::Result::Format::format($res, $format, $r->{naked_res});
    }

    # ux: prefix error message with program name
    if ($format=~/text/ && $r->{res}[0] =~ /\A[45]/ && defined($r->{res}[1])) {
        $fres = "$self->{program_name}: $fres";
    }

    $fres;
}

sub hook_display_result {
    my ($self, $r) = @_;

    my $res  = $r->{res};
    my $resmeta = $res->[3] // {};

    my $handle = $r->{output_handle};

    if ($ENV{COMP_LINE} || $res->[3]{"cmdline.skip_format"}) {
        print $handle $res->[2];
        return;
    }

    # set utf8 flag
    my $utf8;
    {
        if ($resmeta->{'x.hint.result_binary'}) {
            # XXX only when format is text?
            $utf8 = 0; last;
        }

        my $am;
        $am = $self->action_metadata->{$r->{action}}
            if $r->{action};
        last if defined($utf8 = $am->{use_utf8});

        if ($r->{subcommand_data}) {
            last if defined($utf8 = $r->{subcommand_data}{use_utf8});
        }

        $utf8 = $self->use_utf8;
    }
    binmode($handle, ":encoding(utf8)") if $utf8;

    $self->display_result($r);
}

sub hook_after_run {
    my ($self, $r) = @_;
    $self->_unsetup_progress_output;
}

sub action_subcommands {
    my ($self, $r) = @_;

    if (!$self->subcommands) {
        return [200, "OK", __("There are no subcommands") . ".",
                {"cmdline.skip_format"=>1}];
    }

    $r->{_help_buf} = '';

    my $subcommands = $self->list_subcommands;

    # XXX get summary from Riap if not exist, but this results in multiple Riap
    # requests.

    my %percat_subc; # (cat1 => {subcmd1=>..., ...}, ...)
    while (my ($scn, $sc) = each %$subcommands) {
        my $cat = "";
        for my $tag (@{$sc->{tags} // []}) {
            my $tn = ref($tag) ? $tag->{name} : $tag;
            next unless $tn =~ /^category:(.+)/;
            $cat = $1;
            last;
        }
        $percat_subc{$cat}       //= {};
        $percat_subc{$cat}{$scn}   = $sc;
    }
    my $has_many_cats = scalar(keys %percat_subc) > 1;

    my $i = 0;
    for my $cat (sort keys %percat_subc) {
        if ($has_many_cats) {
            $self->_help_add_heading(
                $r,
                __x("{category} subcommands",
                    category => ucfirst($cat || __("main"))));
        }
        my $subc = $percat_subc{$cat};
        for my $scn (sort keys %$subc) {
            my $sc = $subc->{$scn};
            my $summary = rimeta($sc)->langprop("summary");
            $self->_help_add_row(
                $r,
                [$self->_color('program_name', $scn), $summary],
                {column_widths=>[-17, -40], indent=>1});
        }
    }
    $self->_help_draw_curtbl($r);

    [200, "OK", $r->{_help_buf},
     {"cmdline.skip_format"=>1}];
}

sub action_version {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my ($self, $r) = @_;

    my $url = $r->{subcommand_data}{url} // $self->url;

    my @text;

    {
        my $meta = $self->get_meta($r, $url);
        push @text, __x(
            "{program} version {version}",
            program => $self->_color('program_name',
                                     $self->get_program_and_subcommand_name),
            version => $self->_color('emphasis', ($meta->{entity_v} // "?")),
        ),
            ($meta->{entity_date} ? " ($meta->{entity_date})" : ""),
            "\n";
        for my $mod (@{ $meta->{'x.dynamic_generator_modules'} // [] }) {
            push @text, "  ", __x(
                "{program} version {version}",
                program => $self->_color('emphasis', $mod),
                version => $self->_color('emphasis', (${"$mod\::VERSION"} // "?")),
            ),
                (${"$mod\::DATE"} ? " (".${"$mod\::DATE"}.")" : ""),
                    "\n";
        }
    }

    for my $url (@{ $self->extra_urls_for_version // [] }) {
        my $meta = $self->get_meta($r, $url);
        push @text, "  ", __x(
            "{program} version {version}",
            program => $self->_color('emphasis', $url),
            version => $self->_color('emphasis', ($meta->{entity_v} // "?")),
        ),
            ($meta->{entity_date} ? " ($meta->{entity_date})" : ''),
            "\n";
    }

    push @text, "  ", __x(
        "{program} version {version}",
        program => $self->_color('emphasis', "Perinci::CmdLine::Classic"),
        version => $self->_color('emphasis',
                                 $Perinci::CmdLine::Classic::VERSION || "dev"),
    ),
        ($Perinci::CmdLine::Classic::DATE ? " ($Perinci::CmdLine::Classic::DATE)" : ""),
        "\n";

    [200, "OK", join("", @text), {"cmdline.skip_format"=>1}];
}

sub action_call {
    my ($self, $r) = @_;

    my $scn = $r->{subcommand_name};
    my $scd = $r->{subcommand_data};

    my %fargs = %{$r->{args} // {}};

    my $tx_id;

    my $dry_run = $r->{dry_run};
    my $using_tx = !$dry_run && $self->undo && ($scd->{undo} // 1);

    # currently we don't attempt to insert tx_id or dry_run when using argv,
    # we'll just give up
    if ($r->{send_argv} && ($dry_run || $using_tx)) {
        return $r->{parse_argv_res};
    }

    if ($using_tx) {
        require UUID::Random;
        $tx_id = UUID::Random::generate();
        $tx_id =~ s/-.+//; # 32bit suffices for small number of txs
        my $summary = join(" ", @{ $r->{orig_argv} });
        my $tres = $self->riap_client->request(
            begin_tx => "/", {tx_id=>$tx_id, summary=>$summary});
        if ($tres->[0] != 200) {
            return [$tres->[0], "Can't start transaction '$tx_id': $tres->[1]"];
        }
    }

    # setup output progress indicator
    if ($r->{meta}{features}{progress}) {
        $self->_setup_progress_output;
    }

    # call function
    my $res;
    if ($r->{send_argv}) {
        $res = $self->riap_client->request(
            call => $scd->{url},
            {argv=>$r->{orig_argv}}, # XXX tx_id, dry_run (see above)
        );
    } else {
        #$log->tracef("Calling function via _pa with arguments: %s", \%fargs);
        $res = $self->riap_client->request(
            call => $scd->{url},
            {args=>\%fargs, tx_id=>$tx_id, dry_run=>$dry_run});
    }
    log_trace("call res=%s", $res);

    # commit transaction (if using tx)
    if ($using_tx && $res->[0] =~ /\A(?:200|304)\z/) {
        my $tres = $self->riap_client->request(commit_tx => "/", {tx_id=>$tx_id});
        if ($tres->[0] != 200) {
            return [$tres->[0],"Can't commit transaction '$tx_id': $tres->[1]"];
        }
    }

    $res;
}

sub action_history {
    my ($self, $r) = @_;
    my $res = $self->riap_client->request(list_txs => "/", {detail=>1});
    log_trace("list_txs res=%s", $res);
    return $res unless $res->[0] == 200;
    $res->[2] = [sort {($b->{tx_commit_time}//0) <=> ($a->{tx_commit_time}//0)}
                     @{$res->[2]}];
    my @txs;
    for my $tx (@{$res->[2]}) {
        next unless $tx->{tx_status} =~ /[CUX]/;
        push @txs, {
            id          => $tx->{tx_id},
            start_time  => $tx->{tx_start_time},
            commit_time => $tx->{tx_commit_time},
            status      => $tx->{tx_status} eq 'X' ? 'error' :
                $tx->{tx_status} eq 'U' ? 'undone' : '',
            summary     => $tx->{tx_summary},
        };
    }
    [200, "OK", \@txs];
}

sub action_clear_history {
    my ($self, $r) = @_;
    $self->riap_client->request(discard_all_txs => "/");
}

sub action_undo {
    my ($self, $r) = @_;
    $self->riap_client->request(undo => "/");
}

sub action_redo {
    my ($self, $r) = @_;
    $self->riap_client->request(redo => "/");
}

1;
# ABSTRACT: Rinci/Riap-based command-line application framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Classic - Rinci/Riap-based command-line application framework

=head1 VERSION

This document describes version 1.817 of Perinci::CmdLine::Classic (from Perl distribution Perinci-CmdLine-Classic), released on 2022-10-19.

=head1 SYNOPSIS

In C<gen-random-num> script:

 use Perinci::CmdLine::Classic;

 our %SPEC;

 $SPEC{gen_random_num} = {
     v => 1.1,
     summary => 'Generate some random numbers',
     args => {
         count => {
             summary => 'How many numbers to generate',
             schema => ['int*' => min=>0],
             default => 1,
             cmdline_aliases=>{n=>{}},
             req => 1,
             pos => 0,
         },
         min => {
             summary => 'Lower limit of random number',
             schema => 'float*',
             default => 0,
         },
         max => {
             summary => 'Upper limit of random number',
             schema => 'float*',
             default => 1,
         },
     },
     result_naked => 1,
 };
 sub gen_random_num {
     my %args = @_;

     my @res;
     for (1..$args{count}) {
         push @res, $args{min} + rand()*($args{max}-$args{min});
     }
     \@res;
 }

 Perinci::CmdLine::Classic->new(url => '/main/gen_random_num')->run;

Run your script:

 % ./gen-random-num
 0.999473691060306

 % ./gen-random-num --min 1 --max 10 5
 1.27390166158969
 1.69077475473679
 8.97748327778684
 5.86943773494068
 8.34341298182493

JSON output support out of the box:

 % ./gen-random-num -n3 --json
 [200,"OK (envelope added by Perinci::Access::Lite)",[0.257073684902029,0.393782991540746,0.848740540017513],{}]

Automatic help message:

 % ./gen-random-num -h
 gen-random-num - Generate some random numbers

 Usage:
   gen-random-num --help (or -h, -?)
   gen-random-num --version (or -v)
   gen-random-num [options] [count]
 Options:
   --config-path=s     Set path to configuration file
   --config-profile=s  Set configuration profile to use
   --count=i, -n       How many numbers to generate (=arg[0]) [1]
   --format=s          Choose output format, e.g. json, text [undef]
   --help, -h, -?      Display this help message
   --json              Set output format to json
   --max=f             Upper limit of random number [1]
   --min=f             Lower limit of random number [0]
   --naked-res         When outputing as JSON, strip result envelope [0]
   --no-config         Do not use any configuration file
   --version, -v

Automatic configuration file support:

 % cat ~/gen-random-num.conf
 count=5
 max=0.01

 % ./gen-random-num
 0.00105268954838724
 0.00701443611501844
 0.0021247476506154
 0.00813872824513005
 0.00752832346491306

Automatic tab completion support:

 % complete -C gen-random-num gen-random-num
 % gen-random-num --mi<tab>

See L<Perinci::CmdLine::Manual> for details on other available features
(subcommands, automatic formatting of data structures, automatic schema
validation, dry-run mode, automatic POD generation, remote function support,
automatic CLI generation, automatic --version, automatic HTTP API,
undo/transactions, configurable output format, logging, progress bar,
colors/Unicode, and more).

=head1 DESCRIPTION

Perinci::CmdLine is a command-line application framework. It allows you to
create full-featured CLI applications easily and quickly.

See L<Perinci::CmdLine::Manual> for more details.

There is also a blog post series on Perinci::CmdLine tutorial:
L<https://perlancar.wordpress.com/category/pericmd-tut/>

Perinci::CmdLine::Classic is the heavier backend implementation which supports
some extra features currently not supported by the default backend
implementation L<Perinci::CmdLine::Lite>. These features come at some startup
overhead cost and more dependencies. You normally should use
L<Perinci::CmdLine::Any> instead to be able to switch backend on the fly.

Screenshots:

=for Pod::Coverage ^(.+)$

=begin HTML

<p><img src="http://blogs.perl.org/users/perlancar/screenshot-pericmd-help.jpg" /><br />Autogenerated help message

<p><img src="http://blogs.perl.org/users/perlancar/screenshot-pericmd-help_verbose.jpg" /><br />Autogenerated help message (verbose mode)

<p><img src="http://blogs.perl.org/users/perlancar/progany-tpc.jpg" /><br />Progress bar

<p><img src="http://blogs.perl.org/users/perlancar/screenshot-pericmd-completion.jpg" /><br />Tab completion

<p><img src="http://blogs.perl.org/users/perlancar/screenshot-pericmd-format.jpg" /><br />Some output formats

<p><img src="http://blogs.perl.org/users/perlancar/screenshot-trashu.jpg" /><br />Undo/redo

=end HTML

=head1 REQUEST KEYS

See also L<Perinci::CmdLine::Base>. Extra stuffs put by this module to the C<$r>
hash/stash.

=over

=item * format_options => hash

=back

=head1 RESULT METADATA

All those supported by L<Perinci::CmdLine::Base>, plus:

=head2 x.hint.result_binary => bool

If set to true, then when formatting to C<text> formats, this class won't print
any newline to keep the data being printed unmodified.

=head1 ATTRIBUTES

All the attributes of L<Perinci::CmdLine::Base>, plus:

=head2 use_utf8 => BOOL

From L<Term::App::Role::Attrs> (please see its docs for more details). There are
several other attributes added by the role.

=head2 undo => BOOL (optional, default 0)

Whether to enable undo/redo functionality. Some things to note if you intend to
use undo:

=over

=item * These common command-line options will be recognized

C<--undo>, C<--redo>, C<--history>, C<--clear-history>.

=item * Transactions will be used

C<< use_tx=>1 >> will be passed to L<Perinci::Access>, which will cause it to
initialize the transaction manager. Riap requests begin_tx and commit_tx will
enclose the call request to function.

=item * Called function will need to support transaction and undo

Function which does not meet qualifications will refuse to be called.

Exception is when subcommand is specified with C<< undo=>0 >>, where transaction
will not be used for that subcommand. For an example of disabling transaction
for some subcommands, see C<bin/u-trash> in the distribution.

=back

=head2 undo_dir => STR (optional, default ~/.<program_name>/.undo)

Where to put undo data. This is actually the transaction manager's data dir.

=head1 METHODS

All the methods of L<Perinci::CmdLine::Base>, plus:

=over

=back

=head1 ENVIRONMENT

All the environment variables that L<Perinci::CmdLine::Base> supports, plus:

=head2 PERINCI_CMDLINE_COLOR_THEME => STR

Can be used to set C<color_theme>.

=head2 PROGRESS => BOOL

Explicitly turn the progress bar on/off.

=head2 COLOR => INT

Please see L<Term::App::Role::Attrs>.

=head2 UTF8 => BOOL

Please see L<Term::App::Role::Attrs>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Classic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Classic>.

=head1 SEE ALSO

L<Perinci::CmdLine::Any>, L<Perinci::CmdLine::Lite>.

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

This software is copyright (c) 2022, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Classic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
