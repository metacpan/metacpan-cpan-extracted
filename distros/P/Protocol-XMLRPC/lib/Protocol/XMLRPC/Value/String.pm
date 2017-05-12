package Protocol::XMLRPC::Value::String;

use strict;
use warnings;

use base 'Protocol::XMLRPC::Value';

sub type {'string'}

sub to_string {
    my $self = shift;

    my $value = $self->value;

    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;

    return "<string>$value</string>";
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::String - XML-RPC array

=head1 SYNOPSIS

    my $string = Protocol::XMLRPC::Value::String->new('Hello, world!');

=head1 DESCRIPTION

XML-RPC string

=head1 ATTRIBUTES

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::String> instance.

=head2 C<type>

Returns 'string'.

=head2 C<value>

    my $string = Protocol::XMLRPC::Value::String->new('foo');
    # $string->value returns 'foo'

Returns serialized Perl5 scalar.

=head2 C<to_string>

    my $string = Protocol::XMLRPC::Value::String->new('foo');
    # $string->to_string is now '<string>foo</string>'

XML-RPC string string representation.
