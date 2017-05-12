#!/usr/bin/perl -w

=head1 NAME

bench_optree.pl - Look at different ways of storing data that transform fast.

=cut

use strict;
use Benchmark qw(cmpthese timethese);
use CGI::Ex::Dump qw(debug);
use constant skip_execute => 1;

#my $obj = bless [1, 2], __PACKAGE__;
#my $struct1 = \ [ '-', 1, 2 ];
#my $struct2 = ['-', 1, 2];
#
#sub call { $_[0]->[0] - $_[0]->[1] }
#
#sub obj_meth {  $obj->call }
#sub ref_type { if (ref($struct1) eq 'REF') { if (${$struct1}->[0] eq '-') { ${$struct1}->[1] - ${$struct1}->[2] } } }
#
#print "(".obj_meth().")\n";
#print "(".ref_type().")\n";
#cmpthese timethese(-2, {
#    obj_meth => \&obj_meth,
#    ref_type => \&ref_type,
#}, 'auto');


###----------------------------------------------------------------###
### setup a new way of storing and executing the variable tree

sub get_var2 { ref($_[1]) ? $_[1]->call($_[0]) : $_[1] }

{
    package Num;
    sub new { my $c = shift; bless \@_, $c };
    sub call { $_[0]->[0] }
    package A::B;
    sub new { my $c = shift; bless \@_, $c }
#    sub new { my $c = shift; bless [map{ref$_?$_:Num->new($_)} @_], $c }
    package A::B::Minus;
    our @ISA = qw(A::B);
    sub call { $_[1]->get_var2($_[0]->[0]) - $_[1]->get_var2($_[0]->[1]) }
    package A::B::Plus;
    our @ISA = qw(A::B);
    sub call { $_[1]->get_var2($_[0]->[0]) + $_[1]->get_var2($_[0]->[1]) }
    package A::B::Mult;
    our @ISA = qw(A::B);
    sub call { $_[1]->get_var2($_[0]->[0]) * $_[1]->get_var2($_[0]->[1]) }
    package A::B::Div;
    our @ISA = qw(A::B);
    sub call { $_[1]->get_var2($_[0]->[0]) / $_[1]->get_var2($_[0]->[1]) }
    package A::B::Var;
    our @ISA = qw(A::B);
use vars qw($HASH_OPS $LIST_OPS $SCALAR_OPS $FILTER_OPS $OP_FUNC);
BEGIN {
    $HASH_OPS   = $CGI::Ex::Template::HASH_OPS;
    $LIST_OPS   = $CGI::Ex::Template::LIST_OPS;
    $SCALAR_OPS = $CGI::Ex::Template::SCALAR_OPS;
    $FILTER_OPS = $CGI::Ex::Template::FILTER_OPS;
    $OP_FUNC    = $CGI::Ex::Template::OP_FUNC;
}
use constant trace => 0;
sub call {
    my $var  = shift;
    my $self = shift;
    my $ARGS = shift || {};
    my $i    = 0;
    my $generated_list;

    ### determine the top level of this particular variable access
    my $ref  = $var->[$i++];
    my $args = $var->[$i++];
    warn "get_variable: begin \"$ref\"\n" if trace;

    if (defined $ref) {
        if ($ARGS->{'is_namespace_during_compile'}) {
            $ref = $self->{'NAMESPACE'}->{$ref};
        } else {
            return if $ref =~ /^[_.]/; # don't allow vars that begin with _
            $ref = $self->{'_vars'}->{$ref};
        }
    }

    my %seen_filters;
    while (defined $ref) {

        ### check at each point if the returned thing was a code
        if (UNIVERSAL::isa($ref, 'CODE')) {
            my @results = $ref->($args ? @{ $self->vivify_args($args) } : ());
            if (defined $results[0]) {
                $ref = ($#results > 0) ? \@results : $results[0];
            } elsif (defined $results[1]) {
                die $results[1]; # TT behavior - why not just throw ?
            } else {
                $ref = undef;
                last;
            }
        }

        ### descend one chained level
        last if $i >= $#$var;
        my $was_dot_call = $ARGS->{'no_dots'} ? 1 : $var->[$i++] eq '.';
        my $name         = $var->[$i++];
        my $args         = $var->[$i++];
        warn "get_variable: nested \"$name\"\n" if trace;

        ### allow for named portions of a variable name (foo.$name.bar)
        if (ref $name) {
            $name = $name->call($self);
            if (! defined($name) || $name =~ /^[_.]/) {
                $ref = undef;
                last;
            }
        }

        if ($name =~ /^_/) { # don't allow vars that begin with _
            $ref = undef;
            last;
        }

        ### allow for scalar and filter access (this happens for every non virtual method call)
        if (! ref $ref) {
            if ($SCALAR_OPS->{$name}) {                        # normal scalar op
                $ref = $SCALAR_OPS->{$name}->($ref, $args ? @{ $self->vivify_args($args) } : ());

            } elsif ($LIST_OPS->{$name}) {                     # auto-promote to list and use list op
                $ref = $LIST_OPS->{$name}->([$ref], $args ? @{ $self->vivify_args($args) } : ());

            } elsif (my $filter = $self->{'FILTERS'}->{$name}    # filter configured in Template args
                     || $FILTER_OPS->{$name}                     # predefined filters in CET
                     || (UNIVERSAL::isa($name, 'CODE') && $name) # looks like a filter sub passed in the stash
                     || $self->list_filters->{$name}) {          # filter defined in Template::Filters

                if (UNIVERSAL::isa($filter, 'CODE')) {
                    $ref = eval { $filter->($ref) }; # non-dynamic filter - no args
                    if (my $err = $@) {
                        $self->throw('filter', $err) if ref($err) !~ /Template::Exception$/;
                        die $err;
                    }
                } elsif (! UNIVERSAL::isa($filter, 'ARRAY')) {
                    $self->throw('filter', "invalid FILTER entry for '$name' (not a CODE ref)");

                } elsif (@$filter == 2 && UNIVERSAL::isa($filter->[0], 'CODE')) { # these are the TT style filters
                    eval {
                        my $sub = $filter->[0];
                        if ($filter->[1]) { # it is a "dynamic filter" that will return a sub
                            ($sub, my $err) = $sub->($self->context, $args ? @{ $self->vivify_args($args) } : ());
                            if (! $sub && $err) {
                                $self->throw('filter', $err) if ref($err) !~ /Template::Exception$/;
                                die $err;
                            } elsif (! UNIVERSAL::isa($sub, 'CODE')) {
                                $self->throw('filter', "invalid FILTER for '$name' (not a CODE ref)")
                                    if ref($sub) !~ /Template::Exception$/;
                                die $sub;
                            }
                        }
                        $ref = $sub->($ref);
                    };
                    if (my $err = $@) {
                        $self->throw('filter', $err) if ref($err) !~ /Template::Exception$/;
                        die $err;
                    }
                } else { # this looks like our vmethods turned into "filters" (a filter stored under a name)
                    $self->throw('filter', 'Recursive filter alias \"$name\"') if $seen_filters{$name} ++;
                    $var = [$name, 0, '|', @$filter, @{$var}[$i..$#$var]]; # splice the filter into our current tree
                    $i = 2;
                }
                if (scalar keys %seen_filters
                    && $seen_filters{$var->[$i - 5] || ''}) {
                    $self->throw('filter', "invalid FILTER entry for '".$var->[$i - 5]."' (not a CODE ref)");
                }
            } else {
                $ref = undef;
            }

        } else {

            ### method calls on objects
            if (UNIVERSAL::can($ref, 'can')) {
                my @args = $args ? @{ $self->vivify_args($args) } : ();
                my @results = eval { $ref->$name(@args) };
                if ($@) {
                    die $@ if ref $@ || $@ !~ /Can\'t locate object method/;
                } elsif (defined $results[0]) {
                    $ref = ($#results > 0) ? \@results : $results[0];
                    next;
                } elsif (defined $results[1]) {
                    die $results[1]; # TT behavior - why not just throw ?
                } else {
                    $ref = undef;
                    last;
                }
                # didn't find a method by that name - so fail down to hash and array access
            }

            ### hash member access
            if (UNIVERSAL::isa($ref, 'HASH')) {
                if ($was_dot_call && exists($ref->{$name}) ) {
                    $ref = $ref->{$name};
                } elsif ($HASH_OPS->{$name}) {
                    $ref = $HASH_OPS->{$name}->($ref, $args ? @{ $self->vivify_args($args) } : ());
                } elsif ($ARGS->{'is_namespace_during_compile'}) {
                    return $var; # abort - can't fold namespace variable
                } else {
                    $ref = undef;
                }

            ### array access
            } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
                if ($name =~ /^\d+$/) {
                    $ref = ($name > $#$ref) ? undef : $ref->[$name];
                } else {
                    $ref = (! $LIST_OPS->{$name}) ? undef : $LIST_OPS->{$name}->($ref, $args ? @{ $self->vivify_args($args) } : ());
                }
            }
        }

    } # end of while

    ### allow for undefinedness
    if (! defined $ref) {
        if ($self->{'_debug_undef'}) {
            my $chunk = $var->[$i - 2];
            $chunk = $chunk->call($self) if ref $chunk;
            die "$chunk is undefined\n";
        } else {
            $ref = $self->undefined_any($var);
        }
    }

    ### allow for special behavior for the '..' operator
    if ($generated_list && $ARGS->{'list_context'} && ref($ref) eq 'ARRAY') {
        return @$ref;
    }

    return $ref;
}
};
sub plus  ($$) { A::B::Plus->new( @_) }
sub minus ($$) { A::B::Minus->new(@_) }
sub mult  ($$) { A::B::Mult->new( @_) }
sub div   ($$) { A::B::Div->new(  @_) }
sub var        { A::B::Var->new(  @_) };
$INC{'A/B.pm'} = 1;
$INC{'A/B/Plus.pm'} = 1;
$INC{'A/B/Minus.pm'} = 1;
$INC{'A/B/Mult.pm'} = 1;
$INC{'A/B/Div.pm'} = 1;
$INC{'A/B/Var.pm'} = 1;

###----------------------------------------------------------------###
### now benchmark the different variable storage methods

my $vars = {
    foo  => {bar => {baz => [qw(a b c)]}},
    bing => 'bang',
};
my $self = bless {'_vars' => $vars}, __PACKAGE__;

#pauls@pslaptop:~/perl/CGI-Ex/lib$    perl -e 'my $a = "1 + 2 * (3 + (4 / 5) * 9) - 20";
#       use CGI::Ex::Template;
#       use Data::Dumper;
#       print Dumper(CGI::Ex::Template->new->parse_variable(\$a));'

###----------------------------------------------------------------###

my $Y0 = '$self->{_vars}->{bing}';
my $Y1 = [ 'bing', 0 ];
my $Y2 = var('bing', 0);
debug $Y2;

### are they all the same
print eval($Y0)."\n";
print $self->get_variable($Y1)."\n";
print $self->get_var2($Y2)."\n";

if (! skip_execute) {
    cmpthese timethese (-2, {
        perl        => sub { eval $Y0 },
        bare_data   => sub { $self->get_variable($Y1) },
        method_call => sub { $self->get_var2($Y2) },
    }, 'auto');
}

###----------------------------------------------------------------###

my $Z0 = '$self->{_vars}->{foo}->{bar}->{baz}->[1]';
my $Z1 = [ 'foo', 0, '.', 'bar', 0, '.', 'baz', 0, '.', 1, 0];
my $Z2 = var('foo', 0, '.', 'bar', 0, '.', 'baz', 0, '.', 1, 0);
debug $Z2;

### are they all the same
print eval($Z0)."\n";
print $self->get_variable($Z1)."\n";
print $self->get_var2($Z2)."\n";

if (! skip_execute) {
    cmpthese timethese (-2, {
        perl        => sub { eval $Z0 },
        bare_data   => sub { $self->get_variable($Z1) },
        method_call => sub { $self->get_var2($Z2) },
    }, 'auto');
}

###----------------------------------------------------------------###

### $A0 = perl, $A1 = old optree, $A2 = new optree
my $A0 = "1 + 2 * (3 + (4 / 5) * 9) - 20";
my $A1 = [ \[ '-', [ \[ '+', '1', [ \[ '*', '2', [ \[ '+', '3', [ \[ '*', [ \[ '/', '4', '5' ], 0 ], '9' ], 0 ] ], 0 ] ], 0 ] ], 0 ], '20' ], 0 ];
my $A2 = minus(plus(1, mult(2, plus(3, mult(div(4,5), 9)))), 20);
debug $A2;

### are they all the same
print eval($A0)."\n";
print $self->get_variable($A1)."\n";
print $self->get_var2($A2)."\n";

if (! skip_execute) {
    cmpthese timethese (-2, {
        perl        => sub { eval $A0 },
        bare_data   => sub { $self->get_variable($A1) },
        method_call => sub { $self->get_var2($A2) },
    }, 'auto');
}

###----------------------------------------------------------------###

my $B0 = "1 + 2";
my $B1 = [ \[ '+', 1, 2] ];
my $B2 = plus(1, 2);
debug $B2;

### are they all the same
print eval($B0)."\n";
print $self->get_variable($B1)."\n";
print $self->get_var2($B2)."\n";

if (! skip_execute) {
    cmpthese timethese (-2, {
        perl        => sub { eval $B0 },
        bare_data   => sub { $self->get_variable($B1) },
        method_call => sub { $self->get_var2($B2) },
    }, 'auto');
}

###----------------------------------------------------------------###
### Test (de)serialization speed

use Storable;
my $d1 = Storable::freeze($A1);
my $d2 = Storable::freeze($A2);
Storable::thaw($d1); # load lib
print length($d1)."\n";
print length($d2)."\n";

cmpthese timethese (-2, {
    freeze_bare => sub { Storable::freeze($A1) },
    freeze_meth => sub { Storable::freeze($A2) },
}, 'auto');

cmpthese timethese (-2, {
    thaw_bare => sub { Storable::thaw($d1) },
    thaw_meth => sub { Storable::thaw($d2) },
}, 'auto');

###----------------------------------------------------------------###
### create libraries similar to those from CGI::Ex::Template 1.201

use CGI::Ex::Template;
use vars qw($HASH_OPS $LIST_OPS $SCALAR_OPS $FILTER_OPS $OP_FUNC);
BEGIN {
    $HASH_OPS   = $CGI::Ex::Template::HASH_OPS;
    $LIST_OPS   = $CGI::Ex::Template::LIST_OPS;
    $SCALAR_OPS = $CGI::Ex::Template::SCALAR_OPS;
    $FILTER_OPS = $CGI::Ex::Template::FILTER_OPS;
    $OP_FUNC    = $CGI::Ex::Template::OP_FUNC;
}
use constant trace => 0;

sub get_variable {
    ### allow for the parse tree to store literals
    return $_[1] if ! ref $_[1];

    my $self = shift;
    my $var  = shift;
    my $ARGS = shift || {};
    my $i    = 0;
    my $generated_list;

    ### determine the top level of this particular variable access
    my $ref  = $var->[$i++];
    my $args = $var->[$i++];
    warn "get_variable: begin \"$ref\"\n" if trace;
    if (ref $ref) {
        if (ref($ref) eq 'SCALAR') { # a scalar literal
            $ref = $$ref;
        } elsif (ref($ref) eq 'REF') { # operator
            return $self->play_operator($$ref) if ${ $ref }->[0] eq '\\'; # return the closure
            $generated_list = 1 if ${ $ref }->[0] eq '..';
            $ref = $self->play_operator($$ref);
        } else { # a named variable access (ie via $name.foo)
            $ref = $self->get_variable($ref);
            if (defined $ref) {
                return if $ref =~ /^[_.]/; # don't allow vars that begin with _
                $ref = $self->{'_vars'}->{$ref};
            }
        }
    } elsif (defined $ref) {
        if ($ARGS->{'is_namespace_during_compile'}) {
            $ref = $self->{'NAMESPACE'}->{$ref};
        } else {
            return if $ref =~ /^[_.]/; # don't allow vars that begin with _
            $ref = $self->{'_vars'}->{$ref};
        }
    }


    my %seen_filters;
    while (defined $ref) {

        ### check at each point if the returned thing was a code
        if (UNIVERSAL::isa($ref, 'CODE')) {
            my @results = $ref->($args ? @{ $self->vivify_args($args) } : ());
            if (defined $results[0]) {
                $ref = ($#results > 0) ? \@results : $results[0];
            } elsif (defined $results[1]) {
                die $results[1]; # TT behavior - why not just throw ?
            } else {
                $ref = undef;
                last;
            }
        }

        ### descend one chained level
        last if $i >= $#$var;
        my $was_dot_call = $ARGS->{'no_dots'} ? 1 : $var->[$i++] eq '.';
        my $name         = $var->[$i++];
        my $args         = $var->[$i++];
        warn "get_variable: nested \"$name\"\n" if trace;

        ### allow for named portions of a variable name (foo.$name.bar)
        if (ref $name) {
            if (ref($name) eq 'ARRAY') {
                $name = $self->get_variable($name);
                if (! defined($name) || $name =~ /^[_.]/) {
                    $ref = undef;
                    last;
                }
            } else {
                die "Shouldn't get a ". ref($name) ." during a vivify on chain";
            }
        }
        if ($name =~ /^_/) { # don't allow vars that begin with _
            $ref = undef;
            last;
        }

        ### allow for scalar and filter access (this happens for every non virtual method call)
        if (! ref $ref) {
            if ($SCALAR_OPS->{$name}) {                        # normal scalar op
                $ref = $SCALAR_OPS->{$name}->($ref, $args ? @{ $self->vivify_args($args) } : ());

            } elsif ($LIST_OPS->{$name}) {                     # auto-promote to list and use list op
                $ref = $LIST_OPS->{$name}->([$ref], $args ? @{ $self->vivify_args($args) } : ());

            } elsif (my $filter = $self->{'FILTERS'}->{$name}    # filter configured in Template args
                     || $FILTER_OPS->{$name}                     # predefined filters in CET
                     || (UNIVERSAL::isa($name, 'CODE') && $name) # looks like a filter sub passed in the stash
                     || $self->list_filters->{$name}) {          # filter defined in Template::Filters

                if (UNIVERSAL::isa($filter, 'CODE')) {
                    $ref = eval { $filter->($ref) }; # non-dynamic filter - no args
                    if (my $err = $@) {
                        $self->throw('filter', $err) if ref($err) !~ /Template::Exception$/;
                        die $err;
                    }
                } elsif (! UNIVERSAL::isa($filter, 'ARRAY')) {
                    $self->throw('filter', "invalid FILTER entry for '$name' (not a CODE ref)");

                } elsif (@$filter == 2 && UNIVERSAL::isa($filter->[0], 'CODE')) { # these are the TT style filters
                    eval {
                        my $sub = $filter->[0];
                        if ($filter->[1]) { # it is a "dynamic filter" that will return a sub
                            ($sub, my $err) = $sub->($self->context, $args ? @{ $self->vivify_args($args) } : ());
                            if (! $sub && $err) {
                                $self->throw('filter', $err) if ref($err) !~ /Template::Exception$/;
                                die $err;
                            } elsif (! UNIVERSAL::isa($sub, 'CODE')) {
                                $self->throw('filter', "invalid FILTER for '$name' (not a CODE ref)")
                                    if ref($sub) !~ /Template::Exception$/;
                                die $sub;
                            }
                        }
                        $ref = $sub->($ref);
                    };
                    if (my $err = $@) {
                        $self->throw('filter', $err) if ref($err) !~ /Template::Exception$/;
                        die $err;
                    }
                } else { # this looks like our vmethods turned into "filters" (a filter stored under a name)
                    $self->throw('filter', 'Recursive filter alias \"$name\"') if $seen_filters{$name} ++;
                    $var = [$name, 0, '|', @$filter, @{$var}[$i..$#$var]]; # splice the filter into our current tree
                    $i = 2;
                }
                if (scalar keys %seen_filters
                    && $seen_filters{$var->[$i - 5] || ''}) {
                    $self->throw('filter', "invalid FILTER entry for '".$var->[$i - 5]."' (not a CODE ref)");
                }
            } else {
                $ref = undef;
            }

        } else {

            ### method calls on objects
            if (UNIVERSAL::can($ref, 'can')) {
                my @args = $args ? @{ $self->vivify_args($args) } : ();
                my @results = eval { $ref->$name(@args) };
                if ($@) {
                    die $@ if ref $@ || $@ !~ /Can\'t locate object method/;
                } elsif (defined $results[0]) {
                    $ref = ($#results > 0) ? \@results : $results[0];
                    next;
                } elsif (defined $results[1]) {
                    die $results[1]; # TT behavior - why not just throw ?
                } else {
                    $ref = undef;
                    last;
                }
                # didn't find a method by that name - so fail down to hash and array access
            }

            ### hash member access
            if (UNIVERSAL::isa($ref, 'HASH')) {
                if ($was_dot_call && exists($ref->{$name}) ) {
                    $ref = $ref->{$name};
                } elsif ($HASH_OPS->{$name}) {
                    $ref = $HASH_OPS->{$name}->($ref, $args ? @{ $self->vivify_args($args) } : ());
                } elsif ($ARGS->{'is_namespace_during_compile'}) {
                    return $var; # abort - can't fold namespace variable
                } else {
                    $ref = undef;
                }

            ### array access
            } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
                if ($name =~ /^\d+$/) {
                    $ref = ($name > $#$ref) ? undef : $ref->[$name];
                } else {
                    $ref = (! $LIST_OPS->{$name}) ? undef : $LIST_OPS->{$name}->($ref, $args ? @{ $self->vivify_args($args) } : ());
                }
            }
        }

    } # end of while

    ### allow for undefinedness
    if (! defined $ref) {
        if ($self->{'_debug_undef'}) {
            my $chunk = $var->[$i - 2];
            $chunk = $self->get_variable($chunk) if ref($chunk) eq 'ARRAY';
            die "$chunk is undefined\n";
        } else {
            $ref = $self->undefined_any($var);
        }
    }

    ### allow for special behavior for the '..' operator
    if ($generated_list && $ARGS->{'list_context'} && ref($ref) eq 'ARRAY') {
        return @$ref;
    }

    return $ref;
}

sub vivify_args {
    my $self = shift;
    my $vars = shift;
    my $args = shift || {};
    return [map {$self->get_variable($_, $args)} @$vars];
}

sub play_operator {
    my $self = shift;
    my $tree = shift;
    my $ARGS = shift || {};
    my $op = $tree->[0];
    $tree = [@$tree[1..$#$tree]];

    ### allow for operator function override
    if (exists $OP_FUNC->{$op}) {
        return $OP_FUNC->{$op}->($self, $op, $tree, $ARGS);
    }

    ### do constructors and short-circuitable operators
    if ($op eq '~' || $op eq '_') {
        return join "", grep {defined} @{ $self->vivify_args($tree) };
    } elsif ($op eq 'arrayref') {
        return $self->vivify_args($tree, {list_context => 1});
    } elsif ($op eq 'hashref') {
        my $args = $self->vivify_args($tree);
        push @$args, undef if ! ($#$args % 2);
        return {@$args};
    } elsif ($op eq '?') {
        if ($self->get_variable($tree->[0])) {
            return defined($tree->[1]) ? $self->get_variable($tree->[1]) : undef;
        } else {
            return defined($tree->[2]) ? $self->get_variable($tree->[2]) : undef;
        }
    } elsif ($op eq '||' || $op eq 'or' || $op eq 'OR') {
        for my $node (@$tree) {
            my $var = $self->get_variable($node);
            return $var if $var;
        }
        return '';
    } elsif ($op eq '&&' || $op eq 'and' || $op eq 'AND') {
        my $var;
        for my $node (@$tree) {
            $var = $self->get_variable($node);
            return 0 if ! $var;
        }
        return $var;

    } elsif ($op eq '!') {
        my $var = ! $self->get_variable($tree->[0]);
        return defined($var) ? $var : '';

    }

    ### equality operators
    local $^W = 0;
    my $n = $self->get_variable($tree->[0]);
    $tree = [@$tree[1..$#$tree]];
    if ($op eq '==')    { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n eq $_) }; return 1 }
    elsif ($op eq '!=') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n ne $_) }; return 1 }
    elsif ($op eq 'eq') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n eq $_) }; return 1 }
    elsif ($op eq 'ne') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n ne $_) }; return 1 }
    elsif ($op eq '<')  { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n <  $_); $n = $_ }; return 1 }
    elsif ($op eq '>')  { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n >  $_); $n = $_ }; return 1 }
    elsif ($op eq '<=') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n <= $_); $n = $_ }; return 1 }
    elsif ($op eq '>=') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n >= $_); $n = $_ }; return 1 }
    elsif ($op eq 'lt') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n lt $_); $n = $_ }; return 1 }
    elsif ($op eq 'gt') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n gt $_); $n = $_ }; return 1 }
    elsif ($op eq 'le') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n le $_); $n = $_ }; return 1 }
    elsif ($op eq 'ge') { for (@$tree) { $_ = $self->get_variable($_); return '' if ! ($n ge $_); $n = $_ }; return 1 }

    ### numeric operators
    my $args = $self->vivify_args($tree);
    if (! @$args) {
        if ($op eq '-') { return - $n }
        $self->throw('operator', "Not enough args for operator \"$op\"");
    }
    if ($op eq '..')        { return [($n || 0) .. ($args->[-1] || 0)] }
    elsif ($op eq '+')      { $n +=  $_ for @$args; return $n }
    elsif ($op eq '-')      { $n -=  $_ for @$args; return $n }
    elsif ($op eq '*')      { $n *=  $_ for @$args; return $n }
    elsif ($op eq '/')      { $n /=  $_ for @$args; return $n }
    elsif ($op eq 'div'
           || $op eq 'DIV') { $n = int($n / $_) for @$args; return $n }
    elsif ($op eq '%'
           || $op eq 'mod'
           || $op eq 'MOD') { $n %=  $_ for @$args; return $n }
    elsif ($op eq '**'
           || $op eq 'pow') { $n **= $_ for @$args; return $n }

    $self->throw('operator', "Un-implemented operation $op");
}

