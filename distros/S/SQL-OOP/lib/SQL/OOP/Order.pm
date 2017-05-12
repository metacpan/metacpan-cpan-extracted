package SQL::OOP::Order;
use strict;
use warnings;
use SQL::OOP::Base;
use base qw(SQL::OOP::Array);

### ---
### Constructor
### ---
sub new {
    my ($class, @array) = @_;
    return $class->SUPER::new(
                        map {SQL::OOP::ID->new($_)} @array)->set_sepa(', ');
}

### ---
### fix generated string in list context
### ---
sub fix_element_in_list_context {
    my ($self, $obj) = @_;
    return $obj->to_string;
}

### ---
### Construct ORER BY clause by array
### ---
sub abstract {
    my ($class, $array_ref) = @_;
    my $self = $class->SUPER::new()->set_sepa(', ');
    foreach my $rec_ref (@{$array_ref}) {
        if (ref $rec_ref) {
            if ($rec_ref->[1]) {
                $self->append_desc($rec_ref->[0]);
            } else {
                $self->append_asc($rec_ref->[0]);
            }
        } else {
            $self->append_asc($rec_ref);
        }
    }
    return $self;
}

### ---
### Get SQL::OOP::Order::Expression instance(ASC)
### ---
sub new_asc {
    my ($class_or_obj, $key) = @_;
    return SQL::OOP::Order::Expression->new($key);
}

### ---
### Get SQL::OOP::Order::Expression instance(DESC)
### ---
sub new_desc {
    my ($class_or_obj, $key) = @_;
    return SQL::OOP::Order::Expression->new_desc($key);
}

### ---
### Append element(ASC)
### ---
sub append_asc {
    my ($self, $key) = @_;
    $self->_init_gen;
    push(@{$self->{array}}, SQL::OOP::Order::Expression->new($key));
    return $self;
}

### ---
### Append element(DESC)
### ---
sub append_desc {
    my ($self, $key) = @_;
    $self->_init_gen;
    push(@{$self->{array}}, SQL::OOP::Order::Expression->new_desc($key));
    return $self;
}

package SQL::OOP::Order::Expression;
use strict;
use warnings;
use base qw(SQL::OOP::Base);

### ---
### Constructor
### ---
sub new {
    my ($class, $key) = @_;
    if ($key) {
        return $class->SUPER::new(SQL::OOP::ID->new($key));
    }
}

### ---
### DESC Constructor
### ---
sub new_desc {
    my ($class, $key) = @_;
    if ($key) {
        return $class->SUPER::new(
                            SQL::OOP::ID->new($key)->to_string. " DESC");
    }
}

1;

__END__

=head1 NAME

SQL::OOP::Order - ORDER BY class

=head1 SYNOPSIS

    $order = SQL::OOP::Order->new('a', 'b');
    $order->to_string;
    $order->bind;

=head1 DESCRIPTION

SQL::OOP::Order class represents ORDER BY clause.

=head2 SQL::OOP::Order->new(@array);

Constructor.

    my $order = SQL::OOP::Order->new('a', 'b', 'c');
    
    $order->to_string ## "a", "b", "c"

=head2 $instance->append_asc($key);

=head2 $instance->append_desc($key);
    
    my $order = SQL::OOP::Order->new;
    $order->append_asc('age');
    $order->append_desc('address');
    $order->to_string; # "age", "address" DESC

=head2 SQL::OOP::Order->new_asc();

Constructor for ASC expression. This returns SQL::OOP::Order::Expression
instance which can be thrown at SQL::OOP::Order class constructor or instances.

=head2 SQL::OOP::Order->new_desc();

Constructor for DESC expression. This returns SQL::OOP::Order::Expression
instance which can be thrown at SQL::OOP::Order class Constructor or instances.

=head2 SQL::OOP::Order->abstract

Construct by array ref

    SQL::OOP::Order->abstract([['col1', 1], 'col2']);   # "col1" DESC, "col2"
    SQL::OOP::Order->abstract([['col1', 1], ['col2']]); # "col1" DESC, "col2"

=head2 $instance->append_asc

Append ASC entry

=head2 $instance->append_desc

Append DESC entry

=head2 $instance->fix_element_in_list_context

Internal use.

=head1 SEE ALSO

=cut
