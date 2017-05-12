package Net::RRP::Request::Session;

use strict;
use Net::RRP::Request;
use Net::RRP::Exception::InvalidCommandOption;
use Net::RRP::Exception::InvalidEntityValue;

@Net::RRP::Request::Session::ISA = qw(Net::RRP::Request);
$Net::RRP::Request::Session::VERSION = '0.1';

=head1 NAME

Net::RRP::Request::Session - rrp session request representation.

=head1 SYNOPSIS

 use Net::RRP::Request::Session;
 my $sessionRequest = new Net::RRP::Request::Session ( Id       => 'reg1',
						       Password => '***' );
 my $sessionRequest1 = new Net::RRP::Request::Session ();
 $sessionRequest1->setOption ( Id          => 'reg1' );
 $sessionRequest1->setOption ( Password    => '***'  );
 $sessionRequest1->setOption ( NewPassword => '****' );

=head1 DESCRIPTION

This is a rrp session request representation class.

=cut

=head2 getName

return a 'Session'

=cut

sub getName { 'Session' };

=head2 setEntity

throw Net::RRP::Exception::InvalidEntityValue immediate

=cut

sub setEntity
{
    throw Net::RRP::Exception::InvalidEntityValue ();
}

=head2 setOption

Pass only Id, Password, NewPassword options

=cut

sub setOption
{
    my ( $this, $key, $value ) = @_;
    { id => 1, password => 1, newpassword => 1 }->{ lc ( $key ) } || throw Net::RRP::Exception::InvalidCommandOption ();
    $this->SUPER::setOption ( $key => $value );
}

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Request::Session (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Request(3)>, L<Net::RRP::Codec(3)>, RFC 2832,
L<Net::RRP::Exception::InvalidCommandOption(3)>,
L<Net::RRP::Exception::InvalidEntityValue(3)>

=cut

1;

__END__

