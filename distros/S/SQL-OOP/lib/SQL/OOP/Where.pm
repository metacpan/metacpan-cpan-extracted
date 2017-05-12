package SQL::OOP::Where;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use SQL::OOP::ID;

### ---
### Constructor
### ---
sub new {
    my $class = shift;
    return bless {}, $class;
}

### ---
### SQL::Abstract style AND factory
### ---
sub and_hash {
    warn 'Deprecated infavor of and_abstract';
    my ($class, $hash_ref, $op) = @_;
    return _append_hash($class->and, $hash_ref, $op || '=');
}

### ---
### SQL::Abstract style OR factory
### ---
sub or_hash {
    warn 'Deprecated infavor of or_abstract';
    my ($class, $hash_ref, $op) = @_;
    return _append_hash($class->or, $hash_ref, $op || '=');
}

### ---
### SQL::Abstract style AND factory
### ---
sub and_abstract {
    my ($class, $array_ref, $op) = @_;
    return _append_hash($class->and, $array_ref, $op || '=');
}

### ---
### SQL::Abstract style OR factory
### ---
sub or_abstract {
    my ($class, $array_ref, $op) = @_;
    return _append_hash($class->or, $array_ref, $op || '=');
}

### ---
### SQL::Abstract style AND factory backend
### ---
sub _append_hash {
    my ($obj, $array_ref, $op) = @_;
    my @copied = ref $array_ref eq 'HASH' ? %{$array_ref} : @{$array_ref};
    while (my($key, $val) = splice @copied, 0, 2) {
        $obj->append(__PACKAGE__->cmp($op || '=', $key, $val));
    }
    return $obj;
}

### ---
### AND factory
### ---
sub and {
    my ($class, @array) = @_;
    return SQL::OOP::Array->new(@array)->set_sepa(' AND ');
}

### ---
### OR factory
### ---
sub or {
    my ($class, @array) = @_;
    return SQL::OOP::Array->new(@array)->set_sepa(' OR ');
}

### ---
### binary operator expression factory
### ---
sub cmp {
    my ($self, $op, $key, $val) = @_;
    if (scalar @_ != 4) {
        die 'Not enough args given';
    }
    if ($key && defined $val) {
        my $quoted = SQL::OOP::ID->new($key);
        if (ref $val) {
            return SQL::OOP::Array->new($quoted->to_string, $val)->set_sepa(" $op ");
        }
        return SQL::OOP::Base->new($quoted->to_string. qq( $op ?), [$val]);
    }
}

### ---
### binary operator expression factory with sub query in value [DEPRECATED]
### ---
sub cmp_nested {
    warn 'cmp_nested is deprecated! Use cmp instead';
    my ($self, $op, $key, $val) = @_;
    if (scalar @_ != 4) {
        die 'Not enough args given';
    }
    if ($key && defined $val) {
        my $quoted = SQL::OOP::ID->new($key);
        return SQL::OOP::Array->new($quoted->to_string, $val)->set_sepa(" $op ");
    }
}

### ---
### IS NULL factory
### ---
sub is_null {
    my ($self, $key) = @_;
    if ($key) {
        my $quoted = SQL::OOP::ID->new($key);
        return SQL::OOP::Base->new($quoted->to_string. qq( IS NULL));
    }
}

### ---
### IS NOT NULL factory
### ---
sub is_not_null {
    my ($self, $key) = @_;
    if ($key) {
        my $quoted = SQL::OOP::ID->new($key);
        return SQL::OOP::Base->new($quoted->to_string. qq( IS NOT NULL));
    }
}

### ---
### BETWEEN ? AND ? factory
### ---
sub between {
    my ($self, $key, $val1, $val2) = @_;
    if ($key) {
        if (defined $val1 and defined $val2) {
            my $quoted = SQL::OOP::ID->new($key)->to_string;
            my $str = $quoted. qq( BETWEEN ? AND ?);
            return SQL::OOP::Base->new($str, [$val1, $val2]);
        } elsif (defined $val1) {
            return $self->cmp('>=', $key, $val1);
        } else {
            return $self->cmp('<=', $key, $val2);
        }
    }
}

### ---
### IN factory
### ---
sub in {
    my ($self, $key, $val) = @_;
    if ($key) {
        my $quoted = SQL::OOP::ID->new($key)->to_string;
        if (ref $val eq 'ARRAY') {
            my $placeholder = '?, ' x scalar @$val;
            $placeholder = substr($placeholder, 0, -2);
            return SQL::OOP::Base->new("$quoted IN ($placeholder)", $val);
        } elsif (blessed($val) && $val->isa('SQL::OOP::Base')) {
            return SQL::OOP::Array->new($quoted, $val)->set_sepa(" IN ");
        }
    }
}

### ---
### NOT IN factory
### ---
sub not_in {
    my ($self, $key, $val) = @_;
    if ($key) {
        my $quoted = SQL::OOP::ID->new($key)->to_string;
        if (ref $val eq 'ARRAY') {
            my $placeholder = '?, ' x scalar @$val;
            $placeholder = substr($placeholder, 0, -2);
            return SQL::OOP::Base->new("$quoted NOT IN ($placeholder)", $val);
        } elsif (blessed($val) && $val->isa('SQL::OOP::Base')) {
            return SQL::OOP::Array->new($quoted, $val)->set_sepa(" NOT IN ");
        }
    }
}

1;

__END__

=head1 NAME

SQL::OOP::Where - WHERE factory class

=head1 SYNOPSIS
    
    use SQL::OOP::Where;
    
    my $where = SQL::OOP::Where->new();
    my $cond1 = $where->cmp($operator, $field, $value);
    my $cond2 = $where->is_null('some_field');
    my $cond3 = $where->is_not_null('some_field');
    my $cond4 = $where->between('some_field', 1, 2);
    my $cond5 = $where->in('some_field', [1, 2, 3]);
    
    my $sql  = $cond1->to_string;
    my @bind = $cond1->bind;
    
    # combine conditions
    my $cond7 = $where->or($cond1, $cond2);
    $cond7->append($cond3);
    my $cond8 = $where->and($cond7, $where->and($cond4, $cond5));
    
    my $sql  = $cond8->to_string;
    my @bind = $cond8->bind;
    
    # SQL::Abstract style
    my $seed = [a => 'b', c => 'd'];
    my $cond10 = $where->and_abstract($seed); # default operator is '='
    my $cond11 = $where->and_abstract($seed, "LIKE");
    my $cond12 = $where->or_abstract($seed); # default operator is '='
    my $cond13 = $where->or_abstract($seed, "LIKE");
    
    my $sql  = $cond13->to_string;
    my @bind = $cond13->bind;

=head1 DESCRIPTION

SQL::OOP::Where is a Factory Class for WHERE clause elements.
All methods of this returns SQL::OOP::Base or SQL::OOP::Array.

=head1 METHODS

=head2 SQL::OOP::Where->new

Returns SQL::OOP::Where instance. This class instance is just for convenience.
All methods in this class also can be called as Class method.

    my $util = SQL::OOP::Where->new;

=head2 $instance->cmp($operator, $fieldname, $value)

Generates 1 operator expression.

    my $where = SQL::OOP::Where->new;
    $where->cmp('=', 'col1', 'value') # "col1" = ?
    $where->cmp('=', ['table', 'col1'], 'value') # "table"."col1" = ?
    $where->cmp('=', $subquery, $subquery)

=head2 $instance->cmp_nested($fieldname, $object) [DEPRECATED]

Generates 1 operator expression with sub query in value.

=head2 $instance->in($fieldname, $array_ref)

Generates IN clause

    my $where = SQL::OOP::Where->new;
    $where->in('col1', ['candidate1', 'candidate2']) # "col1" IN (?, ?)
    $where->in(['table', 'col1'], ['c1', 'c2']) # "table"."col1" IN (?, ?)

=head2 $instance->not_in($fieldname, $array_ref)

Generates NOT IN clause

    my $where = SQL::OOP::Where->new;
    $where->not_in('col1', ['val1', 'val2']) # "col1" NOT IN (?, ?)
    $where->not_in(['tbl', 'col1'], ['v1', 'v2']) # "tbl"."col1" NOT IN (?, ?)

=head2 $instance->between($fieldname, $upper, $lower)

Generates BETWEEN clause

    my $where = SQL::OOP::Where->new;
    $where->between('col1', 5, 10]) # "col1" BETWEEN ? AND ?
    $where->between(['table', 'col1'], 5, 10) # "table"."col1" BETWEEN ? AND ?

=head2 $instance->is_not_null($fieldname)

Generates IS NOT NULL clause

    my $where = SQL::OOP::Where->new;
    $where->is_not_null('col1') # "col1" IS NOT NULL
    $where->is_not_null(['table', 'col1']) # "table"."col1" IS NOT NULL

=head2 $instance->is_null($fieldname)

Generates IS NULL clause

    my $where = SQL::OOP::Where->new;
    $where->is_null('col1') # "col1" IS NULL
    $where->is_null(['table', 'col1']) # "table"."col1" IS NULL

=head2 $instance->or(@array)

Generates OR expression in SQL::OOP::Array

=head2 $instance->or_hash(%hash_ref) DEPRECATED

Generates OR expression in SQL::OOP::Array by hash

=head2 $instance->or_abstract($array_ref)

Generates OR expression in SQL::OOP::Array by key-value array

=head2 $instance->and(@array)

Generates AND expression in SQL::OOP::Array

=head2 $instance->and_hash(%hash_ref) DEPRECATED

Generates AND expression in SQL::OOP::Array by hash

=head2 $instance->and_abstract($array_ref)

Generates AND expression in SQL::OOP::Array by key-value array

=head1 SEE ALSO

=cut
