package Net::RRP::Entity::Contact;

use strict;
use Net::RRP::Entity;
use Net::RRP::Exception::InvalidAttributeName;
@Net::RRP::Entity::Contact::ISA = qw(Net::RRP::Entity);
$Net::RRP::Entity::Contact::VERSION = '0.1';

=head1 NAME

Net::RRP::Entity::Contact - rrp contact entity representation.

=head1 SYNOPSIS

 use Net::RRP::Entity::Contact;
 my $contactEntity = new Net::RRP::Entity::Contact ( name => 'contactname',
						     fax  => 'password',
						     .... );

=head1 DESCRIPTION

This is a rrp contact entity representation class.

=cut

=head2 getName

return a 'Contact'

=cut

sub getName { 'Contact' }

=head2 setAttribute

Add check constraint to attributes. Only firstname, lastname, middlename, address, phone, email and fax attributes may be exists

=cut

sub setAttribute
{
    my ( $this, $key, $value ) = @_;
    { contactname => 1, firstname => 1, lastname => 1, middlename => 1, address => 1, phone => 1, email => 1, fax => 1 }->{ lc ( $key ) } ||
	throw Net::RRP::Exception::InvalidAttributeName ();
    $this->SUPER::setAttribute ( $key => $value );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Entity::Contact (C) Michael Kulakov, Zenon N.S.P. 2000
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
