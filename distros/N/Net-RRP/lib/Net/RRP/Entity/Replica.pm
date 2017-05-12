package Net::RRP::Entity::Replica;

use strict;
use Net::RRP::Entity;
use Net::RRP::Exception::InvalidAttributeName;
@Net::RRP::Entity::Replica::ISA = qw(Net::RRP::Entity);
$Net::RRP::Entity::Replica::VERSION = '0.1';

=head1 NAME

Net::RRP::Entity::Replica - rrp replica entity representation.

=head1 SYNOPSIS

 use Net::RRP::Entity::Replica;
 my $replicaEntity = new Net::RRP::Entity::Replica ( name => 'replicaname',
						      => 'password',
							 .... );

=head1 DESCRIPTION

This is a rrp replica entity representation class.

=cut

=head2 getName

return a 'Replica'

=cut

sub getName { 'Replica' }

=head2 setAttribute

Add check constraint to attributes. Only techcontact, serial, name and password may be exists

=cut

sub setAttribute
{
    my ( $this, $key, $value ) = @_;
    { replicaname => 1, techcontact => 1, serial => 1, password => 1 }->{ lc ( $key ) } || throw Net::RRP::Exception::InvalidAttributeName ();
    $this->SUPER::setAttribute ( $key => $value );
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Entity::Replica (C) Michael Kulakov, Zenon N.S.P. 2000
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
