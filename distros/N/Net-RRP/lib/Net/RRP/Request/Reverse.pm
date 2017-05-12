package Net::RRP::Request::Reverse;

use strict;
use Net::RRP::Request;
use Net::RRP::Exception::InvalidCommandOption;
use Net::RRP::Exception::InvalidEntityValue;

@Net::RRP::Request::Reverse::ISA = qw(Net::RRP::Request);
$Net::RRP::Request::Reverse::VERSION = '0.1';

=head1 NAME

Net::RRP::Request::Reverse - rrp reverse request representation. This command must reverse protocol for replication issues.

=head1 SYNOPSIS

 use Net::RRP::Request::Reverse;
 my $reverseRequest = new Net::RRP::Request::Reverse ();

=head1 DESCRIPTION

This is a rrp reverse request representation class. RRP rfc extension.

=cut

=head2 getName

return a 'Reverse'

=cut

sub getName { 'Reverse' };

=head2 setEntity

throw Net::RRP::Exception::InvalidEntityValue immediate

=cut

sub setEntity
{
    throw Net::RRP::Exception::InvalidEntityValue ();
}

=head2 setOption

throw Net::RRP::Exception::InvalidCommandOption () immediate

=cut

sub setOption
{
    throw Net::RRP::Exception::InvalidCommandOption ();
}

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Request::Reverse (C) Vladimir B. Grebenschikov
                                TSB "Russian Express"
                                vova@express.ru

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

