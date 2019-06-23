package Perinci::CmdLine::Base;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '1.820'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

# this class can actually be a role instead of base class for pericmd &
# pericmd-lite, but Mo is more lightweight than Role::Tiny (also R::T doesn't
# have attributes), Role::Basic, or Moo::Role.

BEGIN {
    if ($INC{'Perinci/CmdLine/Classic.pm'}) {
        require Moo; Moo->import;
    } else {
        require Mo; Mo->import(qw(build default));
    }
}

# BEGIN taken from Array::Iter
sub __array_iter {
    my $ary = shift;
    my $i = 0;
    sub {
        if ($i < @$ary) {
            return $ary->[$i++];
        } else {
            return undef;
        }
    };
}

sub __list_iter {
    __array_iter([@_]);
}
# END from Array::Iter

has actions => (is=>'rw');
has common_opts => (is=>'rw');
has completion => (is=>'rw');
has default_subcommand => (is=>'rw');
has get_subcommand_from_arg => (is=>'rw', default=>1);
has auto_abbrev_subcommand => (is=>'rw', default=>1);
has description => (is=>'rw');
has exit => (is=>'rw', default=>1);
has formats => (is=>'rw');
has default_format => (is=>'rw');
has pass_cmdline_object => (is=>'rw', default=>0);
has per_arg_json => (is=>'rw');
has per_arg_yaml => (is=>'rw');
has program_name => (
    is=>'rw',
    default => sub {
        my $pn = $ENV{PERINCI_CMDLINE_PROGRAM_NAME};
        if (!defined($pn)) {
            $pn = $0; $pn =~ s!.+/!!;
        }
        $pn;
    });
has riap_version => (is=>'rw', default=>1.1);
has riap_client => (is=>'rw');
has riap_client_args => (is=>'rw');
has subcommands => (is=>'rw');
has summary => (is=>'rw');
has tags => (is=>'rw');
has url => (is=>'rw');
has log => (is=>'rw', default => 0);
has log_level => (is=>'rw');

has read_env => (is=>'rw', default=>1);
has env_name => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        __default_env_name($self->program_name);
    },
);

has read_config => (is=>'rw', default=>1);
has config_filename => (is=>'rw');
has config_dirs => (
    is=>'rw',
    default => sub {
        require Perinci::CmdLine::Util::Config;
        Perinci::CmdLine::Util::Config::get_default_config_dirs();
    },
);

has cleanser => (
    is => 'rw',
    lazy => 1,
    default => sub {
        require Data::Clean::JSON;
        Data::Clean::JSON->get_cleanser;
    },
);
has use_cleanser => (is=>'rw', default=>1);

has extra_urls_for_version => (is=>'rw');

has skip_format => (is=>'rw');

has use_utf8 => (
    is=>'rw',
    default => sub {
        $ENV{UTF8} // 0;
    },
);

has default_dry_run => (
    is=>'rw',
    default => 0,
);

# role: requires 'default_prompt_template'

# role: requires 'hook_before_run'
# role: requires 'hook_before_parse_argv'
# role: requires 'hook_before_read_config_file'
# role: requires 'hook_config_file_section'
# role: requires 'hook_after_read_config_file'
# role: requires 'hook_after_get_meta'
# role: requires 'hook_after_parse_argv'
# role: requires 'hook_before_action'
# role: requires 'hook_format_row' (for action=call)
# role: requires 'hook_after_action'
# role: requires 'hook_format_result'
# role: requires 'hook_display_result'
# role: requires 'hook_after_run'

# we put common stuffs here, but PC::Classic's final version will differ from
# PC::Lite's in several aspects: translation, supported output formats,
# PC::Classic currently adds some extra keys, some options are not added by
# PC::Lite (e.g. history/undo stuffs).
our %copts = (

    version => {
        getopt  => "version|v",
        summary => "Display program's version and exit",
        usage   => "--version (or -v)",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{action} = 'version';
            $r->{skip_parse_subcommand_argv} = 1;
        },
    },

    help => {
        getopt  => 'help|h|?',
        summary => 'Display help message and exit',
        usage   => "--help (or -h, -?)",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{action} = 'help';
            $r->{skip_parse_subcommand_argv} = 1;
        },
        order => 0, # high
    },

    format => {
        getopt  => 'format=s',
        summary => 'Choose output format, e.g. json, text',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{format} = $val;
        },
        default => undef,
        tags => ['category:output'],
        is_settable_via_config => 1,
    },
    json => {
        getopt  => 'json',
        summary => 'Set output format to json',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{format} = (-t STDOUT) ? 'json-pretty' : 'json';
        },
        tags => ['category:output'],
    },

    naked_res => {
        getopt  => 'naked-res!',
        summary => 'When outputing as JSON, strip result envelope',
        'summary.alt.bool.not' => 'When outputing as JSON, add result envelope',
        description => <<'_',

By default, when outputing as JSON, the full enveloped result is returned, e.g.:

    [200,"OK",[1,2,3],{"func.extra"=>4}]

The reason is so you can get the status (1st element), status message (2nd
element) as well as result metadata/extra result (4th element) instead of just
the result (3rd element). However, sometimes you want just the result, e.g. when
you want to pipe the result for more post-processing. In this case you can use
`--naked-res` so you just get:

    [1,2,3]

_
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{naked_res} = $val ? 1:0;
        },
        default => 0,
        tags => ['category:output'],
        is_settable_via_config => 1,
    },

    subcommands => {
        getopt  => 'subcommands',
        summary => 'List available subcommands',
        usage   => "--subcommands",
        show_in_usage => sub {
            my ($self, $r) = @_;
            !$r->{subcommand_name};
        },
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{action} = 'subcommands';
            $r->{skip_parse_subcommand_argv} = 1;
        },
    },

    # 'cmd=SUBCOMMAND_NAME' can be used to select other subcommands when
    # default_subcommand is in effect.
    cmd => {
        getopt  => "cmd=s",
        summary => 'Select subcommand',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{subcommand_name} = $val;
            $r->{subcommand_name_from} = '--cmd';
        },
        completion => sub {
            require Complete::Util;
            my %args = @_;
            my $cmdline = $args{cmdline};
            Complete::Util::complete_array_elem(
                array => [keys %{ $cmdline->list_subcommands }],
                word  => $args{word},
                ci    => 1,
            );
        },
    },

    config_path => {
        getopt  => 'config-path=s@',
        schema  => ['array*', of => 'str*'],
        'x.schema.element_entity' => 'filename',
        summary => 'Set path to configuration file',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{config_paths} //= [];
            push @{ $r->{config_paths} }, $val;
        },
        tags => ['category:configuration'],
    },
    no_config => {
        getopt  => 'no-config',
        summary => 'Do not use any configuration file',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{read_config} = 0;
        },
        tags => ['category:configuration'],
    },
    no_env => {
        getopt  => 'no-env',
        summary => 'Do not read environment for default options',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{read_env} = 0;
        },
        tags => ['category:environment'],
    },
    config_profile => {
        getopt  => 'config-profile=s',
        summary => 'Set configuration profile to use',
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{config_profile} = $val;
        },
        completion => sub {
            # return list of profiles in read config file

            my %args = @_;
            my $word    = $args{word} // '';
            my $cmdline = $args{cmdline};
            my $r       = $args{r};

            # we are not called from cmdline, bail (actually we might want to
            # return list of programs anyway, but we want to read the value of
            # bash_global_dir et al)
            return undef unless $cmdline;

            # since this is common option, at this point we haven't parsed
            # argument or even read config file. let's parse argv first (argv
            # might set --config-path). then read the config files.
            {
                # this is not activated yet
                $r->{read_config} = 1;

                my $res = $cmdline->parse_argv($r);
                #return undef unless $res->[0] == 200;

                # parse_argv() might decide that it doesn't need to read config
                # files (e.g. in the case of program having a subcommand and
                # user does not specify any subcommand name, then it will
                # shortcut to --help and set skip_parse_subcommand_argv=1). we
                # don't want that here, we want to force reading config files:
                $cmdline->_read_config($r) unless $r->{config};
            }

            # we are not reading any config file, return empty list
            return [] unless $r->{config};

            my @profiles;
            for my $section (keys %{$r->{config}}) {
                my %keyvals;
                for my $word (split /\s+/, ($section eq 'GLOBAL' ? '' : $section)) {
                    if ($word =~ /(.+)=(.*)/) {
                        $keyvals{$1} = $2;
                    } else {
                        # old syntax, will be removed sometime in the future
                        $keyvals{subcommand} = $word;
                    }
                }
                if (defined(my $p = $keyvals{profile})) {
                    push @profiles, $p unless grep {$_ eq $p} @profiles;
                }
            }

            require Complete::Util;
            Complete::Util::complete_array_elem(
                array=>\@profiles, word=>$word, ci=>1);
        },
        tags => ['category:configuration'],
    },

    # since the cmdline opts is consumed, Log::Any::App doesn't see this. we
    # currently work around this via setting env.
    log_level => {
        getopt  => 'log-level=s',
        summary => 'Set log level',
        schema  => ['str*' => in => [
            qw/trace debug info warn warning error fatal/]],
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{log_level} = $val;
        },
        is_settable_via_config => 1,
        tags => ['category:logging'],
    },
    trace => {
        getopt  => "trace",
        summary => "Shortcut for --log-level=trace",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{log_level} = 'trace';
        },
        tags => ['category:logging'],
    },
    debug => {
        getopt  => "debug",
        summary => "Shortcut for --log-level=debug",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{log_level} = 'debug';
        },
        tags => ['category:logging'],
    },
    verbose => {
        getopt  => "verbose",
        summary => "Shortcut for --log-level=info",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{log_level} = 'info';
            $r->{_help_verbose} = 1;
        },
        tags => ['category:logging'],
    },
    quiet => {
        getopt  => "quiet",
        summary => "Shortcut for --log-level=error",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{log_level} = 'error';
        },
        tags => ['category:logging'],
    },

);

sub __default_env_name {
    my ($prog) = @_;

    for ($prog) {
        $_ //= "PROG"; # shouldn't happen
        $_ = uc($_);
        s/[^A-Z0-9]+/_/g;
        $_ = "_$_" if /\A\d/;
    }
    "${prog}_OPT";
}

sub hook_before_run {}

sub hook_before_read_config_file {}

sub hook_after_read_config_file {}

sub hook_before_action {}

sub hook_after_action {}

sub get_meta {
    my ($self, $r, $url) = @_;

    my $res = $self->riap_client->request(meta => $url);
    die $res unless $res->[0] == 200;
    my $meta = $res->[2];
    $r->{meta} = $meta;
    log_trace("[pericmd] Running hook_after_get_meta ...");
    $self->hook_after_get_meta($r);
    $meta;
}

sub get_program_and_subcommand_name {
    my ($self, $r) = @_;
    my $res = ($self->program_name // "") . " " .
        ($r->{subcommand_name} // "");
    $res =~ s/\s+$//;
    $res;
}

sub get_subcommand_data {
    my ($self, $name) = @_;

    my $scs = $self->subcommands;
    return undef unless $scs;

    if (ref($scs) eq 'CODE') {
        return $scs->($self, name=>$name);
    } else {
        return $scs->{$name};
    }
}

sub list_subcommands {
    my ($self) = @_;
    return $self->{_cache_subcommands} if $self->{_cache_subcommands};

    my $scs = $self->subcommands;
    my $res;
    if ($scs) {
        if (ref($scs) eq 'CODE') {
            $scs = $scs->($self);
            die [500, "BUG: Subcommands code didn't return a hashref"]
                unless ref($scs) eq 'HASH';
        }
        $res = $scs;
    } else {
        $res = {};
    }
    $self->{_cache_subcommands} = $res;
    $res;
}

sub status2exitcode {
    my ($self, $status) = @_;
    return 0 if $status =~ /^2..|304/;
    $status - 300;
}

sub _detect_completion {
    my ($self, $r) = @_;

    if ($ENV{COMP_SHELL}) {
        $r->{shell} = $ENV{COMP_SHELL};
        return 1;
    } elsif ($ENV{COMP_LINE}) {
        $r->{shell} = 'bash';
        return 1;
    } elsif ($ENV{COMMAND_LINE}) {
        $r->{shell} = 'tcsh';
        return 1;
    }

    $r->{shell} //= 'bash';
    0;
}

sub _read_env {
    my ($self, $r) = @_;

    return [] unless $self->read_env;
    my $env_name = $self->env_name;
    my $env = $ENV{$env_name};
    log_trace("[pericmd] Checking env %s: %s", $env_name, $env);
    return [] unless defined $env;

    # XXX is it "proper" to use Complete::* modules to parse cmdline, outside
    # the context of completion?

    my $words;
    if ($r->{shell} eq 'bash') {
        require Complete::Bash;
        ($words, undef) = @{ Complete::Bash::parse_cmdline($env, 0) };
    } elsif ($r->{shell} eq 'fish') {
        ($words, undef) = @{ Complete::Base::parse_cmdline($env) };
    } elsif ($r->{shell} eq 'tcsh') {
        require Complete::Tcsh;
        ($words, undef) = @{ Complete::Tcsh::parse_cmdline($env) };
    } elsif ($r->{shell} eq 'zsh') {
        require Complete::Bash;
        ($words, undef) = @{ Complete::Bash::parse_cmdline($env) };
    } else {
        die "Unsupported shell '$r->{shell}'";
    }
    log_trace("[pericmd] Words from env: %s", $words);
    $words;
}

sub do_dump_object {
    require Data::Dump;

    my ($self, $r) = @_;

    local $r->{in_dump_object} = 1;

    # check whether subcommand is defined. try to search from --cmd, first
    # command-line argument, or default_subcommand.
    $self->hook_before_parse_argv($r);
    $self->_parse_argv1($r);

    if ($r->{read_env}) {
        my $env_words = $self->_read_env($r);
        unshift @ARGV, @$env_words;
    }

    my $scd = $r->{subcommand_data};
    # we do get_meta() currently because some common option like dry_run is
    # added in hook_after_get_meta().
    my $meta = $self->get_meta($r, $scd->{url} // $self->{url});

    # additional information, because scripts often put their metadata in 'main'
    # package
    $self->{'x.main.spec'} = \%main::SPEC;

    my $label = $ENV{PERINCI_CMDLINE_DUMP_OBJECT} //
        $ENV{PERINCI_CMDLINE_DUMP}; # old name that will be removed
    my $dump = join(
        "",
        "# BEGIN DUMP $label\n",
        Data::Dump::dump($self), "\n",
        "# END DUMP $label\n",
    );

    [200, "OK", $dump,
     {
         stream => 0,
         "cmdline.skip_format" => 1,
     }];
}

sub do_dump_args {
    require Data::Dump;

    my ($self, $r) = @_;

    [200, "OK", Data::Dump::dump($r->{args}) . "\n",
     {
         stream => 0,
         "cmdline.skip_format" => 1,
     }];
}

sub do_dump_config {
    require Data::Dump;

    my ($self, $r) = @_;

    [200, "OK", Data::Dump::dump($r->{config}) . "\n",
     {
         stream => 0,
         "cmdline.skip_format" => 1,
     }];
}

sub do_completion {
    my ($self, $r) = @_;

    local $r->{in_completion} = 1;

    my ($words, $cword);
    if ($r->{shell} eq 'bash') {
        require Complete::Bash;
        require Encode;
        ($words, $cword) = @{ Complete::Bash::parse_cmdline(undef, undef, {truncate_current_word=>1}) };
        ($words, $cword) = @{ Complete::Bash::join_wordbreak_words($words, $cword) };
        $words = [map {Encode::decode('UTF-8', $_)} @$words];
    } elsif ($r->{shell} eq 'fish') {
        require Complete::Bash;
        ($words, $cword) = @{ Complete::Bash::parse_cmdline() };
    } elsif ($r->{shell} eq 'tcsh') {
        require Complete::Tcsh;
        ($words, $cword) = @{ Complete::Tcsh::parse_cmdline() };
    } elsif ($r->{shell} eq 'zsh') {
        require Complete::Bash;
        ($words, $cword) = @{ Complete::Bash::parse_cmdline() };
    } else {
        die "Unsupported shell '$r->{shell}'";
    }

    shift @$words; $cword--; # strip program name

    # @ARGV given by bash is messed up / different. during completion, we
    # get ARGV from parsing COMP_LINE/COMP_POINT.
    @ARGV = @$words;

    # check whether subcommand is defined. try to search from --cmd, first
    # command-line argument, or default_subcommand.
    $self->hook_before_parse_argv($r);
    $self->_parse_argv1($r);

    if ($r->{read_env}) {
        my $env_words = $self->_read_env($r);
        unshift @ARGV, @$env_words;
        $cword += @$env_words;
    }

    #log_trace("ARGV=%s", \@ARGV);
    #log_trace("words=%s", $words);

    # force format to text for completion, because user might type 'cmd --format
    # blah -^'.
    $r->{format} = 'text';

    my $scd = $r->{subcommand_data};
    my $meta = $self->get_meta($r, $scd->{url} // $self->{url});

    my $subcommand_name_from = $r->{subcommand_name_from} // '';

    require Perinci::Sub::Complete;
    my $compres = Perinci::Sub::Complete::complete_cli_arg(
        meta            => $meta, # must be normalized
        words           => $words,
        cword           => $cword,
        common_opts     => $self->common_opts,
        riap_server_url => $scd->{url},
        riap_uri        => undef,
        riap_client     => $self->riap_client,
        extras          => {r=>$r, cmdline=>$self},
        func_arg_starts_at => ($subcommand_name_from eq 'arg' ? 1:0),
        completion      => sub {
            my %args = @_;
            my $type = $args{type};

            # user specifies custom completion routine, so use that first
            if ($self->completion) {
                my $res = $self->completion(%args);
                return $res if $res;
            }
            # if subcommand name has not been supplied and we're at arg#0,
            # complete subcommand name
            if ($self->subcommands &&
                    $subcommand_name_from ne '--cmd' &&
                         $type eq 'arg' && $args{argpos}==0) {
                require Complete::Util;
                return Complete::Util::complete_array_elem(
                    array => [keys %{ $self->list_subcommands }],
                    word  => $words->[$cword]);
            }

            # otherwise let periscomp do its thing
            return undef;
        },
    );

    my $formatted;
    if ($r->{shell} eq 'bash') {
        require Complete::Bash;
        $formatted = Complete::Bash::format_completion(
            $compres, {word=>$words->[$cword]});
    } elsif ($r->{shell} eq 'fish') {
        require Complete::Fish;
        $formatted = Complete::Fish::format_completion($compres);
    } elsif ($r->{shell} eq 'tcsh') {
        require Complete::Tcsh;
        $formatted = Complete::Tcsh::format_completion($compres);
    } elsif ($r->{shell} eq 'zsh') {
        require Complete::Zsh;
        $formatted = Complete::Zsh::format_completion($compres);
    }

    # to properly display unicode filenames
    $self->use_utf8(1);

    [200, "OK", $formatted,
     # these extra result are for debugging
     {
         "func.words" => $words,
         "func.cword" => $cword,
         "cmdline.skip_format" => 1,
     }];
}

sub _read_config {
    require Perinci::CmdLine::Util::Config;

    my ($self, $r) = @_;

    my $hook_section;
    if ($self->can("hook_config_file_section")) {
        $hook_section = sub {
            my ($section_name, $section_content) = @_;
            $self->hook_config_file_section(
                $r, $section_name, $section_content);
        };
    }

    my $res = Perinci::CmdLine::Util::Config::read_config(
        config_paths     => $r->{config_paths},
        config_filename  => $self->config_filename,
        config_dirs      => $self->config_dirs,
        program_name     => $self->program_name,
        hook_section     => $hook_section,
    );
    die $res unless $res->[0] == 200;
    $r->{config} = $res->[2];
    $r->{read_config_files} = $res->[3]{'func.read_files'};
    $r->{_config_section_read_order} = $res->[3]{'func.section_read_order'}; # we currently don't want to publish this request key

    if ($ENV{LOG_DUMP_CONFIG}) {
        log_trace "config: %s", $r->{config};
        log_trace "read_config_files: %s", $r->{read_config_files};
    }
}

sub __min(@) {
    my $m = $_[0];
    for (@_) {
        $m = $_ if $_ < $m;
    }
    $m;
}

# straight copy of Wikipedia's "Levenshtein Distance"
sub __editdist {
    my @a = split //, shift;
    my @b = split //, shift;

    # There is an extra row and column in the matrix. This is the distance from
    # the empty string to a substring of the target.
    my @d;
    $d[$_][0] = $_ for 0 .. @a;
    $d[0][$_] = $_ for 0 .. @b;

    for my $i (1 .. @a) {
        for my $j (1 .. @b) {
            $d[$i][$j] = (
                $a[$i-1] eq $b[$j-1]
                    ? $d[$i-1][$j-1]
                    : 1 + __min(
                        $d[$i-1][$j],
                        $d[$i][$j-1],
                        $d[$i-1][$j-1]
                    )
                );
        }
    }

    $d[@a][@b];
}

sub __uniq {
    my %seen = ();
    my $k;
    my $seen_undef;
    grep { defined $_ ? not $seen{ $k = $_ }++ : not $seen_undef++ } @_;
}

# $cut is whether we should only compare each element of haystack up to the
# length of needle, so if needle is "foo" and haystack is ["bar", "baroque",
# "fizzle", "food"], it will be as if haystack is ["bar", "bar", "fiz", "foo"].
sub __find_similar_strings {
    my ($needle, $haystack, $cut) = @_;

    my $factor   = 1.5;
    my $max_dist = 4;

    my @res =
        map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        grep { defined }
        map {
            my $el = $_;
            if ($cut && length($_) > length($needle)) {
                $el = substr($el, 0, length($needle));
            }
            my $d = __editdist($el, $needle);
            my $max_distance = __min(
                __min(length($el), length($needle))/$factor,
                $max_dist,
            );
            ($d <= $max_distance) ? [$_, $d] : undef
        } @$haystack;

    $cut ? __uniq(@res) : @res;
}

sub __find_similar_go_opts {
    my ($opt, $go_spec) = @_;

    $opt =~ s/^--?//;

    my @ospecs0 = ref($go_spec) eq 'ARRAY' ?
        keys(%{ { @$go_spec } }) : keys(%$go_spec);
    my @ospecs;
    for my $o (@ospecs0) {
        $o =~ s/^--?//;
        my $is_neg = $o =~ /\!$/;
        $o =~ s/[=:].+|[?+!]$//;
        for (split /\|/, $o) {
            if ($is_neg && length($_) > 1) {
                push @ospecs, $_, "no$_", "no-$_";
            } else {
                push @ospecs, $_;
            }
        }
    }

    map { length($_) > 1 ? "--$_" : "-$_" }
        __find_similar_strings($opt, \@ospecs, "cut");
}

sub _parse_argv1 {
    my ($self, $r) = @_;

    # parse common_opts which potentially sets subcommand
    my @go_spec;
    {
        # one small downside for this is that we cannot do autoabbrev here,
        # because we're not yet specifying all options here.

        require Getopt::Long;
        my $old_go_conf = Getopt::Long::Configure(
            'pass_through', 'no_ignore_case', 'no_auto_abbrev',
            'no_getopt_compat', 'gnu_compat', 'bundling');
        my $co = $self->common_opts // {};
        for my $k (keys %$co) {
            push @go_spec, $co->{$k}{getopt} => sub {
                my ($go, $val) = @_;
                $co->{$k}{handler}->($go, $val, $r);
            };
        }
        #log_trace("\@ARGV before parsing common opts: %s", \@ARGV);
        Getopt::Long::GetOptions(@go_spec);
        Getopt::Long::Configure($old_go_conf);
        #log_trace("\@ARGV after  parsing common opts: %s", \@ARGV);
    }

    # select subcommand and fill subcommand data
    {
        my $scn = $r->{subcommand_name};
        my $scn_from = $r->{subcommand_name_from};
        if (!defined($scn) && defined($self->{default_subcommand})) {
            # get from default_subcommand
            if ($self->get_subcommand_from_arg == 1) {
                $scn = $self->{default_subcommand};
                $scn_from = 'default_subcommand';
            } elsif ($self->get_subcommand_from_arg == 2 && !@ARGV) {
                $scn = $self->{default_subcommand};
                $scn_from = 'default_subcommand';
            }
        }
        if (!defined($scn) && $self->{subcommands} && @ARGV) {
            # get from first command-line arg
            if ($ARGV[0] =~ /\A-/) {
                if ($r->{in_completion}) {
                    $scn = shift @ARGV;
                    $scn_from = 'arg';
                } else {
                    my $suggestion = '';
                    my @similar = __find_similar_go_opts($ARGV[0], \@go_spec);
                    $suggestion = " (perhaps you meant ".
                        join("/", @similar)."?)" if @similar;
                    die [400, "Unknown option: $ARGV[0]".$suggestion];
                }
            } else {
                $scn = shift @ARGV;
                $scn_from = 'arg';
            }
        }

        my $scd;
        if (defined $scn) {
            $scd = $self->get_subcommand_data($scn);
            unless ($r->{in_completion}) {
                unless ($scd) {
                    my $scs = $self->list_subcommands;
                    if ($self->auto_abbrev_subcommand) {
                        # check that subcommand is an unambiguous abbreviation
                        # of an existing subcommand
                        my $num_matches = 0;
                        my $complete_scn;
                        for (keys %$scs) {
                            if (index($_, $scn) == 0) {
                                $num_matches++;
                                $complete_scn = $_;
                                last if $num_matches > 1;
                            }
                        }
                        if ($num_matches == 1) {
                            $scn = $complete_scn;
                            $scd = $self->get_subcommand_data($scn);
                            goto L1;
                        }
                    }
                    # provide suggestion of probably mistyped subcommand to user
                    my @similar =
                        __find_similar_strings($scn, [keys %$scs]);
                    my $suggestion = '';
                    $suggestion = " (perhaps you meant ".
                        join("/", @similar)."?)" if @similar;
                    die [500, "Unknown subcommand: $scn".$suggestion];
                }
            }
        } elsif (!$r->{action} && $self->{subcommands}) {
            # program has subcommands but user doesn't specify any subcommand,
            # or specific action. display help instead.
            $r->{action} = 'help';
            $r->{skip_parse_subcommand_argv} = 1;
        } else {
            $scn = '';
            $scd = {
                url => $self->url,
                summary => $self->summary,
                description => $self->description,
                pass_cmdline_object => $self->pass_cmdline_object,
                tags => $self->tags,
            };
        }
      L1:
        $r->{subcommand_name} = $scn;
        $r->{subcommand_name_from} = $scn_from;
        $r->{subcommand_data} = $scd;
    }

    $r->{_parse_argv1_done} = 1;
}

sub _parse_argv2 {
    require Perinci::CmdLine::Util::Config;

    my ($self, $r) = @_;

    my %args;

    if ($r->{read_env}) {
        my $env_words = $self->_read_env($r);
        unshift @ARGV, @$env_words;
    }

    # parse argv for per-subcommand command-line opts
    if ($r->{skip_parse_subcommand_argv}) {
        return [200, "OK (subcommand options parsing skipped)"];
    } else {
        my $scd = $r->{subcommand_data};
        if ($r->{meta} && !$self->{subcommands}) {
            # we have retrieved meta, no need to get it again
        } else {
            $self->get_meta($r, $scd->{url});
        }

        # first fill in from subcommand specification
        if ($scd->{args}) {
            $args{$_} = $scd->{args}{$_} for keys %{ $scd->{args} };
        }

        # then read from configuration
        if ($r->{read_config}) {

            log_trace("[pericmd] Running hook_before_read_config_file ...");
            $self->hook_before_read_config_file($r);

            $self->_read_config($r) unless $r->{config};

            log_trace("[pericmd] Running hook_after_read_config_file ...");
            $self->hook_after_read_config_file($r);

            my $res = Perinci::CmdLine::Util::Config::get_args_from_config(
                r                  => $r,
                config             => $r->{config},
                args               => \%args,
                program_name       => $self->program_name,
                subcommand_name    => $r->{subcommand_name},
                config_profile     => $r->{config_profile},
                common_opts        => $self->common_opts,
                meta               => $r->{meta},
                meta_is_normalized => 1,
            );
            die $res unless $res->[0] == 200;
            log_trace("[pericmd] args after reading config files: %s",
                         \%args);
            my $found = $res->[3]{'func.found'};
            if (defined($r->{config_profile}) && !$found &&
                    defined($r->{read_config_files}) &&
                        @{$r->{read_config_files}} &&
                            !$r->{ignore_missing_config_profile_section}) {
                return [412, "Profile '$r->{config_profile}' not found ".
                            "in configuration file"];
            }

        }

        # finally get from argv

        # since get_args_from_argv() doesn't pass $r, we need to wrap it
        my $copts = $self->common_opts;
        my %old_handlers;
        for (keys %$copts) {
            my $h = $copts->{$_}{handler};
            $copts->{$_}{handler} = sub {
                my ($go, $val) = @_;
                $h->($go, $val, $r);
            };
            $old_handlers{$_} = $h;
        }

        my $has_cmdline_src;
        for my $ak (keys %{$r->{meta}{args} // {}}) {
            my $av = $r->{meta}{args}{$ak};
            if ($av->{cmdline_src}) {
                $has_cmdline_src = 1;
                last;
            }
        }

        require Perinci::Sub::GetArgs::Argv;
        my $ga_res = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
            argv                => \@ARGV,
            args                => \%args,
            meta                => $r->{meta},
            meta_is_normalized  => 1,
            allow_extra_elems   => $has_cmdline_src ? 1:0,
            per_arg_json        => $self->{per_arg_json},
            per_arg_yaml        => $self->{per_arg_yaml},
            common_opts         => $copts,
            strict              => $r->{in_completion} ? 0:1,
            (ggls_res            => $r->{_ggls_res}) x defined($r->{_ggls_res}),
            on_missing_required_args => sub {
                my %a = @_;

                my ($an, $aa, $as) = ($a{arg}, $a{args}, $a{spec});
                my $src = $as->{cmdline_src} // '';

                # we only get from stdin if stdin is piped
                $src = '' if $src eq 'stdin_or_args' && -t STDIN;

                if ($src && $as->{req}) {
                    # don't complain, we will fill argument from other source
                    return 1;
                } else {
                    # we have no other sources, so we complain about missing arg
                    return 0;
                }
            },
        );

        return $ga_res unless $ga_res->[0] == 200;

        # wrap stream arguments with iterator
        my $args_p = $r->{meta}{args} // {};
        for my $arg (keys %{$ga_res->[2]}) {
            next unless $args_p->{$arg};
            next unless $args_p->{$arg}{stream};
            for ($ga_res->[2]{$arg}) {
                $_ = ref $_ eq 'ARRAY' ? __array_iter($_) : __list_iter($_);
            }
        }

        # restore
        for (keys %$copts) {
            $copts->{$_}{handler} = $old_handlers{$_};
        }

        return $ga_res;
    }
}

sub parse_argv {
    my ($self, $r) = @_;

    log_trace("[pericmd] Parsing \@ARGV: %s", \@ARGV);

    # we parse argv twice. the first parse is with common_opts only so we're
    # able to catch --help, --version, etc early without having to know about
    # subcommands. two reasons for this: sometimes we need to get subcommand
    # name *from* cmdline opts (e.g. --cmd) and thus it's a chicken-and-egg
    # problem. second, it's faster because we don't have to load Riap client and
    # request the meta through it (especially in the case of remote URL).
    #
    # the second parse is after ge get subcommand name and the function
    # metadata. we can parse the remaining argv to get function arguments.
    #
    # note that when doing completion we're not using this algorithem and only
    # parse argv once. this is to make completion work across common- and
    # per-subcommand opts, e.g. --he<tab> resulting in --help (common opt) as
    # well as --height (function argument).

    $self->_parse_argv1($r) unless $r->{_parse_argv1_done};
    $self->_parse_argv2($r);
}

sub __gen_iter {
    require Data::Sah::Util::Type;

    my ($fh, $argspec, $argname) = @_;
    my $schema = $argspec->{schema};
    $schema = $schema->[1]{of} if $schema->[0] eq 'array';
    my $type = Data::Sah::Util::Type::get_type($schema);

    if (Data::Sah::Util::Type::is_simple($schema)) {
        my $chomp = $type eq 'buf' ? 0 :
            $argspec->{'cmdline.chomp'} // 1;
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
            chomp($l) if $chomp;
            $l;
        };
    } else {
        # expect JSON stream for non-simple types
        require JSON::MaybeXS;
        state $json = JSON::MaybeXS->new->allow_nonref;
        my $i = -1;
        return sub {
            state $eof;
            return undef if $eof;
            $i++;
            my $l = <$fh>;
            unless (defined $l) {
                $eof++; return undef;
            }
            eval { $l = $json->decode($l) };
            if ($@) {
                die "Invalid JSON in stream argument '$argname' record #$i: $@";
            }
            $l;
        };
    }
}

# parse cmdline_src argument spec properties for filling argument value from
# file and/or stdin. currently does not support argument submetadata.
sub parse_cmdline_src {
    my ($self, $r) = @_;

    my $action = $r->{action};
    my $meta   = $r->{meta};

    my $url = $r->{subcommand_data}{url} // $self->{url} // '';
    my $is_network = $url =~ m!^(https?|riap[^:]+):!;

    # handle cmdline_src
    if ($action eq 'call') {
        my $args_p = $meta->{args} // {};
        my $stdin_seen;
        for my $an (sort {
            my $csa  = $args_p->{$a}{cmdline_src};
            my $csb  = $args_p->{$b}{cmdline_src};
            my $posa = $args_p->{$a}{pos} // 9999;
            my $posb = $args_p->{$b}{pos} // 9999;

            # first, always put stdin_line before stdin / stdin_or_files
            (
                !$csa || !$csb ? 0 :
                    $csa eq 'stdin_line' && $csb eq 'stdin_line' ? 0 :
                    $csa eq 'stdin_line' && $csb =~ /^(stdin|stdin_or_files?|stdin_or_args)/ ? -1 :
                    $csb eq 'stdin_line' && $csa =~ /^(stdin|stdin_or_files?|stdin_or_args)/ ? 1 : 0
            )
            ||

            # then order by pos
            ($posa <=> $posb)

            ||
            # then by name
            ($a cmp $b)
        } keys %$args_p) {
            #log_trace("TMP: handle cmdline_src for arg=%s", $an);
            my $as = $args_p->{$an};
            my $src = $as->{cmdline_src};
            my $type = $as->{schema}[0]
                or die "BUG: No schema is defined for arg '$an'";
            # Riap::HTTP currently does not support streaming input
            my $do_stream = $as->{stream} && $url !~ /^https?:/;
            if ($src) {
                die [531,
                     "Invalid 'cmdline_src' value for argument '$an': $src"]
                    unless $src =~ /\A(stdin|file|stdin_or_files?|stdin_or_args|stdin_line)\z/;
                die [531,
                     "Sorry, argument '$an' is set cmdline_src=$src, but type ".
                         "is not str/buf/array, only those are supported now"]
                    unless $do_stream || $type =~ /\A(str|buf|array)\z/; # XXX stdin_or_args needs array only, not str/buf

                if ($src =~ /\A(stdin|stdin_or_files?|stdin_or_args)\z/) {
                    die [531, "Only one argument can be specified ".
                             "cmdline_src stdin/stdin_or_file/stdin_or_files/stdin_or_args"]
                        if $stdin_seen++;
                }
                my $is_ary = $type eq 'array';
                if ($src eq 'stdin_line' && !exists($r->{args}{$an})) {
                    require Perinci::Object;
                    my $term_readkey_available = eval { require Term::ReadKey; 1 };
                    my $prompt = Perinci::Object::rimeta($as)->langprop('cmdline_prompt') //
                        sprintf($self->default_prompt_template, $an);
                    print $prompt;
                    my $iactive = (-t STDOUT);
                    Term::ReadKey::ReadMode('noecho')
                          if $term_readkey_available && $iactive && $as->{is_password};
                    chomp($r->{args}{$an} = <STDIN>);
                    do { print "\n"; Term::ReadKey::ReadMode(0) if $term_readkey_available }
                        if $iactive && $as->{is_password};
                    $r->{args}{"-cmdline_src_$an"} = 'stdin_line';
                } elsif ($src eq 'stdin' || $src eq 'file' &&
                        ($r->{args}{$an}//"") eq '-') {
                    die [400, "Argument $an must be set to '-' which means ".
                             "from stdin"]
                        if defined($r->{args}{$an}) &&
                            $r->{args}{$an} ne '-';
                    #log_trace("Getting argument '$an' value from stdin ...");
                    $r->{args}{$an} = $do_stream ?
                        __gen_iter(\*STDIN, $as, $an) :
                            $is_ary ? [<STDIN>] :
                                do {local $/; ~~<STDIN>};
                    $r->{args}{"-cmdline_src_$an"} = 'stdin';
                } elsif ($src eq 'stdin_or_file' || $src eq 'stdin_or_files') {
                    # push back argument value to @ARGV so <> can work to slurp
                    # all the specified files
                    local @ARGV = @ARGV;
                    unshift @ARGV, $r->{args}{$an}
                        if defined $r->{args}{$an};

                    # with stdin_or_file, we only accept one file
                    splice @ARGV, 1
                        if @ARGV > 1 && $src eq 'stdin_or_file';

                    #log_trace("Getting argument '$an' value from ".
                    #                 "$src, \@ARGV=%s ...", \@ARGV);

                    # perl doesn't seem to check files, so we check it here
                    for (@ARGV) {
                        next if $_ eq '-';
                        die [500, "Can't read file '$_': $!"] if !(-r $_);
                    }

                    $r->{args}{"-cmdline_srcfilenames_$an"} = [@ARGV];
                    $r->{args}{$an} = $do_stream ?
                        __gen_iter(\*ARGV, $as, $an) :
                            $is_ary ? [<>] :
                                do {local $/; ~~<>};
                    $r->{args}{"-cmdline_src_$an"} = $src;
                } elsif ($src eq 'stdin_or_args' && !(-t STDIN)) {
                    unless (defined($r->{args}{$an})) {
                        $r->{args}{$an} = $do_stream ?
                            __gen_iter(\*STDIN, $as, $an) :
                            $is_ary ? [map {chomp;$_} <STDIN>] :
                                do {local $/; ~~<STDIN>};
                    }
                } elsif ($src eq 'file') {
                    unless (exists $r->{args}{$an}) {
                        if ($as->{req}) {
                            die [400,
                                 "Please specify filename for argument '$an'"];
                        } else {
                            next;
                        }
                    }
                    die [400, "Please specify filename for argument '$an'"]
                        unless defined $r->{args}{$an};
                    #log_trace("Getting argument '$an' value from ".
                    #                "file ...");
                    my $fh;
                    my $fname = $r->{args}{$an};
                    unless (open $fh, "<", $fname) {
                        die [500, "Can't open file '$fname' for argument '$an'".
                                 ": $!"];
                    }
                    $r->{args}{$an} = $do_stream ?
                        __gen_iter($fh, $as, $an) :
                            $is_ary ? [<$fh>] :
                                do { local $/; ~~<$fh> };
                    close $fh;
                    $r->{args}{"-cmdline_src_$an"} = 'file';
                    $r->{args}{"-cmdline_srcfilenames_$an"} = [$fname];
                }
            }

            # encode to base64 if binary and we want to cross network (because
            # it's usually JSON)
            if ($self->riap_version == 1.2 && $is_network &&
                    defined($r->{args}{$an}) && $args_p->{$an}{schema} &&
                        $args_p->{$an}{schema}[0] eq 'buf' &&
                            !$r->{args}{"$an:base64"}) {
                require MIME::Base64;
                $r->{args}{"$an:base64"} =
                    MIME::Base64::encode_base64($r->{args}{$an}, "");
                delete $r->{args}{$an};
            }
        } # for arg
    }
    #log_trace("args after cmdline_src is processed: %s", $r->{args});
}

# determine filehandle to output to (normally STDOUT, but we can also send to a
# pager, or a temporary file when sending to viewer (the difference between
# pager and viewer: when we page we use pipe, when we view we write to temporary
# file then open the viewer. viewer settings override pager settings.
sub select_output_handle {
    my ($self, $r) = @_;

    my $resmeta = $r->{res}[3] // {};

    my $handle;
  SELECT_HANDLE:
    {
        # view result using external program
        if ($ENV{VIEW_RESULT} // $resmeta->{"cmdline.view_result"}) {
            my $viewer = $resmeta->{"cmdline.viewer"} // $ENV{VIEWER} //
                $ENV{BROWSER};
            last if defined $viewer && !$viewer; # ENV{VIEWER} can be set 0/'' to disable viewing result using external program
            die [500, "No VIEWER program set"] unless defined $viewer;
            $r->{viewer} = $viewer;
            require File::Temp;
            my $filename;
            ($handle, $filename) = File::Temp::tempfile();
            $r->{viewer_temp_path} = $filename;
        }

        if ($ENV{PAGE_RESULT} // $resmeta->{"cmdline.page_result"}) {
            require File::Which;
            my $pager = $resmeta->{"cmdline.pager"} //
                $ENV{PAGER};
            unless (defined $pager) {
                $pager = "less -FRSX" if File::Which::which("less");
            }
            unless (defined $pager) {
                $pager = "more" if File::Which::which("more");
            }
            unless (defined $pager) {
                die [500, "Can't determine PAGER"];
            }
            last unless $pager; # ENV{PAGER} can be set 0/'' to disable paging
            #log_trace("Paging output using %s", $pager);
            ## no critic (InputOutput::RequireBriefOpen)
            open $handle, "| $pager";
        }
        $handle //= \*STDOUT;
    }
    $r->{output_handle} = $handle;
}

sub save_output {
    my ($self, $r, $dir) = @_;
    $dir //= $ENV{PERINCI_CMDLINE_OUTPUT_DIR};

    unless (-d $dir) {
        warn "Can't save output to $dir: doesn't exist or not a directory,skipped saving program output";
        return;
    }

    my $time = do {
        if (eval { require Time::HiRes; 1 }) {
            Time::HiRes::time();
        } else {
            time();
        }
    };

    my $fmttime = do {
        my @time = gmtime($time);
        sprintf(
            "%04d-%02d-%02dT%02d%02d%02d.%09dZ",
            $time[5]+1900,
            $time[4]+1,
            $time[3],
            $time[2],
            $time[1],
            $time[0],
            ($time - int($time))*1_000_000_000,
        );
    };

    my ($fpath_out, $fpath_meta);
    my ($fh_out, $fh_meta);
    {
        require Fcntl;
        my $counter = -1;
        while (1) {
            if ($counter++ >= 10_000) {
                warn "Can't create file to save program output, skipped saving program output";
                return;
            }
            my $fpath_out  = "$dir/" . ($counter ? "$fmttime.out.$counter"  : "$fmttime.out");
            my $fpath_meta = "$dir/" . ($counter ? "$fmttime.meta.$counter" : "$fmttime.meta");
            if ((-e $fpath_out) || (-e $fpath_meta)) {
                next;
            }
            unless (sysopen $fh_out , $fpath_out , Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL()) {
                warn "Can't create file '$fpath_out' to save program output: $!, skipped saving program output";
                return;
            }
            unless (sysopen $fh_meta, $fpath_meta, Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL()) {
                warn "Can't create file '$fpath_meta' to save program output meta information: $!, skipped saving program output";
                unlink $fpath_out;
                return;
            }
            last;
        }
    }

    require JSON::MaybeXS;
    state $json = JSON::MaybeXS->new->allow_nonref;

    my $out = $self->cleanser->clone_and_clean($r->{res});
    my $meta = {
        time        => $time,
        pid         => $$,
        argv        => $r->{orig_argv},
        read_env    => $r->{read_env},
        read_config => $r->{read_config},
        read_config_files => $r->{read_config_files},
    };
    log_trace "Saving program output to %s ...", $fpath_out;
    print $fh_out $json->encode($out);
    log_trace "Saving program output's meta information to %s ...", $fpath_meta;
    print $fh_meta $json->encode($meta);
}

sub display_result {
    require Data::Sah::Util::Type;

    my ($self, $r) = @_;

    my $meta = $r->{meta};
    my $res = $r->{res};
    my $fres = $r->{fres};
    my $resmeta = $res->[3] // {};

    my $handle = $r->{output_handle};

    my $sch = $meta->{result}{schema} // $resmeta->{schema};
    my $type = Data::Sah::Util::Type::get_type($sch) // '';

    if ($resmeta->{stream} // $meta->{result}{stream}) {
        my $x = $res->[2];
        if (ref($x) eq 'CODE') {
            if (Data::Sah::Util::Type::is_simple($sch)) {
                while (defined(my $l = $x->())) {
                    print $l;
                    print "\n" unless $type eq 'buf';
                }
            } else {
                require JSON::MaybeXS;
                state $json = JSON::MaybeXS->new->allow_nonref;
                if ($self->use_cleanser) {
                    while (defined(my $rec = $x->())) {
                        print $json->encode(
                            $self->cleanser->clone_and_clean($rec)), "\n";
                    }
                } else {
                    while (defined(my $rec = $x->())) {
                        print $json->encode($rec), "\n";
                    }
                }
            }
        } else {
            die "Result is a stream but no coderef provided";
        }
    } else {
        print $handle $fres;
        if ($r->{viewer}) {
            require ShellQuote::Any::Tiny;
            my $cmd = $r->{viewer} ." ". ShellQuote::Any::Tiny::shell_quote($r->{viewer_temp_path});
            system $cmd;
        }
    }
}

sub run {
    my ($self) = @_;
    log_trace("[pericmd] -> run(), \@ARGV=%s", \@ARGV);

    my $co = $self->common_opts;

    my $r = {
        orig_argv   => [@ARGV],
        common_opts => $co,
    };

    # dump object is special case, we delegate to do_dump_object()
    if ($ENV{PERINCI_CMDLINE_DUMP_OBJECT} //
            $ENV{PERINCI_CMDLINE_DUMP} # old name that will be removed
        ) {
        $r->{res} = $self->do_dump_object($r);
        goto FORMAT;
    }

    # completion is special case, we delegate to do_completion()
    if ($self->_detect_completion($r)) {
        $r->{res} = $self->do_completion($r);
        goto FORMAT;
    }

    # set default from common options
    $r->{naked_res} = $co->{naked_res}{default} if $co->{naked_res};
    $r->{format}    = $co->{format}{default} if $co->{format};

    # EXPERIMENTAL, set default format to json if we are running in a pipeline
    # and the right side of the pipe is the 'td' program
    {
        last if (-t STDOUT) || $r->{format};
        last unless eval { require Pipe::Find; 1 };
        my $pipeinfo = Pipe::Find::get_stdout_pipe_process();
        last unless $pipeinfo;
        last unless $pipeinfo->{exe} =~ m![/\\]td\z! ||
            $pipeinfo->{cmdline} =~ m!\A([^\0]*[/\\])?perl\0([^\0]*[/\\])?td\0!;
        $r->{format} = 'json';
    }

    $r->{format} //= $self->default_format;

    if ($self->read_config) {
        # note that we will be reading config file
        $r->{read_config} = 1;
    }

    if ($self->read_env) {
        # note that we will be reading env for default options
        $r->{read_env} = 1;
    }

    eval {
        log_trace("[pericmd] Running hook_before_run ...");
        $self->hook_before_run($r);

        log_trace("[pericmd] Running hook_before_parse_argv ...");
        $self->hook_before_parse_argv($r);

        my $parse_res = $self->parse_argv($r);
        if ($parse_res->[0] == 501) {
            # we'll need to send ARGV to the server, because it's impossible to
            # get args from ARGV (e.g. there's a cmdline_alias with CODE, which
            # has been transformed into string when crossing network boundary)
            $r->{send_argv} = 1;
        } elsif ($parse_res->[0] != 200) {
            die $parse_res;
        }
        $r->{parse_argv_res} = $parse_res;
        $r->{args} = $parse_res->[2] // {};

        # set defaults
        $r->{action} //= 'call';

        # init logging
        if ($self->log) {
            require Log::ger::App;
            my $default_level = do {
                my $dry_run = $r->{dry_run} // $self->default_dry_run;
                $dry_run ? 'info' : 'warn';
            };
            Log::ger::App->import(
                level => $r->{log_level} // $self->log_level // $default_level,
                name  => $self->program_name,
            );
        }

        log_trace("[pericmd] Running hook_after_parse_argv ...");
        $self->hook_after_parse_argv($r);

        if ($ENV{PERINCI_CMDLINE_DUMP_CONFIG}) {
            log_trace "[pericmd] Dumping config ...";
            $r->{res} = $self->do_dump_config($r);
            goto FORMAT;
        }

        $self->parse_cmdline_src($r);

        #log_trace("TMP: parse_res: %s", $parse_res);

        my $missing = $parse_res->[3]{"func.missing_args"};
        die [400, "Missing required argument(s): ".join(", ", @$missing)]
            if $missing && @$missing;

        my $scd = $r->{subcommand_data};
        if ($scd->{pass_cmdline_object} // $self->pass_cmdline_object) {
            $r->{args}{-cmdline} = $self;
            $r->{args}{-cmdline_r} = $r;
        }

        log_trace("[pericmd] Running hook_before_action ...");
        $self->hook_before_action($r);

        my $meth = "action_$r->{action}";
        die [500, "Unknown action $r->{action}"] unless $self->can($meth);
        if ($ENV{PERINCI_CMDLINE_DUMP_ARGS}) {
            log_trace "[pericmd] Dumping arguments ...";
            $r->{res} = $self->do_dump_args($r);
            goto FORMAT;
        }
        log_trace("[pericmd] Running %s() ...", $meth);
        $r->{res} = $self->$meth($r);
        #log_trace("[pericmd] res=%s", $r->{res}); #1

        log_trace("[pericmd] Running hook_after_action ...");
        $self->hook_after_action($r);
    };
    my $err = $@;
    if ($err || !$r->{res}) {
        if ($err) {
            $err = [500, "Died: $err"] unless ref($err) eq 'ARRAY';
            if (%Devel::Confess::) {
                no warnings 'once';
                require Scalar::Util;
                my $id = Scalar::Util::refaddr($err);
                my $stack_trace = $Devel::Confess::MESSAGES{$id};
                $err->[1] .= "\n$stack_trace" if $stack_trace;
            }
            $err->[1] =~ s/\n+$//;
            $r->{res} = $err;
        } else {
            $r->{res} = [500, "Bug: no response produced"];
        }
    } elsif (ref($r->{res}) ne 'ARRAY') {
        log_trace("[pericmd] res=%s", $r->{res}); #2
        $r->{res} = [500, "Bug in program: result not an array"];
    }

    if (!$r->{res}[0] || $r->{res}[0] < 200 || $r->{res}[0] > 555) {
        $r->{res}[3]{'x.orig_status'} = $r->{res}[0];
        $r->{res}[0] = 555;
    }

    $r->{format} //= $r->{res}[3]{'cmdline.default_format'};
    $r->{format} //= $r->{meta}{'cmdline.default_format'};
    my $restore_orig_result;
    my $orig_result;
    if (exists $r->{res}[3]{'cmdline.result.noninteractive'} && !(-t STDOUT)) {
        $restore_orig_result = 1;
        $orig_result = $r->{res}[2];
        $r->{res}[2] = $r->{res}[3]{'cmdline.result.noninteractive'};
    } elsif (exists $r->{res}[3]{'cmdline.result.interactive'} && -t STDOUT) {
        $restore_orig_result = 1;
        $orig_result = $r->{res}[2];
        $r->{res}[2] = $r->{res}[3]{'cmdline.result.interactive'};
    } elsif (exists $r->{res}[3]{'cmdline.result'}) {
        $restore_orig_result = 1;
        $orig_result = $r->{res}[2];
        $r->{res}[2] = $r->{res}[3]{'cmdline.result'};
    }
  FORMAT:
    my $is_success = $r->{res}[0] =~ /\A2/ || $r->{res}[0] == 304;

    if (defined $ENV{PERINCI_CMDLINE_OUTPUT_DIR}) {
        $self->save_output($r);
    }

    if ($is_success &&
            ($self->skip_format ||
             $r->{meta}{'cmdline.skip_format'} ||
             $r->{res}[3]{'cmdline.skip_format'})) {
        $r->{fres} = $r->{res}[2] // '';
    } elsif ($is_success &&
                 ($r->{res}[3]{stream} // $r->{meta}{result}{stream})) {
        # stream will be formatted as displayed by display_result()
    }else {
        log_trace("[pericmd] Running hook_format_result ...");
        $r->{res}[3]{stream} = 0;
        $r->{fres} = $self->hook_format_result($r) // '';
    }
    $self->select_output_handle($r);
    log_trace("[pericmd] Running hook_display_result ...");
    $self->hook_display_result($r);
    log_trace("[pericmd] Running hook_after_run ...");
    $self->hook_after_run($r);

    if ($restore_orig_result) {
        $r->{res}[2] = $orig_result;
    }

    my $exitcode;
    if ($r->{res}[3] && defined($r->{res}[3]{'cmdline.exit_code'})) {
        $exitcode = $r->{res}[3]{'cmdline.exit_code'};
    } else {
        $exitcode = $self->status2exitcode($r->{res}[0]);
    }
    if ($self->exit) {
        log_trace("[pericmd] exit(%s)", $exitcode);
        exit $exitcode;
    } else {
        # so this can be tested
        log_trace("[pericmd] <- run(), exitcode=%s", $exitcode);
        $r->{res}[3]{'x.perinci.cmdline.base.exit_code'} = $exitcode;
        return $r->{res};
    }
}

1;
# ABSTRACT: Base class for Perinci::CmdLine{::Classic,::Lite}

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Base - Base class for Perinci::CmdLine{::Classic,::Lite}

=head1 VERSION

This document describes version 1.820 of Perinci::CmdLine::Base (from Perl distribution Perinci-CmdLine-Lite), released on 2019-06-20.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 PROGRAM FLOW (NORMAL)

If you execute C<run()>, this is what will happen, in order:

=over

=item * Detect if we are running under tab completion mode

This is done by checking the existence of special environment varibles like
C<COMP_LINE> (bash) or C<COMMAND_LINE> (tcsh). If yes, then jump to L</"PROGRAM
FLOW (TAB COMPLETION)">. Otherwise, continue.

=item * Run hook_before_run, if defined

This hook (and every other hook) will be passed a single argument C<$r>, a hash
that contains request data (see L</"REQUEST KEYS">).

Some ideas that you can do in this hook: XXX.

=item * Parse command-line arguments (@ARGV) and set C<action>

If C<read_env> attribute is set to true, and there is environment variable
defined to set default options (see documentation on C<read_env> and C<env_name>
attributes) then the environment variable is parsed and prepended first to the
command-line, so it can be parsed together. For example, if your program is
called C<foo> and environment variable C<FOO_OPT> is set to C<--opt1 --opt2
val>. When you execute:

 % foo --no-opt1 --trace 1 2

then C<@ARGV> will be set to C<< ('--opt1', '--opt2', 'val', '--no-opt1',
'--trace', 1, 2) >>. This way, command-line arguments can have a higher
precedence and override settings from the environment variable (in this example,
C<--opt1> is negated by C<--no-opt1>).

Currently, parsing is done in two steps. The first step is to extract subcommand
name. Because we want to allow e.g. C<cmd --verbose subcmd> in addition to C<cmd
subcmd> (that is, user is allowed to specify options before subcommand name) we
cannot simply get subcommand name from the first element of C<@ARGV> but must
parse command-line options. Also, we want to allow user specifying subcommand
name from option C<cmd --cmd subcmd> because we want to support the notion of
"default subcommand" (subcommand that takes effect if there is no subcommand
specified).

In the first step, since we do not know the subcommand yet, we only parse common
options and strip them. Unknown options at this time will be passed through.

If user specifies common option like C<--help> or C<--version>, then action will
be set to (respectively) C<help> and C<version> and the second step will be
skipped. Otherwise we continue the the second step and action by default is set
to C<call>.

At the end of the first step, we already know the subcommand name (of course, if
subcommand name is unknown, we exit with error) along with subcommand spec: its
URL, per-subcommand settings, and so on (see the C<subcommands> attribute). If
there are no subcommands, subcommand name is set to C<''> (empty string) and the
subcommand spec is filled from the attributes, e.g. C<url>, C<summary>, <tags>,
and so on.

We then perform a C<meta> Riap request to the URL to get the Rinci metadata.
After that, C<hook_after_get_meta> is run if provided. From the Rinci metadata
we get list of arguments (the C<args> property). From this, we generate a spec
of command-line options to feed to L<Getopt::Long>. There are some conversions
being done, e.g. an argument called C<foo_bar> will become command-line option
C<--foo-bar>. Command-line aliases from metadata are also added to the
C<Getopt::Long> spec.

Config file: It is also at this step that we read config file (if C<read_config>
attribute is true). We run C<hook_before_read_config_file> first. Some ideas to
do in this hook: setting default config profile. For each found config section,
we also run C<hook_config_file_section> first. The hook will be fed C<< ($r,
$section_name, $section_content) >> and should return 200 status or 204 (no
content) to skip this config section or 4xx/5xx to terminate config reading with
an error message. After config files are read, we run
C<hook_after_read_config_file>.

We then pass the spec to C<Getopt::Long::GetOptions>, we get function arguments.

We then run C<hook_after_parse_argv>. Some ideas to do in this hook: XXX.

Function arguments that are still missing can be filled from STDIN or files, if
the metadata specifies C<cmdline_src> property (see L<Rinci::function> for more
details).

=item * Delegate to C<action_$action> method

Before running the C<action_$action> method, C<hook_before_action> is called
e.g. to allow changing/fixing action, last chance to check arguments, etc.

After we get the action from the previous step, we delegate to separate
C<action_$action> method (so there is C<action_version>, C<action_help>, and so
on; and also C<action_call>). These methods also receive C<$r> as their argument
and must return an enveloped result (see L<Rinci::function> for more details).

Result is put in C<< $r->{res} >>.

C<hook_after_action> is then called e.g. to preformat result.

=item * Run hook_format_result

Hook must set C<< $r->{fres} >> (formatted result).

If C<skip_format> attribute is true, or function metadata has
C<cmdline.skip_format> set to true, or result has C<cmdline.skip_format>
metadata property set to true, then this step is skipped and C<< $r->{fres} >>
is simply taken from C<< $r->{res}[2] >>.

=item * Run hook_display_result

This hook is used by XXX.

=item * Run hook_after_run, if defined

Some ideas to do in this hook: XXX.

=item * Exit (or return result)

If C<exit> attribute is true, will C<exit()> with the action's envelope result
status. If status is 200, exit code is 0. Otherwise exit code is status minus
300. So, a response C<< [501, "Not implemented"] >> will result in exit code of
201.

If C<exit> attribute is false, will simply return the action result (C<<
$r->{res} >>). And will also set exit code in C<<
$r->{res}[3]{'x.perinci.cmdline.base.exit_code'} >>.

=back

=head1 PROGRAM FLOW (TAB COMPLETION)

If program is detected running in tab completion mode, there is some differences
in the flow. First, C<@ARGV> is set from C<COMP_LINE> (or C<COMMAND_LINE>)
environment variable. Afterwards, completion is done by calling
L<Perinci::Sub::Complete>'s C<complete_cli_arg>.

The result is then output to STDOUT (resume from Run hook_format_result step in
the normal program flow).

=head1 REQUEST KEYS

The various values in the C<$r> hash/stash.

=over

=item * orig_argv => array

Original C<@ARGV> at the beginning of C<run()>.

=item * common_opts => hash

Value of C<common_opts> attribute, for convenience.

=item * action => str

Selected action to use. Usually set from the common options.

=item * format => str

Selected format to use. Usually set from the common option C<--format>.

=item * read_config => bool

This is set in run() to signify that we have tried to read config file (this is
set to true even though config file does not exist). This is never set to true
when C<read_config> attribute is set, which means that we never try to read any
config file.

=item * read_env => bool

This is set in run() to signify that we will try to read env for default
options. This settng can be turned off e.g. in common option C<no_env>. This is
never set to true when C<read_env> attribute is set to false, which means that
we never try to read environment.

=item * config => hash

This is set in the routine that reads config file, containing the config hash.
It might be an empty hash (if there is on config file to read), or a hash with
sections as keys and hashrefs as values (configuration for each section). The
data can be merged from several existing config files.

=item * read_config_files => array

This is set in the routine that reads config file, containing the list of config
files actually read, in order.

=item * config_paths => array of str

=item * config_profile => str

=item * parse_argv_res => array

Enveloped result of C<parse_argv()>.

=item * ignore_missing_config_profile_section => bool (default 1)

This is checked in the parse_argv(). To aid error checking, when a user
specifies a profile (e.g. via C<--config-profile FOO>) and config file exists
but the said profile section is not found in the config file, an error is
returned. This is to notify user that perhaps she mistypes the profile name.

But this checking can be turned off with this setting. This is sometimes used
when e.g. a subclass wants to pick a config profile automatically by setting C<<
$r->{config_profile} >> somewhere before reading config file, but do not want to
fail execution when config profile is not found. An example of code that does
this is L<Perinci::CmdLine::depak>.

=item * subcommand_name => str

Also set by C<parse_argv()>. The subcommand name in effect, either set
explicitly by user using C<--cmd> or the first command-line argument, or set
implicitly with the C<default_subcommand> attribute. Undef if there is no
subcommand name in effect.

=item * subcommand_name_from => str

Also set by C<parse_argv()>. Tells how the C<subcommand_name> request key is
set. Value is either C<--cmd> (if set through C<--cmd> common option), C<arg>
(if set through first command-line argument), C<default_subcommand> (if set to
C<default_subcommand> attribute), or undef if there is no subcommand_name set.

=item * subcommand_data => hash

Also set by C<parse_argv()>. Subcommand data, including its URL, summary (if
exists), and so on. Note that if there is no subcommand, this will contain data
for the main command, i.e. URL will be set from C<url> attribute, summary from
C<summary> attribute, and so on. This is a convenient way to get what URL and
summary to use, and so on.

=item * skip_parse_subcommand_argv => bool

Checked by C<parse_argv()>. Can be set to 1, e.g. in common option handler for
C<--help> or C<--version> to skip parsing @ARGV for per-subcommand options.

=item * args => hash

Also taken from C<parse_argv()> result.

=item * meta => hash

Result of C<get_meta()>.

=item * dry_run => bool

Whether to pass C<-dry_run> special argument to function.

=item * res => array

Enveloped result of C<action_ACTION()>.

=item * fres => str

Result from C<hook_format_result()>.

=item * output_handle => handle

Set by select_output_handle() to choose output handle. Normally it's STDOUT but
can also be pipe to pager (if paging is turned on).

=item * naked_res => bool

Set to true if user specifies C<--naked-res>.

=item * viewer => str

Program to use as external viewer.

=item * viewer_temp_path => str

Set to temporary filename created to store the result to view to external viewer
program.

=back

=head1 HOOKS

All hooks will receive the argument C<$r>, a per-request hash/stash. The list
below is by order of calling.

=head2 $cmd->hook_before_run($r)

Called at the start of C<run()>. Can be used to set some initial values of other
C<$r> keys. Or setup the logger.

=head2 $cmd->hook_before_read_config_file($r)

Only called when C<read_config> attribute is true.

=head2 $cmd->hook_after_read_config_file($r)

Only called when C<read_config> attribute is true.

=head2 $cmd->hook_after_get_meta($r)

Called after the C<get_meta> method gets function metadata, which normally
happens during parsing argument, because parsing function arguments require the
metadata (list of arguments, etc).

PC:Lite as well as PC:Classic use this hook to insert a common option
C<--dry-run> if function metadata expresses that function supports dry-run mode.

PC:Lite also checks the C<deps> property here. PC:Classic doesn't do this
because it uses function wrapper (L<Perinci::Sub::Wrapper>) which does this.

=head2 $cmd->hook_after_parse_argv($r)

Called after C<run()> calls C<parse_argv()> and before it checks the result.
C<$r->{parse_argv_res}> will contain the result of C<parse_argv()>. The hook
gets a chance to, e.g. fill missing arguments from other source.

Note that for sources specified in the C<cmdline_src> property, this base class
will do the filling in after running this hook, so no need to do that here.

PC:Lite uses this hook to give default values to function arguments C<<
$r->{args} >> from the Rinci metadata. PC:Classic doesn't do this because it
uses function wrapper (L<Perinci::Sub::Wrapper>) which will do this as well as
some other stuffs (validate function arguments, etc).

=head2 $cmd->hook_before_action($r)

Called before calling the C<action_ACTION> method. Some ideas to do in this
hook: modifying action to run (C<< $r->{action} >>), last check of arguments
(C<< $r->{args} >>) before passing them to function.

PC:Lite uses this hook to validate function arguments. PC:Classic does not do
this because it uses function wrapper which already does this.

=head2 $cmd->hook_after_action($r)

Called after calling C<action_ACTION> method. Some ideas to do in this hook:
preformatting result (C<< $r->{res} >>).

=head2 $cmd->hook_format_result($r)

The hook is supposed to format result in C<$res->{res}> (an array).

All direct subclasses of PC:Base do the formatting here.

=head2 $cmd->hook_display_result($r)

The hook is supposed to display the formatted result (stored in C<$r->{fres}>)
to STDOUT. But in the case of streaming output, this hook can also set it up.

All direct subclasses of PC:Base do the formatting here.

=head2 $cmd->hook_after_run($r)

Called at the end of C<run()>, right before it exits (if C<exit> attribute is
true) or returns C<$r->{res}>. The hook has a chance to modify exit code or
result.

=head1 SPECIAL ARGUMENTS

Below is list of special arguments that may be passed to your function by the
framework. Per L<Rinci> specification, these are prefixed by C<-> (dash).

=head2 -dry_run => bool

Only when in dry run mode, to notify function that we are in dry run mode.

=head2 -cmdline => obj

Only when C<pass_cmdline_object> attribute is set to true. This can be useful
for the function to know about various stuffs, by probing the framework object.

=head2 -cmdline_r => hash

Only when C<pass_cmdline_object> attribute is set to true. Contains the C<$r>
per-request hash/stash. This can be useful for the function to know about
various stuffs, e.g. parsed configuration data, etc.

=head2 -cmdline_src_ARGNAME => str

This will be set if argument is retrieved from C<file>, C<stdin>,
C<stdin_or_file>, C<stdin_or_files>, or C<stdin_line>.

=head2 -cmdline_srcfilenames_ARGNAME => array

An extra information if argument value is retrieved from file(s), so the
function can know the filename(s).

=head1 METADATA PROPERTY ATTRIBUTE

This module observes the following Rinci metadata property attributes:

=head2 cmdline.default_format => STR

Set default output format (if user does not specify via --format command-line
option).

=head2 cmdline.skip_format => bool

If you set it to 1, you specify that function's result never needs formatting
(i.e. the function outputs raw text to be outputted directly), so no formatting
will be done. See also: C<skip_format> attribute, C<cmdline.skip_format> result
metadata attribute.

=head1 RESULT METADATA

This module interprets the following result metadata property/attribute:

=head2 attribute: cmdline.exit_code => int

Instruct to use this exit code, instead of using (function status - 300).

=head2 attribute: cmdline.result => any

Replace result. Can be useful for example in this case:

 sub is_palindrome {
     my %args = @_;
     my $str = $args{str};
     my $is_palindrome = $str eq reverse($str);
     [200, "OK", $is_palindrome,
      {"cmdline.result" => ($is_palindrome ? "Palindrome" : "Not palindrome")}];
 }

When called as a normal function we return boolean value. But as a CLI, we
display a more user-friendly message.

=head2 attribute: cmdline.result.interactive => any

Like C<cmdline.result> but when script is run interactively.

=head2 attribute: cmdline.result.noninteractive => any

Like C<cmdline.result> but when script is run non-interactively (in a pipeline).

=head2 attribute: cmdline.default_format => str

Default format to use. Can be useful when you want to display the result using a
certain format by default, but still allows user to override the default.

=head2 attribute: cmdline.page_result => bool

If you want to filter the result through pager (currently defaults to
C<$ENV{PAGER}> or C<less -FRSX>), you can set C<cmdline.page_result> in result
metadata to true.

For example:

 $SPEC{doc} = { ... };
 sub doc {
     ...
     [200, "OK", $doc, {"cmdline.page_result"=>1}];
 }

=head2 attribute: cmdline.pager => STR

Instruct to use specified pager instead of C<$ENV{PAGER}> or the default C<less>
or C<more>.

=head2 attribute: cmdline.view_result => bool

Aside from using a pager, you can also use a viewer. The difference is, when we
use a pager we pipe the output directly to the pager, but when we use a viewer
we write to a temporary file then call the viewer with that temporary filename
as argument. Viewer settings override pager settings.

If this attribute is set to true, will view result using external viewer
(external viewer program is set either from C<cmdline.viewer> or C<VIEWER> or
C<BROWSER>. An error is raised when there is no viewer set.)

=head2 attribute: cmdline.viewer => STR

Instruct to use specified viewer instead of C<$ENV{VIEWER}> or C<$ENV{BROWSER}>.

=head2 attribute: cmdline.skip_format => bool (default: 0)

When we want the command-line framework to just print the result without any
formatting. See also: C<skip_format> attribute, C<cmdline.skip_format> function
metadata attribute.

=head2 attribute: x.perinci.cmdline.base.exit_code => int

This is added by this module, so exit code can be tested.

=head1 ATTRIBUTES

=head2 actions => array

Contains a list of known actions and their metadata. Keys should be action
names, values should be metadata. Metadata is a hash containing these keys:

=head2 common_opts => hash

A hash of common options, which are command-line options that are not associated
with any subcommand. Each option is itself a specification hash containing these
keys:

=over

=item * category (str)

Optional, for grouping options in help/usage message, defaults to C<Common
options>.

=item * getopt (str)

Required, for Getopt::Long specification.

=item * handler (code)

Required, for Getopt::Long specification. Note that the handler will receive C<<
($geopt, $val, $r) >> (an extra C<$r>).

=item * usage (str)

Optional, displayed in usage line in help/usage text.

=item * summary (str)

Optional, displayed in description of the option in help/usage text.

=item * show_in_usage (bool or code, default: 1)

A flag, can be set to 0 if we want to skip showing this option in usage in
--help, to save some space. The default is to show all, except --subcommand when
we are executing a subcommand (obviously).

=item * show_in_options (bool or code, default: 1)

A flag, can be set to 0 if we want to skip showing this option in options in
--help. The default is to 0 for --help and --version in compact help. Or
--subcommands, if we are executing a subcommand (obviously).

=item * order (int)

Optional, for ordering. Lower number means higher precedence, defaults to 1.

=back

A partial example from the default set by the framework:

 {
     help => {
         category        => 'Common options',
         getopt          => 'help|h|?',
         usage           => '--help (or -h, -?)',
         handler         => sub { ... },
         order           => 0,
         show_in_options => sub { $ENV{VERBOSE} },
     },
     format => {
         category    => 'Common options',
         getopt      => 'format=s',
         summary     => 'Choose output format, e.g. json, text',
         handler     => sub { ... },
     },
     undo => {
         category => 'Undo options',
         getopt   => 'undo',
         ...
     },
     ...
 }

The default contains: help (getopt C<help|h|?>), version (getopt C<version|v>),
action (getopt C<action>), format (getopt C<format=s>), format_options (getopt
C<format-options=s>), json). If there are more than one subcommands, this will
also be added: list (getopt C<list|l>). If dry-run is supported by function,
there will also be: dry_run (getopt C<dry-run>). If undo is turned on, there
will also be: undo (getopt C<undo>), redo (getopt C<redo>), history (getopt
C<history>), clear_history (getopt C<clear-history>).

Sometimes you do not want some options, e.g. to remove C<format> and
C<format_options>:

 delete $cmd->common_opts->{format};
 delete $cmd->common_opts->{format_options};
 $cmd->run;

Sometimes you want to rename some command-line options, e.g. to change version
to use capital C<-V> instead of C<-v>:

 $cmd->common_opts->{version}{getopt} = 'version|V';

Sometimes you want to add subcommands as common options instead. For example:

 $cmd->common_opts->{halt} = {
     category    => 'Server options',
     getopt      => 'halt',
     summary     => 'Halt the server',
     handler     => sub {
         my ($go, $val, $r) = @_;
         $r->{subcommand_name} = 'shutdown';
     },
 };

This will make:

 % cmd --halt

equivalent to executing the 'shutdown' subcommand:

 % cmd shutdown

=head2 completion => code

Will be passed to L<Perinci::Sub::Complete>'s C<complete_cli_arg()>. See its
documentation for more details.

=head2 default_subcommand => str

Set subcommand to this if user does not specify which to use (either via first
command-line argument or C<--cmd> option). See also: C<get_subcommand_from_arg>.

=head2 auto_abbrev_subcommand => bool (default: 1)

If set to yes, then if a partial subcommand name is given on the command-line
and unambiguously completes to an existing subcommand name, it will be assumed
to be the complete subcommand name. This is like the C<auto_abbrev> behavior of
L<Getopt::Long>. For example:

 % myapp c

If there are subcommands C<create>, C<modify>, C<move>, C<delete>, then C<c> is
assumed to be C<create>. But if:

 % myapp mo

then it results in an unknown subcommand error because mo is ambiguous between
C<modify> and C<move>.

Note that subcommand name in config section must be specified in full. This
option is about convenience at the command-line only.

=head2 get_subcommand_from_arg => int (default: 1)

The default is 1, which is to get subcommand from the first command-line
argument except when there is C<default_subcommand> defined. Other valid values
are: 0 (not getting from first command-line argument), 2 (get from first
command-line argument even though there is C<default_subcommand> defined).

=head2 description => str

=head2 exit => bool (default: 1)

=head2 formats => array

Available output formats.

=head2 default_format => str

Default format.

=head2 pass_cmdline_object => bool (default: 0)

Whether to pass special argument C<-cmdline> containing the cmdline object to
function. This can be overriden using the C<pass_cmdline_object> on a
per-subcommand basis.

In addition to C<-cmdline>, C<-cmdline_r> will also be passed, containing the
C<$r> per-request stash/hash (see L</"REQUEST KEYS">).

Passing the cmdline object can be useful, e.g. to call action_help(), to get the
settings of the Perinci::CmdLine, etc.

=head2 per_arg_json => bool (default: 1 in ::Lite)

This will be passed to L<Perinci::Sub::GetArgs::Argv>.

=head2 per_arg_yaml => bool (default: 0 in ::Lite)

This will be passed to L<Perinci::Sub::GetArgs::Argv>.

=head2 program_name => str

Default is from PERINCI_CMDLINE_PROGRAM_NAME environment or from $0.

=head2 riap_version => float (default: 1.1)

Specify L<Riap> protocol version to use. Will be passed to Riap client
constructor (unless you already provide a Riap client object, see
C<riap_client>).

=head2 riap_client => obj

Set to Riap client instance, should you want to create one yourself. Otherwise
will be set L<Perinci::Access> (in PC:Classic), or L<Perinci::Access::Lite> (in
PC:Lite).

=head2 riap_client_args => hash

Arguments to pass to Riap client constructor. Will be used unless you create
your own Riap client object (see C<riap_client>). One of the things this
attribute is used is to pass HTTP basic authentication to Riap client
(L<Perinci::Access::HTTP::Client>):

 riap_client_args => {handler_args => {user=>$USER, password=>$PASS}}

=head2 subcommands => hash | code

Should be a hash of subcommand specifications or a coderef.

Each subcommand specification is also a hash(ref) and should contain these keys:

=over

=item * C<url> (str, required)

Location of function (accessed via Riap).

=item * C<summary> (str, optional)

Will be retrieved from function metadata at C<url> if unset

=item * C<description> (str, optional)

Shown in verbose help message, if description from function metadata is unset.

=item * C<tags> (array of str, optional)

For grouping or categorizing subcommands, e.g. when displaying list of
subcommands.

=item * C<use_utf8> (bool, optional)

Whether to issue L<< binmode(STDOUT, ":utf8") >>. See L</"LOGGING"> for more
details.

=item * C<undo> (bool, optional)

Can be set to 0 to disable transaction for this subcommand; this is only
relevant when C<undo> attribute is set to true.

=item * C<show_in_help> (bool, optional, default 1)

If you have lots of subcommands, and want to show only some of them in --help
message, set this to 0 for subcommands that you do not want to show.

=item * C<pass_cmdline_object> (bool, optional, default 0)

To override C<pass_cmdline_object> attribute on a per-subcommand basis.

=item * C<args> (hash, optional)

If specified, will send the arguments (as well as arguments specified via the
command-line). This can be useful for a function that serves more than one
subcommand, e.g.:

 subcommands => {
     sub1 => {
         summary => 'Subcommand one',
         url     => '/some/func',
         args    => {flag=>'one'},
     },
     sub2 => {
         summary => 'Subcommand two',
         url     => '/some/func',
         args    => {flag=>'two'},
     },
 }

In the example above, both subcommand C<sub1> and C<sub2> point to function at
C</some/func>. But the function can differentiate between the two via the
C<flag> argument being sent.

 % cmdprog sub1 --foo 1 --bar 2
 % cmdprog sub2 --foo 2

In the first invocation, function will receive arguments C<< {foo=>1, bar=>2,
flag=>'one'} >> and for the second: C<< {foo=>2, flag=>'two'} >>.

=back

Subcommands can also be a coderef, for dynamic list of subcommands. The coderef
will be called as a method with hash arguments. It can be called in two cases.
First, if called without argument C<name> (usually when doing --subcommands) it
must return a hashref of subcommand specifications. If called with argument
C<name> it must return subcommand specification for subcommand with the
requested name only.

=head2 summary => str

=head2 tags => array of str

=head2 url => str

Required if you only want to run one function. URL should point to a function
entity.

Alternatively you can provide multiple functions from which the user can select
using the first argument (see B<subcommands>).

=head2 read_env => bool (default: 1)

Whether to read environment variable for default options.

=head2 env_name => str

Environment name to read default options from. Default is from program name,
upper-cased, sequences of dashes/nonalphanums replaced with a single underscore,
plus a C<_OPT> suffix. So if your program name is called C<cpandb-cpanmeta> the
default environment name is C<CPANDB_CPANMETA_OPT>.

=head2 read_config => bool (default: 1)

Whether to read configuration files.

=head2 config_filename => str|array[str]|array[hash]

Configuration filename(s). The default is C<< program_name . ".conf" >>. For
example, if your program is named C<foo-bar>, config_filename will be
C<foo-bar.conf>.

You can specify an array of filename strings, which will be checked in order,
e.g.: C<< ["myapp.conf", "myapp.ini"] >>.

You can also specify an array of hashrefs, for more complex scenario. Each hash
can contain these keys: C<filename>, C<section>. For example:

 [
     {filename => 'mysuite.conf', section=>'myapp1'},
     {filename => 'myapp1.conf'}, # section = GLOBAL (default)
 ]

This means, configuration will be searched in C<mysuite.conf> under the section
C<myapp1>, and then in C<myapp1.conf> in the default/global section.

=head2 config_dirs => array of str

Which directories to look for configuration file. The default is to look at the
user's home and then system location. On Unix, it's C<< [ "$ENV{HOME}/.config",
$ENV{HOME}, "/etc"] >>. If $ENV{HOME} is empty, getpwuid() is used to get home
directory entry.

=head2 cleanser => obj

Object to cleanse result for JSON output. By default this is an instance of
L<Data::Clean::JSON> and should not be set to other value in most cases.

=head2 use_cleanser => bool (default: 1)

When a function returns result, and the user wants to display the result as
JSON, the result might need to be cleansed first (using L<Data::Clean::JSON> by
default) before it can be encoded to JSON, for example it might contain Perl
objects or scalar references or other stuffs. If you are sure that your function
does not produce those kinds of data, you can set this to false to produce a
more lightweight script.

=head2 extra_urls_for_version => array of str

=head2 skip_format => bool

If set to 1, assume that function returns raw text that need not be translated,
and so will not offer common command-line options C<--format>, C<--json>, as
well as C<--naked-res>.

As an alternative to this, can also be done on a per-function level by setting
function metadata property C<cmdline.skip_format> to true. Or, can also be done
on a per-function result basis by returning result metadata
C<cmdline.skip_format> set to true.

=head2 use_utf8 => bool (default: from env UTF8, or 0)

Whether or not to set utf8 flag on output. If undef, will default to UTF8
environment. If that is also undef, will default to 0.

=head2 default_dry_run => bool (default: 0)

If set to 1, then dry-mode will be turned on by default unless user uses
DRY_RUN=0 or C<--no-dry-run>.

=head2 log => bool

Whether to enable logging. Default is off. If true, will load L<Log::ger::App>.

=head2 log_level => str

Set default log level. Will be overriden by C<< $r->{log_level} >> which is set
from command-line options like C<--log-level>, C<--trace>, etc.

=head1 METHODS

=head2 $cmd->run() => ENVRES

The main method to run your application. See L</"PROGRAM FLOW"> for more details
on what this method does.

=head2 $cmd->do_dump() => ENVRES

Called by run().

=head2 $cmd->do_completion() => ENVRES

Called by run().

=head2 $cmd->parse_argv() => ENVRES

Called by run().

=head2 $cmd->get_meta($r, $url) => ENVRES

Called by parse_argv() or do_dump() or do_completion(). Subclass has to
implement this.

=head1 ENVIRONMENT

=head2 BROWSER

String. When L</"VIEWER"> is not set, then this environment variable will be
used to select external viewer program.

=head2 LOG_DUMP_CONFIG

Boolean. If set to true, will dump parsed configuration at the trace level.

=head2 PAGE_RESULT

Boolean. Can be set to 1 to force paging of result. Can be set to 0 to
explicitly disable paging even though C<cmd.page_result> result metadata
attribute is active.

See also: L</"PAGER">.

=head2 PAGER

String. Like in other programs, can be set to select the pager program (when
C<cmdline.page_result> result metadata is active). Can also be set to C<''> or
C<0> to explicitly disable paging even though C<cmd.page_result> result metadata
is active.

=head2 PERINCI_CMDLINE_DUMP_ARGS

Boolean. If set to true, instead of running normal action, will instead dump
arguments that will be passed to function, (after merge with values from
environment/config files, and validation/coercion), in Perl format (using
L<Data::Dump>) and exit.

Useful for debugging or information extraction.

=head2 PERINCI_CMDLINE_DUMP_CONFIG

Boolean. If set to true, instead of running normal action, will dump
configuration that is using C<read_config()>, in Perl format (using
L<Data::Dump>) and exit.

Useful for debugging or information extraction.

=head2 PERINCI_CMDLINE_DUMP_OBJECT

String. Default undef. If set to a true value, instead of running normal action,
will dump Perinci::CmdLine object at the start of run() in Perl format (using
L<Data::Dump>) and exit. Useful to get object's attributes and reconstruct the
object later. Used in, e.g. L<App::shcompgen> to generate an appropriate
completion script for the CLI, or L<Pod::Weaver::Plugin::Rinci> to generate POD
documentation about the script. See also L<Perinci::CmdLine::Dump>.

The value of the this variable will be used as the label in the dump delimiter,
.e.g:

 # BEGIN DUMP foo
 ...
 # END DUMP foo

Useful for debugging or information extraction.

=head2 PERINCI_CMDLINE_OUTPUT_DIR

String. If set, then aside from displaying output as usual, the unformatted
result (enveloped result) will also be saved as JSON to an output directory. The
filename will be I<UTC timestamp in ISO8601 format>C<.out>, e.g.:

 2017-12-11T123456.000000000Z.out
 2017-12-11T123456.000000000Z.out.1 (if the same filename already exists)

or each output (C<.out>) file there will also be a corresponding C<.meta> file
that contains information like: command-line arguments, PID, etc. Some notes:

Output directory must already exist, or Perinci::CmdLine will display a warning
and then skip saving output.

Data that is not representable as JSON will be cleansed using
L<Data::Clean::JSON>.

Streaming output will not be saved appropriately, because streaming output
contains coderef that will be called repeatedly during the normal displaying of
result.

=head2 PERINCI_CMDLINE_PROGRAM_NAME

String. Can be used to set CLI program name.

=head2 UTF8

Boolean. To set default for C<use_utf8> attribute.

=head2 VIEW_RESULT

Boolean. Can be set to 1 to force using viewer to view result. Can be set to 0
to explicitly disable using viewer to view result even though
C<cmdline.view_result> result metadata attribute is active.

=head2 VIEWER

String. Can be set to select the viewer program to override C<cmdline.viewer>.
Can also be set to C<''> or C<0> to explicitly disable using viewer to view
result even though C<cmdline.view_result> result metadata attribute is active.

See also L</"BROWSER">.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
