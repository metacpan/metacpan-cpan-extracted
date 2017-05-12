package Seis::Compiler;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Perl6::PVIP 0.07;
use Carp ();
use Data::Dumper ();
use Encode ();
use Seis::Runtime;

use constant {
    G_VOID => 1,
    G_SCALAR => 2,
    G_ARRAY  => 3,
};

# `no warnings 'misc'` suppress `"our" variable $x redeclared` message
# in `our $x; { my $x; { our $x}}`
our $HEADER = <<'...';
package # Hide from PAUSE
    Main;
use strict;
use 5.018_000;
use utf8;
no warnings "experimental::smartmatch";
no warnings "experimental::lexical_subs";
use feature "lexical_subs";
use Seis::Autobox;
use List::Util qw(min max);
use Seis::Runtime;
use POSIX qw(floor);
no warnings 'misc', 'void';
BEGIN {
    *gcd = *Seis::BuiltinFunctions::gcd;
    *Int = *Seis::Runtime::Int;
    *Mu = *Seis::Runtime::Mu;
    *Array = *Seis::Runtime::Array;
    *True = *Bool::True;
}

...

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub compile {
    my ($self, $src, $filename) = @_;
    $filename //= '-e';
    local $self->{filename} = $filename;
    local $self->{line_number} = 0;
    my $parser = Perl6::PVIP->new();
    my $node = $parser->parse_string($src)
        or Seis::Exception::ParsingError->throw("Can't parse $filename:\n"  . $parser->errstr);
    return join('',
        $HEADER,
        qq{#line 1 "$filename"\n},
        $self->do_compile($node)
    );
}

sub do_compile {
    my ($self, $node, $gimme) = @_;
    $gimme //= G_SCALAR;
    Carp::confess "Invalid node" unless ref $node;

    my $v = $node->value;
    my $type = $node->type;

    if ($type == PVIP_NODE_STATEMENTS) {
        my $ret;
        for (my $i=0; $i<@$v; $i++) {
            next if $v->[$i]->type == PVIP_NODE_NOP;
            # $ret .= sprintf("# NODE:%d SELF:%d\n", $v->[$i]->line_number, $self->{line_number});
            while ($self->{line_number} < $v->[$i]->line_number) {
                $ret .= "\n";
                $self->{line_number}++;
            }
            my $stmt = $self->do_compile($v->[$i], $i==@$v-1 ? G_SCALAR : G_VOID);
            if ($stmt =~ /\n\z/ && $i!=@$v-1) {
                $ret .= $stmt;
            } else {
                $ret .= "$stmt;\n";
                $self->{line_number}++;
            }
        }
        $ret;
    } elsif ($type == PVIP_NODE_UNDEF) {
        undef;
    } elsif ($type == PVIP_NODE_RANGE) {
        if ($gimme == G_ARRAY) {
            $self->do_compile($v->[0]) . '..' . $self->do_compile($v->[1]);
        } else {
            '[' . $self->do_compile($v->[0]) . '..' . $self->do_compile($v->[1]) .']';
        }
    } elsif ($type == PVIP_NODE_REDUCE) {
        my $body;
        if ($v->[0]->value =~ /[a-z]/) {
            $body = sprintf '$seis_reduce_ret = %s($seis_reduce_ret, $seis_reduce_stuff)', $v->[0]->value;
        } else {
            $body = sprintf '$seis_reduce_ret %s= $seis_reduce_stuff', $v->[0]->value;
        }
        # XXX I should care the other cases?
        my $initial = $v->[0]->value eq '*' ? 1 : 0;
        sprintf('do { my @seis_reduce_ary = %s; my $seis_reduce_ret = @seis_reduce_ary==0 ? %s : shift @seis_reduce_ary; for my $seis_reduce_stuff (@seis_reduce_ary) { %s } $seis_reduce_ret; }', $self->do_compile($v->[1], G_ARRAY), $initial, $body);
    } elsif ($type == PVIP_NODE_INT) {
        $node->value;
    } elsif ($type == PVIP_NODE_NUMBER) {
        $node->value;
    } elsif ($type == PVIP_NODE_DIV) {
        '(' . $self->do_compile($v->[0]) . ')/(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_MUL) {
        '(' . $self->do_compile($v->[0]) . ')*(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_ADD) {
        '(' . $self->do_compile($v->[0]) . ')+(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_SUB) {
        '(' . $self->do_compile($v->[0]) . ')-(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_IDENT) {
        if ($v eq '::Array') {
            'Seis::Class->_new(name => "Array")'
        } elsif ($v eq 'self') {
            '$self'
        } elsif ($v eq '::Hash') {
            'Seis::Class->_new(name => "Hash")'
        } elsif ($v eq 'Buf') {
            'Buf::'
        } elsif ($v eq 'Exception') {
            'Seis::Class->_new(name => "Exception")'
        } elsif ($v eq 'Real') {
            'Seis::Real::'
        } elsif ($v eq 'Duration') {
            'Seis::Duration::'
        } elsif ($v eq 'Pair') {
            'Pair::'
        } elsif ($v eq 'Instant') {
            'Seis::Instant::'
        } elsif ($v eq 'IO::Handle') {
            'IO::Handle::'
        } elsif ($v eq 'Bool::False') {
            'Bool::False()'
        } elsif ($v eq 'Bool::True') {
            'Bool::True()'
        } elsif ($v eq 'True') {
            'Bool::True()'
        } elsif ($v eq 'False') {
            'Bool::False()'
        } elsif ($v eq 'IO::Path::Cygwin') {
            'IO::Path::Cygwin::'
        } else {
            $v;
        }
    } elsif ($type == PVIP_NODE_FUNCALL) {
        if ($v->[0]->type == PVIP_NODE_IDENT) {
            # builtin functions
            if ($v->[0]->value eq 'shift' || $v->[0]->value eq 'pop') {
                # shift(@array)
                local $self->{args_list} = 1;
                sprintf('%s(%s)',
                    $self->do_compile($v->[0]),
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'elems') {
                # TODO You may optimize this function... elems(3) can be caluculate while compilation time.
                sprintf('Seis::Runtime::builtin_elems(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'eval') {
                my $is_perl5 = do {
                    my @args = @{$v->[1]->value};
                    if (@args==2) {
                        my $pair = $args[1];
                        if (
                            $pair->type == PVIP_NODE_PAIR
                            && $pair->value->[0]->value eq 'lang'
                            && $pair->value->[1]->value eq 'perl5'
                        ) {
                            1;
                        }
                    } else {
                        0;
                    }
                };
                if ($is_perl5) {
                    sprintf('CORE::eval(%s)',
                        $self->do_compile($v->[1]->value->[0]),
                    );
                } else {
                    join('',
                        'do {',
                        'my $__rg_compiler = Seis::Compiler->new();',
                        'my $__rg_compiled = $__rg_compiler->compile(',
                        $self->do_compile($v->[1]),
                        ');',
                        'my $__rg_ret = eval $__rg_compiled;',
                        'if ($@) {',
                            'Seis::Exception::CompilationFailed->throw("$@");',
                        '}',
                        '$__rg_ret;}',
                    );
                }
            } elsif ($v->[0]->value eq 'now') {
                'Seis::BuiltinFunctions::now()';
            } elsif ($v->[0]->value eq 'kv') {
                sprintf('(%s)->kv',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'list') {
                sprintf('List->new(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'copy') {
                sprintf('Seis::BuiltinFunctions::copy(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'reduce') {
                sprintf('Seis::BuiltinFunctions::reduce(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'gcd') {
                sprintf('Seis::BuiltinFunctions::gcd(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'chdir') {
                if (@{$v->[1]->value} == 0) {
                    Seis::Exception::CompilationFailed->throw(
                        'You need pass 1 argument for chdir function'
                    );
                }
                sprintf('CORE::chdir(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'connect') {
                sprintf('Seis::BuiltinFunctions::connect(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'any') {
                sprintf('Seis::BuiltinFunctions::any(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'get') {
                sprintf('Seis::BuiltinFunctions::get(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'sign') {
                sprintf('(%s)->sign',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'ords') {
                sprintf('Seis::BuiltinFunctions::ords(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'is-prime') {
                sprintf('Seis::BuiltinFunctions::is_prime(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'open') {
                sprintf('Seis::BuiltinFunctions::open(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'end') {
                # TODO support the 'list' style.
                sprintf('Seis::BuiltinFunctions::end(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'lines') {
                sprintf('Str::lines(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'slurp') {
                sprintf('Seis::BuiltinFunctions::slurp(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'hash') {
                sprintf('+{%s}',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'push') {
                # (funcall (ident "push") (args (variable "@a") (string "e")))
                if (
                    $v->[1]->type == PVIP_NODE_ARGS && @{$v->[1]->value}==2 && $v->[1]->value->[0]->type == PVIP_NODE_VARIABLE && $v->[1]->value->[0]->value =~ /\A\@/) {
                    sprintf('CORE::push(%s,%s)',
                        $self->do_compile($v->[1]->value->[0], G_ARRAY),
                        $self->do_compile($v->[1]->value->[1]),
                    );
                } else {
                    sprintf('CORE::push(%s)',
                        $self->do_compile($v->[1]),
                    );
                }
            } elsif ($v->[0]->value eq 'values') {
                # (args (variable "@array"))
                if (
                    $v->[1]->type == PVIP_NODE_ARGS && @{$v->[1]->value}==1 && $v->[1]->value->[0]->type == PVIP_NODE_VARIABLE && $v->[1]->value->[0]->value =~ /\A\@/) {
                    # values(@a)
                    if ($gimme == G_ARRAY) {
                        sprintf('CORE::values(%s)',
                            $self->do_compile($v->[1]->value->[0], G_ARRAY),
                        );
                    } else {
                        sprintf('[CORE::values(%s)]',
                            $self->do_compile($v->[1]->value->[0], G_ARRAY),
                        );
                    }
                } else {
                    sprintf('CORE::values(%s)',
                        $self->do_compile($v->[1]),
                    );
                }
            } elsif ($v->[0]->value eq 'keys') {
                # (args (variable "@array"))
                if (
                    $v->[1]->type == PVIP_NODE_ARGS && @{$v->[1]->value}==1 && $v->[1]->value->[0]->type == PVIP_NODE_VARIABLE && $v->[1]->value->[0]->value =~ /\A\@/) {
                    # keys(@a)
                    if ($gimme == G_ARRAY) {
                        sprintf('CORE::keys(%s)',
                            $self->do_compile($v->[1]->value->[0], G_ARRAY),
                        );
                    } else {
                        sprintf('[CORE::keys(%s)]',
                            $self->do_compile($v->[1]->value->[0], G_ARRAY),
                        );
                    }
                } else {
                    sprintf('CORE::keys(%s)',
                        $self->do_compile($v->[1]),
                    );
                }
            } elsif ($v->[0]->value eq 'getc') {
                sprintf('Seis::BuiltinFunctions::getc(%s)',
                    $self->do_compile($v->[1]),
                );
            } elsif ($v->[0]->value eq 'close') {
                sprintf('Seis::BuiltinFunctions::close(%s)',
                    $self->do_compile($v->[1]),
                );
            } else {
                sprintf('%s(%s)',
                    $self->do_compile($v->[0]),
                    $self->do_compile($v->[1]),
                );
            }
        } else {
            sprintf('(%s)->(%s)',
                $self->do_compile($v->[0]),
                $self->do_compile($v->[1]),
            );
        }
    } elsif ($type == PVIP_NODE_ARGS) {
        my @args = map {
            if ($_->type == PVIP_NODE_IDENT && $_->value eq 'Hash') {
                'Seis::Hash::'
            } elsif ($_->type == PVIP_NODE_IDENT && $_->value eq 'Array') {
                'Array::'
            } elsif ($_->type == PVIP_NODE_IDENT && $_->value eq 'IO::Path') {
                'IO::Path::'
            } elsif ($_->type == PVIP_NODE_IDENT && $_->value eq 'True') {
                'Bool::True()'
            } elsif ($_->type == PVIP_NODE_IDENT && $_->value eq 'False') {
                'Bool::False()'
            } elsif ($_->type == PVIP_NODE_IDENT) {
                my $v = $_->value;
                $v =~ s/\A:://;
                sprintf('Seis::Class->_new(name => %s)', $self->compile_string($v));
            } elsif ($_->type == PVIP_NODE_VARIABLE && $_->value =~ /\A\@/) {
                my $v = $_->value;
                $v =~ s/−/ー/g;
                "\\$v";
            } else {
                $self->do_compile($_)
            }
        } @$v;
        if ($self->{args_list}) {
            join(",", map { "$_" } @args);
        } else {
            join(",", map { "scalar($_)" } @args);
        }
    } elsif ($type == PVIP_NODE_STRING) {
        $self->compile_string($v);
    } elsif ($type == PVIP_NODE_MOD) {
        sprintf('(%s)%%(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_VARIABLE) {
        $v =~ s!-!ー!g;
        $v;
    } elsif ($type == PVIP_NODE_MY) {
        if (@$v==1) {
            # (my (list (variable "$a") (variable "$b") (variable "$c")))
            if ($v->[0]->type == PVIP_NODE_LIST) {
                sprintf('my (%s)',
                    join(',', map { $self->do_compile($_) } @{$v->[0]->value})
                );
            } else {
                die "NYI: (1)" . $node->as_sexp
            }
        } else {
            my ($type, $vars) = @$v;
            if ($vars->type == PVIP_NODE_VARIABLE) {
                # (my (nop) (variable "$i"))
                sprintf('my %s',
                    $self->do_compile($vars)
                );
            } elsif ($vars->type == PVIP_NODE_FUNC) {
                # (my (nop) (func (ident "vtest") (params (param (nop) (variable "$cmp") (nop)) (param (vargs (variable "@v")))) (nop) (block (statements (list_assignment (my (nop) (variable "$x")) (funcall (ident "shift") (args (variable "@v")))) (while (variable "@v") (block (statements (list_assignment (my (nop) (variable "$y")) (funcall (ident "shift") (args (variable "@v")))) (funcall (ident "is") (args (cmp (methodcall (ident "Version") (ident "new") (args (variable "$x"))) (methodcall (ident "Version") (ident "new") (args (variable "$y")))) (variable "$cmp") (string_concat (string_concat (string_concat (string_concat (string_concat (string "") (variable "$x")) (string " cmp ")) (variable "$y")) (string " is ")) (variable "$cmp")))) (list_assignment (variable "$x") (variable "$y")))))))))
                sprintf('my %s', $self->do_compile($vars));
            } elsif ($vars->type == PVIP_NODE_LIST) {
                # my ($a, $b);
                sprintf('my %s', $self->do_compile($vars, G_ARRAY));
            } else {
                die "NYI: " . $node->as_sexp
            }
        }
    } elsif ($type == PVIP_NODE_OUR) {
        my @vars = map { $self->do_compile($_) } @$v;
        sprintf('our (%s)',
            join(',', map { "($_)" } @vars)
        );
    } elsif ($type == PVIP_NODE_BIND) {
        # TODO: This may not compatible with Perl6.
        sprintf('%s=(%s)',
            $self->do_compile($v->[0], G_ARRAY),
            $self->do_compile($v->[1], G_ARRAY),
        );
    } elsif ($type == PVIP_NODE_LIST_ASSIGNMENT) {
        sprintf('%s=(%s)',
            $self->do_compile($v->[0], G_ARRAY),
            $self->do_compile($v->[1],
                $self->is_list_lvalue($v->[0]) ? G_ARRAY : G_SCALAR
            ),
        );
    } elsif ($type == PVIP_NODE_STRING_CONCAT) {
        sprintf('(%s).(%s)',
            $v->[0]->type == PVIP_NODE_STATEMENTS ? $self->do_compile($v->[0]->value->[0]) : $self->do_compile($v->[0]),
            $v->[1]->type == PVIP_NODE_STATEMENTS ? $self->do_compile($v->[1]->value->[0]) : $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_IF) {
        # (if (int 1) (statements (int 5)) (else (int 4)))
        my $ret = 'if (' . $self->do_compile($v->[0]) . ') {' . $self->do_compile($v->[1]) . '}';
        shift @$v; shift @$v;
        while (@$v) {
            $ret .= $self->do_compile(shift @$v);
        }
        $ret;
    } elsif ($type == PVIP_NODE_EQV) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_EQV is not implemented")
    } elsif ($type == PVIP_NODE_ARRAY) {
        sprintf('[%s]',
            join(',', map { "($_)" } map { $self->do_compile($_, G_ARRAY) } @$v)
        );
    } elsif ($type == PVIP_NODE_ATPOS) {
        my $invocant = $self->do_compile($v->[0]);
        my $pos = $self->do_compile($v->[1]);
        if (
            ($v->[0]->type == PVIP_NODE_VARIABLE && $v->[0]->value =~ /\A@/)
        ) {
            # @a[0]
            sprintf('%s[(%s)]',
                $invocant,
                $pos,
            );
        } else {
            # $a[0]
            sprintf('(%s)->[(%s)]',
                $invocant,
                $pos,
            );
        }
    } elsif ($type == PVIP_NODE_METHODCALL) {
        my $invocant = $self->do_compile($v->[0]);
        if ($v->[0]->type != PVIP_NODE_IDENT) {
            $invocant = "($invocant)";
        }

        my $method = $self->do_compile($v->[1]);
        my $params = defined($v->[2]) ? $self->do_compile($v->[2]) : '';

        $method =~ s!-!ー!g;

        if ($v->[0]->type == PVIP_NODE_WHATEVER) {
            return sprintf('(sub { shift->%s(%s) })',
                $method,
                $params
            );
        }

        if ($v->[1]->type == PVIP_NODE_STRING || $v->[1]->type == PVIP_NODE_STRING_CONCAT) {
            sprintf('%s->${\(%s)}(%s)',
                $invocant,
                $method,
                $params,
            );
        } else {
            sprintf('%s->%s(%s)',
                $invocant,
                $method,
                $params,
            );
        }
    } elsif ($type == PVIP_NODE_FUNC) {
        my $name = $self->do_compile($v->[0]);
        my $exportable = $v->[2]->type == PVIP_NODE_EXPORT;

        my $ret = '';
        $ret .= "sub $name {";
        $ret .= "\n"; $self->{line_number}++;
        $ret .= $self->do_compile($v->[1]);
        $ret .= $self->do_compile($v->[3]);
        $ret .= "}\n"; $self->{line_number}++;
        if ($exportable) {
            $ret .= sprintf("push \@__RG_EXPORT, %s;", $self->compile_string($name));
        }
        $ret;
    } elsif ($type == PVIP_NODE_PARAMS) {
        # (params (param (nop) (variable "$n") (nop)))
        # (params (param (ident "Int") (variable "$n") (nop) (int 0)))
        my $ret = '';
        my $is_vargs = 0;
        my $min_args = 0;
        my $max_args = 0;
        for my $param (@$v) {
            $ret .= $self->do_compile($param) . ";";
            if ($param->value->[1]->type == PVIP_NODE_VARGS) {
                $is_vargs++;
            } else {
                if ($param->value->[2] == PVIP_NODE_NOP) {
                    # no default value.
                    $min_args++;
                    $max_args++;
                } else {
                    # has default value.
                    $max_args++;
                }
                if ($param->value->[0]->type == PVIP_NODE_IDENT) {
                    my $type = $self->compile_string($param->value->[0]->value);
                    $ret .= sprintf('Seis::Exception::ArgumentType->throw("invalid argument type(expected %s)") unless %s->isa(%s);', $param->value->[0]->value, $param->value->[1]->value, $type);
                }
            }
        }
        unless ($is_vargs) {
            $ret .= sprintf('Seis::Exception::ArgumentCount->throw("Invalid argument count(Expected %d to %d but " . (0+@_) . ")") unless %d <= @_ && @_<=%d;', $min_args, $max_args, $min_args, $max_args);
        }
        $ret .= "undef;";
    } elsif ($type == PVIP_NODE_PARAM) {
        # (params (param (nop) (variable "$n") (nop)))
        # (param (nop) (vargs (variable "@a")) (nop) (int 0))
        if (@$v==4) {
            if ($v->[1]->type == PVIP_NODE_VARGS) {
                sprintf('%s;', $self->do_compile($v->[1]));
            } elsif ($v->[1]->value =~ /\A\@/) {
                # (param (ident "Int") (variable "$x") (nop))
                sprintf('my %s=@_;', $self->do_compile($v->[1]));
            } else {
                sprintf('my %s=shift;', $self->do_compile($v->[1]));
            }
        } else {
            die "Should not reach here : " . $node->as_sexp;
        }
    } elsif ($type == PVIP_NODE_RETURN) {
        'return (' . join(',', map { "($_)" } map {$self->do_compile($_)} @$v) . ')';
    } elsif ($type == PVIP_NODE_ELSE) {
        'else { ' . join(';', map { $self->do_compile($_) } @$v) . '}';
    } elsif ($type == PVIP_NODE_WHILE) {
        sprintf("while (%s) %s",
            $self->do_compile($v->[0]),
            $self->maybe_block($v->[1]));
    } elsif ($type == PVIP_NODE_UNTIL) {
        sprintf("until (%s) %s",
            $self->do_compile($v->[0]),
            $self->maybe_block($v->[1]));
    } elsif ($type == PVIP_NODE_DIE) {
        sprintf('die (%s)', $self->do_compile($v->[0]));
    } elsif ($type == PVIP_NODE_ELSIF) {
        sprintf('elsif (%s) { %s }', $self->do_compile($v->[0]), $self->do_compile($v->[1]));
    } elsif ($type == PVIP_NODE_NOW) {
        'Seis::BuiltinFunctions::now()'
    } elsif ($type == PVIP_NODE_RAND) {
        'rand()'
    } elsif ($type == PVIP_NODE_TIME) {
        'time()'
    } elsif ($type == PVIP_NODE_LIST) {
        if ($gimme == G_SCALAR) {
            # In scalar context, create arrayref automatically.
            sprintf('[%s]',
                join(',', map { "($_)" } map { $self->do_compile($_) } @$v)
            );
        } else {
            sprintf('(%s)',
                join(',', map { "($_)" } map { $self->do_compile($_, G_ARRAY) } @$v)
            );
        }
    } elsif ($type == PVIP_NODE_FOR) {
        my $iteratee = $self->do_compile($v->[0], G_ARRAY);
        if ($v->[1]->type == PVIP_NODE_LAMBDA) {
            # (for (list (int 1) (int 2) (int 3)) (lambda (params (param (nop) (variable "$x") (nop))) (statements (inplace_add (variable "$i") (variable "$x")))))
            # (for (variable "@list") (lambda (params) (block (statements (funcall (ident "isnt") (args (variable "$_") (string "a") (string "$_ does not get set implicitly if a pointy is given")))))))
            my $varname = $v->[1]->value->[0]->value->[0]->value->[1]->value;
            sprintf('for my %s (%s) %s',
                $varname,
                $iteratee,
                $self->maybe_block($v->[1]->value->[1])
            );
        } else {
            sprintf('for (%s) %s',
                $iteratee,
                $self->maybe_block($v->[1])
            );
        }
    } elsif ($type == PVIP_NODE_UNLESS) {
        my $ret = 'unless (' . $self->do_compile($v->[0]) . ') {' . $self->do_compile($v->[1]) . '}';
        shift @$v; shift @$v;
        while (@$v) {
            $ret .= $self->do_compile(shift @$v);
        }
        $ret;
    } elsif ($type == PVIP_NODE_NOT) {
        if ($self->is_array_variable($v->[0])) {
            sprintf('!(0+%s)',
                $self->do_compile($v->[0]->value)
            );
        } else {
            # I want to do this with PL_check hack.
            sprintf('Seis::Runtime::_not(%s)',
                $self->do_compile($v->[0])
            );
        }
    } elsif ($type == PVIP_NODE_CONDITIONAL) {
        sprintf('(%s)?(%s):(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
            $self->do_compile($v->[2]),
        );
    } elsif ($type == PVIP_NODE_NOP) {
        return "()";
    } elsif ($type == PVIP_NODE_POW) {
        sprintf('(%s)**(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_CLARGS) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_CLARGS is not implemented")
    } elsif ($type == PVIP_NODE_HASH) {
        if ($gimme == G_ARRAY) {
            '(' .  join(',', map { $self->do_compile($_, G_ARRAY) } @$v) . ')';
        } else {
            '{' . join(',', map { $self->do_compile($_, G_ARRAY) } @$v) . '}';
        }
    } elsif ($type == PVIP_NODE_PAIR) {
        if ($gimme == G_SCALAR) {
            sprintf('Pair->_new(scalar(%s),scalar(%s))',
                $v->[0]->type == PVIP_NODE_IDENT ? $self->compile_string($v->[0]) : $self->do_compile($v->[0]),
                $self->do_compile($v->[1]),
            );
        } else {
            my $key = $v->[0]->type == PVIP_NODE_IDENT
                ? $self->compile_string($v->[0]->value)
                : $self->do_compile($v->[0]);
            sprintf('(%s)=>scalar(%s)',
                $key,
                $self->do_compile($v->[1]),
            );
        }
    } elsif ($type == PVIP_NODE_ATKEY) {
        if ($v->[0]->type == PVIP_NODE_VARIABLE && $v->[0]->value =~ /\A%/) {
            my $target = $self->do_compile($v->[0]);
            $target =~ s/\A%/\$/;
            sprintf('%s{(%s)}',
                $target,
                $self->do_compile($v->[1]),
            );
        } elsif ($v->[0]->type == PVIP_NODE_VARIABLE && $v->[0]->value =~ /\A\$/) {
            sprintf('(%s)->{(%s)}',
                $self->do_compile($v->[0]),
                $self->do_compile($v->[1]),
            );
        } elsif ($v->[0]->type == PVIP_NODE_TW_ENV || ($v->[0]->type == PVIP_NODE_VARIABLE && $v->[0]->value =~ /\A$/)) {
            sprintf('(%s)->{(%s)}',
                $self->do_compile($v->[0]),
                $self->do_compile($v->[1]),
            );
        } else {
            sprintf('(%s){(%s)}',
                $self->do_compile($v->[0]),
                $self->do_compile($v->[1]),
            );
        }
    } elsif ($type == PVIP_NODE_LOGICAL_AND) {
        sprintf('(%s)&&(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_LOGICAL_OR) {
        sprintf('(%s)||(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_LOGICAL_XOR) {
        sprintf('do { my $a = (%s); my $b = (%s); if ($a) { $b ? !!0 : $a } else { $b ? $b : !!0 } }',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BIN_AND) {
        sprintf('(%s)&(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BIN_OR) {
        sprintf('(%s)|(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BIN_XOR) {
        sprintf('(%s)^(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BLOCK) {
        my $ret = '';
        # $ret .= sprintf("# %d %d\n", $node->line_number, $self->{line_number});
        if (@$v) {
            $ret .= '{' . $self->do_compile($v->[0]) . '}';
        } else {
            $ret .= '{ }';
        }
        $ret;
    } elsif ($type == PVIP_NODE_LAMBDA) {
        # (lambda (params (param (nop) (variable "$n") (nop))) (statements (mul (variable "$n") (int 2))))
        # (lambda (block (statements (logical_or (chain (mod (variable "$_") (int 3)) (eq (int 0))) (chain (mod (variable "$_") (int 5)) (eq (int 0)))))))
        if (@$v==1) {
            if ($v->[0]->type == PVIP_NODE_BLOCK) {
                my $ret = 'sub ';
                $ret .= $self->do_compile($v->[0]);
                $ret;
            } elsif ($v->[0]->type == PVIP_NODE_HASH) {
                # (lambda (hash (pair (ident "out") (string "(IO)\n"))))
                my $ret = 'sub ';
                $ret .= $self->do_compile($v->[0]);
                $ret;
            } else {
                ...
            }
        } else {
            my $ret = 'sub {';
            $ret .= $self->do_compile($v->[0]);
            $ret .= $self->do_compile($v->[1]);
            $ret .= "}";
            $ret;
        }
    } elsif ($type == PVIP_NODE_USE) {
        if ($v->[0]->value eq 'v6') {
            $self->{line_number}++;
            "# use v6;\n";
        } else {
            'use ' . $self->do_compile($v->[0]);
        }
    } elsif ($type == PVIP_NODE_MODULE) {
        sprintf('package %s; our @__RG_EXPORT; use parent qw(Seis::Exporter);', $v->[0]->value);
    } elsif ($type == PVIP_NODE_CLASS) {
        # (class (ident "Foo7") (nop) (statements (method (ident "bar") (nop) (statements (int 5963)))))
        # (class (ident "Foo8") (list (is (ident "Foo7"))) (statements))
        state $ANON_CLASS = 0;
        my $pkg = $v->[0]->type == PVIP_NODE_NOP ? "Seis::_AnonClass" . $ANON_CLASS++ : $self->do_compile($v->[0]);
        my $retval = $gimme == G_VOID ? '' : "Seis::Class->_new(name => '$pkg')";
        my $body = $self->do_compile($v->[2]);
        if ($body eq '{ }') {
            $body = '';
        }
        sprintf(q!do {
            package %s;
            BEGIN {
                our @ISA;
                unshift @ISA, "Seis::Object";
                %s;
            }
            %s;
            %s
        }!, $pkg, join(";\n", map { $self->do_compile($_) } @{$v->[1]->value}), $body, $retval);
    } elsif ($type == PVIP_NODE_METHOD) {
        # (method (ident "bar") (nop) (statements))
        # TODO: support arguments
        # (method (ident "bar") (params (param (nop) (variable "$n") (nop))) (statements (mul (variable "$n") (int 3))))
        my $name = $self->do_compile($v->[0]);
        join('',
            'sub ' . $name . ' {',
            'my $self=shift;',
            $self->do_compile($v->[1]),
            ';undef;',
            $self->do_compile($v->[2]),
            ';}'
        );
    } elsif ($type == PVIP_NODE_UNARY_PLUS) {
        if ($v->[0]->type == PVIP_NODE_LIST) {
            sprintf('0+@{[%s]}', $self->do_compile($v->[0], G_ARRAY));
        } else {
            sprintf('(%s)->Int()', $self->do_compile($v->[0]));
        }
    } elsif ($type == PVIP_NODE_UNARY_MINUS) {
        sprintf('-(%s)', $self->do_compile($v->[0]));
    } elsif ($type == PVIP_NODE_IT_METHODCALL) {
        sprintf('$_->%s(%s)',
            $self->do_compile($v->[0]),
            defined($v->[1]) ? $self->do_compile($v->[1]) : '',
        );
    } elsif ($type == PVIP_NODE_LAST) {
        'last';
    } elsif ($type == PVIP_NODE_NEXT) {
        'next';
    } elsif ($type == PVIP_NODE_REDO) {
        'redo';
    } elsif ($type == PVIP_NODE_POSTINC) {
        sprintf('(%s)++',
            $self->do_compile($v->[0]),
        );
    } elsif ($type == PVIP_NODE_POSTDEC) {
        sprintf('(%s)--',
            $self->do_compile($v->[0]),
        );
    } elsif ($type == PVIP_NODE_PREINC) {
        sprintf('++(%s)',
            $self->do_compile($v->[0]),
        );
    } elsif ($type == PVIP_NODE_PREDEC) {
        sprintf('--(%s)',
            $self->do_compile($v->[0]),
        );
    } elsif ($type == PVIP_NODE_UNARY_BITWISE_NEGATION) {
        sprintf('~(%s)',
            $self->do_compile($v->[0]),
        );
    } elsif ($type == PVIP_NODE_BRSHIFT) {
        sprintf('(%s)>>(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BLSHIFT) {
        sprintf('(%s)<<(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_CHAIN) {
        my $compile = sub {
            my ($lhs, $type, $rhs) = @_; 
            my $op = +{
                PVIP_NODE_EQ() => '==',
                PVIP_NODE_NE() => '!=',
                PVIP_NODE_LT() => '<',
                PVIP_NODE_LE() => '<=',
                PVIP_NODE_GT() => '>',
                PVIP_NODE_GE() => '>=',
                PVIP_NODE_STREQ() => 'eq',
                PVIP_NODE_STRNE() => 'ne',
                PVIP_NODE_STRNE() => 'ne',
                PVIP_NODE_STRGT() => 'gt',
                PVIP_NODE_STRGE() => 'ge',
                PVIP_NODE_STRLT() => 'lt',
                PVIP_NODE_STRLE() => 'le',
                PVIP_NODE_EQV()   => 'eq', # TODO
                PVIP_NODE_SMART_MATCH()   => '~~',
            }->{$type};
            if ($type == PVIP_NODE_NOT_SMART_MATCH) {
                # Perl5 does not support `!~~` operator!
                sprintf("(!((%s)~~(%s)))", $lhs, $rhs);
            } else {
                unless ($op) {
                    Seis::Exception::NotImplemented->throw(sprintf "PVIP_NODE_%s is not implemented in chaning", $type)
                }
                sprintf("(%s)%s(%s)", $lhs, $op, $rhs);
            }
        };
        if (@$v == 1) {
            return $self->do_compile($v->[0]);
        } elsif (@$v == 2) {
            # optimized for simple case
            $compile->(
                $self->do_compile($v->[0]),
                $v->[1]->type,
                $self->do_compile($v->[1]->value->[0]),
            );
        } else {
            my $ret = 'do { my $_rg_chain_ret = 1; my $_rg_chain_rhs; my $_rg_chain_lhs = ';
            $ret .= $self->do_compile(shift @$v);
            $ret .= ';';

            while (my $rhs_node = shift @$v) {
                $ret .= sprintf('$_rg_chain_rhs=%s;', $self->do_compile($rhs_node->value->[0]));
                $ret .= sprintf('unless (%s) { $_rg_chain_ret=0; goto _RG_CHAIN_END; }', $compile->('$_rg_chain_lhs', $rhs_node->type, '$_rg_chain_rhs'));
                $ret .= '$_rg_chain_lhs=$_rg_chain_rhs;';
            }
            $ret .= '_RG_CHAIN_END: $_rg_chain_ret; }';
            return $ret;
        }
    } elsif ($type == PVIP_NODE_INPLACE_ADD) {
        '(' . $self->do_compile($v->[0]) . ')+=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_SUB) {
        '(' . $self->do_compile($v->[0]) . ')-=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_MUL) {
        '(' . $self->do_compile($v->[0]) . ')*=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_DIV) {
        '(' . $self->do_compile($v->[0]) . ')/=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_POW) {
        '(' . $self->do_compile($v->[0]) . ')**=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_MOD) {
        '(' . $self->do_compile($v->[0]) . ')%=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_BIN_OR) {
        sprintf('(%s)|=(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_INPLACE_BIN_AND) {
        sprintf('(%s)&=(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_INPLACE_BIN_XOR) {
        sprintf('(%s)^=(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_INPLACE_BLSHIFT) {
        sprintf('(%s)<<=(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_INPLACE_BRSHIFT) {
        sprintf('(%s)>>=(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_INPLACE_CONCAT_S) {
        '(' . $self->do_compile($v->[0]) . ').=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_REPEAT_S) {
        '(' . $self->do_compile($v->[0]) . ')x(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_INPLACE_REPEAT_S) {
        '(' . $self->do_compile($v->[0]) . ')x=(' . $self->do_compile($v->[1]) . ')';
    } elsif ($type == PVIP_NODE_STRINGIFY) {
        # STRINGIFY, stringification
        if ($self->is_array_variable($v->[0]) || $v->[0]->type == PVIP_NODE_LIST) {
            sprintf(q{join(' ', (%s))}, $self->do_compile($v->[0], G_ARRAY));
        } else {
            sprintf(q{(%s)->Str()}, $self->do_compile($v->[0]));
        }
    } elsif ($type == PVIP_NODE_TRY) {
        "eval " . $self->do_compile($v->[0]);
    } elsif ($type == PVIP_NODE_REF) {
        sprintf(q{\(%s)}, $self->do_compile($v->[0]));
    } elsif ($type == PVIP_NODE_MULTI) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_MULTI is not implemented")
    } elsif ($type == PVIP_NODE_UNARY_BOOLEAN) {
        sprintf 'Seis::Runtime::boolean(%s)', $self->do_compile($v->[0]);
    } elsif ($type == PVIP_NODE_UNARY_UPTO) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_UNARY_UPTO is not implemented")
    } elsif ($type == PVIP_NODE_ARRAY_DEREF) {
        '@{' . $self->do_compile($v->[0]) . '}';
    } elsif ($type == PVIP_NODE_STDOUT) {
        '*STDOUT'
    } elsif ($type == PVIP_NODE_STDERR) {
        '*STDERR'
    } elsif ($type == PVIP_NODE_SCALAR_DEREF) {
        '${' . $self->do_compile($v->[0]) . '}';
    } elsif ($type == PVIP_NODE_TW_ENV) {
        '(\%ENV)'
    } elsif ($type == PVIP_NODE_TW_TMPDIR) {
        'IO::Path->new(File::Spec->tmpdir())'
    } elsif ($type == PVIP_NODE_TW_INC) {
        if ($gimme == G_SCALAR) {
            '\\@Seis::INC';
        } else {
            '@Seis::INC';
        }
    } elsif ($type == PVIP_NODE_META_METHOD_CALL) {
        # (meta_method_call (class (nop) (nop) (statements)) (ident "methods") (nop))
        sprintf('(%s)->meta()->%s(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
            $self->do_compile($v->[2]),
        );
    } elsif ($type == PVIP_NODE_REGEXP) {
        $self->compile_regexp($v);
    } elsif ($type == PVIP_NODE_SMART_MATCH) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_SMART_MATCH is not implemented")
    } elsif ($type == PVIP_NODE_NOT_SMART_MATCH) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_NOT_SMART_MATCH is not implemented")
    } elsif ($type == PVIP_NODE_PERL5_REGEXP) {
        sprintf('qr!%s!', $v);
    } elsif ($type == PVIP_NODE_FALSE) {
        '(Bool::false())'
    } elsif ($type == PVIP_NODE_TRUE) {
        '(Bool::True())'
    } elsif ($type == PVIP_NODE_TW_VM) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_TW_VM is not implemented")
    } elsif ($type == PVIP_NODE_HAS) {
        # (has (public_attribute "x"))
        # support private variable
        if ($v->[0]->type == PVIP_NODE_ATTRIBUTE_VARIABLE) {
            sprintf(q!__PACKAGE__->meta->add_attribute(%s)!, $self->compile_string($v->[0]->value));
        } else {
            die "Should not reach here";
        }
    } elsif ($type == PVIP_NODE_ATTRIBUTE_VARIABLE) {
        # (public_attribute "x")
        sprintf('$self->{%s}', $self->compile_string($v));
    } elsif ($type == PVIP_NODE_FUNCREF) {
        sprintf('\&%s', $self->do_compile($v->[0]));
    } elsif ($type == PVIP_NODE_PATH) {
        sprintf('IO::Path->new(%s)',
            $self->compile_string($node)
        );
    } elsif ($type == PVIP_NODE_TW_PACKAGE) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_TW_PACKAGE is not implemented")
    } elsif ($type == PVIP_NODE_TW_CLASS) {
        'Seis::MetaClass->new(name => __PACKAGE__)'
    } elsif ($type == PVIP_NODE_TW_MODULE) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_TW_MODULE is not implemented")
    } elsif ($type == PVIP_NODE_TW_OS) {
        '($^O)';
    } elsif ($type == PVIP_NODE_E) {
        '(exp(1))';
    } elsif ($type == PVIP_NODE_TW_PID) {
        '($$)';
    } elsif ($type == PVIP_NODE_TW_PERLVER) {
        '6'
    } elsif ($type == PVIP_NODE_TW_OSVER) {
       'do {require Config; $Config::Config{osvers} }';
    } elsif ($type == PVIP_NODE_TW_CWD) {
        '(IO::Path->new(Cwd::getcwd()))'
    } elsif ($type == PVIP_NODE_TW_EXECUTABLE_NAME) {
        '($0)'
    } elsif ($type == PVIP_NODE_TW_ROUTINE) {
        'Sub->_new(__SUB__)';
    } elsif ($type == PVIP_NODE_SLANGS) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_SLANGS is not implemented")
    } elsif ($type == PVIP_NODE_LOGICAL_ANDTHEN) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_LOGICAL_ANDTHEN is not implemented")
    } elsif ($type == PVIP_NODE_VALUE_IDENTITY) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_VALUE_IDENTITY is not implemented")
    } elsif ($type == PVIP_NODE_CMP) {
        sprintf('(%s)cmp(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_SPECIAL_VARIABLE_REGEXP_MATCH) {
        '@Seis::Runtime::REGEXP_MATCH'
    } elsif ($type == PVIP_NODE_SPECIAL_VARIABLE_EXCEPTIONS) {
        # Perl5's $@ contains "" if there is no errors.
        # It's incompatible with Perl6.
        '($@ ? $@ : undef)';
    } elsif ($type == PVIP_NODE_ENUM) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_ENUM is not implemented")
    } elsif ($type == PVIP_NODE_NUM_CMP) {
        sprintf('(%s)<=>(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_UNARY_FLATTEN_OBJECT) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_UNARY_FLATTEN_OBJECT is not implemented")
    } elsif ($type == PVIP_NODE_COMPLEX) {
        sprintf('Seis::Complex->_new(%s)', $self->compile_string($v));
    } elsif ($type == PVIP_NODE_ROLE) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_ROLE is not implemented")
    } elsif ($type == PVIP_NODE_IS) {
        # (is (ident "Foo7"))
        sprintf q!push @ISA, '%s'!, $self->do_compile($v->[0]);
    } elsif ($type == PVIP_NODE_DOES) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_DOES is not implemented")
    } elsif ($type == PVIP_NODE_JUNCTIVE_AND) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_JUNCTIVE_AND is not implemented")
    } elsif ($type == PVIP_NODE_JUNCTIVE_SAND) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_JUNCTIVE_SAND is not implemented")
    } elsif ($type == PVIP_NODE_JUNCTIVE_OR) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_JUNCTIVE_OR is not implemented")
    } elsif ($type == PVIP_NODE_UNICODE_CHAR) {
        sprintf(q!"\N{%s}"!, $v);
    } elsif ($type == PVIP_NODE_STUB) {
        '...';
    } elsif ($type == PVIP_NODE_EXPORT) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_EXPORTABLE is not implemented")
    } elsif ($type == PVIP_NODE_BITWISE_OR) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_BITWISE_OR is not implemented")
    } elsif ($type == PVIP_NODE_BITWISE_AND) {
        sprintf('(%s)&(%s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BITWISE_XOR) {
        Seis::Exception::NotImplemented->throw("PVIP_NODE_BITWISE_XOR is not implemented")
    } elsif ($type == PVIP_NODE_VARGS) {
        # (vargs (variable "@a"))
        sprintf('my %s = @_;', $self->do_compile($v->[0]));
    } elsif ($type == PVIP_NODE_TW_A) {
        '($Seis::Runtime::TW_A)';
    } elsif ($type == PVIP_NODE_TW_B) {
        '($Seis::Runtime::TW_B)';
    } elsif ($type == PVIP_NODE_TW_C) {
        '($Seis::Runtime::TW_C)';
    } elsif ($type == PVIP_NODE_WHATEVER) {
        '(Seis::Whatever->new())';
    } elsif ($type == PVIP_NODE_NEED) {
        sprintf("BEGIN { require %s }", $self->do_compile($v->[0]));
    } elsif ($type == PVIP_NODE_END) {
        "END " . $self->do_compile($v->[0]);
    } elsif ($type == PVIP_NODE_GCD) {
        sprintf('Seis::BuiltinFunctions::gcd(%s, %s)',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1]),
        );
    } elsif ($type == PVIP_NODE_BEGIN) {
        "BEGIN " . $self->do_compile($v->[0]);
    } elsif ($type == PVIP_NODE_PACKAGE) {
        sprintf('package %s %s',
            $self->do_compile($v->[0]),
            $self->do_compile($v->[1])
        );
    } else {
        Seis::Exception::UnknownNode->throw(
             ("Unknown node: PVIP_NODE_" . uc($node->name))
        );
    }
}

sub binop {
    my ($self, $op, $v) = @_;
    sprintf('(%s)%s(%s)',
        $self->do_compile($v->[0]),
        $op,
        $v,
        $self->do_compile($v->[1]),
    );
}

sub maybe_block {
    my ($self, $node) = @_;
    if ($node->type == PVIP_NODE_BLOCK) {
        return $self->do_compile($node);
    } else {
        return '{' . $self->do_compile($node) . "}";
    }
}

sub compile_string{
    my ($self, $v) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper(Encode::decode_utf8($v));
}

sub is_list_lvalue {
    my ($self, $node) = @_;
    my $is_list_var = sub {
        my $c = shift;
        return $c->type == PVIP_NODE_VARIABLE && $c->value =~ /\A[%@]/;
    };
    if ($node->type == PVIP_NODE_MY) {
        # my, nop, list
        # my, nop, var
        if (@{$node->value}==2) {
            my $c = $node->value->[1];
            if ($is_list_var->($c)) {
                # my @x = ...
                1
            } elsif ($c->type == PVIP_NODE_LIST) {
                # my ($x, $y) = ...
                1
            } elsif ($c->type == PVIP_NODE_TW_INC) {
                1; # @*INC
            } else {
                # my $x = ...
                0
            }
        } elsif (@{$node->value}==1) {
            my $c = $node->value->[0];
            if ($c->type == PVIP_NODE_LIST) {
                1
            } elsif ($c->type == PVIP_NODE_TW_INC) {
                1; # @*INC
            } else {
                0;
            }
        } else {
            0;
        }
    } else {
        # @x = ...
        if ($is_list_var->($node)) {
            # my @x = ...
            1
        } elsif ($node->type == PVIP_NODE_TW_INC) {
            1; # @*INC
        } else {
            # my $x = ...
            0
        }
    }
}

sub compile_regexp {
    my ($class, $regexp) = @_;
    my $ret = '';
    while (length($regexp)) {
        if ($regexp =~ s/\A<alpha>//) {
            $ret .= '\p{PosixAlpha}';
        } elsif ($regexp =~ s/\A +//) {
            next;
        } elsif ($regexp =~ s/\A!//) {
            $ret .= '\!';
        } elsif ($regexp =~ s/\A(.)//s) {
            $ret .= $1;
        } else {
            die "Should not reache here: " . Data::Dumper::Dumper($regexp);
        }
    }
    sprintf('qr!%s!sxp', $ret);
}

sub is_array_variable {
    my ($self, $node) = @_;
    return $node->type == PVIP_NODE_VARIABLE && $node->value =~ /\A\@/;
}

1;

