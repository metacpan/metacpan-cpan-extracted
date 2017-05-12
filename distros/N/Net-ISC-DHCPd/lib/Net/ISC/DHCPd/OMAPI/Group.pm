package Net::ISC::DHCPd::OMAPI::Group;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Group - OMAPI group class

=head1 SEE ALSO

L<Net::ISC::DHCPd::OMAPI::Actions>.
L<Net::ISC::DHCPd::OMAPI::Meta::Attribute>.

=head1 SYNOPSIS

 use Net::ISC::DHCPd::OMAPI;

 $omapi = Net::ISC::DHCPd::OMAPI->new(...);
 $omapi->connect
 $group = $omapi->new_object("group", { $attr => $value });
 $group->$attr($value); # same as in constructor
 $group->read; # retrieve server information
 $group->write; # write to server

=cut

use Net::ISC::DHCPd::OMAPI::Sugar;
use Moose;

with 'Net::ISC::DHCPd::OMAPI::Actions';

=head1 ATTRIBUTES

=head2 name

 $self->name($name);
 $str = $self->name;

The name of the group. All groups that are created using OMAPI must
have names, and the names must be unique among all groups.

Actions: examine lookup modify.

=cut

omapi_attr name => (
    isa => 'Str',
    actions => [qw/examine lookup modify/],
);

=head2 statements

 $self->statements(\@statements);
 $self->statements("foo,bar");
 $str = $self->statements;

A list of statements in the format of the dhcpd.conf file that will be
executed whenever a message from a client whose host  declaration
references this group is processed.

Actions: examine lookup modify.

=cut

omapi_attr statements => (
    isa => Statements,
    actions => [qw/examine lookup modify/],
);

=head1 ACKNOWLEDGEMENTS

Most of the documentation is taken from C<dhcpd(8)>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
