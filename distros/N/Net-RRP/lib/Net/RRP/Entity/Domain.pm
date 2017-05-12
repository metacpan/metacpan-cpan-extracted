package Net::RRP::Entity::Domain;

use strict;
use Net::RRP::Entity;
use Net::RRP::Exception::InvalidAttributeName;
@Net::RRP::Entity::Domain::ISA = qw(Net::RRP::Entity);
$Net::RRP::Entity::Domain::VERSION = '0.1';

=head1 NAME

Net::RRP::Entity::Domain - rrp domain entity representation.

=head1 SYNOPSIS

 use Net::RRP::Entity::Domain;
 my $domainEntity = new Net::RRP::Entity::Domain ( DomainName => [ 'domain.ru' ],
						   NameServer => [ 'ns1.domain.ru' ] );
 my $domainEntity1 = new Net::RRP::Entity::Domain ();
 $domainEntity1->setAttribute ( DomainName => [ 'domain.ru' ] );
 $domainEntity1->setAttribute ( NameServer => [ 'ns1.domain.ru' ] );

=head1 DESCRIPTION

This is a rrp domain entity representation class.

=cut

=head2 getName

return a 'Domain'

=cut

sub getName { 'Domain' }

=head2 setAttribute

Add check constraint to attributes. Only DomainName and NameServer attributes can exists.

=cut

sub setAttribute
{
    my ( $this, $key, $value ) = @_;
    { domainname => 1, nameserver => 1, status => 1, whoisinfo => 1, owner => 1 }->{ lc ( $key ) } ||
	throw Net::RRP::Exception::InvalidAttributeName ();
    $this->SUPER::setAttribute ( $key => $value );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Entity::Domain (C) Michael Kulakov, Zenon N.S.P. 2000
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
