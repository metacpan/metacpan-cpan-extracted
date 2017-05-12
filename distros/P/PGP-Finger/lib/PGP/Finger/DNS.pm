package PGP::Finger::DNS;

use Moose;

extends 'PGP::Finger::Source';

# ABSTRACT: gpgfinger source to query DNS for OPENPGPKEYs
our $VERSION = '1.1'; # VERSION

use Net::DNS::Resolver;
use Digest::SHA qw(sha224_hex);

use PGP::Finger::Result;
use PGP::Finger::Key;

has 'dnssec' => ( is => 'rw', isa => 'Bool', default => 1 );

has _resolver => ( is => 'ro', isa => 'Net::DNS::Resolver', lazy => 1,
	default => sub {
		my $self = shift;
		my $res = Net::DNS::Resolver->new;
		$res->dnssec( $self->dnssec );
		return( $res );
	},
);

has 'rr_types' => ( is => 'rw', isa => 'ArrayRef[Str]',
	default => sub { [ 'TYPE61' ] },
);

sub fetch {
	my ( $self, $addr ) = @_;
	my ($local, $domain) = split('@', $addr, 2);
	if( ! defined $local || ! defined $domain ) {
		die("could not parse mail address $addr");
	}
	my $record = join('.', sha224_hex($local), '_openpgpkey', $domain);
	my $result = PGP::Finger::Result->new;

	foreach my $rr_type ( @{$self->rr_types} ) {
		my $reply = $self->_resolver->query( $record, $rr_type );
		if( ! defined $reply ) {
			die("error while looking up $rr_type: ".$self->_resolver->errorstring);
		}
		foreach my $rr ( $reply->answer ) {
			if($rr->type ne $rr_type ) {
				next;
			}
			my $key = PGP::Finger::Key->new(
				mail => $addr,
				data => $rr->rdata,
			);
			$key->set_attr( source => 'DNS' );
			$key->set_attr( domain => $domain );
			$key->set_attr( dnssec => $reply->header->ad ? 'ok' : 'unauthenticated' );
			$result->add_key( $key );
		}
	}

	return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::DNS - gpgfinger source to query DNS for OPENPGPKEYs

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
