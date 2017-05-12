package Net::ISC::DHCPd::OMAPI::Meta::Attribute;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Meta::Attribute - Attribute role for OMAPI attributes

=cut

use Moose::Role;

=head1 ATTRIBUTES

=head2 actions

 $array_ref = $attr->actions;

Actions possible to execute on attribute. Can be:

 lookup
 examine
 update

=cut

has actions => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
);

=head1 METHODS

=head2 has_action

 $bool = $attr->has_action($action_name);

Returns true if the attribute can execute C<$action_name>.

=cut

sub has_action {
    return grep { $_[1] eq $_ } @{ $_[0]->actions };
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

1;
