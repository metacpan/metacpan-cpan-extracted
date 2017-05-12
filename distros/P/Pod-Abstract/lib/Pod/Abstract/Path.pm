package Pod::Abstract::Path;
use strict;
use warnings;

use Data::Dumper;

use Pod::Abstract::BuildNode qw(node);

$Data::Dumper::Indent = 1;

our $VERSION = '0.20';

use constant CHILDREN  => 1;  # /
use constant ALL       => 2;  # //
use constant NAME      => 3;  # head1
use constant INDEX     => 4;  # (3)
use constant L_SELECT  => 5;  # [
use constant ATTR      => 6;  # @label
use constant N_CMP     => 7;  # == != < <= > >=
use constant STRING    => 8;  # 'foobar'
use constant R_SELECT  => 9;  # ]
use constant NUM_OF    => 10; # #
use constant NOT       => 15; # !
use constant PARENT    => 16; # ..
use constant MATCHES   => 17; # =~
use constant REGEXP    => 18; # {<pattern>}
use constant NOP       => 19; # .
use constant PREV      => 20; # <<
use constant NEXT      => 21; # >>
use constant ROOT      => 22; # ^
use constant UNION     => 23; # |
use constant INTERSECT => 24; # &
use constant S_CMP     => 25; # eq lt gt le ge ne

=pod

=head1 NAME

Pod::Abstract::Path - Search for POD nodes matching a path within a
document tree.

=head1 SYNOPSIS

 /head1(1)/head2          # All head2 elements under 
                          # the 2nd head1 element
 //item                   # All items anywhere
 //item[@label =~ {^\*$}] # All items with '*' labels.
 //head2[/hilight]        # All head2 elements containing
                          # "hilight" elements

 # Top level head1s containing head2s that have headings matching
 # "NAME", and also have at least one list somewhere in their
 # contents.
 /head1[/head2[@heading =~ {NAME}]][//over]
 
 # Top level headings having the same title as the following heading.
 /head1[@heading = >>@heading]
 
 # Top level headings containing at least one subheading with the same
 # name.
 /head1[@heading = ./head2@heading]

=head1 DESCRIPTION

Pod::Abstract::Path is a path selection syntax that allows fast and
easy traversal of Pod::Abstract documents. While it has a simple
syntax, there is significant complexity in the queries that you can
create.

Not all of the designed features have yet been implemented, but it is
currently quite useful, and all of the filters in C<paf> make use of
Pod Paths.

=head2 SYMBOLS:

=over

=item /

Selects children of the left hand side.

=item //

Selects all descendants of the left hand side.

=item .

Selects the current node - this is a NOP that can be used in
expressions.

=item ..

Selects the parrent node. If there are multiple nodes selected, all of
their parents will be included.

=item ^

Selects the root node of the tree for the current node. This allows
you to escape from a nested expression. Note that this is the ROOT
node, not the node that you started from.

If you want to evaluate an expression from a node as though it were
the root node, the easiest ways are to detach or dup it - otherwise
the root operator will find the original root node.

=item name, #cut, :text, :verbatim, :paragraph

Any element name, or symbolic type name, will restrict the selection
to only elements matching that type. e.g, "C<//:paragraph>" will
select all descendants, anywhere, but then restrict that set to only
C<:paragraph> type nodes.

Names together separated by spaces will match all of those names -
e.g: C<//head1 over> will match all lists and all head1s.

=item &, | (union and intersection)

Union will take expressions on either side, and return all nodes that
are members of either set. Intersection returns nodes that are members
of BOTH sets. These can be used to extend expressions, and within [
expressions ] where a path is supported (left side of a match, left or
right side of an = sign). These are NOT logical and/or, though a
similar effect can be induced through these operators.

=item @attrname

The named attribute of the nodes on the left hand side. Current
attributes are C<@heading> for head1 through head4, and C<@label> for
list items.

=item [ expression ]

Select only the left hand elements that match the expression in the
brackets. The expression will be evaluated from the point of view of
each node in the current result set.

Expressions can be:

=over

=item simple: C<[/head2]>

Any regular path will be true if there are any nodes matched. The
above example will be true if there are any head2 nodes as direct
children of the selected node.

=item regex match: C<[@heading =~ {FOO}]>

A regex match will be true if the left hand expression has nodes that
match the regular expression between the braces on the right hand
side. The above example will match anything with a heading containing
"FOO".

Optionally, the right hand closing brace may have the C<i> modifier to
cause case-insensitive matching. i.e C<[@heading =~ {foo}i]> will
match C<foo> or C<fOO>.

=item complement: C<[! /head2 ]>

Reverses the remainder of the expression. The above example will match
anything B<without> a child head2 node.

=item compare operators: eg. C<[ /node1 eq /node2 ]>

Matches nodes where the operator is satistied for at least one pair of
nodes. The right hand expression can be a constant string (single
quoted: C<'string'>, or a second expression. If two expressions are
used, they are matched combinationally - i.e, all result nodes on the
left are matched against all result nodes on the right. Both sides may
contain nested expressions.

The following Perl compatible operators are supported:

String: C< eq gt lt le ge ne >

Numeric: C<<< == < > <= >= != >>>

=back

=back

=head1 PERFORMANCE

Pod::Abstract::Path is not designed to be fast. It is designed to be
expressive and useful, but it involves sucessive
expand/de-duplicate/linear search operations and doing this with large
documents containing many nodes is not suitable for high performance
systems.

Simple expressions can be fast enough, but there is nothing to stop
you from writing "//[<condition>]" and linear-searching all 10,000
nodes of your Pod document. Use with caution in interactive systems.

=head1 INTERFACE

It is recommended you use the C<<Pod::Abstract::Node->select>> method
to evaluate Path expressions.

If you wish to generate paths for use in other modules, use
C<parse_path> to generate a parse tree, pass that as an argument to
C<new>, then use C<process> to evaluate the expression against a list
of nodes. You can re-use the same parse tree to process multiple lists
of nodes in this fashion.

=cut

sub new {
    my $class = shift;
    my $expression = shift;
    my $parse_tree = shift;
    
    if($parse_tree) {
        my $self = bless { 
            expression => $expression,
            parse_tree => $parse_tree
        }, $class;
        return $self;
    } else {
        my $self = bless { expression => $expression }, $class;
        
        my @lexemes = $self->lex($expression);
        my $parse_tree = $self->parse_path(\@lexemes);
        $self->{parse_tree} = $parse_tree;
        
        return $self;
    }
}

sub lex {
    my $self = shift;
    my $expression = shift;
    my @l = ( );

    # Digest expression into @l
    while($expression) {
        if($expression =~ m/^\/\//) {
            substr($expression,0,2) = '';
            push @l, [ ALL, undef ];
        } elsif($expression =~ m/^\//) {
            substr($expression,0,1) = '';
            push @l, [ CHILDREN, undef ];
        } elsif($expression =~ m/^\|/) {
            substr($expression,0,1) = '';
            push @l, [ UNION, undef ];
        } elsif($expression =~ m/^\&/) {
            substr($expression,0,1) = '';
            push @l, [ INTERSECT, undef ];
        } elsif($expression =~ m/^\[/) {
            substr($expression,0,1) = '';
            push @l, [ L_SELECT, undef ];
        } elsif($expression =~ m/^\]/) {
            substr($expression,0,1) = '';
            push @l, [ R_SELECT, undef ];
        } elsif($expression =~ m/^(eq|lt|gt|le|ge|ne)/) {
            push @l, [ S_CMP, $1 ];
            substr($expression,0,2) = '';
        } elsif($expression =~ m/^([#_\:a-zA-Z0-9]+)/) {
            push @l, [ NAME, $1 ];
            substr($expression, 0, length $1) = '';
        } elsif($expression =~ m/^\@([a-zA-Z0-9]+)/) {
            push @l, [ ATTR, $1 ];
            substr($expression, 0, length( $1 ) + 1) = '';
        } elsif($expression =~ m/^\(([0-9]+)\)/) {
            push @l, [ INDEX, $1 ];
            substr($expression, 0, length( $1 ) + 2) = '';
        } elsif($expression =~ m/^\{(([^\}]|\\\})+)\}([i]?)/) {
            my $case = $3 eq 'i' ? 0 : 1;
            push @l, [ REGEXP, $1, $case ];
            substr($expression, 0, length( $1 ) + 2 + length($3)) = '';
        } elsif($expression =~ m/^'(([^']|\\')+)'/) {
            push @l, [ STRING, $1 ];
            substr($expression, 0, length( $1 ) + 2) = '';
        } elsif($expression =~ m/^\=\~/) {
            push @l, [ MATCHES, undef ];
            substr($expression, 0, 2) = '';
        } elsif($expression =~ m/^\.\./) {
            push @l, [ PARENT, undef ];
            substr($expression, 0, 2) = '';
        } elsif($expression =~ m/^\^/) {
            push @l, [ ROOT, undef ];
            substr($expression, 0, 1) = '';
        } elsif($expression =~ m/^\./) {
            push @l, [ NOP, undef ];
            substr($expression, 0, 1) = '';
        } elsif($expression =~ m/^\<\</) {
            push @l, [ PREV, undef ];
            substr($expression, 0, 2) = '';
        } elsif($expression =~ m/^\>\>/) {
            push @l, [ NEXT, undef ];
            substr($expression, 0, 2) = '';
        } elsif($expression =~ m/^(==|!=|<=|>=)/) {
            push @l, [ N_CMP, $1 ];
            substr($expression,0,2) = '';
        } elsif($expression =~ m/^(<|>)/) {
            push @l, [ N_CMP, $1 ];
            substr($expression,0,1) = '';
        } elsif($expression =~ m/^\!/) {
            push @l, [ NOT, undef ];
            substr($expression, 0, 1) = '';
        } elsif($expression =~ m/^\%/) {
            push @l, [ NUM_OF, undef ];
            substr($expression, 0, 1) = '';
        } elsif($expression =~ m/^'([\^']*)'/) {
            push @l, [ STRING, $1 ];
            substr($expression, 0, length( $1 ) + 2) = '';
        } elsif($expression =~ m/(\s+)/) {
            # Discard uncaptured whitespace
            substr($expression, 0, length($1)) = '';
        } else {
            die "Invalid token encountered - remaining string is $expression";
        }
    }
    return @l;
}

=head1 METHODS

=head2 filter_unique

It is possible during processing - especially using ^ or .. operators
- to generate many duplicate matches of the same nodes. Each pass
around the loop, we filter to unique nodes so that duplicates cannot
inflate more than one time.

This effectively means that C<//^> (however awful that is) will match
one node only - just really inefficiently.

=cut

sub filter_unique {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    my %seen = ( );
    foreach my $node (@$ilist) {
        push @$nlist, $node unless $seen{$node->serial};
        $seen{$node->serial} = 1;
    }
    
    return $nlist;
}

# Rec descent process of expression.
sub process {
    my $self = shift;
    my @nodes = @_;
    
    my $pt = $self->{parse_tree};
    my $ilist = [ @nodes ];
    
    while($pt && $pt->{action} ne 'end_select') {
        my $action = $pt->{action};
        my @args = ( );
        if($pt->{arguments}) {
            @args = @{$pt->{arguments}};
        }
        if($self->can($action)) {
            $ilist = $self->$action($ilist, @args);
            $ilist = $self->filter_unique($ilist);
        } else {
            warn "discarding '$action', can't do that";
        }
        $pt = $pt->{'next'};
    }
    return @$ilist;
}

sub select_name {
    my $self = shift;
    my $ilist = shift;
    my @names = @_;
    my $nlist = [ ];
    
    my %names = map { $_ => 1 } @names;
    
    for(my $i = 0; $i < @$ilist; $i ++) {
        if($names{$ilist->[$i]->type}) {
            push @$nlist, $ilist->[$i];
        };
    }
    return $nlist;
}

sub select_union {
    my $self = shift;
    my $class = ref $self;

    my $ilist = shift;
    my $left = shift;
    my $right = shift;
    
    my $l_path = $class->new('union left', $left);
    my $r_path = $class->new('union right', $right);
    
    my @l_result = $l_path->process(@$ilist);
    my @r_result = $r_path->process(@$ilist);
    
    return [ @l_result, @r_result ];
}

sub select_intersect {
    my $self = shift;
    my $class = ref $self;
    
    my $ilist = shift;
    my $left = shift;
    my $right = shift;
    
    my $l_path = $class->new("intersect left", $left);
    my $r_path = $class->new("intersect right", $right);
    
    my @l_result = $l_path->process(@$ilist);
    my @r_result = $r_path->process(@$ilist);
    
    my %seen = ( );
    my $nlist = [ ];
    foreach my $a (@l_result) {
        $seen{$a->serial} = 1;
    }
    foreach my $b (@r_result) {
        push @$nlist, $b if $seen{$b->serial};
    }
    
    return $nlist;
}

sub select_attr {
    my $self = shift;
    my $ilist = shift;
    my $name = shift;
    my $nlist = [ ];
    
    foreach my $i (@$ilist) {
        my $pv = $i->param($name);
        if($pv) {
            push @$nlist, $pv;
        }
    }
    return $nlist;
}

sub select_index {
    my $self = shift;
    my $ilist = shift;
    my $index = shift;
    
    if($index < scalar @$ilist) {
        return [ $ilist->[$index] ];
    } else {
        return [ ];
    }
}

sub match_expression {
    my $self = shift;
    my $ilist = shift;
    my $test_action = shift;
    my $invert = shift;
    my $exp = shift;
    my $r_exp = shift;
    
    my $op = shift; # Only for some operators
    
    my $nlist = [ ];
    foreach my $n(@$ilist) {
        my @t_list = $exp->process($n);
        my $t_result;
        # Allow for r_exp to be another expression - generate both
        # node lists if required.
        if( eval { $r_exp->can('process') } ) {
            my @r_list = $r_exp->process($n);
            $t_result = $self->$test_action(\@t_list, \@r_list, $op);
        } else {
            $t_result = $self->$test_action(\@t_list, $r_exp, $op);
        }
        $t_result = !$t_result if $invert;
        if($t_result) {
            push @$nlist, $n;
        }
    }
    return $nlist;
}

sub test_cmp_op {
    my $self = shift;
    my $l_list = shift;
    my $r_exp = shift;
    my $op = shift;
    
    if(scalar(@$r_exp) == 0 || eval { $r_exp->[0]->isa('Pod::Abstract::Node') }) {
        # combination test
        my $match = 0;
        foreach my $l (@$l_list) {
            my $lb = $l->body;
            $lb = $l->pod unless $lb;
            foreach my $r (@$r_exp) {
                my $rb = $r->body;
                $rb = $r->pod unless $rb;
                eval "\$match++ if \$lb $op \$rb";
                die $@ if $@;
            }
        }
        return $match;
    } elsif($r_exp->[0] == STRING) {
        # simple string test
        my $str = $r_exp->[1];
        my $match = 0;
        foreach my $l (@$l_list) {
            my $lb = $l->body;
            $lb = $l->pod unless $lb;
            eval "\$match++ if \$lb $op \$str";
            die $@ if $@;
        }
        return $match;
    } else {
        die "Don't know what to do with ", Dumper([$r_exp]);
    }
}

sub test_regexp {
    my $self = shift;
    my $t_list = shift;
    my $regexp_set = shift;
    my $regexp = $regexp_set->[0];
    my $case = $regexp_set->[1];
    if($case) {
        $regexp = qr/$regexp/;
    } else {
        $regexp = qr/$regexp/i;
    }

    my $match = 0;
    foreach my $t_n (@$t_list) {
        my $body = $t_n->body;
        $body = $t_n->pod unless defined $body;
        if($body =~ $regexp) {
            $match ++;
        }
    }
    return $match;
}

sub test_simple {
    my $self = shift;
    my $t_list = shift;
    
    return (scalar @$t_list) > 0;
}

sub select_children {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        my @children = $n->children;
        push @$nlist, @children;
    }
    
    return $nlist;
}

sub select_next {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        my $next = $n->next;
        if($next) {
            push @$nlist, $next;
        }
    }
    
    return $nlist;
}

sub select_prev {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        my $prev = $n->previous;
        if($prev) {
            push @$nlist, $prev;
        }
    }
    
    return $nlist;
}

sub select_parents {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    foreach my $n (@$ilist) {
        if($n->parent) {
            push @$nlist, $n->parent;
        }
    }
    
    return $nlist;
}

sub select_root {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    foreach my $n (@$ilist) {
        push @$nlist, $n->root; # almost certainly all the same - not
                                # efficient but consistent.
    }
    
    return $nlist;
}

sub select_current {
    my $self = shift;
    my $ilist = shift;
    return $ilist;
}

sub select_all {
    my $self = shift;
    my $ilist = shift;
    my $nlist = [ ];
    
    foreach my $n (@$ilist) {
        push @$nlist, $self->expand_all($n);
    }
    
    return $nlist;
}

sub expand_all {
    my $self = shift;
    my $n = shift;
    
    my @children = $n->children;
    my @r = ( );
    foreach my $c (@children) {
        push @r, $c;
        push @r, $self->expand_all($c);
    };
    
    return @r;
}

=head2 parse_path

Parse a list of lexemes and generate a driver tree for the process
method. This is a simple recursive descent parser with one element of
lookahead.

=cut

sub parse_path {
    my $self = shift;
    my $l = shift;
    
    my $left = $self->parse_l_path($l);
    
    # Handle UNION or INTERSECT operators
    my $next = shift @$l;
    if($next) {
        my $tok = $next->[0];
        if($tok == UNION) {
            return {
                action => "select_union",
                arguments => [ $left, $self->parse_path($l) ],
            };
        } elsif($tok == INTERSECT) {
            return {
                action => "select_intersect",
                arguments => [ $left, $self->parse_path($l) ],
            }
        } else {
            unshift @$l, $next;
            return $left;
        }
    } else {
        return $left;
    }
}


sub parse_l_path {
    my $self = shift;
    my $l = shift;
    
    my $next = shift @$l;
    my $tok = $next->[0] if $next;
    my $val = $next->[1] if $next;
    
    # Accept: / (children), // (all), name, <select>, @attr, .index
    if(not defined $next) {
        return {
            'action' => 'end_select',
        };
    } elsif(grep { $tok == $_ } 
            (MATCHES, R_SELECT, S_CMP, N_CMP, UNION, INTERSECT)) {
        unshift @$l, $next;
        return {
            'action' => 'end_select',
        };
    } elsif($tok == CHILDREN) {
        return { 
            'action' => 'select_children',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == ALL) {
        return {
            'action' => 'select_all',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == NEXT) {
        return {
            'action' => 'select_next',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == PREV) {
        return {
            'action' => 'select_prev',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == PARENT) {
        return {
            'action' => 'select_parents',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == ROOT) {
        return {
            'action' => 'select_root',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == NOP) {
        return {
            'action' => 'select_current',
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == NAME) {
        my @extra_names = $self->parse_names($l);
        return {
            'action' => 'select_name',
            'arguments' => [ $val, @extra_names ],
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == ATTR) {
        return {
            'action' => 'select_attr',
            'arguments' => [ $val ],
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == INDEX) {
        return {
            'action' => 'select_index',
            'arguments' => [ $val ],
            'next' => $self->parse_l_path($l),
        };
    } elsif($tok == L_SELECT) {
        unshift @$l, $next;
        my $exp = $self->parse_expression($l);
        $exp->{'next'} = $self->parse_l_path($l);
        return $exp;
    } elsif($tok == ATTR) {
        return {
            'action' => 'select_attribute',
            'arguments' => [ $val ],
            'next' => $self->parse_l_path($l),
        }
    } else {
        die "Unexpected token, ", Dumper([$next]);
    }
}

sub parse_names {
    my $self = shift;
    my $l = shift;
    my @r = ( );
    
    # Collect a list of names until there are no more.
    while(@$l && $l->[0][0] == NAME) {
        my $next = shift @$l;
        my $val = $next->[1];
        push @r, $val;
    }
    
    return @r;
}

sub parse_expression {
    my $self = shift;
    my $class = ref $self;
    my $l = shift;
    
    my $l_select = shift @$l;
    die "Expected L_SELECT, got ", Dumper([$l_select])
        unless $l_select->[0] == L_SELECT;
    
    # See if we lead with a NOT
    if($l->[0][0] == NOT) {
        shift @$l;
        unshift @$l, $l_select;
        
        my $exp = $self->parse_expression($l);
        $exp->{arguments}[1] = !$exp->{arguments}[1];
        return $exp;
    }
    
    my $l_exp = $self->parse_path($l);
    $l_exp = $class->new("select expression",$l_exp);
    my $op = shift @$l;
    my $op_tok = $op->[0];
    my $op_val = $op->[1];
    my $exp = undef;
    
    if($op_tok == MATCHES) {
        my $re = shift @$l;
        my $re_tok = $re->[0];
        my $re_str = $re->[1];
        my $case_sensitive = $re->[2];
        
        if($re_tok == REGEXP) {
            $exp = {
                'action' => 'match_expression',
                'arguments' => [ 'test_regexp', 0, 
                                 $l_exp, 
                                 [ $re_str, $case_sensitive ] ],
            }
        } else {
            die "Expected REGEXP, got ", Dumper([$re_tok]);
        }
    } elsif($op_tok == S_CMP || $op_tok == N_CMP) {
        my $rh = shift @$l;
        my $rh_tok = $rh->[0];
        my $r_exp = undef;
        
        if($rh_tok == STRING) { # simple string equality
            $r_exp = $rh;
        } else {
            unshift @$l, $rh;
            $r_exp = $self->parse_path($l);
            $r_exp = $class->new("select expression",$r_exp);
        }
        $exp = {
            action => 'match_expression',
            arguments => [ 'test_cmp_op', 0,
                           $l_exp, $r_exp, $op_val ],
        };
    } elsif($op_tok == R_SELECT) {
        # simple expression
        unshift @$l, $op;
        $exp = {
            'action' => 'match_expression',
            'arguments' => [ 'test_simple', 0, $l_exp ],
        }
    } else {
        die "Expected MATCHES, got ", Dumper([$op_tok]);
    }
    
    # Must match close of select;
    my $r_select = shift @$l;
    die "Expected R_SELECT, got, ", Dumper([$r_select])
        unless $r_select->[0] == R_SELECT;
    die "Failed to generate expression"
        unless $exp;
    
    # All OK!
    return $exp;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
 
