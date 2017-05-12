package Net::RRP::Entity::NameServer;

use strict;
use Net::RRP::Entity;
use Net::RRP::Exception::InvalidAttributeName;
@Net::RRP::Entity::NameServer::ISA = qw(Net::RRP::Entity);
$Net::RRP::Entity::NameServer::VERSION = '0.1';

=head1 NAME

Net::RRP::Entity::NameServer - rrp domain entity representation.

=head1 SYNOPSIS

 use Net::RRP::Entity::NameServer;
 my $nameServerEntity = new Net::RRP::Entity::NameServer ( NameServer => [ 'ns1.domain.ru' ],
						       IPAddress  => [ '1.1.1.1' ] );
 my $nameServerEntity1 = new Net::RRP::Entity::NameServer ();
 $nameServerEntity1->setAttribute ( NameServer => [ 'ns1.domain.ru' ] );
 $nameServerEntity1->setAttribute ( IPAddress  => [ '1.1.1.1' ] );

=head1 DESCRIPTION

This is a rrp name server entity representation class.

=cut

=head2 getName

return a 'NameServer'

=cut

sub getName { 'NameServer' }

=head2 setAttribute

Add check constraint to attributes. Only NameServer and IPAddress attributes can exists.

=cut

sub setAttribute
{
    my ( $this, $key, $value ) = @_;
    { nameserver => 1, ipaddress => 1, newnameserver => 1 }->{ lc ( $key ) } || throw Net::RRP::Exception::InvalidAttributeName;
    $this->SUPER::setAttribute ( $key => $value );
}

=head2 getPrimaryAttributeValue

return a "primary" attribute value

=cut

sub getPrimaryAttributeValue
{
    my $this = shift;
    $this->getAttribute ( $this->getName );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Entity::NameServer (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Entity(3)>, L<Net::RRP::Codec(3)>, RFC 2832, L<Net::RRP::Exception::InvalidAttributeName(3)>

=cut

__END__
