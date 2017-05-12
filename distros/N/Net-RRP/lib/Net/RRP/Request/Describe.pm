package Net::RRP::Request::Describe;

use strict;
use Net::RRP::Request;
@Net::RRP::Request::Describe::ISA = qw(Net::RRP::Request);
$Net::RRP::Request::Describe::VERSION = '0.1';

=head1 NAME

Net::RRP::Request::Describe - rrp describe request representation.

=head1 SYNOPSIS

 use Net::RRP::Request::Describe;
 my $describeRequest = new Net::RRP::Request::Describe ( Target => 'Protocol' );
 my $describeRequest1 = new Net::RRP::Request::Describe ();
 $describeRequest1->setOption ( Target => 'Protocol' );

=head1 DESCRIPTION

This is a rrp describe request representation class.

=cut

=head2 getName

return a 'Describe'

=cut

sub getName { 'Describe' };

=head2 setEntity

throw Net::RRP::Exception::InvalidEntityValue immediate

=cut

sub setEntity
{
    throw Net::RRP::Exception::InvalidEntityValue ();
}

=head2 setOption

Pass only Target option with Protocol value. Throw Net::RRP::Exception::InvalidCommandOption in other case.

=cut

sub setOption
{
    my ( $this, $key, $value ) = @_;
    throw Net::RRP::Exception::InvalidCommandOption () unless ( ( lc ( $key ) eq 'target' ) && ( lc ( $value ) eq 'protocol' ) );
    $this->SUPER::setOption ( $key => $value );
}

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Request::Describe (C) Michael Kulakov, Zenon N.S.P. 2000
                        125124, 19, 1-st Jamskogo polja st,
                        Moscow, Russian Federation

                        mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Request(3)>, L<Net::RRP::Codec(3)>, RFC 2832

=cut

1;

__END__

