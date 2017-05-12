package Protocol::XMLRPC::Value::Array;

use strict;
use warnings;

use Protocol::XMLRPC::ValueFactory;

use overload '""' => sub { shift->to_string }, fallback => 1;

sub new {
    my $class = shift;

    my @values;

    if (@_ == 1) {
        @values = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : ($_[0]);
    }
    else {
        @values = @_;
    }

    my $self = {};
    bless $self, $class;

    $self->{data} ||= [];

    foreach my $value (@values) {
        $self->add_data($value);
    }

    return $self;
}

sub type {'array'}

sub data { defined $_[1] ? $_[0]->{data} = $_[1] : $_[0]->{data} }

sub add_data {
    my $self = shift;
    my ($param) = @_;

    my $value = Protocol::XMLRPC::ValueFactory->build($param);
    return unless defined $value;

    push @{$self->data}, $value;
}

sub value {
    my $self = shift;

    return [map { $_->value } @{$self->data}];
}

sub to_string {
    my $self = shift;

    my $string = '<array><data>';

    foreach my $data (@{$self->data}) {
        my $value = $data->to_string;

        $string .= "<value>$value</value>";
    }

    $string .= '</data></array>';

    return $string;
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::Array - XML-RPC array

=head1 SYNOPSIS

    my $array = Protocol::XMLRPC::Value::Array->new(1, 2, 3);
    my $array = Protocol::XMLRPC::Value::Array->new([1, 2, 3]);
    my $array = Protocol::XMLRPC::Value::Array->new([1]);
    my $array = Protocol::XMLRPC::Value::Array->new(
        [Protocol::XMLRPC::Value::Double->new(1.2)]);

=head1 DESCRIPTION

XML-RPC array

=head1 ATTRIBUTES

=head2 C<data>

    my $data = $array->data;
    $data->[0]->value;

Holds elements as objects.

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::Array> instance. Elements can be provided
as an array or as an array reference.

=head2 C<type>

Returns 'array'.

=head2 C<add_data>

    $array->add_data(1);
    $array->add_data([1]);
    $array->add_data(Protocol::XMLRPC::Value::String->new('foo'));

Adds value to the array. Can be Perl5 scalar or any Protocol::XMLRCP::Value::*
instance, including another array.

=head2 C<value>

    my $array = Protocol::XMLRPC::Value::Array->new(1, 2, 3);
    my $arrayref = $array->value;
    # $arrayref is now [1, 2, 3]

Returns serialized Perl5 array reference.

=head2 C<to_string>

    my $array = Protocol::XMLRPC::Value::Array->new(12);
    my $string = $array->to_string;
    # <array>
    #   <data>
    #     <value><i4>12</i4></value>
    #   </data>
    # </array>'

XML-RPC array string representation.
