package Net::RRP::Entity::Owner;

use strict;
use Net::RRP::Entity;
use Net::RRP::Exception::InvalidAttributeName;
@Net::RRP::Entity::Owner::ISA = qw(Net::RRP::Entity);
$Net::RRP::Entity::Owner::VERSION = '0.1';

=head1 NAME

Net::RRP::Entity::Owner - rrp owner entity representation.

=head1 SYNOPSIS

 use Net::RRP::Entity::Owner;
 my $ownerEntity = new Net::RRP::Entity::Owner ( name     => 'ownername',
						 password => 'password',
						 .... );

=head1 DESCRIPTION

This is a rrp owner entity representation class.

=cut

=head2 getName

return a 'Owner'

=cut

sub getName { 'Owner' }

=head2 setAttribute

Add check constraint to attributes. Only OwnerName and NameServer attributes can exists.

=cut

sub setAttribute
{
    my ( $this, $key, $value ) = @_;
    { ownername => 1, password => 1, whoisinfo => 1, techcontact => 1, admincontact => 1 }->{ lc ( $key ) } ||
	throw Net::RRP::Exception::InvalidAttributeName ();
    $this->SUPER::setAttribute ( $key => $value );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Entity::Owner (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Entity(3)>, L<Net::RRP::Codec(3)>, RFC 2832,
L<Net::RRP::Exception::InvalidAttributeName(3)>

=cut

__END__
