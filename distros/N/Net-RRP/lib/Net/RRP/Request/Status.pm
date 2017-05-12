package Net::RRP::Request::Status;

use strict;
use Net::RRP::Request;
use Net::RRP::Exception::InvalidCommandOption;
use Net::RRP::Exception::InvalidEntityValue;

@Net::RRP::Request::Status::ISA = qw(Net::RRP::Request);
$Net::RRP::Request::Status::VERSION = '0.1';

=head1 NAME

Net::RRP::Request::Status - rrp status request representation.

=head1 SYNOPSIS

 use Net::RRP::Request::Status;
 my $statusRequest = new Net::RRP::Request::Status 
    ( entity  => new Net::RRP::Entity::Domain ( DomainName => [ 'domain.ru' ] ) );
 my $statusRequest1 = new Net::RRP::Request::Status ();
 $statusRequest1->setEntity ( new Net::RRP::Entity::NameServer ( NameServer => [ 'ns1.domain.ru' ] ) );

=head1 DESCRIPTION

This is a rrp status request representation class.

=cut

=head2 getName

return a 'Status'

=cut

sub getName { 'Status' };

=head2 setEntity

throw Net::RRP::Exception::InvalidEntityValue unless entity is Net::RRP::Entity::Domain or Net::RRP::Entity::NameServer

=cut

sub setEntity
{
    my ( $this, $entity ) = @_;
    my $ref = ref ( $entity ) || throw Net::RRP::Exception::InvalidEntityValue ();
    {  'Net::RRP::Entity::Domain'     => 1,
       'Net::RRP::Entity::NameServer' => 1,
       'Net::RRP::Entity::Registrar'  => 1,
       'Net::RRP::Entity::Replica'    => 1,
       'Net::RRP::Entity::Owner'      => 1,
       'Net::RRP::Entity::Contact'    => 1 }->{ $ref } || throw Net::RRP::Exception::InvalidEntityValue ();
    $this->SUPER::setEntity ( $entity );
}

=head2 setOption

throw Net::RRP::Exception::InvalidCommandOption

=cut

sub setOption
{
    throw Net::RRP::Exception::InvalidCommandOption ();
}

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Request::Status (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Request(3)>, L<Net::RRP::Codec(3)>, L<Net::RRP::Entity::Domain(3)>,
L<Net::RRP::Entity::NameServer(3)>, RFC 2832,
L<Net::RRP::Exception::InvalidCommandOption(3)>,
L<Net::RRP::Exception::InvalidEntityValue(3)>

=cut

1;

__END__
