package FakeDNS;

# Answers Net::DNS::Resolver sends from a table instead of the network.
#
# %FakeDNS::ANSWERS is keyed by "name type", lower cased, each a hash ref
# of rcode, default NOERROR, answer, a array ref of RR strings, and aa.
# A missing key is NXDOMAIN, and a key with undef is no reply. A key of
# "name type @server" is used for that server before "name type".
# @FakeDNS::ASKED gets [ servers, name, type ] for each send.

use strict;
use warnings;
use Net::DNS;

our %ANSWERS;
our @ASKED;

{
	no warnings 'redefine';
	*Net::DNS::Resolver::send = sub {
		my ( $resolver, $name, $type ) = @_;
		$type //= 'A';
		push( @ASKED, [ [ $resolver->nameservers ], $name, $type ] );
		my $key    = lc( $name . ' ' . $type );
		my $server = ( $resolver->nameservers )[0] // '';
		$key = $key . ' @' . $server if exists( $ANSWERS{ $key . ' @' . $server } );
		if ( exists( $ANSWERS{$key} ) && !defined( $ANSWERS{$key} ) ) {
			$resolver->errorstring('query timed out');
			return undef;
		}
		my $answer = $ANSWERS{$key} // { rcode => 'NXDOMAIN' };
		my $packet = Net::DNS::Packet->new( $name, $type );
		$packet->header->qr(1);
		$packet->header->rcode( $answer->{rcode} // 'NOERROR' );
		$packet->header->aa( $answer->{aa} ? 1 : 0 );
		$packet->push( answer => Net::DNS::RR->new($_) ) foreach @{ $answer->{answer} // [] };
		$packet->answerfrom( ( $resolver->nameservers )[0] // '127.0.0.1' );
		return $packet;
	}; ## end *Net::DNS::Resolver::send = sub
}

1;
