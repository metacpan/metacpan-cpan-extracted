package Protocol::XMLRPC::Value::Boolean;

use strict;
use warnings;

use base 'Protocol::XMLRPC::Value';

sub type {'boolean'}

sub parse {
    my $class = shift;
    my $string = shift;

    die "Invalid 'Boolean' value"
      unless defined $string && $string =~ m/^(?:0|false|1|true)$/;

    return $class->new($string, @_);
}

sub value {
    my $self = shift;

    if (@_) {
        my $value = shift;

        if (ref($value) eq 'SCALAR') {
            $value = $$value ? 1 : 0;
        }
        else {
            $value = $value eq 'true' ? 1 : $value eq 'false' ? 0 : !!$value;
        }

        $self->{value} =
          $value
          ? Protocol::XMLRPC::Value::_True->new
          : Protocol::XMLRPC::Value::_False->new;

        return $self;
    }

    return $self->{value};
}

sub to_string {
    my $self = shift;

    my $value = $self->value;

    return "<boolean>$value</boolean>";
}

package Protocol::XMLRPC::Value::_True;

use overload '""'   => sub {'true'}, fallback => 1;
use overload 'bool' => sub {1},      fallback => 1;
use overload 'eq' => sub { $_[1] eq 'true' ? 1 : 0; }, fallback => 1;
use overload '==' => sub { $_[1] == 1 ? 1 : 0; }, fallback => 1;

sub new { bless {}, $_[0] }

package Protocol::XMLRPC::Value::_False;

use overload '""'   => sub {'false'}, fallback => 1;
use overload 'bool' => sub {0},       fallback => 1;
use overload 'eq' => sub { $_[1] eq 'false' ? 1 : 0; }, fallback => 1;
use overload '==' => sub { $_[1] == 0 ? 1 : 0; }, fallback => 1;

sub new { bless {}, $_[0] }

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::Boolean - XML-RPC array

=head1 SYNOPSIS

    my $true  = Protocol::XMLRPC::Value::Boolean->new(\1);
    my $true  = Protocol::XMLRPC::Value::Boolean->new('true');
    my $false = Protocol::XMLRPC::Value::Boolean->new(\0);
    my $false = Protocol::XMLRPC::Value::Boolean->new('false');

=head1 DESCRIPTION

XML-RPC boolean

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::Boolean> instance.

=head2 C<type>

Returns 'boolean'.

=head2 C<value>

    my $boolean = Protocol::XMLRPC::Value::Boolean->new(\1);
    # $boolean->value returns 1

    my $boolean = Protocol::XMLRPC::Value::Boolean->new('false');
    # $boolean->value returns 'false'

Returns serialized Perl5 boolean.

=head2 C<to_string>

    my $boolean = Protocol::XMLRPC::Value::Boolean->new(\1);
    # $boolean->to_string is now '<boolean>1</boolean>'

XML-RPC boolean string representation.
