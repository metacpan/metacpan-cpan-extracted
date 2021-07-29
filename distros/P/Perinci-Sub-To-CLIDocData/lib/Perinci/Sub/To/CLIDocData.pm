package Perinci::Sub::To::CLIDocData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-11'; # DATE
our $DIST = 'Perinci-Sub-To-CLIDocData'; # DIST
our $VERSION = '0.298'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Object;
use Perinci::Sub::Util qw(err);

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_cli_doc_data_from_meta);

sub _has_cats {
    for my $spec (@{ $_[0] }) {
        for (@{ $spec->{tags} // [] }) {
            my $tag_name = ref($_) ? $_->{name} : $_;
            if ($tag_name =~ /^category:/) {
                return 1;
            }
        }
    }
    0;
}

sub _add_category_from_spec {
    my ($cats_spec, $thing, $spec, $noun, $has_cats) = @_;
    my @cats;
    for (@{ $spec->{tags} // [] }) {
        my $tag_name = ref($_) ? $_->{name} : $_;
        if ($tag_name =~ /^category(\d+)?:(.+)/) {
            my $cat = ucfirst($2);
            my $ordering = $1 // 50;
            $cat =~ s/-/ /g;
            $cat .= " " . $noun;
            push @cats, [$cat, $ordering]; # name, ordering
        }
    }
    if (!@cats) {
        @cats = [$has_cats ? "Other $noun" : ucfirst($noun), 99]; # XXX translatable?
    }

    # old, will be removed someday
    $thing->{category} = $cats[0][0];
    # new/current
    $thing->{categories} = [map {$_->[0]} @cats];

    $cats_spec->{$_->[0]}{order} //= $_->[1] for @cats;
}

sub _add_default_from_arg_spec {
    my ($opt, $arg_spec) = @_;
    if (exists $arg_spec->{default}) {
        $opt->{default} = $arg_spec->{default};
    } elsif ($arg_spec->{schema} && exists($arg_spec->{schema}[1]{default})) {
        $opt->{default} = $arg_spec->{schema}[1]{default};
    }
}

sub _dash_prefix {
    length($_[0]) > 1 ? "--$_[0]" : "-$_[0]";
}

sub _fmt_opt {
    my $spec = shift;
    my @ospecs = @_;
    my @res;
    my $i = 0;
    for my $ospec (@ospecs) {
        my $j = 0;
        my $parsed = $ospec->{parsed};
        for (@{ $parsed->{opts} }) {
            my $opt = _dash_prefix($_);
            if ($i==0 && $j==0) {
                if ($parsed->{type}) {
                    if ($spec->{'x.schema.entity'}) {
                        $opt .= "=".$spec->{'x.schema.entity'};
                    } elsif ($spec->{'x.schema.element_entity'}) {
                        $opt .= "=".$spec->{'x.schema.element_entity'};
                    } else {
                        $opt .= "=$parsed->{type}";
                    }
                }
                # mark required option with a '*'
                $opt .= "*" if $spec->{req} && !$ospec->{is_base64} &&
                    !$ospec->{is_json} && !$ospec->{is_yaml};
            }
            push @res, $opt;
            $j++;
        }
        $i++;
    }
    join ", ", @res;
}

$SPEC{gen_cli_doc_data_from_meta} = {
    v => 1.1,
    summary => 'From Rinci function metadata, generate structure convenient '.
        'for producing CLI documentation (help/usage/POD)',
    description => <<'_',

This function calls <pm:Perinci::Sub::GetArgs::Argv>'s
`gen_getopt_long_spec_from_meta()` (or receive its result as an argument, if
passed, to avoid calling the function twice) and post-processes it: produce
command usage line, format the options, include information from metadata, group
the options by category. It also selects examples in the `examples` property
which are applicable to CLI environment and format them.

The resulting data structure is convenient to use when one wants to produce a
documentation for CLI program (including help/usage message and POD).

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
        ggls_res => {
            summary => 'Full result from gen_getopt_long_spec_from_meta()',
            schema  => 'array*', # XXX envres
            description => <<'_',

If you already call <pm:Perinci::Sub::GetArgs::Argv>'s
`gen_getopt_long_spec_from_meta()`, you can pass the _full_ enveloped result
here, to avoid calculating twice. What will be useful for the function is the
extra result in result metadata (`func.*` keys in `$res->[3]` hash).

_
        },
        per_arg_json => {
            schema => 'bool',
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
        },
        per_arg_yaml => {
            schema => 'bool',
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
        },
        lang => {
            schema => 'str*',
        },
    },
    result => {
        schema => 'hash*',
    },
};
sub gen_cli_doc_data_from_meta {
    require Getopt::Long::Negate::EN;

    my %args = @_;

    my $lang = $args{lang};
    my $meta = $args{meta} or return [400, 'Please specify meta'];
    my $common_opts = $args{common_opts};
    unless ($args{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }
    my $ggls_res = $args{ggls_res} // do {
        require Perinci::Sub::GetArgs::Argv;
        Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
            meta=>$meta, meta_is_normalized=>1, common_opts=>$common_opts,
            per_arg_json => $args{per_arg_json},
            per_arg_yaml => $args{per_arg_yaml},
        );
    };
    $ggls_res->[0] == 200 or return $ggls_res;

    my $args_prop = $meta->{args} // {};
    my $clidocdata = {
        option_categories => {},
        example_categories => {},
    };

    my %opts;
  GEN_LIST_OF_OPTIONS: {
        my $ospecs = $ggls_res->[3]{'func.specmeta'};
        # separate groupable aliases because they will be merged with the
        # argument options
        my (@k, @k_aliases);
      OSPEC1:
        for (sort keys %$ospecs) {
            my $ospec = $ospecs->{$_};
            {
                last unless $ospec->{is_alias};
                next if $ospec->{is_code};
                my $arg_spec = $args_prop->{$ospec->{arg}};
                my $alias_spec = $arg_spec->{cmdline_aliases}{$ospec->{alias}};
                next if $alias_spec->{summary};
                push @k_aliases, $_;
                next OSPEC1;
            }
            push @k, $_;
        }

        my %negs; # key=arg, only show one negation form for each arg option

      OSPEC2:
        while (@k) {
            my $k = shift @k;
            my $ospec = $ospecs->{$k};
            my $opt;
            my $optkey;

            if ($ospec->{is_alias} || defined($ospec->{arg})) {
                my $arg_spec;
                my $alias_spec;

                if ($ospec->{is_alias}) {
                    # non-groupable alias

                    my $real_opt_ospec = $ospecs->{ $ospec->{alias_for} };

                    $arg_spec = $args_prop->{ $ospec->{arg} };
                    $alias_spec = $arg_spec->{cmdline_aliases}{$ospec->{alias}};
                    my $rimeta = rimeta($alias_spec);
                    $optkey = _fmt_opt($arg_spec, $ospec);
                    $opt = {
                        opt_parsed => $ospec->{parsed},
                        orig_opt => $k,
                        is_alias => 1,
                        alias_for => $ospec->{alias_for},
                        summary => $rimeta->langprop({lang=>$lang}, 'summary') //
                            "Alias for "._dash_prefix($real_opt_ospec->{parsed}{opts}[0]),
                        description =>
                            $rimeta->langprop({lang=>$lang}, 'description'),
                    };
                } else {
                    # an option for argument

                    $arg_spec = $args_prop->{$ospec->{arg}};
                    my $rimeta = rimeta($arg_spec);
                    $opt = {
                        opt_parsed => $ospec->{parsed},
                        orig_opt => $k,
                    };

                    # for bool, only display either the positive (e.g. --bool)
                    # or the negative (e.g. --nobool) depending on the default
                    if (defined($ospec->{is_neg})) {
                        my $default = $arg_spec->{default} //
                            $arg_spec->{schema}[1]{default};
                        next OSPEC2 if  $default && !$ospec->{is_neg};
                        next OSPEC2 if !$default &&  $ospec->{is_neg};
                        if ($ospec->{is_neg}) {
                            next OSPEC2 if $negs{$ospec->{arg}}++;
                        }
                    }

                    if ($ospec->{is_neg}) {
                        # for negative option, use negative summary instead of
                        # regular (positive sentence) summary
                        $opt->{summary} =
                            $rimeta->langprop({lang=>$lang}, 'summary.alt.bool.not');
                    } elsif (defined $ospec->{is_neg}) {
                        # for boolean option which we show the positive, show
                        # the positive summary if available
                        $opt->{summary} =
                            $rimeta->langprop({lang=>$lang}, 'summary.alt.bool.yes') //
                                $rimeta->langprop({lang=>$lang}, 'summary');
                    } elsif (($ospec->{parsed}{type}//'') eq 's@') {
                        # for array of string that can be specified via multiple
                        # --opt, show singular version of summary if available.
                        # otherwise show regular summary.
                        $opt->{summary} =
                            $rimeta->langprop({lang=>$lang}, 'summary.alt.plurality.singular') //
                                $rimeta->langprop({lang=>$lang}, 'summary');
                    } else {
                        $opt->{summary} =
                            $rimeta->langprop({lang=>$lang}, 'summary');
                    }
                    $opt->{description} =
                        $rimeta->langprop({lang=>$lang}, 'description');

                    # find aliases that can be grouped together with this option
                    my @aliases;
                    my $j = $#k_aliases;
                    while ($j >= 0) {
                        my $aospec = $ospecs->{ $k_aliases[$j] };
                        {
                            last unless $aospec->{arg} eq $ospec->{arg};
                            push @aliases, $aospec;
                            splice @k_aliases, $j, 1;
                        }
                        $j--;
                    }

                    $optkey = _fmt_opt($arg_spec, $ospec, @aliases);
                }

                $opt->{arg_spec} = $arg_spec;
                $opt->{alias_spec} = $alias_spec if $alias_spec;

                # include keys from func.specmeta
                for (qw/arg fqarg is_base64 is_json is_yaml/) {
                    $opt->{$_} = $ospec->{$_} if defined $ospec->{$_};
                }

                # include keys from arg_spec
                for (qw/req pos slurpy greedy is_password links tags/) {
                    $opt->{$_} = $arg_spec->{$_} if defined $arg_spec->{$_};
                }

                {
                    # we don't want argument options to end up in "Other" like
                    # --help or -v, they are put at the end. so if an argument
                    # option does not have category, we'll put it in the "main"
                    # category.
                    local $arg_spec->{tags} = ['category0:main']
                        if !$arg_spec->{tags} || !@{$arg_spec->{tags}};
                    _add_category_from_spec($clidocdata->{option_categories},
                                            $opt, $arg_spec, "options", 1);
                }
                _add_default_from_arg_spec($opt, $arg_spec);

            } else {
                # option from common_opts

                my $spec = $common_opts->{$ospec->{common_opt}};

                # for bool, only display either the positive (e.g. --bool)
                # or the negative (e.g. --nobool) depending on the default
                my $show_neg = $ospec->{parsed}{is_neg} && $spec->{default};

                local $ospec->{parsed}{opts} = do {
                    # XXX check if it's single-letter, get first
                    # non-single-letter
                    my @opts = Getopt::Long::Negate::EN::negations_for_option(
                        $ospec->{parsed}{opts}[0]);
                    [ $opts[0] ];
                } if $show_neg;

                $optkey = _fmt_opt($spec, $ospec);
                my $rimeta = rimeta($spec);
                $opt = {
                    opt_parsed => $ospec->{parsed},
                    orig_opt => $k,
                    common_opt => $ospec->{common_opt},
                    common_opt_spec => $spec,
                    summary => $show_neg ?
                        $rimeta->langprop({lang=>$lang}, 'summary.alt.bool.not') :
                            $rimeta->langprop({lang=>$lang}, 'summary'),
                    (schema => $spec->{schema}) x !!$spec->{schema},
                    ('x.schema.entity' => $spec->{'x.schema.entity'}) x !!$spec->{'x.schema.entity'},
                    ('x.schema.element_entity' => $spec->{'x.schema.element_entity'}) x !!$spec->{'x.schema.element_entity'},
                    description =>
                        $rimeta->langprop({lang=>$lang}, 'description'),
                    (default => $spec->{default}) x !!(exists($spec->{default}) && !$show_neg),
                };

                _add_category_from_spec($clidocdata->{option_categories},
                                        $opt, $spec, "options", 1);

            }

            $opts{$optkey} = $opt;
        }

        # link ungrouped alias to its main opt
      OPT1:
        for my $k (keys %opts) {
            my $opt = $opts{$k};
            next unless $opt->{is_alias} || $opt->{is_base64} ||
                $opt->{is_json} || $opt->{is_yaml};
            for my $k2 (keys %opts) {
                my $arg_opt = $opts{$k2};
                next if $arg_opt->{is_alias} || $arg_opt->{is_base64} ||
                    $arg_opt->{is_json} || $arg_opt->{is_yaml};
                next unless defined($arg_opt->{arg}) &&
                    $arg_opt->{arg} eq $opt->{arg};
                $opt->{main_opt} = $k2;
                next OPT1;
            }
        }

    } # GEN_LIST_OF_OPTIONS
    $clidocdata->{opts} = \%opts;

  GEN_USAGE_LINE: {
        my @plain_args;
        my @pod_args;

        my %args_prop = %$args_prop; # copy because we want to iterate & delete
        my $max_pos = -1;
        for (values %args_prop) {
            $max_pos = $_->{pos}
                if defined($_->{pos}) && $_->{pos} > $max_pos;
        }
        my $pos = 0;
        while ($pos <= $max_pos) {
            my ($arg, $arg_spec);
            for (keys %args_prop) {
                $arg_spec = $args_prop{$_};
                if (defined($arg_spec->{pos}) && $arg_spec->{pos}==$pos) {
                    $arg = $_;
                    last;
                }
            }
            $pos++;
            next unless defined($arg);
            if ($arg_spec->{slurpy} // $arg_spec->{greedy}) {
                # try to find the singular form
                $arg = $arg_spec->{'x.name.singular'}
                    if $arg_spec->{'x.name.is_plural'} &&
                    defined $arg_spec->{'x.name.singular'};
            }
            if ($arg_spec->{req}) {
                push @plain_args, "<$arg>";
                push @pod_args  , "E<lt>I<$arg>E<gt>";
            } else {
                push @plain_args, "[$arg]";
                push @pod_args  , "[I<$arg>]";
            }
            $plain_args[-1] .= " ..." if ($arg_spec->{slurpy} // $arg_spec->{greedy});
            $pod_args  [-1] .= " ..." if ($arg_spec->{slurpy} // $arg_spec->{greedy});
            delete $args_prop{$arg};
        }

        # XXX utilize information from args_rels

        require Getopt::Long::Util;
        my @plain_opts;
        my @pod_opts;
        my %opt_locations; # key=$ARGNAME or "common:$SOMEKEY"
        for my $ospec (sort {
            ($ggls_res->[3]{'func.specmeta'}{$a}{is_neg} ? 1:0) <=> ($ggls_res->[3]{'func.specmeta'}{$b}{is_neg} ? 1:0) ||
            ($ggls_res->[3]{'func.specmeta'}{$a}{is_alias} ? 1:0) <=> ($ggls_res->[3]{'func.specmeta'}{$b}{is_alias} ? 1:0) ||
            ($ggls_res->[3]{'func.specmeta'}{$a}{is_json} ? 1:0) <=> ($ggls_res->[3]{'func.specmeta'}{$b}{is_json} ? 1:0) ||
            ($ggls_res->[3]{'func.specmeta'}{$a}{is_yaml} ? 1:0) <=> ($ggls_res->[3]{'func.specmeta'}{$b}{is_yaml} ? 1:0) ||
                $a cmp $b
            } keys %{ $ggls_res->[3]{'func.specmeta'} }) {
            my $ospecmeta = $ggls_res->[3]{'func.specmeta'}{$ospec};

            my $argprop = defined $ospecmeta->{arg} ? $args_prop{ $ospecmeta->{arg} } : undef;
            # only include args that have not been mentioned in positional
            next if defined $ospecmeta->{arg} && !$argprop;
            # only inlude common options that are not a specific action that are
            # invoked on its own

            my $copt = defined $ospecmeta->{common_opt} ? $common_opts->{ $ospecmeta->{common_opt} } : undef;

            next if defined $ospecmeta->{common_opt} && $copt->{usage};
            my $caption_from_schema;
            if ($argprop && $argprop->{schema} &&
                    ref $argprop->{schema} eq 'ARRAY' # ignore non-normalized schema for now
                ) {
                my $type = $argprop->{schema}[0];
                my $cset = $argprop->{schema}[1];
                if ($type eq 'array') {
                    if ($cset->{of} && ref $cset->{of} eq 'ARRAY') {
                        $caption_from_schema = $cset->{of}[0];
                    }
                } elsif ($type eq 'hash') {
                    if ($cset->{of} && ref $cset->{of} eq 'ARRAY') {
                        $caption_from_schema = $cset->{of}[0];
                    }
                } else {
                    $caption_from_schema = $type;
                }
            }
            my $hres = Getopt::Long::Util::humanize_getopt_long_opt_spec({
                extended=>1,
                separator=>"|",
                value_label=>(
                    $ospecmeta->{is_json} ? 'json' :
                    $ospecmeta->{is_yaml} ? 'yaml' :
                        $argprop ?
                        ($argprop->{'x.cli.opt_value_label'} // $argprop->{caption} // $caption_from_schema) :
                        $copt->{value_label}
                    ),
            }, $ospec);
            my $plain_opt = $hres->{plaintext};
            my $pod_opt   = $hres->{pod};

            my $key;
            if ($copt && defined $copt->{key}) {
                # group common options by key.
                $key = "00common:" . $copt->{key};
            } elsif ($ospecmeta->{is_alias} || $ospecmeta->{is_neg} || $ospecmeta->{is_json} || $ospecmeta->{is_yaml}) {
                # put option from arg and its cmdline aliases or its json/yaml
                # version and its negation version together as alternates.
                $key = $ospecmeta->{arg};
            } else {
                $key = $ospec;
            }
            $key =~ s/_/-/g;

            $opt_locations{$key} //= scalar @plain_opts;
            push @{ $plain_opts[ $opt_locations{$key} ] }, $plain_opt;
            push @{ $pod_opts  [ $opt_locations{$key} ] }, $pod_opt;
            #use Data::Dmp; print "key: $key, ospec: $ospec, ospecmeta: ", dmp($ospecmeta), ", argprop: ", dmp($argprop), ", copt: ", dmp($copt), "\n";
        }

        $clidocdata->{compact_usage_line} = "[[prog]]".
            (keys(%args_prop) || keys(%$common_opts) ? " [options]" : ""). # XXX translatable?
            (@plain_args ? " ".join(" ", @plain_args) : "");
        $clidocdata->{usage_line} = "[[prog]]".
            (@plain_opts+@plain_args ? " ".
             join(" ",
                  (map { "[". join("|", @$_) . "]" } @plain_opts),
                  (@plain_opts && @plain_args ? ("--") : ()),
                  @plain_args,
              ) : "");
        $clidocdata->{'usage_line.alt.fmt.pod'} = "B<[[prog]]>".
            (@pod_opts+@pod_args ? " ".
             join(" ",
                  (map { "[". join("|", @$_) . "]" } @pod_opts),
                  (@pod_opts && @pod_args ? ("--") : ()),
                  @pod_args,
              ) : "");
    } # GEN_USAGE_LINE

    # filter and format examples
    my @examples;
    {
        my $examples = $meta->{examples} // [];
        my $has_cats = _has_cats($examples);

        for my $eg (@$examples) {
            my $rimeta = rimeta($eg);
            my $argv;
            my $cmdline;
            if (defined($eg->{src})) {
                # we only show shell command examples
                if ($eg->{src_plang} =~ /^(sh|bash)$/) {
                    $cmdline = $eg->{src};
                } else {
                    next;
                }
            } else {
                require String::ShellQuote;
                if ($eg->{argv}) {
                    $argv = $eg->{argv};
                } else {
                    require Perinci::Sub::ConvertArgs::Argv;
                    my $res = Perinci::Sub::ConvertArgs::Argv::convert_args_to_argv(
                        args => $eg->{args}, meta => $meta, use_pos => 1);
                    return err($res, 500, "Can't convert args to argv")
                        unless $res->[0] == 200;
                    $argv = $res->[2];
                }
                $cmdline = "[[prog]]";
                for my $arg (@$argv) {
                    my $qarg = String::ShellQuote::shell_quote($arg);
                    $cmdline .= " $qarg"; # XXX markup with color?
                }
            }
            my $egdata = {
                cmdline      => $cmdline,
                summary      => $rimeta->langprop({lang=>$lang}, 'summary'),
                description  => $rimeta->langprop({lang=>$lang}, 'description'),
                example_spec => $eg,
            };
            # XXX show result from $eg
            _add_category_from_spec($clidocdata->{example_categories},
                                    $egdata, $eg, "examples", $has_cats);
            push @examples, $egdata;
        }
    }
    $clidocdata->{examples} = \@examples;

    [200, "OK", $clidocdata];
}

1;
# ABSTRACT: From Rinci function metadata, generate structure convenient for producing CLI documentation (help/usage/POD)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::To::CLIDocData - From Rinci function metadata, generate structure convenient for producing CLI documentation (help/usage/POD)

=head1 VERSION

This document describes version 0.298 of Perinci::Sub::To::CLIDocData (from Perl distribution Perinci-Sub-To-CLIDocData), released on 2021-07-11.

=head1 SYNOPSIS

 use Perinci::Sub::To::CLIDocData qw(gen_cli_doc_data_from_meta);
 my $clidocdata = gen_cli_doc_data_from_meta(meta => $meta);

Sample function metadata (C<$meta>):

 {
   args => {
     bool1 => {
                cmdline_aliases => { z => { summary => "This is summary for option `-z`" } },
                schema => "bool",
                summary => "Another bool option",
                tags => ["category:cat1"],
              },
     flag1 => {
                cmdline_aliases => { f => {} },
                schema => ["bool", "is", 1],
                tags => ["category:cat1"],
              },
     str1  => {
                pos => 0,
                req => 1,
                schema => "str*",
                summary => "A required option as well as positional argument",
              },
   },
   examples => [
     {
       argv    => ["a value", "--bool1"],
       summary => "Summary for an example",
       test    => 0,
     },
   ],
   summary => "Function summary",
   v => 1.1,
 }
Sample result:

 do {
   my $a = [
     200,
     "OK",
     {
       "compact_usage_line" => "[[prog]] [options] <str1>",
       "example_categories" => { Examples => { order => 99 } },
       "examples" => [
         {
           categories   => ["Examples"],
           category     => "Examples",
           cmdline      => "[[prog]] 'a value' --bool1",
           description  => undef,
           example_spec => {
                             argv    => ["a value", "--bool1"],
                             summary => "Summary for an example",
                             test    => 0,
                           },
           summary      => "Summary for an example",
         },
       ],
       "option_categories" => { "Cat1 options" => { order => 50 }, "Main options" => { order => 0 } },
       "opts" => {
         "--bool1" => {
           arg         => "bool1",
           arg_spec    => {
                            cmdline_aliases => { z => { summary => "This is summary for option `-z`" } },
                            schema => ["bool", {}, {}],
                            summary => "Another bool option",
                            tags => ["category:cat1"],
                          },
           categories  => ["Cat1 options"],
           category    => "Cat1 options",
           description => undef,
           fqarg       => "bool1",
           opt_parsed  => { opts => ["bool1"] },
           orig_opt    => "bool1",
           summary     => "Another bool option",
           tags        => 'fix',
         },
         "--flag1, -f" => {
           arg         => "flag1",
           arg_spec    => {
                            cmdline_aliases => { f => {} },
                            schema => ["bool", { is => 1 }, {}],
                            tags => ["category:cat1"],
                          },
           categories  => ["Cat1 options"],
           category    => "Cat1 options",
           description => undef,
           fqarg       => "flag1",
           opt_parsed  => { opts => ["flag1"] },
           orig_opt    => "flag1",
           summary     => undef,
           tags        => 'fix',
         },
         "--str1=s*" => {
           arg => "str1",
           arg_spec => {
             pos => 0,
             req => 1,
             schema => ["str", { req => 1 }, {}],
             summary => "A required option as well as positional argument",
           },
           categories => ["Main options"],
           category => "Main options",
           description => undef,
           fqarg => "str1",
           opt_parsed => { desttype => "", opts => ["str1"], type => "s" },
           orig_opt => "str1=s",
           pos => 0,
           req => 1,
           summary => "A required option as well as positional argument",
         },
         "-z" => {
           alias_for   => "bool1",
           alias_spec  => 'fix',
           arg         => "bool1",
           arg_spec    => 'fix',
           categories  => ["Cat1 options"],
           category    => "Cat1 options",
           description => undef,
           fqarg       => "bool1",
           is_alias    => 1,
           main_opt    => "--bool1",
           opt_parsed  => { opts => ["z"] },
           orig_opt    => "z",
           summary     => "This is summary for option `-z`",
           tags        => 'fix',
         },
       },
       "usage_line" => "[[prog]] [--bool1|-z|--no-bool1|--nobool1] [--flag1|-f] -- <str1>",
       "usage_line.alt.fmt.pod" => "B<[[prog]]> [B<--bool1>|B<-z>|B<--no-bool1>|B<--nobool1>] [B<--flag1>|B<-f>] -- E<lt>I<str1>E<gt>",
     },
   ];
   $a->[2]{"opts"}{"--bool1"}{tags} = $a->[2]{"opts"}{"--bool1"}{arg_spec}{tags};
   $a->[2]{"opts"}{"--flag1, -f"}{tags} = $a->[2]{"opts"}{"--flag1, -f"}{arg_spec}{tags};
   $a->[2]{"opts"}{"-z"}{alias_spec} = $a->[2]{"opts"}{"--bool1"}{arg_spec}{cmdline_aliases}{z};
   $a->[2]{"opts"}{"-z"}{arg_spec} = $a->[2]{"opts"}{"--bool1"}{arg_spec};
   $a->[2]{"opts"}{"-z"}{tags} = $a->[2]{"opts"}{"--bool1"}{arg_spec}{tags};
   $a;
 }
For a more complete sample, see function metadata for C<demo_cli_opts> in
L<Perinci::Examples::CLI>.

=head1 RINCI

Observed function argument attribute: C<x.cli.opt_value_label>, C<caption>, C<>.

=head1 FUNCTIONS


=head2 gen_cli_doc_data_from_meta

Usage:

 gen_cli_doc_data_from_meta(%args) -> [$status_code, $reason, $payload, \%result_meta]

From Rinci function metadata, generate structure convenient for producing CLI documentation (helpE<sol>usageE<sol>POD).

This function calls L<Perinci::Sub::GetArgs::Argv>'s
C<gen_getopt_long_spec_from_meta()> (or receive its result as an argument, if
passed, to avoid calling the function twice) and post-processes it: produce
command usage line, format the options, include information from metadata, group
the options by category. It also selects examples in the C<examples> property
which are applicable to CLI environment and format them.

The resulting data structure is convenient to use when one wants to produce a
documentation for CLI program (including help/usage message and POD).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<common_opts> => I<hash>

Will be passed to gen_getopt_long_spec_from_meta().

=item * B<ggls_res> => I<array>

Full result from gen_getopt_long_spec_from_meta().

If you already call L<Perinci::Sub::GetArgs::Argv>'s
C<gen_getopt_long_spec_from_meta()>, you can pass the I<full> enveloped result
here, to avoid calculating twice. What will be useful for the function is the
extra result in result metadata (C<func.*> keys in C<< $res-E<gt>[3] >> hash).

=item * B<lang> => I<str>

=item * B<meta>* => I<hash>

=item * B<meta_is_normalized> => I<bool>

=item * B<per_arg_json> => I<bool>

Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv.

=item * B<per_arg_yaml> => I<bool>

Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-To-CLIDocData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-To-CLIOptSpec>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-To-CLIDocData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine>, L<Perinci::CmdLine::Lite>

L<Pod::Weaver::Plugin::Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
