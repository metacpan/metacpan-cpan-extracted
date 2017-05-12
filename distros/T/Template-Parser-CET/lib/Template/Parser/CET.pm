package Template::Parser::CET;

###----------------------------------------------------------------###
#  Copyright 2007 - Paul Seamons                                     #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use vars qw($VERSION $TEMP_VARNAME $ORIG_CONFIG_CLASS $NO_LOAD_EXTRA_VMETHODS);
use strict;
use warnings;
use base qw(Template::Alloy);

use Template::Alloy 1.008;
use Template::Alloy::Operator qw($OP_ASSIGN $OP_DISPATCH);
use Template::Directive;
use Template::Constants;

BEGIN {
    $VERSION = '0.05';

    $TEMP_VARNAME = 'template_parser_cet_temp_varname';
};

###----------------------------------------------------------------###

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{'FACTORY'} ||= 'Template::Directive';

    # This debug section taken nearly verbatim from Template::Parser::new
    # DEBUG config item can be a bitmask
    if (defined (my $debug = $self->{'DEBUG'})) {
        $self->{ DEBUG } = $debug & ( Template::Constants::DEBUG_PARSER
                                    | Template::Constants::DEBUG_FLAGS );
        $self->{ DEBUG_DIRS } = $debug & Template::Constants::DEBUG_DIRS;
    }

    # This factory section is taken nearly verbatim from Template::Parser::new
    if ($self->{'NAMESPACE'}) {
        my $fclass = $self->{'FACTORY'};
        $self->{'FACTORY'} = $fclass->new(NAMESPACE => $self->{'NAMESPACE'} )
            || return $class->error($fclass->error());
    }

    return $self;
}

###----------------------------------------------------------------###
### methods for installing

sub activate {
    require Template::Config;
    if (! $ORIG_CONFIG_CLASS || $ORIG_CONFIG_CLASS ne $Template::Config::PARSER) {
        $ORIG_CONFIG_CLASS = $Template::Config::PARSER;
        $Template::Config::PARSER = __PACKAGE__;
    }
    1;
}

sub deactivate {
    if ($ORIG_CONFIG_CLASS) {
        $Template::Config::PARSER = $ORIG_CONFIG_CLASS;
        $ORIG_CONFIG_CLASS = undef;
    }
    1;
}

sub import {
    my ($class, @args) = @_;
    push @args, 1 if @args % 2;
    my %args = @args;
    $class->activate   if $args{'activate'};
    $class->deactivate if $args{'deactivate'};
    1;
}

###----------------------------------------------------------------###
### parse the document and return a valid compiled Template::Document

sub parse {
    my ($self, $text, $info) = @_;
    my ($tokens, $block);

    eval { require Template::Stash };
    local $Template::Alloy::QR_PRIVATE = $Template::Stash::PRIVATE;
    local $self->{'_debug'}     = defined($info->{'DEBUG'}) ? $info->{'DEBUG'} : $self->{'DEBUG_DIRS'} || undef;
    local $self->{'DEFBLOCK'}   = {};
    local $self->{'METADATA'}   = [];
    local $self->{'_component'} = {
        _content => \$text,
        name     => $info->{'name'},
        modtime  => $info->{'time'},
    };

    ### parse to the AST
    my $tree = eval { $self->parse_tree(\$text) }; # errors die
    if (! $tree) {
        my $err = $@;
        $err->doc($self->{'_component'}) if UNIVERSAL::can($err, 'doc') && ! $err->doc;
        die $err;
    }

    ### take the AST to the doc
    my $doc = $self->{'FACTORY'}->template($self->compile_tree($tree));
#    print $doc;

    return {
        BLOCK     => $doc,
        DEFBLOCKS => $self->{'DEFBLOCK'},
        METADATA  => { @{ $self->{'METADATA'} } },
    };
}

###----------------------------------------------------------------###

### takes a tree of DIRECTIVES
### and returns a TT block
sub compile_tree {
    my ($self, $tree) = @_;

    # node contains (0: DIRECTIVE,
    #                1: start_index,
    #                2: end_index,
    #                3: parsed tag details,
    #                4: sub tree for block types
    #                5: continuation sub trees for sub continuation block types (elsif, else, etc)
    #                6: flag to capture next directive
    my @doc;
    for my $node (@$tree) {

        # text nodes are just the bare text
        if (! ref $node) {
            my $result = $self->{'FACTORY'}->textblock($node);
            push @doc, $result if defined $result;
            next;
        }

        # add debug info
        if ($self->{'_debug'}) {
            my $info = $self->node_info($node);
            my ($file, $line, $text) = @{ $info }{qw(file line text) };
            s/([\'\\])/\\$1/g for $file, $text;
            my $result = $self->{'FACTORY'}->debug([["'msg'"],[["file => '$file'", "line => $line", "text => '$text'"]]]);
            push @doc, $result if defined $result;
        }

        # get method to call
        my $directive = $node->[0];
        $directive = 'FILTER' if $directive eq '|';
        next if $directive eq '#';
        my $method = "compile_$directive";
        my $result = $self->$method($node->[3], $node);
        push @doc, $result if defined $result;
    }

    return $self->{'FACTORY'}->block(\@doc);
}

###----------------------------------------------------------------###

### take arguments parsed in parse_args({named_at_front => 1})
### and turn them into normal TT2 style args
sub compile_named_args {
    my $self = shift;
    my $args = shift;
    my ($named, @positional) = @$args;

    # [[undef, '{}', 'key1', 'val1', 'key2', 'val2'], 0]
    my @named;
    $named = $named->[0];
    my (undef, $op, @the_rest) = @$named;
    while (@the_rest) {
        my $key = shift @the_rest;
        my $val = @the_rest ? $self->compile_expr(shift @the_rest) : 'undef';
        $key = $key->[0] if ref($key) && @$key == 2 && ! ref $key->[0]; # simple keys can be set in place
        if (! ref $key) {
            $key = $self->compile_expr($key);
            push @named, "$key => $val";
        } else {
            ### this really is the way TT does it - pseudo assignment into a hash
            ### with a key that gets thrown away - but "getting" the value assigns into the stash
            ### scary and gross
            push @named, "'_' => ".$self->compile_expr($key, $val);
        }
    }

    return [\@named, (map { $self->compile_expr($_) } @positional)];
}

### takes variables or expressions and translates them
### into the language that compiled TT templates understand
### it will recurse as deep as the expression is deep
### foo                      : 'foo'
### ['foo', 0]               : $stash->get('foo')
### ['foo', 0] = ['bar', 0]  : $stash->set('foo', $stash->get('bar'))
### [[undef, '+', 1, 2], 0]  : do { no warnings; 1 + 2 }
sub compile_expr {
    my ($self, $var, $val, $default) = @_;
    my $ARGS = {};
    my $i    = 0;
    my $return_ref = delete $self->{'_return_ref_ident'}; # set in compile_operator

    ### return literals
    if (! ref $var) {
        if ($val) { # allow for bare literal setting [% 'foo' = 'bar' %]
            $var = [$var, 0];
        } else {
            return $var if $var =~ /^-?[1-9]\d{0,13}(?:|\.0|\.\d{0,13}[1-9])$/; # return unquoted numbers if it is simple
            $var =~ s/\'/\\\'/g;
            return "'$var'";  # return quoted items - if they are simple
        }
    }

    ### determine the top level of this particular variable access
    my @ident;
    my $name = $var->[$i++];
    my $args = $var->[$i++];
    my $use_temp_varname;
    if (ref $name) {
        if (! defined $name->[0]) { # operator
            my $op_val = '('. $self->compile_operator($name) .')';
            return $op_val if $i >= @$var;
            $use_temp_varname = "do {\n  ".$self->{'FACTORY'}->assign(["'$TEMP_VARNAME'", 0], $op_val).";\n  ";
            push @ident, "'$TEMP_VARNAME'";
        } else { # a named variable access (ie via $name.foo)
            push @ident, $self->compile_expr($name);
        }
    } elsif (defined $name) {
        if ($ARGS->{'is_namespace_during_compile'}) {
            #$ref = $self->{'NAMESPACE'}->{$name};
        } else {
            $name =~ s/\'/\\\'/g;
            push @ident, "'$name'";
        }
    } else {
        return '';
    }

    ### add args
    if (! $args) {
        push @ident, 0;
    } else {
        push @ident, ("[" . join(",\n", map { $self->compile_expr($_) } @$args) . "]");
    }

    ### now decent through the other levels
    while ($i < @$var) {
        ### descend one chained level
        my $was_dot_call = $ARGS->{'no_dots'} ? 1 : $var->[$i++] eq '.';
        $name            = $var->[$i++];
        $args            = $var->[$i++];

        if ($was_dot_call) {
            if (ref $name) {
                if (! defined $name->[0]) { # operator
                    push @ident, '('. $self->compile_operator($name) .')';
                } else { # a named variable access (ie via $name.foo)
                    push @ident, $self->compile_expr($name);
                }
            } elsif (defined $name) {
                if ($ARGS->{'is_namespace_during_compile'}) {
                    #$ref = $self->{'NAMESPACE'}->{$name};
                } else {
                    $name =~ s/\'/\\\'/g;
                    push @ident, "'$name'";
                }
            } else {
                return '';
            }

            if (! $args) {
                push @ident, 0;
            } else {
                push @ident, ("[" . join(",\n", map { $self->compile_expr($_) } @$args) . "]");
            }

        # chained filter access
        } else {
            # resolve and cleanup the name
            if (ref $name) {
                if (! defined $name->[0]) { # operator
                    $name = '('. $self->compile_operator($name) .')';
                } else { # a named variable access (ie via $name.foo)
                    $name = $self->compile_expr($name);
                }
            } elsif (defined $name) {
                if ($ARGS->{'is_namespace_during_compile'}) {
                    #$ref = $self->{'NAMESPACE'}->{$name};
                } else {
                    $name =~ s/\'/\\\'/g;
                    $name = "'$name'";
                }
            } else {
                return '';
            }

            # get the ident to operate on
            my $ident;
            if ($use_temp_varname) {
                $ident = $use_temp_varname
                    ."my \$val = ".$self->{'FACTORY'}->ident(\@ident).";\n  "
                    .$self->{'FACTORY'}->assign(["'$TEMP_VARNAME'", 0], 'undef').";\n  "
                    ."\$val; # return of the do\n  }";
            } else {
                $ident = $self->{'FACTORY'}->ident(\@ident);
            }

            # get args ready
            my $filter_args = $args ? [[], map {$self->compile_expr($_)} @$args] : [[]];

            # return the value that is able to run the filter
            my $block = "\$output = $ident;";
            my $filt_val = "do { my \$output = '';\n". $self->{'FACTORY'}->filter([[$name], $filter_args], $block) ." \$output;\n }";
            $use_temp_varname = "do {\n  ".$self->{'FACTORY'}->assign(["'$TEMP_VARNAME'", 0], $filt_val).";\n  ";

            @ident = ("'$TEMP_VARNAME'", 0);
        }
    }

    # handle captures
    if ($self->{'_return_capture_ident'}) {
        die "Can't capture to a variable with filters (@ident)" if $use_temp_varname;
        die "Can't capture to a variable with a set value"      if $val;
        return \@ident;

    # handle refence getting
    } elsif ($return_ref) {
        die "Can't get reference to a variable with filters (@ident)" if $use_temp_varname;
        die "Can't get reference to a variable with a set value"      if $val;
        return $self->{'FACTORY'}->identref(\@ident);

    # handle setting values
    } elsif ($val) {
        return $self->{'FACTORY'}->assign(\@ident, $val, $default);

    # handle inline filters
    } elsif ($use_temp_varname) {
        return $use_temp_varname
            ."my \$val = ".$self->{'FACTORY'}->ident(\@ident).";\n  "
            .$self->{'FACTORY'}->assign(["'$TEMP_VARNAME'", 0], 'undef').";\n  "
            ."\$val; # return of the do\n  }";

    # finally - normal getting
    } else {
        return $self->{'FACTORY'}->ident(\@ident);
    }
}

### plays operators
### [[undef, '+', 1, 2], 0]  : do { no warnings; 1 + 2 }
### unfortunately we had to provide a lot of perl
### here ourselves which means that Jemplate can't
### use this parser directly without overriding this method
sub compile_operator {
    my $self = shift;
    my $args = shift;
    my (undef, $op, @the_rest) = @$args;
    $op = lc $op;

    $op = ($op eq 'mod') ? '%'
        : ($op eq 'pow') ? '**'
        :                  $op;

    if ($op eq '{}') {
        return '{}' if ! @the_rest;
        my $out = "{\n";
        while (@the_rest) {
            my $key = $self->compile_expr(shift @the_rest);
            my $val = @the_rest ? $self->compile_expr(shift @the_rest) : 'undef';
            $out .= "     $key => $val,\n";
        }
        $out .= "}";
        return $out;
    } elsif ($op eq '[]') {
        return "[".join(",\n     ", (map { $self->compile_expr($_) } @the_rest))."]";
    } elsif ($op eq '~' || $op eq '_') {
        return "(''.". join(".\n    ", map { $self->compile_expr($_) } @the_rest).")";
    } elsif ($op eq '=') {
        return $self->compile_expr($the_rest[0], $self->compile_expr($the_rest[1]));

    } elsif ($op eq '++') {
        my $is_postfix = $the_rest[1] || 0; # set to 1 during postfix
        return "do { no warnings;\nmy \$val = 0 + ".$self->compile_expr($the_rest[0]).";\n"
            .$self->compile_expr($the_rest[0], "\$val + 1").";\n"
            ."$is_postfix ? \$val : \$val + 1;\n}";

    } elsif ($op eq '--') {
        my $is_postfix = $the_rest[1] || 0; # set to 1 during postfix
        return "do { no warnings;\nmy \$val = 0 + ".$self->compile_expr($the_rest[0]).";\n"
            .$self->compile_expr($the_rest[0], "\$val - 1").";\n"
            ."$is_postfix ? \$val : \$val - 1;\n}";

    } elsif ($op eq 'div' || $op eq 'DIV') {
        return "do { no warnings;\n int(".$self->compile_expr($the_rest[0])." / ".$self->compile_expr($the_rest[1]).")}";

    } elsif ($op eq '?') {
        return "do { no warnings;\n " .$self->compile_expr($the_rest[0])
            ." ? ".$self->compile_expr($the_rest[1])
            ." : ".$self->compile_expr($the_rest[2])." }";

    } elsif ($op eq '\\') {
        return do { local $self->{'_return_ref_ident'} = 1; $self->compile_expr($the_rest[0]) };

    } elsif ($op eq 'qr') {
        return $the_rest[1] ? "qr{(?$the_rest[1]:$the_rest[0])}" : "qr{$the_rest[0]}";

    } elsif (@the_rest == 1) {
        return $op.$self->compile_expr($the_rest[0]);
    } elsif ($op eq '//' || $op eq 'err') {
        return "do { my \$var = ".$self->compile_expr($the_rest[0])."; defined(\$var) ? \$var : ".$self->compile_expr($the_rest[1])."}";
    } else {
        return "do { no warnings; ".$self->compile_expr($the_rest[0])." $op ".$self->compile_expr($the_rest[1])."}";
    }
}

### takes an already parsed identity
### and strips it of args and outputs a string
### so that the passing mechanism of Template::Directive
### can hand off to set or get which will reparse again - wow and sigh
sub compile_ident_str_from_cet {
    my ($self, $ident) = @_;
    return ''     if ! defined $ident;
    return $ident if ! ref $ident;
    return ''     if ref $ident->[0] || ! defined $ident->[0];

    my $i = 0;
    my $str = $ident->[$i++];
    $i++; # for args;

    while ($i < @$ident) {
        my $dot = $ident->[$i++];
        return $str if $dot ne '.';
        return $str if ref $ident->[$i] || ! defined $ident->[$i];
        $str .= ".". $ident->[$i++];
        $i++; # for args
    }
    return $str;
}

###----------------------------------------------------------------###
### everything in this section are the output of DIRECTIVES - as much as possible we
### try to use the facilities provided by Template::Directive

sub compile_BLOCK {
    my ($self, $name, $node) = @_;
    $self->{'DEFBLOCK'}->{$name} = $self->{'FACTORY'}->template($self->compile_tree($node->[4]));
    return '';
}

sub compile_BREAK { shift->{'FACTORY'}->break }

sub compile_CALL {
    my ($self, $ident) = @_;
    return $self->{'FACTORY'}->call($self->compile_expr($ident));
}

sub compile_CLEAR {
    my $self = shift;
    return $self->{'FACTORY'}->clear;
}

sub compile_COMMENT {}

sub compile_CONFIG {
    my ($self, $config) = @_;

    ### prepare runtime config - not many options get these
    my ($named, @the_rest) = @$config;
    $named = $self->compile_named_args([$named])->[0];
    $named = join ",", @$named;

    ### show what current values are
    my $items = join ",", map { s/\\([\'\$])/$1/g; "'$_'" } @the_rest;

    my $get = $self->{'FACTORY'}->get($self->{'FACTORY'}->ident(["'$TEMP_VARNAME'", 0]));
    return <<EOF;
        do {
            my \$conf = \$context->{'CONFIG'} ||= {};
            my \$newconf = {$named};
            \$conf->{\$_} = \$newconf->{\$_} foreach keys %\$newconf;

            my \@items = ($items);
            if (\@items) {
                my \$str  = join("\n", map { /(^[A-Z]+)\$/ ? ("CONFIG \$_ = ".(defined(\$conf->{\$_}) ? \$conf->{\$_} : 'undef')) : \$_ } \@items);
                \$stash->set(['$TEMP_VARNAME', 0], \$str);
                $get;
                \$stash->set(['$TEMP_VARNAME', 0], '');
            }
        };
EOF
}

sub compile_DEBUG {
    my ($self, $ref) = @_;
    my @options = "'$ref->[0]'";
    if ($ref->[0] eq 'format') {
        my $format = $ref->[1];
        $format =~ s/([\'\\])/\\$1/g;
        push @options, "'$format'";
    } elsif (defined $self->{'_debug'}) { # defined if on at beginning
        if ($ref->[0] eq 'on') {
            $self->{'_debug'} = 1;
        } elsif ($ref->[0] eq 'off') {
            $self->{'_debug'} = 0;
        }
    }
    return $self->{'FACTORY'}->debug([\@options, [[]]]);
}

sub compile_DEFAULT {
    my ($self, $set, $node) = @_;
    return $self->compile_SET($set, $node, 1);
}

sub compile_DUMP {
    my ($self, $dump, $node) = @_;
    my $info = $self->node_info($node);

    ### This would work if the DUMP patch was accepted.  It wasn't because of concerns about the size of the Grammar table
    # return $self->{'FACTORY'}->dump($self->compile_named_args($dump), $info->{'file'}, $info->{'line'}, \$info->{'text'});

    ### so we'll inline the method here

    my $args = $self->compile_named_args($dump);
    my $_file = $info->{'file'};
    my $_line = $info->{'line'};
    my $_text = $info->{'text'};

    # add on named arguments as a final hashref
    my $named = shift @$args;
    push @$args, "{\n        " . join(",\n        ", @$named) . ",\n    },\n" if @$named;

    # prepare arguments to pass to Dumper
    my $_args = (@$args > 1) ? "[\n    ". join(",\n    ", @$args) .",\n    ]" # treat multiple args as a single arrayref to help name align
              : (@$args > 0) ? $args->[0]                                     # treat single item as a single item
              : '$stash';                                                     # treat entire stash as one item

    # find the name of the variables being dumped
    my $is_entire = ! @$args ? 1 : 0;
    my $_name = $is_entire ? 'EntireStash' : $_text;
    $_name =~ s/^.*?\bDUMP\s*//;
    s/\'/\\\'/g for $_name, $_file;

    my $get = $self->{'FACTORY'}->get($self->{'FACTORY'}->ident(["'$TEMP_VARNAME'", 0]));

    return <<EOF;
    do {
        # DUMP
        require Template::Parser::CET;
        \$stash->set(['$TEMP_VARNAME', 0], Template::Parser::CET->play_dump({
            context => \$context,
            file    => '$_file',
            line    => $_line,
            name    => '$_name',
            args    => $_args,
            EntireStash => $is_entire,
        }));
        $get;
        \$stash->set(['$TEMP_VARNAME', 0], '');
    };
EOF

}

sub compile_END { '' }

sub compile_EVAL {
    my ($self, $ref, $node) = @_;
    my ($named, @strs) = @$ref;

    $named = [[]]; # TT doesn't allow args to eval ! $named ? [[]] : [[], map { $self->compile_expr($_) } @$named];

    my $block = "
    foreach my \$str (".join(",\n", map {$self->compile_expr($_)} @strs).") {
        next if ! defined \$str;
        \$output .= \$str; # Alloy does them one at a time
    }";

    $self->{'FACTORY'}->filter([["'eval'"], $named, ''], $block);
}

sub compile_FILTER {
    my ($self, $ref, $node) = @_;
    my ($alias, $filter) = @$ref;

    my ($filt_name, $args) = @$filter; # doesn't support Template::Alloy chained filters

    $args = ! $args ? [[]] : [[], map { $self->compile_expr($_) } @$args];

    $self->{'FACTORY'}->filter([[$self->compile_expr($filt_name)],
                                $args,
                                $self->compile_expr($alias)
                                ],
                               $self->compile_tree($node->[4]));
}

sub compile_FOR { shift->compile_FOREACH(@_) }

sub compile_FOREACH {
    my ($self, $ref, $node) = @_;
    my ($var, $items) = @$ref;
    if ($var) {
        $var = $var->[0];
    }

    $items = $self->compile_expr($items);

    local $self->{'loop_type'} = 'FOREACH';
    return $self->{'FACTORY'}->foreach($var, $items, [[]], $self->compile_tree($node->[4]));
}

sub compile_GET {
    my ($self, $ident) = @_;
    return $self->{'FACTORY'}->get($self->compile_expr($ident));
}

sub compile_IF {
    my ($self, $ref, $node, $unless) = @_;

    my $expr  = $self->compile_expr($ref);
    $expr = "!$expr" if $unless;

    my $block = $self->compile_tree($node->[4]);

    my @elsif;
    my $had_else;
    while ($node = $node->[5]) { # ELSE, ELSIF's
        if ($node->[0] eq 'ELSE') {
            if ($node->[4]) {
                push @elsif, $self->compile_tree($node->[4]);
                $had_else = 1;
            }
            last;
        }
        my $_expr  = $self->compile_expr($node->[3]);
        my $_block = $self->compile_tree($node->[4]);
        push @elsif, [$_expr, $_block];
    }
    push @elsif, undef if ! $had_else;

    return $self->{'FACTORY'}->if($expr, $block, \@elsif);
}

sub compile_INCLUDE {
    my ($self, $ref, $node) = @_;

    my ($named, @files) = @{ $self->compile_named_args($ref) };

    return $self->{'FACTORY'}->include([\@files, [$named]]);
}

sub compile_INSERT {
    my ($self, $ref, $node) = @_;

    my ($named, @files) = @{ $self->compile_named_args($ref) };

    return $self->{'FACTORY'}->insert([\@files, [$named]]);
}

sub compile_LAST {
    my $self = shift;
    my $type = $self->{'loop_type'} || '';
    return "last LOOP;\n" if $type eq 'WHILE' || $type eq 'FOREACH';
    return "last;\n"; # the grammar nicely hard codes the choices
    return "last;\n";
}

sub compile_LOOP {
    my ($self, $ref, $node) = @_;
    $ref = [$ref, 0] if ! ref $ref;

    my $out = "do {
    my \$var = ".$self->compile_expr($ref).";
    if (\$var) {
        my \$conf = \$context->{'CONFIG'} ||= {};
        my \$global = ! \$conf->{'SYNTAX'} || \$conf->{'SYNTAX'} ne 'ht' || \$conf->{'GLOBAL_VARS'};
        my \$items  = ref(\$var) eq 'ARRAY' ? \$var : ref(\$var) eq 'HASH' ? [\$var] : [];
        my \$i = 0;
        for my \$ref (\@\$items) {
            \$context->throw('loop', 'Scalar value used in LOOP') if \$ref && ref(\$ref) ne 'HASH';
            my \$stash = \$global ? \$stash : ref(\$stash)->new;
            \$stash = \$context->localise() if \$global;
            if (\$conf->{'LOOP_CONTEXT_VARS'} && ! \$Template::Stash::PRIVATE) {
                my \%set;
                \@set{qw(__counter__ __first__ __last__ __inner__ __odd__)}
                    = (++\$i, (\$i == 1 ? 1 : 0), (\$i == \@\$items ? 1 : 0), (\$i == 1 || \$i == \@\$items ? 0 : 1), (\$i % 2) ? 1 : 0);
                \$stash->set(\$_, \$set{\$_}) foreach keys %set;
            }
            if (ref(\$ref) eq 'HASH') {
                \$stash->set(\$_, \$ref->{\$_}) foreach keys %\$ref;
            }
".$self->compile_tree($node->[4])."
            \$stash = \$context->delocalise() if \$global;
        }
    }
};";
    return $out;
}

sub compile_MACRO {
    my ($self, $ref, $node) = @_;
    my ($name, $args) = @$ref;

    $name = $self->compile_ident_str_from_cet($name);
    $args = [map {$self->compile_ident_str_from_cet($_)} @$args] if $args;

    ### get the sub tree
    my $sub_tree = $node->[4];
    if (! $sub_tree || ! $sub_tree->[0]) {
        $self->set_variable($name, undef);
        return;
    } elsif (ref($sub_tree->[0]) && $sub_tree->[0]->[0] eq 'BLOCK') {
        $sub_tree = $sub_tree->[0]->[4];
    }

    return $self->{'FACTORY'}->macro($name, $self->compile_tree($sub_tree), $args);
}

sub compile_META {
    my ($self, $hash, $node) = @_;
    push(@{ $self->{'METADATA'} }, %$hash) if $hash;
    return '';
}

sub compile_NEXT {
    my $self = shift;
    my $type = $self->{'loop_type'} || '';
    return $self->{'FACTORY'}->next if $type eq 'FOREACH';
    return "next LOOP;\n" if $type eq 'WHILE';
    return "next;\n";
}

sub compile_PERL {
    my ($self, $ref, $node) = @_;
    my $block = $node->[4] || return '';
    return $self->{'FACTORY'}->no_perl if ! $self->{'EVAL_PERL'};

    return $self->{'FACTORY'}->perl($self->compile_tree($block));
}

sub compile_PROCESS {
    my ($self, $ref, $node) = @_;

    my ($named, @files) = @{ $self->compile_named_args($ref) };

    return $self->{'FACTORY'}->process([\@files, [$named]]);
}

sub compile_RAWPERL {
    my ($self, $ref, $node) = @_;

    return $self->{'FACTORY'}->no_perl if ! $self->{'EVAL_PERL'};

    my $block = $node->[4] || return '';
    my $info  = $self->node_info($node);
    my $txt = '';
    foreach my $chunk (@$block) {
        next if ! defined $chunk;
        if (! ref $chunk) {
            $txt .= $chunk;
            next;
        }
        next if $chunk->[0] eq 'END';
        die "Handling of $chunk->[0] not yet implemented in RAWPERL";
    }

    return $self->{'FACTORY'}->rawperl($txt, $info->{'line'});
}

sub compile_RETURN {
    my $self = shift;
    return $self->{'FACTORY'}->return;
}

sub compile_SET {
    my ($self, $set, $node, $default) = @_;

    my $out = '';
    foreach (@$set) {
        my ($op, $set, $val) = @$_;

        if (! defined $val) { # not defined
            $val = "''";
        } elsif ($node->[4] && $val == $node->[4]) { # a captured directive
            my $sub_tree = $node->[4];
            $sub_tree = $sub_tree->[0]->[4] if $sub_tree->[0] && $sub_tree->[0]->[0] eq 'BLOCK';
            $set = do { local $self->{'_return_capture_ident'} = 1; $self->compile_expr($set) };
            $out .= $self->{'FACTORY'}->capture($set, $self->compile_tree($sub_tree));
            next;
        } else { # normal var
            $val = $self->compile_expr($val);
        }

        if ($OP_DISPATCH->{$op}) {
            $op =~ /^([^\w\s\$]+)=$/ || die "Not sure how to handle that op $op during SET";
            my $short = ($1 eq '_' || $1 eq '~') ? '.' : $1;
            $val = "do { no warnings;\n". $self->compile_expr($set) ." $short $val}";
        }

        $out .= $self->compile_expr($set, $val, $default).";\n";
    }

    return $out;
}

sub compile_STOP {
    my $self = shift;
    return $self->{'FACTORY'}->stop;
}

sub compile_SWITCH {
    my ($self, $var, $node) = @_;

    my $expr = $self->compile_expr($var);
    ### $node->[4] is thrown away

    my @cases;
    my $default;
    while ($node = $node->[5]) { # CASES
        my $var   = $node->[3];
        my $block = $self->compile_tree($node->[4]);
        if (! defined $var) {
            $default = $block;
            next;
        }

        $var = $self->compile_expr($var);
        push @cases, [$var, $block];
    }
    push @cases, $default;

    return $self->{'FACTORY'}->switch($expr, \@cases);
}

sub compile_TAGS { '' } # doesn't really do anything - but needs to be in the parse tree

sub compile_THROW {
    my ($self, $ref) = @_;
    my ($name, $args) = @$ref;

    $name = $self->compile_expr($name);

    $self->{'FACTORY'}->throw([[$name], $self->compile_named_args($args)]);
}

sub compile_TRY {
    my ($self, $foo, $node, $out_ref) = @_;
    my $out = '';

    my $block = $self->compile_tree($node->[4]);

    my @catches;
    my $had_final;
    while ($node = $node->[5]) { # FINAL, CATCHES
        if ($node->[0] eq 'FINAL') {
            if ($node->[4]) {
                $had_final = $self->compile_tree($node->[4]);
            }
            next;
        }
        my $_expr  = defined($node->[3]) && uc($node->[3]) ne 'DEFAULT' ? $node->[3] : ''; #$self->compile_expr($node->[3]);
        my $_block = $self->compile_tree($node->[4]);
        push @catches, [$_expr, $_block];
    }
    push @catches, $had_final;

    return $self->{'FACTORY'}->try($block, \@catches);
}

sub compile_UNLESS {
    return shift->compile_IF(@_);
}

sub compile_USE {
    my ($self, $ref) = @_;
    my ($var, $module, $args) = @$ref;

    $var = $self->compile_expr($var) if defined $var;

    return $self->{'FACTORY'}->use([[$self->compile_expr($module)], $self->compile_named_args($args), $var]);
}

sub compile_VIEW {
    my ($self, $ref, $node) = @_;

    my ($blocks, $args, $viewname) = @$ref;

    $viewname = $self->compile_ident_str_from_cet($viewname);
    $viewname =~ s/\\\'/\'/g;
    $viewname = "'$viewname'";

    my $named = $self->compile_named_args([$args])->[0];

    ### prepare the blocks
    #my $prefix = $hash->{'prefix'} || (ref($name) && @$name == 2 && ! $name->[1] && ! ref($name->[0])) ? "$name->[0]/" : '';
    foreach my $key (keys %$blocks) {
        $blocks->{$key} = $self->{'FACTORY'}->template($self->compile_tree($blocks->{$key})); #{name => "${prefix}${key}", _tree => $blocks->{$key}};
    }

    my $block = $self->compile_tree($node->[4]);
    my $stuff= $self->{'FACTORY'}->view([[$viewname], [$named]], $block, $blocks);
#    print "---------------------\n". $stuff ."------------------------------\n";
    return $stuff;
}

sub compile_WHILE {
    my ($self, $ref, $node) = @_;

    my $expr  = $self->compile_expr($ref);

    local $self->{'loop_type'} = 'WHILE';
    my $block = $self->compile_tree($node->[4]);

    return $self->{'FACTORY'}->while($expr, $block);
}

sub compile_WRAPPER {
    my ($self, $ref, $node) = @_;

    my ($named, @files) = @{ $self->compile_named_args($ref) };

    return $self->{'FACTORY'}->wrapper([\@files, [$named]], $self->compile_tree($node->[4]));
}

###----------------------------------------------------------------###
### Install some CET vmethods that dont' exist in TT2 as of 2.19

if (! $NO_LOAD_EXTRA_VMETHODS
    && eval {require Template::Stash}) {

    for my $meth (qw(0 abs atan2 cos exp fmt hex int js lc log oct rand sin sprintf sqrt uc)) {
        next if defined $Template::Stash::SCALAR_OPS{$meth};
        Template::Stash->define_vmethod('scalar', $meth => $Template::Alloy::SCALAR_OPS->{$meth});
    }

    for my $meth (qw(fmt pick)) {
        next if defined $Template::Stash::LIST_OPS{$meth};
        Template::Stash->define_vmethod('list', $meth => $Template::Alloy::LIST_OPS->{$meth});
    }

    for my $meth (qw(fmt)) {
        next if defined $Template::Stash::HASH_OPS{$meth};
        Template::Stash->define_vmethod('hash', $meth => $Template::Alloy::HASH_OPS->{$meth});
    }
}

sub add_top_level_functions {
    my ($class, $hash) = @_;
    eval {require Template::Stash};
    foreach (keys %{ $Template::Stash::SCALAR_OPS }) {
        next if defined $hash->{$_};
        $hash->{$_} = $Template::Stash::SCALAR_OPS->{$_};
    }
    foreach (keys %{ $Template::Alloy::VOBJS }) {
        next if defined $hash->{$_};
        $hash->{$_} = $Template::Alloy::VOBJS->{$_};
    }
}

###----------------------------------------------------------------###
### handle the playing of the DUMP directive since it the patch wasn't accepted

sub play_dump {
    my ($class, $info) = @_;
    my $context = $info->{'context'} || die "Missing context";

    # find configuration overrides
    my $conf = $context->{'CONFIG'}->{'DUMP'};
    return '' if ! $conf && defined $conf; # DUMP => 0
    $conf = {} if ref $conf ne 'HASH';

    my ($file, $line, $name, $args, $EntireStash) = @{ $info }{qw(file line name args EntireStash)};

    # allow for handler override
    my $handler = $conf->{'handler'};
    if (! $handler) {
        require Data::Dumper;

        # new object and configure it with keys that it understands
        my $obj = Data::Dumper->new([]);
        my $meth;
        foreach my $prop (keys %$conf) {
            $obj->$prop($conf->{$prop}) if $prop =~ /^\w+$/ && ($meth = $obj->can($prop));
        }

        # add in custom Sortkeys handler that can trim out private variables
        my $sort = defined($conf->{'Sortkeys'}) ? $obj->Sortkeys : 1;
        $obj->Sortkeys(sub { my $h = shift; [grep {$_ !~ $Template::Stash::PRIVATE} ($sort ? sort keys %$h : keys %$h)] });

        $handler = sub { $obj->Values([@_]); $obj->Dump }
    }

    # play the handler
    my $out;
    if (! $EntireStash                      # always play if not EntireStash
        || $conf->{'EntireStash'}           # explicitly set
        || ! defined $conf->{'EntireStash'} # default to on
        ) {
        delete $args->{$TEMP_VARNAME} if $EntireStash;
        $out = $handler->($args);
    }
    $out = '' if ! defined $out;

    # show our variable names
    $EntireStash ? $out =~ s/\$VAR1/$name/g : $out =~ s/\$VAR1/$name/;

    # add headers and formatting
    if ($conf->{'html'}                # explicitly html
        || (! defined($conf->{'html'}) # or not explicitly no html
            && $ENV{'REQUEST_METHOD'}  # and looks like a web request
            )) {
        if (defined $out) {
            $out = $context->filter('html')->($out);
            $out = "<pre>$out</pre>";
        }
        $out = "<b>DUMP: File \"$info->{file}\" line $info->{line}</b>$out" if $conf->{'header'} || ! defined $conf->{'header'};
    } else {
        $out = "DUMP: File \"$info->{file}\" line $info->{line}\n    $out" if $conf->{'header'} || ! defined $conf->{'header'};
    }

    return $out;
}

###----------------------------------------------------------------###

1;

__END__

=head1 NAME

Template::Parser::CET - Template::Alloy based parser for the TT2 engine

=head1 SYNOPSIS

    use Template;
    use Template::Parser::CET;

    my $t = Template->new(
        PARSER => Template::Parser::CET->new
    );


    # you can override all instances of TT
    # by any of the following methods
    use Template::Parser::CET activate => 1;

    # OR
    use Template::Parser::CET;
    Template::Parser::CET->activate;

    # OR
    use Template::Config;
    $Template::Config::PARSER = 'Template::Parser::CET';

    my $t = Template->new;

=head1 DESCRIPTION

Template::Parser::CET provides much or most of the TT3 syntax and runs
on the current TT2 engine.

Template::Alloy which was formerly known as CGI::Ex::Template (CET)
provides a fast implementation of TT2 and TT3.  There are some cases
where Template::Toolkit is faster.  There are also some cases where
shops have custom providers, or custom stashes that require the use of
the current TT2 engine.  In these cases, Template::Parser::CET
provides the best of both worlds - offering TT2 AND TT3 syntax and
running on the existing platform making use of all of your current
work (In many cases CET should be able to do this anyway).

This module may eventually be made obsolete when the final real
Template::Toolkit 3 engine by Andy Wardley is released.  But that
would only be a good thing.  If the TT3 engine doesn't provide full
backward compatibility this module will.

CET has provided TT3 features since Spring of 2006 but there has
been little reported uptake.  The TT3 features/extended syntax
are very compelling.  For various reasons people chose not to use CET.
Now people can use TT2 and get the features of TT3 (through CET) today.

Hopefully Template::Parser::CET and Template::Alloy can be used in
the same spirit as Pugs is used for Perl 6.  All of the code from
CET and Template::Parser::CET are free for use in TT3.

=head1 SPEED

All speed is relative and varies tremendously depending upon the size
and content of your template.

Template::Parser::CET generally compiles documents a little faster
than Template::Parser and Template::Grammar. Template::Alloy compiles
documents to its AST (abastract syntax tree) very quickly, but
Template::Paser::CET then has to emit a TT2 style compiled
Template::Document perl document.  So even though Template::Alloy has
a speed advantage, the advantage is lost in Template::Parser::CET.

If you use compiled in memory templates - they will execute as quickly
as the normal TT2 documents.  In all other cases Template::Parser::CET
will prepare the documents at about the same speed (usually a little
faster).

=head1 SYNTAXES

Template::Alloy supports TT2 and TT3.  It also supports Text::Tmpl,
Velocity (VTL), HTML::Template and HTML::Template::Expr.  It is now
possible to run HTML::Template templates on your TT2 engine.

Template::Alloy allows you to use any of the interfaces of any of the
major template engines.  Template::Parser::CET, because it is used
through Template, only supports the Template interface (perl calling
methods).  However by setting the SYNTAX during startup, you can use
templates from the other major engines.

The L<Template::Alloy> documentation will have more examples of using
different syntaxes.

=head2 Template::Toolkit style usage (tt3)

    use Template;
    use Template::Parser::CET;
    Template::Parser::CET->activate;

    my $t = Template->new(SYNTAX => 'tt3');

    # OR
    my $t = Template->new(SYNTAX => 'tt2'); # syntax that is more TT2 friendly

    $t->process(\"[% foo %]", {foo => 'bar'});

=head2 HTML::Template::Expr style usage (hte)

    use Template;
    use Template::Parser::CET;
    Template::Parser::CET->activate;

    my $t = Template->new(SYNTAX => 'hte');

    # or
    my $t = Template->new(SYNTAX => 'ht'); # HTML::Template

    $t->process(\"<TMPL_VAR NAME=foo>", {foo => 'bar'});

=head2 Text::Tmpl style usage (tmpl)

    use Template;
    use Template::Parser::CET;
    Template::Parser::CET->activate;

    my $t = Template->new(SYNTAX => 'tmpl');

    $t->process(\"[% echo $foo %]", {foo => 'bar'});

=head2 Velocity (VTL) style usage

    use Template;
    use Template::Parser::CET;
    Template::Parser::CET->activate;

    my $t = Template->new(SYNTAX => 'velocity');

    $t->process(\"#set($foo 1 + 3) ($foo)");

=head1 FEATURES

So what exactly are the features and syntax that Template::Parser::CET
provides?  The following is a list of most of the features that will
be in TT3 and are in Template::Parser::CET.  All of the listed features
are in addition to those provided natively by Template::Toolkit.

=over 4

=item Grammar

Template::Alloy provides Template::Parser::CET with a recursive
grammar.  This provides a range of benefits including speed, better
error reporting, more consistent syntax, and more possibilities for
extending the grammar.

=item Syntax

As part of the grammar, Template::Parser::CET supports the SYNTAX
configuration item which can be one of tt2 (Template::Toolkit v2), tt3
(Template::Toolkit v3), ht (HTML::Template), hte
(HTML::Template::Expr), tmpl (Text::Tmpl), or velocity (Velocity VTL).
This means you can use any of your templates from any of the major
mini-language based template engines and run them on your stock TT2
engine.

=item Numerical hash keys work

    [% a = {1 => 2} %]

All hash key parsing is a little more sane.  Not entirely more since
CET needs to be backwards compatible.

=item Quoted hash key interpolation is fine

    [% a = {"$foo" => 1} %]

=item Multiple ranges in same array constructor

    [% a = [1..10, 21..30] %]

=item Constructor types can call virtual methods. (TT3)

    [% a = [1..10].reverse %]

    [% "$foo".length %]

    [% 123.length %]   # = 3

    [% 123.4.length %]  # = 5

    [% -123.4.length %] # = -5 ("." binds more tightly than "-")

    [% (a ~ b).length %]

    [% "hi".repeat(3) %] # = hihihi

    [% {a => b}.size %] # = 1

=item The "${" and "}" variable interpolators can contain expressions,
not just variables.

    [% [0..10].${ 1 + 2 } %] # = 4

    [% {ab => 'AB'}.${ 'a' ~ 'b' } %] # = AB

    [% color = qw/Red Blue/; FOR [1..4] ; color.${ loop.index % color.size } ; END %]
      # = RedBlueRedBlue

=item You can use regular expression quoting.

    [% "foo".match( /(F\w+)/i ).0 %] # = foo

    [% a = /a b c . e/xs %]

=item Tags can be nested.

    [% f = "[% (1 + 2) %]" %][% f | eval %] # = 3

=item Reserved names are less reserved.

    [% GET GET %] # gets the variable named "GET"

    [% GET $GET %] # gets the variable who's name is stored in "GET"

=item Pipe "|" can be used anywhere dot "." can be and means to call
the virtual method.

    [% a = {size => "foo"} %][% a.size %] # = foo

    [% a = {size => "foo"} %][% a|size %] # = 1 (size of hash)

=item Added V2PIPE configuration item

Restores the behavior of the pipe operator to be
compatible with TT2.

With V2PIPE = 1

    [% PROCESS a | repeat(2) %] # = value of block or file a repeated twice

With V2PIPE = 0 (default)

    [% PROCESS a | repeat(2) %] # = process block or file named a ~ a

=item Added "fmt" scalar, list, and hash virtual methods which work
similar to the Perl 6 methods.

    [% text.fmt("%s") %]

    [% list.fmt("%s", ", ") %]

    [% hash.fmt("%s => %s", "\n") %]

=item Added "pick" list virtual method which picks a random value.

    [% ["a".."z"].pick(8).join %]

=item Added "rand" text virtual method which gives a random number
between 0 and the item.

    [% 20.rand %]

=item Added "0" text virtual method which returns the
item itself.  This blurs the line between list and text items.

    [% a = "20" %][% a.0 IF a.size %]

=item Added "int" text virtual method which returns
the integer portion of a value.

    [% "2.3343".int %]

=item Whitespace is less meaningful.

    [% 2-1 %] # = 1 (fails in TT2)

=item Added pow operator.

    [% 2 ** 3 %] [% 2 pow 3 %] # = 8 8

=item Added self modifiers (+=, -=, *=, /=, %=, **=, ~=).

    [% a = 2;  a *= 3  ; a %] # = 6
    [% a = 2; (a *= 3) ; a %] # = 66

=item Added pre and post increment and decrement (++ --).

    [% ++a ; ++a %] # = 12
    [% a-- ; a-- %] # = 0-1

=item Added qw// contructor.

    [% a = qw(a b c); a.1 %] # = b

    [% qw/a b c/.2 %] # = c

=item Added regex contructor.

    [% "FOO".match(/(foo)/i).0 %] # = FOO

    [% a = /(foo)/i; "FOO".match(a).0 %] # = FOO

=item Allow for scientific notation. (TT3)

    [% a = 1.2e-20 %]

    [% 123.fmt('%.3e') %] # = 1.230e+02

=item Allow for hexidecimal input.

    [% a = 0xff0000 %][% a %] # = 16711680

    [% a = 0xff2 / 0xd; a.fmt('%x') %] # = 13a

=item Post operative directives can be nested.

Andy Wardley calls this side-by-side effect notation.

    [% one IF two IF three %]

    same as

    [% IF three %][% IF two %][% one %][% END %][% END %]


    [% a = [[1..3], [5..7]] %][% i FOREACH i = j FOREACH j = a %] # = 123567

=item Semi-colons on directives in the same tag are optional.

    [% SET a = 1
       GET a
     %]

    [% FOREACH i = [1 .. 10]
         i
       END %]

Note: a semi-colon is still required in front of any block directive
that can be used as a post-operative directive.

    [% 1 IF 0
       2 %]   # prints 2

    [% 1; IF 0
       2
       END %] # prints 1

=item Added a DUMP directive.

Used for Data::Dumpering the passed variable or expression.

   [% DUMP a.a %] # dumps contents of a.a

   [% DUMP %] # dumps entire stash

The Dumping is configurable via a DUMP configuration item.

=item Added CONFIG directive.

   [% CONFIG
        ANYCASE   => 1
        PRE_CHOMP => '-'
   %]

=item There is better line information

When debug dirs is on, directives on different lines separated
by colons show the line they are on rather than a general line range.

Parse errors actually know what line and character they occured at and
tell you about it.

=back

=head1 USING Template::Parser::CET

There are several ways to get TT to use Template::Parser::CET.

=over 4

=item Pass in object during configuration.

    use Template;
    use Template::Parser::CET;

    my $t = Template->new(
        PARSER => Template::Parser::CET->new(\%config),
    );

=item Override the current program (option 1).

    use Template::Parser::CET activate => 1;

=item Override the current program (option 2).

    use Template::Parser::CET;
    Template::Parser::CET->activate;

You can then deactivate if youy want to use the normal parser
by using:

    Template::Parser::CET->deactivate;

=item Override the current program (option 3).

    use Template::Parser::CET;
    use Template::Config;
    local $Template::Config::PARSER = 'Template:Parser::CET';

=item Override all default instances.

    Modify the $PARSER value in Template/Config.pm
    to be 'Template::Parser::CET' rather than 'Template::Parser'.

=back

=head1 DOCUMENTATION

Template::Toolkit and Template::Alloy already cover everything that
would be covered here.  If you are running Template::Parser::CET then
you already have both Template::Toolkit and Template::Alloy installed.
Please refer to their documentation for complete configuration and
syntax examples.

For any of the items in the FEATURES section you will need to refer to
the Template::Alloy documentation.

=head1 BUGS / TODO

=over 4

=item

Template::Parser::CET is as non-invasive as it can be.  It does no
modification to the existing TT2 install.  In order to provide features
such as inline filters, self modifying operators, pre and post decrement
and increment, and CONFIG and DUMP directive support, the abstraction
to Template::Directive was broken.  This means that projects such as
Jemplate can't use these extended features directly (but projects such
as Jemplate could write faster smaller templates if they used Template::Alloy's
compiled AST directly).

=item

Cleanup compiled document output.

=item

Add more line numbers to the compiled output.

=item

Actually add the VObjects to the compile phase to get the
compile time speed benefit.

=item

Override filter generation code to allow for fall back
to the SCALAR_OPS methods if a filter can't be found
by the passed name.

=back

=head1 TT2 SYNTAX THAT WILL BREAK

=over 4

=item Pipe (FILTER alias) operators in ambiguous places.

Under TT2 the following line:

    [% BLOCK a %]b is [% b %][% END %][% PROCESS a b => 234 | repeat(2) %]

Would print:

    b is 234b is 234

Under CET and TT3 that line will print

    b is 234234

This is because the "|" has been used to allow for filter operations
to be used inline on variables and also to call vmethods.

The configuration option V2PIPE can be used to restore the old behavior.
When V2PIPE is set to true (default is false), then CET will parse the
block the same as TT2.  When false it will parse the same as CET or TT3.

You can use the CONFIG directive to set the option around some chunks
of code that use the old syntax.

    [% CONFIG V2PIPE 1 -%]
    [% BLOCK a %]b is [% b %][% END %][% PROCESS a b => 234 | repeat(2) %]
    [%- CONFIG V2PIPE 0 %]

Would print

    b is 234b is 234


=item Inline comments that end with the tag and not a newline.

Because of the way the TT2 engine matches tags, the following
works in TT2:

    [% a # GET THE value of a %]

Because CET is recursive in nature, the closing tag has not
been matched by the time the comment is removed.  You will get
a parse error saying not sure how to handle the tag.

Simply change the previous example to the following:

    [% a # GET THE value of a
    %]

All other commenting constructs parse just fine.

=item The qw variable parse error

If your template had a variable named qw - there will most likely be
a parse error.

In TT2 there was no qw() construct but there is in CET and TT3.

    [% a = qw %]          Works fine in TT2 but is a parse error in TT3
    [% a = qw(Foo Bar) %] Works fine in TT3 but is a parse error in TT2

=back

=head1 TT2 TESTS THAT FAIL

The following is a list of tests that will fail as of the
TT2.19 test suite.  All of the failed tests are caused by behavior
that will be obsoleted by TT3.

=over 4

=item t/compile3.t - Fails 1 test

Both CET and TT2 return the same error - but the error isn't formatted the same.

=item t/debug.t - Fails 1 test

CET debugs INTERPOLATED GETS - TT2 doesn't.  There is an INTERPOLATED value that TT2 doesn't debug.

=item t/fileline.t - Fails 4 tests

CET is warn clean - even when performing numeric operations on non-numeric data - TT2 isn't and is testing for warnings.

=item t/filter.t - Fails 1 test

CET parses { 1 2 3 } as a hashref just fine - TT2 doesn't and expects an error.

=item t/vars.t - Fails 8 tests (4 really, but parsing is failing)

TT2 is allowing inline comments with closing tag on the same line.
CET is recursive, the closing tag isn't matched before the closing tag -
changing the closing tag to be on a separate line fixes the issue.

=back

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
