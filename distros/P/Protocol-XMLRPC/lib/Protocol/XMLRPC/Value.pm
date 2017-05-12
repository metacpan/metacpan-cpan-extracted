package Protocol::XMLRPC::Value;

use strict;
use warnings;

use overload '""'   => sub { shift->to_string }, fallback => 1;
use overload 'bool' => sub { shift->value }, fallback => 1;

sub new {
    my $class = shift;

    my $value; $value = shift if @_ % 2;

    my $self = {@_};
    bless $self, $class;

    $self->value($value) if defined $value;

    return $self;
}

sub value { @_ > 1 ? $_[0]->{value} = $_[1] : $_[0]->{value} }

sub to_string { '' }

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value - a base class for scalar values

=head1 SYNOPSIS

    package Protocol::XMLRPC::Value::Boolean;

    use strict;
    use warnings;

    use base 'Protocol::XMLRPC::Value';

    ...

    1;

=head1 DESCRIPTION

This is a base class for all scalar types. Used internally.

=head1 ATTRIBUTES

=head2 C<value>

Hold parameter value.

=head1 METHODS

=head2 C<new>

Returns new L<Protocol::XMLRPC::Value> instance.

=head2 C<to_string>

String representation.
