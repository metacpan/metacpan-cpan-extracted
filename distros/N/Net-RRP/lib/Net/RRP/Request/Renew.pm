package Net::RRP::Request::Renew;

use strict;
use Net::RRP::Request;
use Net::RRP::Exception::InvalidCommandOption;
use Net::RRP::Exception::InvalidEntityValue;

@Net::RRP::Request::Renew::ISA = qw(Net::RRP::Request);
$Net::RRP::Request::Renew::VERSION = '0.1';

=head1 NAME

Net::RRP::Request::Renew - rrp renew request representation.

=head1 SYNOPSIS

 use Net::RRP::Request::Renew;
 my $renewRequest = new Net::RRP::Request::Renew 
    ( entity  => new Net::RRP::Entity::Domain ( DomainName => 'domain.ru' )
      options => { Period => 10, CurrentExpirationYear => 2000 } );

=head1 DESCRIPTION

This is a rrp renew request representation class.

=cut

=head2 getName

return a 'Renew'

=cut

sub getName { 'Renew' };

=head2 setEntity

throw Net::RRP::Exception::InvalidEntityValue unless entity is Net::RRP::Entity::Domain

=cut

sub setEntity
{
    my ( $this, $entity ) = @_;
    my $ref = ref ( $entity ) || throw Net::RRP::Exception::InvalidEntityValue ();
    $ref eq 'Net::RRP::Entity::Domain' || throw throw Net::RRP::Exception::InvalidEntityValue ();
    $this->SUPER::setEntity ( $entity );
}

=head2 setOption

Pass only Period && CurrentExpirationYear option. Throw Net::RRP::Exception::InvalidCommandOption at other case.

=cut

sub setOption
{
    my ( $this, $key, $value ) = @_;
    { period => 1, currentexpirationyear => 1 }->{ lc ( $key ) } || throw Net::RRP::Exception::InvalidCommandOption ();
    $this->SUPER::setOption ( $key => $value );
}

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Request::Renew (C) Michael Kulakov, Zenon N.S.P. 2000
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
