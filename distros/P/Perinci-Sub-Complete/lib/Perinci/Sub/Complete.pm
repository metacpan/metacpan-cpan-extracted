package Perinci::Sub::Complete;

our $DATE = '2019-06-29'; # DATE
our $VERSION = '0.937'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Complete::Util qw(hashify_answer complete_array_elem complete_hash_key combine_answers modify_answer);
use Complete::Common qw(:all);
use Perinci::Sub::Util qw(gen_modified_sub);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_from_schema
                       complete_arg_val
                       complete_arg_index
                       complete_arg_elem
                       complete_cli_arg
               );
our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Complete command-line argument using Rinci metadata',
};

my %common_args_riap = (
    riap_client => {
        summary => 'Optional, to perform complete_arg_val to the server',
        schema  => 'obj*',
        description => <<'_',

When the argument spec in the Rinci metadata contains `completion` key, this
means there is custom completion code for that argument. However, if retrieved
from a remote server, sometimes the `completion` key no longer contains the code
(it has been cleansed into a string). Moreover, the completion code needs to run
on the server.

If supplied this argument and te `riap_server_url` argument, the function will
try to request to the server (via Riap request `complete_arg_val`). Otherwise,
the function will just give up/decline completing.

_
        },
    riap_server_url => {
        summary => 'Optional, to perform complete_arg_val to the server',
        schema  => 'str*',
        description => <<'_',

See the `riap_client` argument.

_
    },
    riap_uri => {
        summary => 'Optional, to perform complete_arg_val to the server',
        schema  => 'str*',
        description => <<'_',

See the `riap_client` argument.

_
    },
);

$SPEC{complete_from_schema} = {
    v => 1.1,
    summary => 'Complete a value from schema',
    description => <<'_',

Employ some heuristics to complete a value from Sah schema. For example, if
schema is `[str => in => [qw/new open resolved rejected/]]`, then we can
complete from the `in` clause. Or for something like `[int => between => [1,
20]]` we can complete using values from 1 to 20.

_
    args => {
        schema => {
            summary => 'Must be normalized',
            req => 1,
        },
        word => {
            schema => [str => default => ''],
            req => 1,
        },
    },
};
sub complete_from_schema {
    my %args = @_;
    my $sch  = $args{schema}; # must be normalized
    my $word = $args{word} // "";

    my $fres;
    log_trace("[comp][periscomp] entering complete_from_schema, word=<%s>, schema=%s", $word, $sch);

    my ($type, $cs) = @{$sch};

    # schema might be based on other schemas, if that is the case, let's try to
    # look at Sah::SchemaR::* module to quickly find the base type
    unless ($type =~ /\A(all|any|array|bool|buf|cistr|code|date|duration|float|hash|int|num|obj|re|str|undef)\z/) {
        no strict 'refs';
        my $pkg = "Sah::SchemaR::$type";
        (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
        eval { require $pkg_pm; 1 };
        if ($@) {
            log_trace("[comp][periscomp] couldn't load schema module %s: %s, skipped", $pkg, $@);
            goto RETURN_RES;
        }
        my $rsch = ${"$pkg\::rschema"};
        $type = $rsch->[0];
        # let's just merge everything, for quick checking of clause
        $cs = {};
        for my $cs0 (@{ $rsch->[1] // [] }) {
            for (keys %$cs0) {
                $cs->{$_} = $cs0->{$_};
            }
        }
        log_trace("[comp][periscomp] retrieving schema from module %s, base type=%s", $pkg, $type);
    }

    my $static;
    my $words;
    my $summaries;
    eval {
        if (my $xcomp = $cs->{'x.completion'}) {
            require Module::Installed::Tiny;
            my $comp;
            if (ref($xcomp) eq 'CODE') {
                $comp = $xcomp;
            } else {
                my ($submod, $xcargs);
                if (ref($xcomp) eq 'ARRAY') {
                    $submod = $xcomp->[0];
                    $xcargs = $xcomp->[1];
                } else {
                    $submod = $xcomp;
                    $xcargs = {};
                }
                my $mod = "Perinci::Sub::XCompletion::$submod";
                if (Module::Installed::Tiny::module_installed($mod)) {
                    log_trace("[comp][periscomp] loading module %s ...", $mod);
                    my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                    require $mod_pm;
                    my $fref = \&{"$mod\::gen_completion"};
                    log_trace("[comp][periscomp] invoking %s's gen_completion(%s) ...", $mod, $xcargs);
                    $comp = $fref->(%$xcargs);
                } else {
                    log_trace("[comp][periscomp] module %s is not installed, skipped", $mod);
                }
            }
            if ($comp) {
                log_trace("[comp][periscomp] using arg completion routine from schema's 'x.completion' attribute");
                $fres = $comp->(
                    %{$args{extras} // {}},
                    word=>$word, arg=>$args{arg}, args=>$args{args});
                return; # from eval
                }
            }

        if ($cs->{is} && !ref($cs->{is})) {
            log_trace("[comp][periscomp] adding completion from schema's 'is' clause");
            push @$words, $cs->{is};
            push @$summaries, undef;
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($cs->{in}) {
            log_trace("[comp][periscomp] adding completion from schema's 'in' clause");
            for my $i (0..$#{ $cs->{in} }) {
                next if ref $cs->{in}[$i];
                push @$words    , $cs->{in}[$i];
                push @$summaries, $cs->{'x.in.summaries'} ? $cs->{'x.in.summaries'}[$i] : undef;
            }
            $static++;
            return; # from eval. there should not be any other value
        }
        if ($type eq 'any') {
            # because currently Data::Sah::Normalize doesn't recursively
            # normalize schemas in 'of' clauses, etc.
            require Data::Sah::Normalize;
            if ($cs->{of} && @{ $cs->{of} }) {

                $fres = combine_answers(
                    grep { defined } map {
                        complete_from_schema(
                            schema=>Data::Sah::Normalize::normalize_schema($_),
                            word => $word,
                        )
                    } @{ $cs->{of} }
                );
                goto RETURN_RES; # directly return result
            }
        }
        if ($type eq 'bool') {
            log_trace("[comp][periscomp] adding completion from possible values of bool");
            push @$words, 0, 1;
            push @$summaries, undef, undef;
            $static++;
            return; # from eval
        }
        if ($type eq 'int') {
            my $limit = 100;
            if ($cs->{between} &&
                    $cs->{between}[0] - $cs->{between}[0] <= $limit) {
                log_trace("[comp][periscomp] adding completion from schema's 'between' clause");
                for ($cs->{between}[0] .. $cs->{between}[1]) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif ($cs->{xbetween} &&
                         $cs->{xbetween}[0] - $cs->{xbetween}[0] <= $limit) {
                log_trace("[comp][periscomp] adding completion from schema's 'xbetween' clause");
                for ($cs->{xbetween}[0]+1 .. $cs->{xbetween}[1]-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{min}) && defined($cs->{max}) &&
                         $cs->{max}-$cs->{min} <= $limit) {
                log_trace("[comp][periscomp] adding completion from schema's 'min' & 'max' clauses");
                for ($cs->{min} .. $cs->{max}) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{min}) && defined($cs->{xmax}) &&
                         $cs->{xmax}-$cs->{min} <= $limit) {
                log_trace("[comp][periscomp] adding completion from schema's 'min' & 'xmax' clauses");
                for ($cs->{min} .. $cs->{xmax}-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{xmin}) && defined($cs->{max}) &&
                         $cs->{max}-$cs->{xmin} <= $limit) {
                log_trace("[comp][periscomp] adding completion from schema's 'xmin' & 'max' clauses");
                for ($cs->{xmin}+1 .. $cs->{max}) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (defined($cs->{xmin}) && defined($cs->{xmax}) &&
                         $cs->{xmax}-$cs->{xmin} <= $limit) {
                log_trace("[comp][periscomp] adding completion from schema's 'xmin' & 'xmax' clauses");
                for ($cs->{xmin}+1 .. $cs->{xmax}-1) {
                    push @$words, $_;
                    push @$summaries, undef;
                }
                $static++;
            } elsif (length($word) && $word !~ /\A-?\d*\z/) {
                log_trace("[comp][periscomp] word not an int");
                $words = [];
                $summaries = [];
            } else {
                # do a digit by digit completion
                $words = [];
                $summaries = [];
                for my $sign ("", "-") {
                    for ("", 0..9) {
                        my $i = $sign . $word . $_;
                        next unless length $i;
                        next unless $i =~ /\A-?\d+\z/;
                        next if $i eq '-0';
                        next if $i =~ /\A-?0\d/;
                        next if $cs->{between} &&
                            ($i < $cs->{between}[0] ||
                                 $i > $cs->{between}[1]);
                        next if $cs->{xbetween} &&
                            ($i <= $cs->{xbetween}[0] ||
                                 $i >= $cs->{xbetween}[1]);
                        next if defined($cs->{min} ) && $i <  $cs->{min};
                        next if defined($cs->{xmin}) && $i <= $cs->{xmin};
                        next if defined($cs->{max} ) && $i >  $cs->{max};
                        next if defined($cs->{xmin}) && $i >= $cs->{xmax};
                        push @$words, $i;
                        push @$summaries, undef;
                    }
                }
            }
            return; # from eval
        }
        if ($type eq 'float') {
            if (length($word) && $word !~ /\A-?\d*(\.\d*)?\z/) {
                log_trace("[comp][periscomp] word not a float");
                $words = [];
                $summaries = [];
            } else {
                $words = [];
                $summaries = [];
                for my $sig ("", "-") {
                    for ("", 0..9,
                         ".0",".1",".2",".3",".4",".5",".6",".7",".8",".9") {
                        my $f = $sig . $word . $_;
                        next unless length $f;
                        next unless $f =~ /\A-?\d+(\.\d+)?\z/;
                        next if $f eq '-0';
                        next if $f =~ /\A-?0\d\z/;
                        next if $cs->{between} &&
                            ($f < $cs->{between}[0] ||
                                 $f > $cs->{between}[1]);
                        next if $cs->{xbetween} &&
                            ($f <= $cs->{xbetween}[0] ||
                                 $f >= $cs->{xbetween}[1]);
                        next if defined($cs->{min} ) && $f <  $cs->{min};
                        next if defined($cs->{xmin}) && $f <= $cs->{xmin};
                        next if defined($cs->{max} ) && $f >  $cs->{max};
                        next if defined($cs->{xmin}) && $f >= $cs->{xmax};
                        push @$words, $f;
                        push @$summaries, undef;
                    }
                }
                my @orders = sort { $words->[$a] cmp $words->[$b] }
                    0..$#{$words};
                my $words     = [map {$words->[$_]    } @orders];
                my $summaries = [map {$summaries->[$_]} @orders];
            }
            return; # from eval
        }
    }; # eval

    log_trace("[periscomp] complete_from_schema died: %s", $@) if $@;

    goto RETURN_RES unless $words;
    $fres = hashify_answer(
        complete_array_elem(array=>$words, summaries=>$summaries, word=>$word),
        {static=>$static && $word eq '' ? 1:0},
    );

  RETURN_RES:
    log_trace("[comp][periscomp] leaving complete_from_schema, result=%s", $fres);
    $fres;
}

$SPEC{complete_arg_val} = {
    v => 1.1,
    summary => 'Given argument name and function metadata, complete value',
    description => <<'_',

Will attempt to complete using the completion routine specified in the argument
specification (the `completion` property, or in the case of `complete_arg_elem`
function, the `element_completion` property), or if that is not specified, from
argument's schema using `complete_from_schema`.

Completion routine will get `%args`, with the following keys:

* `word` (str, the word to be completed)
* `arg` (str, the argument name which value is currently being completed)
* `index (int, only for the `complete_arg_elem` function, the index in the
   argument array that is currently being completed, starts from 0)
* `args` (hash, the argument hash to the function, so far)

as well as extra keys from `extras` (but these won't overwrite the above
standard keys).

Completion routine should return a completion answer structure (described in
<pm:Complete>) which is either a hash or an array. The simplest form of answer
is just to return an array of strings. Completion routine can also return undef
to express declination.

_
    args => {
        meta => {
            summary => 'Rinci function metadata, must be normalized',
            schema => 'hash*',
            req => 1,
        },
        arg => {
            summary => 'Argument name',
            schema => 'str*',
            req => 1,
        },
        word => {
            summary => 'Word to be completed',
            schema => ['str*', default => ''],
        },
        args => {
            summary => 'Collected arguments so far, '.
                'will be passed to completion routines',
            schema  => 'hash',
        },
        extras => {
            summary => 'Add extra arguments to completion routine',
            schema  => 'hash',
            description => <<'_',

The keys from this `extras` hash will be merged into the final `%args` passed to
completion routines. Note that standard keys like `word`, `cword`, and so on as
described in the function description will not be overwritten by this.

_
        },

        %common_args_riap,
    },
    result_naked => 1,
    result => {
        schema => 'array', # XXX of => str*
    },
};
sub complete_arg_val {
    my %args = @_;

    log_trace("[comp][periscomp] entering complete_arg_val, arg=<%s>", $args{arg});
    my $fres;

    my $extras = $args{extras} // {};

    my $meta = $args{meta} or do {
        log_trace("[comp][periscomp] meta is not supplied, declining");
        goto RETURN_RES;
    };
    my $arg  = $args{arg} or do {
        log_trace("[comp][periscomp] arg is not supplied, declining");
        goto RETURN_RES;
    };
    my $word = $args{word} // '';

    # XXX reject if meta's v is not 1.1

    my $args_prop = $meta->{args} // {};
    my $arg_spec = $args_prop->{$arg} or do {
        log_trace("[comp][periscomp] arg '$arg' is not specified in meta, declining");
        goto RETURN_RES;
    };

    my $static;
    eval { # completion sub can die, etc.

        my $comp;
      GET_COMP_ROUTINE:
        {
            $comp = $arg_spec->{completion};
            if ($comp) {
                log_trace("[comp][periscomp] using arg completion routine from arg spec's 'completion' property");
                last GET_COMP_ROUTINE;
            }
            my $xcomp = $arg_spec->{'x.completion'};
            if ($xcomp) {
                if (ref($xcomp) eq 'CODE') {
                    $comp = $xcomp;
                } else {
                    my ($submod, $xcargs);
                    if (ref($xcomp) eq 'ARRAY') {
                        $submod = $xcomp->[0];
                        $xcargs = $xcomp->[1];
                    } else {
                        $submod = $xcomp;
                        $xcargs = {};
                    }
                    my $mod = "Perinci::Sub::XCompletion::$submod";
                    require Module::Installed::Tiny;
                    if (Module::Installed::Tiny::module_installed($mod)) {
                        log_trace("[comp][periscomp] loading module %s ...", $mod);
                        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                        require $mod_pm;
                        my $fref = \&{"$mod\::gen_completion"};
                        log_trace("[comp][periscomp] invoking gen_completion() from %s ...", $mod);
                        $comp = $fref->(%$xcargs);
                    } else {
                        log_trace("[comp][periscomp] module %s is not installed, skipped", $mod);
                    }
                }
                if ($comp) {
                    log_trace("[comp][periscomp] using arg completion routine from arg spec's 'x.completion' attribute");
                    last GET_COMP_ROUTINE;
                }
            }
            my $ent = $arg_spec->{'x.schema.entity'};
            if ($ent) {
                require Module::Installed::Tiny;
                my $mod = "Perinci::Sub::ArgEntity::$ent";
                if (Module::Installed::Tiny::module_installed($mod)) {
                    log_trace("[comp][periscomp] loading module %s ...", $mod);
                    my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                    require $mod_pm;
                    if (defined &{"$mod\::complete_arg_val"}) {
                        log_trace("[comp][periscomp] invoking complete_arg_val() from %s ...", $mod);
                        $comp = \&{"$mod\::complete_arg_val"};
                        last GET_COMP_ROUTINE;
                    } else {
                        log_trace("[comp][periscomp] module %s doesn't define complete_arg_val(), skipped", $mod);
                    }
                } else {
                    log_trace("[comp][periscomp] module %s not installed, skipped", $mod);
                }
            }
        } # GET_COMP_ROUTINE

        if ($comp) {
            if (ref($comp) eq 'CODE') {
                log_trace("[comp][periscomp] invoking arg completion routine");
                $fres = $comp->(
                    %$extras,
                    word=>$word, arg=>$arg, args=>$args{args});
                return; # from eval
            } elsif (ref($comp) eq 'ARRAY') {
                # this is deprecated but will be supported for some time
                log_trace("[comp][periscomp] using array specified in arg completion routine: %s", $comp);
                $fres = complete_array_elem(array=>$comp, word=>$word);
                $static++;
                return; # from eval
            }

            log_trace("[comp][periscomp] arg spec's 'completion' property is not a coderef or arrayref");
            if ($args{riap_client} && $args{riap_server_url}) {
                log_trace("[comp][periscomp] trying to perform complete_arg_val request to Riap server");
                my $res = $args{riap_client}->request(
                    complete_arg_val => $args{riap_server_url},
                    {(uri=>$args{riap_uri}) x !!defined($args{riap_uri}),
                     arg=>$arg, word=>$word},
                );
                if ($res->[0] != 200) {
                    log_trace("[comp][periscomp] Riap request failed (%s), declining", $res);
                    return; # from eval
                }
                $fres = $res->[2];
                return; # from eval
            }

            log_trace("[comp][periscomp] declining");
            return; # from eval
        }

        my $fres_from_arg_examples;
      COMPLETE_FROM_ARG_EXAMPLES:
        {
            my $eg = $arg_spec->{examples};
            unless ($eg) {
                log_trace("[comp][periscomp] arg spec does not specify examples");
                last COMPLETE_FROM_ARG_EXAMPLES;
            }
            $fres_from_arg_examples = complete_array_elem(
                word=>$word, array=>[map {ref $_ eq 'HASH' ? $_->{value} : $_} @$eg]);
        } # COMPLETE_FROM_ARG_EXAMPLES

        my $fres_from_schema;
      COMPLETE_FROM_SCHEMA:
        {
            my $sch = $arg_spec->{schema};
            unless ($sch) {
                log_trace("[comp][periscomp] arg spec does not specify schema");
                last COMPLETE_FROM_SCHEMA;
            }
            # XXX normalize schema if not normalized
            $fres_from_schema = complete_from_schema(arg=>$arg, extras=>$extras, schema=>$sch, word=>$word);
        } # COMPLETE_FROM_SCHEMA

        $fres = combine_answers(grep {defined} (
            $fres_from_arg_examples,
            $fres_from_schema,
        ));
    };
    log_debug("[comp][periscomp] completion died: $@") if $@;
    unless ($fres) {
        log_trace("[comp][periscomp] no completion from metadata possible, declining");
        goto RETURN_RES;
    }

    $fres = hashify_answer($fres);
    $fres->{static} //= $static && $word eq '' ? 1:0;
  RETURN_RES:
    log_trace("[comp][periscomp] leaving complete_arg_val, result=%s", $fres);
    $fres;
}

gen_modified_sub(
    output_name  => 'complete_arg_elem',
    install_sub  => 0,
    base_name    => 'complete_arg_val',
    summary      => 'Given argument name and function metadata, '.
        'complete array element',
    add_args     => {
        index => {
            summary => 'Index of element to complete',
            schema  => ['str*'],
        },
    },
);
sub complete_arg_elem {
    require Data::Sah::Normalize;

    my %args = @_;

    my $fres;

    log_trace("[comp][periscomp] entering complete_arg_elem, arg=<%s>, index=<%d>",
                 $args{arg}, $args{index});

    my $extras = $args{extras} // {};

    my $ourextras = {arg=>$args{arg}, args=>$args{args}};

    my $meta = $args{meta} or do {
        log_trace("[comp][periscomp] meta is not supplied, declining");
        goto RETURN_RES;
    };
    my $arg  = $args{arg} or do {
        log_trace("[comp][periscomp] arg is not supplied, declining");
        goto RETURN_RES;
    };
    defined(my $index = $args{index}) or do {
        log_trace("[comp][periscomp] index is not supplied, declining");
        goto RETURN_RES;
    };
    my $word = $args{word} // '';

    # XXX reject if meta's v is not 1.1

    my $args_prop = $meta->{args} // {};
    my $arg_spec = $args_prop->{$arg} or do {
        log_trace("[comp][periscomp] arg '$arg' is not specified in meta, declining");
        goto RETURN_RES;
    };

    my $static;
    eval { # completion sub can die, etc.

        my $elcomp;
      GET_ELCOMP_ROUTINE:
        {
            $elcomp = $arg_spec->{element_completion};
            if ($elcomp) {
                log_trace("[comp][periscomp] using arg element completion routine from 'element_completion' property");
                last GET_ELCOMP_ROUTINE;
            }
            my $xelcomp = $arg_spec->{'x.element_completion'};
            if ($xelcomp) {
                if (ref($xelcomp) eq 'CODE') {
                    $elcomp = $xelcomp;
                } else {
                    my ($submod, $xcargs);
                    if (ref($xelcomp) eq 'ARRAY') {
                        $submod = $xelcomp->[0];
                        $xcargs = $xelcomp->[1];
                    } else {
                        $submod = $xelcomp;
                        $xcargs = {};
                    }
                    my $mod = "Perinci::Sub::XCompletion::$submod";
                    require Module::Installed::Tiny;
                    if (Module::Installed::Tiny::module_installed($mod)) {
                        log_trace("[comp][periscomp] loading module %s ...", $mod);
                        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                        require $mod_pm;
                        my $fref = \&{"$mod\::gen_completion"};
                        log_trace("[comp][periscomp] invoking gen_completion() from %s ...", $mod);
                        $elcomp = $fref->(%$xcargs);
                    } else {
                        log_trace("[comp][periscomp] module %s is not installed, skipped", $mod);
                    }
                }
                if ($elcomp) {
                    log_trace("[comp][periscomp] using arg element completion routine from 'x.element_completion' attribute");
                    last GET_ELCOMP_ROUTINE;
                }
            }
            my $ent = $arg_spec->{'x.schema.element_entity'};
            if ($ent) {
                require Module::Installed::Tiny;
                my $mod = "Perinci::Sub::ArgEntity::$ent";
                if (Module::Installed::Tiny::module_installed($mod)) {
                    log_trace("[comp][periscomp] loading module %s ...", $mod);
                    my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
                    require $mod_pm;
                    if (defined &{"$mod\::complete_arg_val"}) {
                        log_trace("[comp][periscomp] invoking complete_arg_val() from %s ...", $mod);
                        $elcomp = \&{"$mod\::complete_arg_val"};
                        last GET_ELCOMP_ROUTINE;
                    } else {
                        log_trace("[comp][periscomp] module %s doesn't defined complete_arg_val(), skipped", $mod);
                    }
                } else {
                    log_trace("[comp][periscomp] module %s is not installed, skipped", $mod);
                }
            }
        } # GET_ELCOMP_ROUTINE

        $ourextras->{index} = $index;
        if ($elcomp) {
            if (ref($elcomp) eq 'CODE') {
                log_trace("[comp][periscomp] invoking arg element completion routine");
                $fres = $elcomp->(
                    %$extras,
                    %$ourextras,
                    word=>$word);
                return; # from eval
            } elsif (ref($elcomp) eq 'ARRAY') {
                log_trace("[comp][periscomp] using array specified in arg element completion routine: %s", $elcomp);
                $fres = complete_array_elem(array=>$elcomp, word=>$word);
                $static = $word eq '';
            }

            log_trace("[comp][periscomp] arg spec's 'element_completion' property is not a coderef or ".
                             "arrayref");
            if ($args{riap_client} && $args{riap_server_url}) {
                log_trace("[comp][periscomp] trying to perform complete_arg_elem request to Riap server");
                my $res = $args{riap_client}->request(
                    complete_arg_elem => $args{riap_server_url},
                    {(uri=>$args{riap_uri}) x !!defined($args{riap_uri}),
                     arg=>$arg, args=>$args{args}, word=>$word,
                     index=>$index},
                );
                if ($res->[0] != 200) {
                    log_trace("[comp][periscomp] Riap request failed (%s), declining", $res);
                    return; # from eval
                }
                $fres = $res->[2];
                return; # from eval
            }

            log_trace("[comp][periscomp] declining");
            return; # from eval
        } # if ($elcomp)

        my $sch = $arg_spec->{schema};
        unless ($sch) {
            log_trace("[comp][periscomp] arg spec does not specify schema, declining");
            return; # from eval
        };

        my $nsch = Data::Sah::Normalize::normalize_schema($sch);

        my ($type, $cs) = @$nsch;
        if ($type ne 'array') {
            log_trace("[comp][periscomp] can't complete element for non-array");
            return; # from eval
        }

        unless ($cs->{of}) {
            log_trace("[comp][periscomp] schema does not specify 'of' clause, declining");
            return; # from eval
        }

        # normalize subschema because normalize_schema (as of 0.01) currently
        # does not do it yet
        my $elsch = Data::Sah::Normalize::normalize_schema($cs->{of});

        $fres = complete_from_schema(schema=>$elsch, word=>$word);
    };
    log_debug("[comp][periscomp] completion died: $@") if $@;
    unless ($fres) {
        log_trace("[comp][periscomp] no completion from metadata possible, declining");
        goto RETURN_RES;
    }

    $fres = hashify_answer($fres);
    $fres->{static} //= $static && $word eq '' ? 1:0;
  RETURN_RES:
    log_trace("[comp][periscomp] leaving complete_arg_elem, result=%s", $fres);
    $fres;
}

$SPEC{complete_arg_index} = {
    v => 1.1,
    summary => 'Given argument name and function metadata, complete arg element index',
    description => <<'_',

This is only relevant for arguments which have `index_completion` property set
(currently only `hash` type arguments). When that property is not set, will
simply return undef.

Completion routine will get `%args`, with the following keys:

* `word` (str, the word to be completed)
* `arg` (str, the argument name which value is currently being completed)
* `args` (hash, the argument hash to the function, so far)

as well as extra keys from `extras` (but these won't overwrite the above
standard keys).

Completion routine should return a completion answer structure (described in
<pm:Complete>) which is either a hash or an array. The simplest form of answer
is just to return an array of strings. Completion routine can also return undef
to express declination.

_
    args => {
        meta => {
            summary => 'Rinci function metadata, must be normalized',
            schema => 'hash*',
            req => 1,
        },
        arg => {
            summary => 'Argument name',
            schema => 'str*',
            req => 1,
        },
        word => {
            summary => 'Word to be completed',
            schema => ['str*', default => ''],
        },
        args => {
            summary => 'Collected arguments so far, '.
                'will be passed to completion routines',
            schema  => 'hash',
        },
        extras => {
            summary => 'Add extra arguments to completion routine',
            schema  => 'hash',
            description => <<'_',

The keys from this `extras` hash will be merged into the final `%args` passed to
completion routines. Note that standard keys like `word`, `cword`, and so on as
described in the function description will not be overwritten by this.

_
        },

        %common_args_riap,
    },
    result_naked => 1,
    result => {
        schema => 'array', # XXX of => str*
    },
};
sub complete_arg_index {
    require Data::Sah::Normalize;

    my %args = @_;

    my $fres;

    log_trace("[comp][periscomp] entering complete_arg_index, arg=<%s>",
                 $args{arg});

    my $extras = $args{extras} // {};

    my $ourextras = {arg=>$args{arg}, args=>$args{args}};

    my $meta = $args{meta} or do {
        log_trace("[comp][periscomp] meta is not supplied, declining");
        goto RETURN_RES;
    };
    my $arg  = $args{arg} or do {
        log_trace("[comp][periscomp] arg is not supplied, declining");
        goto RETURN_RES;
    };
    my $word = $args{word} // '';

    # XXX reject if meta's v is not 1.1

    my $args_prop = $meta->{args} // {};
    my $arg_spec = $args_prop->{$arg} or do {
        log_trace("[comp][periscomp] arg '$arg' is not specified in meta, declining");
        goto RETURN_RES;
    };

    my $static;
    eval { # completion sub can die, etc.

        my $idxcomp;
      GET_IDXCOMP_ROUTINE:
        {
            $idxcomp = $arg_spec->{index_completion};
            if ($idxcomp) {
                log_trace("[comp][periscomp] using arg element index completion routine from 'index_completion' property");
                last GET_IDXCOMP_ROUTINE;
            }
        } # GET_IDXCOMP_ROUTINE

        if ($idxcomp) {
            if (ref($idxcomp) eq 'CODE') {
                log_trace("[comp][periscomp] invoking arg element index completion routine");
                $fres = $idxcomp->(
                    %$extras,
                    %$ourextras,
                    word=>$word);
                return; # from eval
            } elsif (ref($idxcomp) eq 'ARRAY') {
                log_trace("[comp][periscomp] using array specified in arg element index completion routine: %s", $idxcomp);
                $fres = complete_array_elem(array=>$idxcomp, word=>$word);
                $static = $word eq '';
            }

            log_trace("[comp][periscomp] arg spec's 'index_completion' property is not a coderef or ".
                             "arrayref");
            if ($args{riap_client} && $args{riap_server_url}) {
                log_trace("[comp][periscomp] trying to perform complete_arg_index request to Riap server");
                my $res = $args{riap_client}->request(
                    complete_arg_index => $args{riap_server_url},
                    {(uri=>$args{riap_uri}) x !!defined($args{riap_uri}),
                     arg=>$arg, args=>$args{args}, word=>$word},
                );
                if ($res->[0] != 200) {
                    log_trace("[comp][periscomp] Riap request failed (%s), declining", $res);
                    return; # from eval
                }
                $fres = $res->[2];
                return; # from eval
            }

            log_trace("[comp][periscomp] declining");
            return; # from eval
        } # if ($idxcomp)

        my $sch = $arg_spec->{schema};
        unless ($sch) {
            log_trace("[comp][periscomp] arg spec does not specify schema, declining");
            return; # from eval
        };

        my $nsch = Data::Sah::Normalize::normalize_schema($sch);

        my ($type, $cs) = @$nsch;
        if ($type ne 'hash') {
            log_trace("[comp][periscomp] can't complete element index for non-hash");
            return; # from eval
        }

        # collect known keys from some clauses
        my %keys;
        if ($cs->{keys}) {
            $keys{$_}++ for keys %{ $cs->{keys} };
        }
        if ($cs->{indices}) {
            $keys{$_}++ for keys %{ $cs->{indices} };
        }
        if ($cs->{req_keys}) {
            $keys{$_}++ for @{ $cs->{req_keys} };
        }
        if ($cs->{allowed_keys}) {
            $keys{$_}++ for @{ $cs->{allowed_keys} };
        }

        # exclude keys that have been specified in collected args
        for (keys %{$args{args}{$arg} // {}}) {
            delete $keys{$_};
        }

        $fres = complete_hash_key(word => $word, hash => \%keys);

    }; # eval
    log_debug("[comp][periscomp] completion died: $@") if $@;
    unless ($fres) {
        log_trace("[comp][periscomp] no index completion from metadata possible, declining");
        goto RETURN_RES;
    }

    $fres = hashify_answer($fres);
    $fres->{static} //= $static && $word eq '' ? 1:0;
  RETURN_RES:
    log_trace("[comp][periscomp] leaving complete_arg_index, result=%s", $fres);
    $fres;
}

$SPEC{complete_cli_arg} = {
    v => 1.1,
    summary => 'Complete command-line argument using Rinci function metadata',
    description => <<'_',

This routine uses <pm:Perinci::Sub::GetArgs::Argv> to generate <pm:Getopt::Long>
specification from arguments list in Rinci function metadata and common options.
Then, it will use <pm:Complete::Getopt::Long> to complete option names, option
values, as well as arguments.

_
    args => {
        meta => {
            summary => 'Rinci function metadata',
            schema => 'hash*',
            req => 1,
        },
        words => {
            summary => 'Command-line arguments',
            schema => ['array*' => {of=>'str*'}],
            req => 1,
        },
        cword => {
            summary => 'On which argument cursor is located (zero-based)',
            schema => 'int*',
            req => 1,
        },
        completion => {
            summary => 'Supply custom completion routine',
            description => <<'_',

If supplied, instead of the default completion routine, this code will be called
instead. Will receive all arguments that <pm:Complete::Getopt::Long> will pass,
and additionally:

* `arg` (str, the name of function argument)
* `args` (hash, the function arguments formed so far)
* `index` (int, if completing argument element value)

_
            schema => 'code*',
        },
        per_arg_json => {
            summary => 'Will be passed to Perinci::Sub::GetArgs::Argv',
            schema  => 'bool',
        },
        per_arg_yaml => {
            summary => 'Will be passed to Perinci::Sub::GetArgs::Argv',
            schema  => 'bool',
        },
        common_opts => {
            summary => 'Common options',
            description => <<'_',

A hash where the values are hashes containing these keys: `getopt` (Getopt::Long
option specification), `handler` (Getopt::Long handler). Will be passed to
`get_args_from_argv()`. Example:

    {
        help => {
            getopt  => 'help|h|?',
            handler => sub { ... },
            summary => 'Display help and exit',
        },
        version => {
            getopt  => 'version|v',
            handler => sub { ... },
            summary => 'Display version and exit',
        },
    }

_
            schema => ['hash*'],
        },
        extras => {
            summary => 'Add extra arguments to completion routine',
            schema  => 'hash',
            description => <<'_',

The keys from this `extras` hash will be merged into the final `%args` passed to
completion routines. Note that standard keys like `word`, `cword`, and so on as
described in the function description will not be overwritten by this.

_
        },
        func_arg_starts_at => {
            schema  => 'int*',
            default => 0,
            description => <<'_',

This is a (temporary?) workaround for <pm:Perinci::CmdLine>. In an application
with subcommands (e.g. `cmd --verbose subcmd arg0 arg1 ...`), then `words` will
still contain the subcommand name. Positional function arguments then start at 1
not 0. This option allows offsetting function arguments.

_
        },
        %common_args_riap,
    },
    result_naked => 1,
    result => {
        schema => 'hash*',
        description => <<'_',

You can use `format_completion` function in <pm:Complete::Bash> module to format
the result of this function for bash.

_
    },
};
sub complete_cli_arg {
    require Complete::Getopt::Long;
    require Perinci::Sub::GetArgs::Argv;

    my %args   = @_;
    my $meta   = $args{meta} or die "Please specify meta";
    my $words  = $args{words} or die "Please specify words";
    my $cword  = $args{cword}; defined($cword) or die "Please specify cword";
    my $copts  = $args{common_opts} // {};
    my $comp   = $args{completion};
    my $extras = {
        %{ $args{extras} // {} },
        words => $args{words},
        cword => $args{cword},
    };

    my $fname = __PACKAGE__ . "::complete_cli_arg"; # XXX use __SUB__
    my $fres;

    my $word   = $words->[$cword];
    my $args_prop = $meta->{args} // {};

    log_trace('[comp][periscomp] entering %s(), words=%s, cword=%d, word=<%s>',
                 $fname, $words, $cword, $word);

    my $ggls_res = Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
        meta         => $meta,
        common_opts  => $copts,
        per_arg_json => $args{per_arg_json},
        per_arg_yaml => $args{per_arg_yaml},
        ignore_converted_code => 1,
    );
    die "Can't generate getopt spec from meta: $ggls_res->[0] - $ggls_res->[1]"
        unless $ggls_res->[0] == 200;
    $extras->{ggls_res} = $ggls_res;
    my $gospec = $ggls_res->[2];
    my $specmeta = $ggls_res->[3]{'func.specmeta'};

    my $gares = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
        argv   => [@$words],
        meta   => $meta,
        strict => 0,
    );

    my $copts_by_ospec = {};
    for (keys %$copts) { $copts_by_ospec->{$copts->{$_}{getopt}}=$copts->{$_} }

    my $compgl_comp = sub {
        log_trace("[comp][periscomp] entering completion routine (that we supply to Complete::Getopt::Long)");
        my %cargs = @_;
        my $type  = $cargs{type};
        my $ospec = $cargs{ospec} // '';
        my $word  = $cargs{word};

        my $fres;

        my %rargs = (
            riap_server_url => $args{riap_server_url},
            riap_uri        => $args{riap_uri},
            riap_client     => $args{riap_client},
        );

        $extras->{parsed_opts} = $cargs{parsed_opts};

        if (my $sm = $specmeta->{$ospec}) {
            $cargs{type} = 'optval';
            if ($sm->{arg}) {
                log_trace("[comp][periscomp] completing option value for a known function argument, arg=<%s>, ospec=<%s>", $sm->{arg}, $ospec);
                $cargs{arg} = $sm->{arg};
                my $arg_spec = $args_prop->{$sm->{arg}} or goto RETURN_RES;
                if ($comp) {
                    log_trace("[comp][periscomp] invoking routine supplied from 'completion' argument");
                    my $compres;
                    eval { $compres = $comp->(%cargs) };
                    log_debug("[comp][periscomp] completion died: $@") if $@;
                    log_trace("[comp][periscomp] result from 'completion' routine: %s", $compres);
                    if ($compres) {
                        $fres = $compres;
                        goto RETURN_RES;
                    }
                }
                if ($ospec =~ /\@$/) {
                    $fres = complete_arg_elem(
                        meta=>$meta, arg=>$sm->{arg}, args=>$gares->[2],
                        word=>$word, index=>$cargs{nth}, # XXX correct index
                        extras=>$extras, %rargs);
                    goto RETURN_RES;
                } elsif ($ospec =~ /\%$/) {
                    if ($word =~ /(.*?)=(.*)/s) {
                        my $key = $1;
                        my $val = $2;
                        $fres = complete_arg_elem(
                            meta=>$meta, arg=>$sm->{arg}, args=>$gares->[2],
                            word=>$val, index=>$key,
                            extras=>$extras, %rargs);
                        modify_answer(answer=>$fres, prefix=>"$key=");
                        goto RETURN_RES;
                    } else {
                        $fres = complete_arg_index(
                            meta=>$meta, arg=>$sm->{arg}, args=>$gares->[2],
                            word=>$word, extras=>$extras, %rargs);
                        modify_answer(answer=>$fres, suffix=>"=");
                        $fres->{path_sep} = "=";
                        # XXX actually not entirely correct, we want normal
                        # escaping but without escaping "=", maybe we should
                        # allow customizing, e.g. esc_mode=normal, dont_esc="="
                        # (list of characters to not escape)
                        $fres->{esc_mode} = "none";
                        goto RETURN_RES;
                    }
                } else {
                    $fres = complete_arg_val(
                        meta=>$meta, arg=>$sm->{arg}, args=>$gares->[2],
                        word=>$word, extras=>$extras, %rargs);
                    goto RETURN_RES;
                }
            } else {
                log_trace("[comp][periscomp] completing option value for a common option, ospec=<%s>", $ospec);
                $cargs{arg}  = undef;
                my $codata = $copts_by_ospec->{$ospec};
                if ($comp) {
                    log_trace("[comp][periscomp] invoking routine supplied from 'completion' argument");
                    my $res;
                    eval { $res = $comp->(%cargs) };
                    log_debug("[comp][periscomp] completion died: $@") if $@;
                    if ($res) {
                        $fres = $res;
                        goto RETURN_RES;
                    }
                }
                if ($codata->{completion}) {
                    $cargs{arg}  = undef;
                    log_trace("[comp][periscomp] completing with common option's 'completion' property");
                    my $res;
                    eval { $res = $codata->{completion}->(%cargs) };
                    log_debug("[comp][periscomp] completion died: $@") if $@;
                    if ($res) {
                        $fres = $res;
                        goto RETURN_RES;
                    }
                }
                if ($codata->{schema}) {
                    require Data::Sah::Normalize;
                    my $nsch = Data::Sah::Normalize::normalize_schema(
                        $codata->{schema});
                    log_trace("[comp][periscomp] completing with common option's schema");
                    $fres = complete_from_schema(
                        schema => $nsch, word=>$word);
                    goto RETURN_RES;
                }
                goto RETURN_RES;
            }
        } elsif ($type eq 'arg') {
            log_trace("[comp][periscomp] completing argument #%d", $cargs{argpos});
            $cargs{type} = 'arg';

            my $pos = $cargs{argpos};
            my $fasa = $args{func_arg_starts_at} // 0;

            # find if there is a non-slurpy argument with the exact position
            for my $an (keys %$args_prop) {
                my $arg_spec = $args_prop->{$an};
                next unless !($arg_spec->{slurpy} // $arg_spec->{greedy}) &&
                    defined($arg_spec->{pos}) && $arg_spec->{pos} == $pos - $fasa;
                log_trace("[comp][periscomp] this argument position is for non-slurpy function argument <%s>", $an);
                $cargs{arg} = $an;
                if ($comp) {
                    log_trace("[comp][periscomp] invoking routine supplied from 'completion' argument");
                    my $res;
                    eval { $res = $comp->(%cargs) };
                    log_debug("[comp][periscomp] completion died: $@") if $@;
                    if ($res) {
                        $fres = $res;
                        goto RETURN_RES;
                    }
                }
                $fres = complete_arg_val(
                    meta=>$meta, arg=>$an, args=>$gares->[2],
                    word=>$word, extras=>$extras, %rargs);
                goto RETURN_RES;
            }

            # find if there is a slurpy argument which takes elements at that
            # position
            for my $an (sort {
                ($args_prop->{$b}{pos} // 9999) <=> ($args_prop->{$a}{pos} // 9999)
            } keys %$args_prop) {
                my $arg_spec = $args_prop->{$an};
                next unless ($arg_spec->{slurpy} // $arg_spec->{greedy}) &&
                    defined($arg_spec->{pos}) && $arg_spec->{pos} <= $pos - $fasa;
                my $index = $pos - $fasa - $arg_spec->{pos};
                $cargs{arg} = $an;
                $cargs{index} = $index;
                log_trace("[comp][periscomp] this position is for slurpy function argument <%s>'s element[%d]", $an, $index);
                if ($comp) {
                    log_trace("[comp][periscomp] invoking routine supplied from 'completion' argument");
                    my $res;
                    eval { $res = $comp->(%cargs) };
                    log_debug("[comp][periscomp] completion died: $@") if $@;
                    if ($res) {
                        $fres = $res;
                        goto RETURN_RES;
                    }
                }
                $fres = complete_arg_elem(
                    meta=>$meta, arg=>$an, args=>$gares->[2],
                    word=>$word, index=>$index, extras=>$extras, %rargs);
                goto RETURN_RES;
            }

            log_trace("[comp][periscomp] there is no matching function argument at this position");
            if ($comp) {
                log_trace("[comp][periscomp] invoking routine supplied from 'completion' argument");
                my $res;
                eval { $res = $comp->(%cargs) };
                log_debug("[comp][periscomp] completion died: $@") if $@;
                if ($res) {
                    $fres = $res;
                    goto RETURN_RES;
                }
            }
            goto RETURN_RES;
        } else {
            log_trace("[comp][periscomp] completing option value for an unknown/ambiguous option, declining ...");
            # decline because there's nothing in Rinci metadata that can aid us
            goto RETURN_RES;
        }
      RETURN_RES:
        log_trace("[comp][periscomp] leaving completion routine (that we supply to Complete::Getopt::Long)");
        $fres;
    }; # completion routine

    $fres = Complete::Getopt::Long::complete_cli_arg(
        getopt_spec => $gospec,
        words       => $words,
        cword       => $cword,
        completion  => $compgl_comp,
        extras      => $extras,
    );

  RETURN_RES:
    log_trace('[comp][periscomp] leaving %s(), result=%s',
                 $fname, $fres);
    $fres;
}

1;
# ABSTRACT: Complete command-line argument using Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Complete - Complete command-line argument using Rinci metadata

=head1 VERSION

This document describes version 0.937 of Perinci::Sub::Complete (from Perl distribution Perinci-Sub-Complete), released on 2019-06-29.

=head1 SYNOPSIS

See L<Perinci::CmdLine> or L<Perinci::CmdLine::Lite> or L<App::riap> which use
this module.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_arg_elem

Usage:

 complete_arg_elem(%args) -> array

Given argument name and function metadata, complete array element.

Will attempt to complete using the completion routine specified in the argument
specification (the C<completion> property, or in the case of C<complete_arg_elem>
function, the C<element_completion> property), or if that is not specified, from
argument's schema using C<complete_from_schema>.

Completion routine will get C<%args>, with the following keys:

=over

=item * C<word> (str, the word to be completed)

=item * C<arg> (str, the argument name which value is currently being completed)

=item * C<index (int, only for the>complete_arg_elem` function, the index in the
argument array that is currently being completed, starts from 0)

=item * C<args> (hash, the argument hash to the function, so far)

=back

as well as extra keys from C<extras> (but these won't overwrite the above
standard keys).

Completion routine should return a completion answer structure (described in
L<Complete>) which is either a hash or an array. The simplest form of answer
is just to return an array of strings. Completion routine can also return undef
to express declination.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg>* => I<str>

Argument name.

=item * B<args> => I<hash>

Collected arguments so far, will be passed to completion routines.

=item * B<extras> => I<hash>

Add extra arguments to completion routine.

The keys from this C<extras> hash will be merged into the final C<%args> passed to
completion routines. Note that standard keys like C<word>, C<cword>, and so on as
described in the function description will not be overwritten by this.

=item * B<index> => I<str>

Index of element to complete.

=item * B<meta>* => I<hash>

Rinci function metadata, must be normalized.

=item * B<riap_client> => I<obj>

Optional, to perform complete_arg_val to the server.

When the argument spec in the Rinci metadata contains C<completion> key, this
means there is custom completion code for that argument. However, if retrieved
from a remote server, sometimes the C<completion> key no longer contains the code
(it has been cleansed into a string). Moreover, the completion code needs to run
on the server.

If supplied this argument and te C<riap_server_url> argument, the function will
try to request to the server (via Riap request C<complete_arg_val>). Otherwise,
the function will just give up/decline completing.

=item * B<riap_server_url> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<riap_uri> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<word> => I<str> (default: "")

Word to be completed.

=back

Return value:  (array)



=head2 complete_arg_index

Usage:

 complete_arg_index(%args) -> array

Given argument name and function metadata, complete arg element index.

This is only relevant for arguments which have C<index_completion> property set
(currently only C<hash> type arguments). When that property is not set, will
simply return undef.

Completion routine will get C<%args>, with the following keys:

=over

=item * C<word> (str, the word to be completed)

=item * C<arg> (str, the argument name which value is currently being completed)

=item * C<args> (hash, the argument hash to the function, so far)

=back

as well as extra keys from C<extras> (but these won't overwrite the above
standard keys).

Completion routine should return a completion answer structure (described in
L<Complete>) which is either a hash or an array. The simplest form of answer
is just to return an array of strings. Completion routine can also return undef
to express declination.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg>* => I<str>

Argument name.

=item * B<args> => I<hash>

Collected arguments so far, will be passed to completion routines.

=item * B<extras> => I<hash>

Add extra arguments to completion routine.

The keys from this C<extras> hash will be merged into the final C<%args> passed to
completion routines. Note that standard keys like C<word>, C<cword>, and so on as
described in the function description will not be overwritten by this.

=item * B<meta>* => I<hash>

Rinci function metadata, must be normalized.

=item * B<riap_client> => I<obj>

Optional, to perform complete_arg_val to the server.

When the argument spec in the Rinci metadata contains C<completion> key, this
means there is custom completion code for that argument. However, if retrieved
from a remote server, sometimes the C<completion> key no longer contains the code
(it has been cleansed into a string). Moreover, the completion code needs to run
on the server.

If supplied this argument and te C<riap_server_url> argument, the function will
try to request to the server (via Riap request C<complete_arg_val>). Otherwise,
the function will just give up/decline completing.

=item * B<riap_server_url> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<riap_uri> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<word> => I<str> (default: "")

Word to be completed.

=back

Return value:  (array)



=head2 complete_arg_val

Usage:

 complete_arg_val(%args) -> array

Given argument name and function metadata, complete value.

Will attempt to complete using the completion routine specified in the argument
specification (the C<completion> property, or in the case of C<complete_arg_elem>
function, the C<element_completion> property), or if that is not specified, from
argument's schema using C<complete_from_schema>.

Completion routine will get C<%args>, with the following keys:

=over

=item * C<word> (str, the word to be completed)

=item * C<arg> (str, the argument name which value is currently being completed)

=item * C<index (int, only for the>complete_arg_elem` function, the index in the
argument array that is currently being completed, starts from 0)

=item * C<args> (hash, the argument hash to the function, so far)

=back

as well as extra keys from C<extras> (but these won't overwrite the above
standard keys).

Completion routine should return a completion answer structure (described in
L<Complete>) which is either a hash or an array. The simplest form of answer
is just to return an array of strings. Completion routine can also return undef
to express declination.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arg>* => I<str>

Argument name.

=item * B<args> => I<hash>

Collected arguments so far, will be passed to completion routines.

=item * B<extras> => I<hash>

Add extra arguments to completion routine.

The keys from this C<extras> hash will be merged into the final C<%args> passed to
completion routines. Note that standard keys like C<word>, C<cword>, and so on as
described in the function description will not be overwritten by this.

=item * B<meta>* => I<hash>

Rinci function metadata, must be normalized.

=item * B<riap_client> => I<obj>

Optional, to perform complete_arg_val to the server.

When the argument spec in the Rinci metadata contains C<completion> key, this
means there is custom completion code for that argument. However, if retrieved
from a remote server, sometimes the C<completion> key no longer contains the code
(it has been cleansed into a string). Moreover, the completion code needs to run
on the server.

If supplied this argument and te C<riap_server_url> argument, the function will
try to request to the server (via Riap request C<complete_arg_val>). Otherwise,
the function will just give up/decline completing.

=item * B<riap_server_url> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<riap_uri> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<word> => I<str> (default: "")

Word to be completed.

=back

Return value:  (array)



=head2 complete_cli_arg

Usage:

 complete_cli_arg(%args) -> hash

Complete command-line argument using Rinci function metadata.

This routine uses L<Perinci::Sub::GetArgs::Argv> to generate L<Getopt::Long>
specification from arguments list in Rinci function metadata and common options.
Then, it will use L<Complete::Getopt::Long> to complete option names, option
values, as well as arguments.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<common_opts> => I<hash>

Common options.

A hash where the values are hashes containing these keys: C<getopt> (Getopt::Long
option specification), C<handler> (Getopt::Long handler). Will be passed to
C<get_args_from_argv()>. Example:

 {
     help => {
         getopt  => 'help|h|?',
         handler => sub { ... },
         summary => 'Display help and exit',
     },
     version => {
         getopt  => 'version|v',
         handler => sub { ... },
         summary => 'Display version and exit',
     },
 }

=item * B<completion> => I<code>

Supply custom completion routine.

If supplied, instead of the default completion routine, this code will be called
instead. Will receive all arguments that L<Complete::Getopt::Long> will pass,
and additionally:

=over

=item * C<arg> (str, the name of function argument)

=item * C<args> (hash, the function arguments formed so far)

=item * C<index> (int, if completing argument element value)

=back

=item * B<cword>* => I<int>

On which argument cursor is located (zero-based).

=item * B<extras> => I<hash>

Add extra arguments to completion routine.

The keys from this C<extras> hash will be merged into the final C<%args> passed to
completion routines. Note that standard keys like C<word>, C<cword>, and so on as
described in the function description will not be overwritten by this.

=item * B<func_arg_starts_at> => I<int> (default: 0)

This is a (temporary?) workaround for L<Perinci::CmdLine>. In an application
with subcommands (e.g. C<cmd --verbose subcmd arg0 arg1 ...>), then C<words> will
still contain the subcommand name. Positional function arguments then start at 1
not 0. This option allows offsetting function arguments.

=item * B<meta>* => I<hash>

Rinci function metadata.

=item * B<per_arg_json> => I<bool>

Will be passed to Perinci::Sub::GetArgs::Argv.

=item * B<per_arg_yaml> => I<bool>

Will be passed to Perinci::Sub::GetArgs::Argv.

=item * B<riap_client> => I<obj>

Optional, to perform complete_arg_val to the server.

When the argument spec in the Rinci metadata contains C<completion> key, this
means there is custom completion code for that argument. However, if retrieved
from a remote server, sometimes the C<completion> key no longer contains the code
(it has been cleansed into a string). Moreover, the completion code needs to run
on the server.

If supplied this argument and te C<riap_server_url> argument, the function will
try to request to the server (via Riap request C<complete_arg_val>). Otherwise,
the function will just give up/decline completing.

=item * B<riap_server_url> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<riap_uri> => I<str>

Optional, to perform complete_arg_val to the server.

See the C<riap_client> argument.

=item * B<words>* => I<array[str]>

Command-line arguments.

=back

Return value:  (hash)


You can use C<format_completion> function in L<Complete::Bash> module to format
the result of this function for bash.



=head2 complete_from_schema

Usage:

 complete_from_schema(%args) -> [status, msg, payload, meta]

Complete a value from schema.

Employ some heuristics to complete a value from Sah schema. For example, if
schema is C<< [str =E<gt> in =E<gt> [qw/new open resolved rejected/]] >>, then we can
complete from the C<in> clause. Or for something like C<< [int =E<gt> between =E<gt> [1,
20]] >> we can complete using values from 1 to 20.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>

Must be normalized.

=item * B<word>* => I<str> (default: "")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Complete>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Complete>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Complete>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>, L<Complete::Getopt::Long>

L<Perinci::CmdLine>, L<Perinci::CmdLine::Lite>, L<App::riap>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
