package Perinci::CmdLine::Lite;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.822'; # VERSION

use 5.010001;
# use strict; # already enabled by Mo
# use warnings; # already enabled by Mo
use Log::ger;

use List::Util qw(first);
use Mo qw(build default);
#use Moo;
extends 'Perinci::CmdLine::Base';

# when debugging, use this instead of the above because Mo doesn't give clear
# error message if base class has errors.
#use parent 'Perinci::CmdLine::Base';

has default_prompt_template => (
    is=>'rw',
    default => 'Enter %s: ',
);
has validate_args => (
    is=>'rw',
    default => 1,
);

my $formats = [qw/text text-simple text-pretty json json-pretty csv html html+datatables perl/];

sub BUILD {
    my ($self, $args) = @_;

    if (!$self->{riap_client}) {
        require Perinci::Access::Lite;
        my %rcargs = (
            riap_version => $self->{riap_version} // 1.1,
            %{ $self->{riap_client_args} // {} },
        );
        $self->{riap_client} = Perinci::Access::Lite->new(%rcargs);
    }

    if (!$self->{actions}) {
        $self->{actions} = {
            call => {},
            version => {},
            subcommands => {},
            help => {},
        };
    }

    my $_t = sub {
        no warnings;
        my $co_name = shift;
        my $href = $Perinci::CmdLine::Base::copts{$co_name};
        %$href;
    };

    if (!$self->{common_opts}) {
        my $copts = {};

        $copts->{version}   = { $_t->('version'), };
        $copts->{help}      = { $_t->('help'), };

        unless ($self->skip_format) {
            $copts->{format}    = {
                $_t->('format'),
                schema => ['str*' => in => $formats],
            };
            $copts->{json}      = { $_t->('json'), };
            $copts->{naked_res} = { $_t->('naked_res'), };
        }
        if ($self->subcommands) {
            $copts->{subcommands} = { $_t->('subcommands'), };
        }
        if ($self->default_subcommand) {
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
        $self->{common_opts} = $copts;
    }

    $self->{formats} //= $formats;

    $self->{per_arg_json} //= 1;
}

my $setup_progress;
sub _setup_progress_output {
    my $self = shift;

    return unless $ENV{PROGRESS} // (-t STDOUT);

    require Progress::Any::Output;
    Progress::Any::Output->set("TermProgressBarColor");
    $setup_progress = 1;
}

sub _unsetup_progress_output {
    my $self = shift;

    return unless $setup_progress;
    no warnings 'once';
    my $out = $Progress::Any::outputs{''}[0];
    $out->cleanup if $out->can("cleanup");
    $setup_progress = 0;
}

sub hook_after_parse_argv {
    my ($self, $r) = @_;

    # since unlike Perinci::CmdLine, we don't wrap the function (where the
    # wrapper assigns default values for arguments), we must do it here
    # ourselves.
    my $ass  = $r->{meta}{args} // {};
    my $args = $r->{args};
    for (keys %$ass) {
        next if exists $args->{$_};
        my $as = $ass->{$_};
        if (exists $as->{default}) {
            $args->{$_} = $as->{default};
        } elsif ($as->{schema} && exists $as->{schema}[1]{default}) {
            $args->{$_} = $as->{schema}[1]{default};
        }
    }
}

# BEGIN_BLOCK: equal2
sub equal2 {
    state $require = do { require Scalar::Util };

    # for lack of a better name, currently i name this 'equal2'
    my ($val1, $val2) = @_;

    # here are the rules:
    # - if both are undef, 1
    # - undef equals nothing else
    # - if both are ref, equal if their refaddr() are equal
    # - if only one is ref, 0
    # - if none is ref, compare using eq

    if (defined $val1) {
        return 0 unless defined $val2;
        if (ref $val1) {
            return 0 unless ref $val2;
            return Scalar::Util::refaddr($val1) eq Scalar::Util::refaddr($val2);
        } else {
            return 0 if ref $val2;
            return $val1 eq $val2;
        }
    } else {
        return 0 if defined $val2;
        return 1;
    }
}
# END_BLOCK: equal2

sub hook_before_parse_argv {
    my ($self, $r) = @_;

    # in this hook, we want to add several shortcut options (e.g. -C for
    # --no-config, etc) if the function is not using those shortcut options. but
    # to do this, we need to get meta first and this is only possible when there
    # is no subcommand
    return if $r->{subcommands};
    $self->get_meta($r, $self->{url});

    my $copts = $self->common_opts;

    # XXX cache
    require Perinci::Sub::GetArgs::Argv;
    my $ggls_res = Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
        meta               => $r->{meta},
        meta_is_normalized => 1,
        args               => $r->{args},
        common_opts        => $copts,
        per_arg_json       => $self->{per_arg_json},
        per_arg_yaml       => $self->{per_arg_yaml},
    );

    my $meta_uses_opt_P = 0;
    my $meta_uses_opt_c = 0;
    my $meta_uses_opt_C = 0;
    {
        last unless $ggls_res->[0] == 200;
        my $opts = $ggls_res->[3]{'func.opts'};
        if (grep { $_ eq '-P' } @$opts) { $meta_uses_opt_P = 1 }
        if (grep { $_ eq '-c' } @$opts) { $meta_uses_opt_c = 1 }
        if (grep { $_ eq '-C' } @$opts) { $meta_uses_opt_C = 1 }
    }

    #say "D:meta_uses_opt_P=<$meta_uses_opt_P>";
    #say "D:meta_uses_opt_c=<$meta_uses_opt_c>";
    #say "D:meta_uses_opt_C=<$meta_uses_opt_C>";

    # add -P shortcut for --config-profile if no conflict
    if ($copts->{config_profile} && !$meta_uses_opt_P) {
        $copts->{config_profile}{getopt} = 'config-profile|P=s';
    }

    # add -c shortcut for --config-path if no conflict
    if ($copts->{config_path} && !$meta_uses_opt_c) {
        $copts->{config_path}{getopt} = 'config-path|c=s';
    }

    # add -P shortcut for --no-config if no conflict
    if ($copts->{no_config} && !$meta_uses_opt_C) {
        $copts->{no_config}{getopt} = 'no-config|C';
    }
}

sub hook_before_action {
    my ($self, $r) = @_;

    # validate arguments using schema from metadata
  VALIDATE_ARGS:
    {
        last unless $self->validate_args;

        # unless we're feeding the arguments to function, don't bother
        # validating arguments
        last unless $r->{action} eq 'call';

        my $meta = $r->{meta};

        # function is probably already wrapped
        last if $meta->{'x.perinci.sub.wrapper.logs'} &&
            (grep { $_->{validate_args} }
             @{ $meta->{'x.perinci.sub.wrapper.logs'} });

        require Data::Sah;

        # to be cheap, we simply use "$ref" as key as cache key. to be proper,
        # it should be hash of serialized content.
        my %validators; # key = "$schema"

        for my $arg (sort keys %{ $meta->{args} // {} }) {
            next unless exists($r->{args}{$arg});

            # we don't support validation of input stream because this must be
            # done after each 'get item' (but periswrap does)
            next if $meta->{args}{$arg}{stream};

            my $schema = $meta->{args}{$arg}{schema};
            next unless $schema;
            unless ($validators{"$schema"}) {
                my $v = Data::Sah::gen_validator($schema, {
                    return_type => 'str+val',
                    schema_is_normalized => 1,
                });
                $validators{"$schema"} = $v;
            }
            my $res = $validators{"$schema"}->($r->{args}{$arg});
            if ($res->[0]) {
                die [400, "Argument '$arg' fails validation: $res->[0]"];
            }
            my $val0 = $r->{args}{$arg};
            my $coerced_val = $res->[1];
            $r->{args}{$arg} = $coerced_val;
            $r->{args}{"-orig_$arg"} = $val0 unless equal2($val0, $coerced_val);
        }

        if ($meta->{args_rels}) {
            my $schema = [hash => $meta->{args_rels}];
            my $sah = Data::Sah->new;
            my $hc  = $sah->get_compiler("human");
            my $cd  = $hc->init_cd;
            $cd->{args}{lang} //= $cd->{default_lang};
            my $v = Data::Sah::gen_validator($schema, {
                return_type => 'str',
                human_hash_values => {
                    field  => $hc->_xlt($cd, "argument"),
                    fields => $hc->_xlt($cd, "arguments"),
                },
            });
            my $res = $v->($r->{args});
            if ($res) {
                die [400, $res];
            }
        }

    }
}

sub hook_format_result {
    require Perinci::Result::Format::Lite;
    my ($self, $r) = @_;

    my $fmt = $r->{format} // 'text';

    if ($fmt eq 'html+datatables') {
        $fmt = 'text-pretty';
        $ENV{VIEW_RESULT} //= 1;
        $ENV{FORMAT_PRETTY_TABLE_BACKEND} //= 'Text::Table::HTML::DataTables';
    }

    my $fres = Perinci::Result::Format::Lite::format(
        $r->{res}, $fmt, $r->{naked_res}, $self->{use_cleanser});

    # ux: prefix error message with program name
    if ($fmt =~ /text/ && $r->{res}[0] =~ /\A[45]/ && defined($r->{res}[1])) {
        $fres = $self->program_name . ": $fres";
    }

    $fres;
}

sub hook_format_row {
    my ($self, $r, $row) = @_;

    if (ref($row) eq 'ARRAY') {
        return join("\t", @$row) . "\n";
    } else {
        return ($row // "") . "\n";
    }
}

sub hook_display_result {
    my ($self, $r) = @_;

    my $res  = $r->{res};
    my $resmeta = $res->[3] // {};

    my $handle = $r->{output_handle};

    # set utf8 flag
    my $utf8;
    {
        last if defined($utf8 = $ENV{UTF8});
        if ($resmeta->{'x.hint.result_binary'}) {
            # XXX only when format is text?
            $utf8 = 0; last;
        }
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

sub hook_after_get_meta {
    my ($self, $r) = @_;

    my $copts = $self->common_opts;

    # note: we cannot cache this to $r->{_ggls_res} because we produce this
    # without dry-run
    require Perinci::Sub::GetArgs::Argv;
    my $ggls_res = Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
        meta               => $r->{meta},
        meta_is_normalized => 1,
        args               => $r->{args},
        common_opts        => $copts,
        per_arg_json       => $self->{per_arg_json},
        per_arg_yaml       => $self->{per_arg_yaml},
    );

    my $meta_uses_opt_n = 0;
    {
        last unless $ggls_res->[0] == 200;
        my $opts = $ggls_res->[3]{'func.opts'};
        if (grep { $_ eq '-n' } @$opts) { $meta_uses_opt_n = 1 }
    }

    require Perinci::Object;
    my $metao = Perinci::Object::risub($r->{meta});

    # delete --format, --json, --naked-res if function does not want its output
    # to be formatted
    {
        last if $self->skip_format; # already doesn't have those copts
        last unless $r->{meta}{'cmdline.skip_format'};
        delete $copts->{format};
        delete $copts->{json};
        delete $copts->{naked_res};
    }

    # add --dry-run (and -n shortcut, if no conflict)
    {
        last unless $metao->can_dry_run;
        my $default_dry_run = $metao->default_dry_run // $self->default_dry_run;
        $r->{dry_run} = 1 if $default_dry_run;
        $r->{dry_run} = ($ENV{DRY_RUN} ? 1:0) if defined $ENV{DRY_RUN};

        my $optname = 'dry-run' . ($meta_uses_opt_n ? '' : '|n');
        $copts->{dry_run} = {
            getopt  => $default_dry_run ? "$optname!" : $optname,
            summary => $default_dry_run ?
                "Disable simulation mode (also via DRY_RUN=0)" :
                "Run in simulation mode (also via DRY_RUN=1)",
            handler => sub {
                my ($go, $val, $r) = @_;
                if ($val) {
                    log_debug("[pericmd] Dry-run mode is activated");
                    $r->{dry_run} = 1;
                } else {
                    log_debug("[pericmd] Dry-run mode is deactivated");
                    $r->{dry_run} = 0;
                }
            },
        };
    }

    # check deps property. XXX this should be done only when we don't wrap
    # subroutine, because Perinci::Sub::Wrapper already checks the deps
    # property.
    if ($r->{meta}{deps} && !$r->{in_dump_object} && !$r->{in_completion}) {
        require Perinci::Sub::DepChecker;
        my $res = Perinci::Sub::DepChecker::check_deps($r->{meta}{deps});
        if ($res) {
            die [412, "Dependency failed: $res"];
        }
    }
}

sub action_subcommands {
    my ($self, $r) = @_;

    if (!$self->subcommands) {
        say "There are no subcommands.";
        return 0;
    }

    say "Available subcommands:";
    my $scs = $self->list_subcommands;
    my $longest = 6;
    for (keys %$scs) { my $l = length; $longest = $l if $l > $longest }
    [200, "OK",
     join("",
          (map { sprintf("  %-${longest}s  %s\n",$_,$scs->{$_}{summary}//"") }
               sort keys %$scs),
      )];
}

sub action_version {
    no strict 'refs';

    my ($self, $r) = @_;

    my @text;

    {
        my $meta = $r->{meta} = $self->get_meta($r, $self->url);
        push @text, $self->get_program_and_subcommand_name($r),
            " version ", ($meta->{entity_v} // "?"),
            ($meta->{entity_date} ? " ($meta->{entity_date})" : ''),
            "\n";
        for my $mod (@{ $meta->{'x.dynamic_generator_modules'} // [] }) {
            push @text, "  $mod version ", ${"$mod\::VERSION"},
                (${"$mod\::DATE"} ? " (".${"$mod\::DATE"}.")" : ""),
                    "\n";
        }
    }

    for my $url (@{ $self->extra_urls_for_version // [] }) {
        my $meta = $self->get_meta($r, $url);
        push @text, "  $url version ", ($meta->{entity_v} // "?"),
            ($meta->{entity_date} ? " ($meta->{entity_date})" : ''),
            "\n";
    }

    push @text, "  ", __PACKAGE__,
        " version ", ($Perinci::CmdLine::Lite::VERSION // "?"),
        ($Perinci::CmdLine::Lite::DATE ?
         " ($Perinci::CmdLine::Lite::DATE)":''),
        "\n";

    [200, "OK", join("", @text)];
}

sub action_help {
    require Perinci::CmdLine::Help;

    my ($self, $r) = @_;

    my @help;
    my $scn    = $r->{subcommand_name};
    my $scd    = $r->{subcommand_data};

    my $meta = $self->get_meta($r, $scd->{url} // $self->{url});

    # XXX use 'delete local' when we bump minimal perl to 5.12
    my $common_opts = { %{$self->common_opts} };

    # hide usage '--subcommands' if we have subcommands but user has specified a
    # subcommand to use
    my $has_sc_no_sc = $self->subcommands &&
        !length($r->{subcommand_name} // '');
    delete $common_opts->{subcommands} if $self->subcommands && !$has_sc_no_sc;

    my $res = Perinci::CmdLine::Help::gen_help(
        program_name => $self->get_program_and_subcommand_name($r),
        program_summary => ($scd ? $scd->{summary}:undef ) // $meta->{summary},
        program_description => $scd ? $scd->{description} : undef,
        meta => $meta,
        subcommands => $has_sc_no_sc ? $self->list_subcommands : undef,
        common_opts => $common_opts,
        per_arg_json => $self->per_arg_json,
        per_arg_yaml => $self->per_arg_yaml,
    );

    $res->[3]{"cmdline.skip_format"} = 1;
    $res;
}

sub action_call {
    my ($self, $r) = @_;

    my %extra;
    if ($r->{send_argv}) {
        log_trace("[pericmd] Sending argv to server: %s", $extra{argv});
        $extra{argv} = $r->{orig_argv};
    } else {
        my %extra_args;
        $extra_args{-dry_run} = 1 if $r->{dry_run};
        $extra{args} = {%extra_args, %{$r->{args}}};
    }

    $extra{stream_arg} = 1 if $r->{stream_arg};

    my $url = $r->{subcommand_data}{url};

    # currently we don't log args because it's potentially large
    log_trace("[pericmd] Riap request: action=call, url=%s", $url);

    #log_trace("TMP: extra=%s", \%extra);

    # setup output progress indicator
    if ($r->{meta}{features}{progress}) {
        $self->_setup_progress_output;
    }

    $self->riap_client->request(
        call => $url, \%extra);
}

1;
# ABSTRACT: A Rinci/Riap-based command-line application framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Lite - A Rinci/Riap-based command-line application framework

=head1 VERSION

This document describes version 1.822 of Perinci::CmdLine::Lite (from Perl distribution Perinci-CmdLine-Lite), released on 2019-06-26.

=head1 SYNOPSIS

In C<gen-random-num> script:

 use Perinci::CmdLine::Lite;

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

 Perinci::CmdLine::Lite->new(url => '/main/gen_random_num')->run;

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

Perinci::CmdLine::Lite is the default backend implementation. Another
implementation is the heavier L<Perinci::CmdLine::Classic> which has a couple of
more features not yet incorporated into ::Lite, e.g. transactions.

You normally should use L<Perinci::CmdLine::Any> instead to be able to switch
backend on the fly.

=for Pod::Coverage ^(BUILD|get_meta|hook_.+|action_.+)$

=head1 REQUEST KEYS

All those supported by L<Perinci::CmdLine::Base>, plus:

=over

=back

=head1 RESULT METADATA

All those supported by L<Perinci::CmdLine::Base>, plus:

=head2 x.hint.result_binary => bool

If set to true, then when formatting to C<text> formats, this class won't print
any newline to keep the data being printed unmodified.

=head1 ATTRIBUTES

All the attributes of L<Perinci::CmdLine::Base>, plus:

=head2 validate_args => bool (default: 1)

=head1 METHODS

All the methods of L<Perinci::CmdLine::Base>, plus:

=head1 ENVIRONMENT

All the environment variables that L<Perinci::CmdLine::Base> supports, plus:

=head2 DEBUG

Set log level to 'debug'.

=head2 VERBOSE

Set log level to 'info'.

=head2 QUIET

Set log level to 'error'.

=head2 TRACE

Set log level to 'trace'.

=head2 LOG_LEVEL

Set log level.

=head2 PROGRESS => bool

Explicitly turn the progress bar on/off.

=head2 FORMAT_PRETTY_TABLE_COLUMN_ORDERS => array (json)

Set the default of C<table_column_orders> in C<format_options> in result
metadata, similar to what's implemented in L<Perinci::Result::Format> and
L<Data::Format::Pretty::Console>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine::Any>

L<Perinci::CmdLine::Classic>

L<Perinci::CmdLine::Inline>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
