package Protocol::XMLRPC::Value::Struct;

use strict;
use warnings;

use Protocol::XMLRPC::ValueFactory;

use overload '""' => sub { shift->to_string }, fallback => 1;

sub type {'struct'}

sub new {
    my $class = shift;

    my @values;

    if (@_ == 1) {
        @values = ref($_[0]) eq 'HASH' ? %{$_[0]} : ($_[0]);
    }
    else {
        @values = @_;
    }

    my $self = {};
    bless $self, $class;

    $self->{_members} = [];

    for (my $i = 0; $i < @values; $i += 2) {
        my $name  = $values[$i];
        my $value = $values[$i + 1];

        $self->add_member($name => $value);
    }

    return $self;
}

sub add_member {
    my $self = shift;
    my ($key, $value) = @_;

    push @{$self->{_members}},
      ($key => Protocol::XMLRPC::ValueFactory->build($value));
}

sub members {
    my $self = shift;

    return {@{$self->{_members}}};
}

sub value {
    my $self = shift;

    my $hash = {};
    for (my $i = 0; $i < @{$self->{_members}}; $i += 2) {
        my $name = $self->{_members}->[$i];
        my $value = $self->{_members}->[$i + 1]->value;

        $hash->{$name} = $value;
    }

    return $hash;
}

sub to_string {
    my $self = shift;

    my $string = '<struct>';

    for (my $i = 0; $i < @{$self->{_members}}; $i += 2) {
        my $name = $self->{_members}->[$i];
        my $value = $self->{_members}->[$i + 1]->to_string;

        $string .= "<member><name>$name</name><value>$value</value></member>";
    }

    $string .= '</struct>';

    return $string;
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::Struct - XML-RPC struct

=head1 SYNOPSIS

    my $struct = Protocol::XMLRPC::Value::Struct->new(foo => 'bar');
    my $struct = Protocol::XMLRPC::Value::Struct->new({foo => 'bar'});
    my $struct =
      Protocol::XMLRPC::Value::Struct->new(
        foo => Protocol::XMLRPC::Value::String->new('bar'));

=head1 DESCRIPTION

XML-RPC struct

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::Struct> instance. Elements can be provided
as a hash or as a hash reference.

=head2 C<type>

Returns 'struct'.

=head2 C<add_member>

    $struct->add_member(foo => 'bar');
    $struct->add_member({foo => 'bar'});
    $struct->add_member(foo => Protocol::XMLRPC::Value::String->new('bar'));

Adds value to the struct. Can be Perl5 scalar or any Protocol::XMLRCP::Value::*
instance, including another struct.

=head2 C<members>

    my $struct = Protocol::XMLRPC::Value::Struct->new(foo => 'bar');
    my $members = $struct->members;

Returns hash reference where values are objects.

=head2 C<value>

    my $struct = Protocol::XMLRPC::Value::Struct->new(foo => 'bar');
    my $structref = $struct->value;
    # $structref is now {foo => 'bar'}

Returns serialized Perl5 hash reference.

=head2 C<to_string>

    my $struct = Protocol::XMLRPC::Value::Struct->new(foo => 'bar');
    my $string = $struct->to_string;
    # <struct>
    #   <member>
    #     <name>foo</name>
    #     <value><string>bar</string></value>
    #   </member>
    # </struct>'

XML-RPC struct string representation.
