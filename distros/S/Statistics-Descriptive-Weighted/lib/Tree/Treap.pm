package Tree::Treap;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';

my %comp = ( str  => sub {return $_[0] cmp $_[1]},
             rstr => sub {return $_[1] cmp $_[0]},
             num  => sub {return $_[0] <=> $_[1]},
             rnum => sub {return $_[1] <=> $_[0]},
           );

sub new {
    my $class = shift;
    $class = ref($class)||$class;
    my $self  = bless {}, $class;
    my $cmp = shift || "str";
    if(ref($cmp) eq 'CODE'){
        $self->{cmp} = $cmp;
    } else {
        $self->{cmp} = $comp{$cmp} || $comp{num};
    }
    $self->{priority} = -100;
    $self->initialize(@_);
    return $self;
}

sub initialize {}

sub insert {
    my $self = shift;
    my $key  = shift;
    my $data = shift;
    $data = defined($data)? $data : $key;
    my $priority = shift() || rand();
    
    if($self->_is_empty()) {
        $self->{priority} = $priority,
        $self->{key}      = $key;
        $self->{data}     = $data;
        $self->{left}     = $self->new($self->{cmp});
        $self->{right}    = $self->new($self->{cmp});
        return $self;
    }
    
    if($self->gt($key)){
        $self->{right}->insert($key,$data,$priority);
        if($self->{right}->{priority} > $self->{priority}){
            $self->_rotate_left();
        }
    }elsif($self->lt($key)){
        $self->{left}->insert($key,$data,$priority);
        if($self->{left}->{priority} > $self->{priority}){
            $self->_rotate_right();
        }

    }else{
        $self->_delete_node();
        $self->insert($key,$data,$priority);
    }
    return $self;
}

sub delete {
    my $self = shift;
    my $key  = shift;
    return 0 unless $self = $self->_get_node($key);
    $self->_delete_node();
}


sub _delete_node {
    my $self = shift;
    if($self->_is_leaf()) {
        %$self = (priority => -100, cmp => $self->{cmp});
    } elsif ($self->{left}->{priority} > $self->{right}->{priority}) {
        $self->_rotate_right();
        $self->{right}->_delete_node();
    } else {
        $self->_rotate_left();
        $self->{left}->_delete_node();
    }
}


sub keys {
    my $self = shift;
    return () if $self -> _is_empty ();
    ($self->{left}->keys(), $self->{key}, $self->{right}->keys());
}

sub keys_post {
    my $self = shift;
    return () if $self->_is_empty();
    ($self->{left}->keys_post(), $self->{right}->keys_post(),$self->{key});
}

sub keys_pre {
    my $self = shift;
    return () if $self->_is_empty();
    ($self->{key},$self->{left}->keys_pre(), $self->{right}->keys_pre());
}

sub values {
    my $self = shift;
    return () if $self->_is_empty ();
    ($self->{left}->values(), $self->{data}, $self->{right}->values());
}

sub exists {
    my $self = shift;
    my $key  = shift;
    return 1 if $self->_get_node($key);
    return;
}

sub get_val {
    my $node = _get_node(@_);
    return $node ? $node->{data} : undef;
}


sub _get_node {
    my $self = shift;
    my $key  = shift;
    while(!$self->_is_empty() and $self->ne($key)){
        $self = $self->{$self->lt($key)?"left":"right"}
    }
    return $self->_is_empty() ? 0 : $self;
}


sub range_keys {
    my $self = shift;
    my @keys = map{$_->{key}} $self->_range_nodes(@_);
    return @keys;
}
sub range_values {
    my $self = shift;
    my @values = map{$_->{data}} $self->_range_nodes(@_);
    return @values;
}

sub _range_nodes {
    my $self = shift;
    my $low  = shift;
    my $high   = shift;
    my @return;
    return () if $self->_is_empty ();

    if (!defined $low || $self->lt($low)) {
        push @return, $self->{left}->_range_nodes($low, $high);
    }

    if ((!defined $low || $self->le($low)) &&
        (!defined $high   || $self->ge($high))) {
        push @return, $self;
    }

    if (!defined $high   || $self->gt($high)) {
        push @return, $self->{right}->_range_nodes($low, $high);
    }

    @return;
}


sub split {
    my $self = shift;
    my $key  = shift;
    $self->insert($key,undef,100);
    my($T1, $T2) = ($self->{left},$self->{right});
    $self->delete($key);
    return ($T1,$T2);
}

sub join {
    my $self = shift;
    my $T1   = shift;
    my $T2   = shift;
    if($T1->{cmp}->($T1->maximum(),$T2->minimum())>=0){
        warn "Tree1 must be less than Tree2 in join()";
        return;
    }
    my $cat  = $self->new($self->{cmp});
    ($cat->{left}, $cat->{right}) = ($T1,$T2);
    $cat->_delete_node();
    return $cat;
}


sub minimum {
    my $self = shift;
    return if $self->_is_empty();
    while ( not $self->{left}->_is_empty()){
        $self = $self->{left};
    }
    return $self->{key};
}
sub maximum {
    my $self = shift;
    return if $self->_is_empty();
    while ( not $self->{right}->_is_empty()){
        $self = $self->{right};
    }
    return $self->{key};
}


sub as_string {
    my $self = shift;
    my $mult = shift || 1;
    my $indent = " " x $mult;
    return "$indent+\n" if $self -> _is_empty ();
    return $self->{right}->as_string($mult + 2) .
           "$indent+-$self->{key}\n"               .
           $self->{left}->as_string($mult + 2);
}


sub max_height {
    my $self = shift;
    my $depth = shift||0;
    return $depth - 1  if $self->_is_empty();
    my $left = $self->{left}->max_height($depth + 1);
    my $right = $self->{right}->max_height($depth + 1);
    $depth = $left if $left > $depth;
    $depth = $right if $right > $depth;
    return $depth;
}

sub successor {
    my $self = shift;
    my $key  = shift;
    my $ret = $self->_successor($key)->{key};
    $ret;
}
sub _successor {
    my $self = shift;
    my $key  = shift;
    return $self if $self->_is_empty();
    return $self->{right}->_successor($key) if $self->ge($key);
    my $succ;
    $succ = $self->{left}->_successor($key) if $self->lt($key);
    $succ->_is_empty()? $self : $succ;
}

sub predecessor {
    my $self = shift;
    my $key  = shift;
    my $ret = $self->_predecessor($key)->{key};
    $ret;
}
sub _predecessor {
    my $self = shift;
    my $key  = shift;
    return $self if $self->_is_empty ();
    return $self->{left}->_predecessor($key) if $self->le($key);
    my $pred;
    $pred = $self->{right}->_predecessor ($key) if $self->gt($key);
    $pred->_is_empty () ? $self : $pred;
}


sub CMP {
    my $self = shift; 
    my $key  = shift;
    my $cmp  = $self->{cmp};
    $cmp->($key, $self->{key});
}

sub lt  {shift->CMP(@_) <  0;}
sub le  {shift->CMP(@_) <= 0;}
sub eq  {shift->CMP(@_) == 0;}
sub ne  {shift->CMP(@_) != 0;}
sub ge  {shift->CMP(@_) >= 0;}
sub gt  {shift->CMP(@_) >  0;}
sub cmp {shift->CMP(@_)}


sub _clone_node  {
    my $self  = shift;
    my $other = shift;
    %$self = %$other;
}

sub _rotate_left {
    my $self = shift;
    my $tmp = $self->new($self->{cmp});
    $tmp->_clone_node($self);
    $self->_clone_node($self->{right});
    $tmp->{right} = $self->{left};
    $self->{left} = $tmp;
    
}

sub _rotate_right {
    my $self = shift;
    my $tmp = $self->new($self->{cmp});
    $tmp->_clone_node($self);
    $self->_clone_node($self->{left});
    $tmp->{left} = $self->{right};
    $self->{right} = $tmp;
}


sub _is_empty {!defined shift->{key}}

sub _is_leaf {
    my $self = shift;
    return $self->{left}->_is_empty() && 
           $self->{right}->_is_empty();
}



1;
__END__

=head1 NAME

Tree::Treap - randomized binary search trees via the treap structure

=head1 SYNOPSIS

    use Tree::Treap;
    my $T = Tree::Treap->new();
    

=head1 DESCRIPTION

A treap is a randomized binary search tree which takes a standard
binary search tree and assigns random priorities to each node as
they are created/inserted. The inorder property of a binary tree
is maintained on the node-keys, and the heap property is also
maintained on the node-priorities. It is this second step that
randomizes the tree. Tree + Heap = Treap.

The structure is relatively efficient in space and time --- the
expected runtime of insertion and deletion is O(log n), with few
rotations required.

=head1 PUBLIC METHODS

=over 4

=item new()

The constructor takes one optional argument to determine the ordering
of keys in the tree. This argument can either one of four strings:
"str", "rstr", "num", or "rnum" (string, reverse string, numeric, and 
reverse numeric respectively), or a reference to a custom
comparison routine that returns -1,0,1 to determine the relative
ordering of keys.

=item insert($key, $value)

Inserts a node containing the key and value into the treap. The value
may be any scalar value (string, number, reference). The key should
of course be compatible with the comparison routine. If the key exists,
its value is set to the new value.

=item delete($key)

Deletes the node with the given key from the treap.

=item exists($key)

Returns true if the key exists in the treap, false otherwise.

=item get_val($key)

Returns the value for the given key, or undef if the key does
not exists in the treap.

=item keys()

Returns a list of all the keys in the treap (inorder)

=item range_keys($lo_key, $hi_key2)

Returns the list of keys greater than or equal to $lo_key and less than
or equal to $hi_key. If either argument is missing or undefined then
the lowest or highest key in the hash is used.

=item range_values($lo_key, $hi_key)

Returns the list of values corresponding the range of keys given (see
range_keys() above).

=item minimum()

Returns the lowest ordered key in the treap.

=item maximum()

Returns the highest ordered key in the treap.

=item successor($key)

Given a key it returns the next ordered key in the treap, or undef.

=item predecessor($key)

Given a key it returns the previous ordered key in the treap, or undef.

=back

=head1 TODO

=over 4

=item 

Implement split() and join() methods. (partially done)

=item

Replace some of the recursive methods with iterative versions.

=item

Currently nodes do not store a reference to their parent node.
Storing a weakened ref to a parent would allow efficient tree 
walking routines (via successor() and predecessor()) for use in
scalar context, without any overhead dealing with circular
references.

=back

=head1 AUTHOR

Copyright 2002-2005 Andrew Johnson (ajohnson@cpan.org). This is free
software released under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Tie::Hash::Treap>

=cut
