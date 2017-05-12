package PGP::Finger::Keyserver;

use Moose;

extends 'PGP::Finger::Source';

# ABSTRACT: gpgfinger source to query a keyserver
our $VERSION = '1.1'; # VERSION

use LWP::UserAgent;

use PGP::Finger::Result;
use PGP::Finger::Key;

has _agent => ( is => 'ro', isa => 'LWP::UserAgent', lazy => 1,
	default => sub {
		LWP::UserAgent->new;
	},
);

has 'exact' => ( is => 'rw', isa => 'Bool', default => 1 );

has 'url' => ( is => 'rw', isa => 'Str',
	default => 'http://a.keyserver.pki.scientia.net/pks/lookup',
);

sub fetch {
	my ( $self, $addr ) = @_;
	my @ids = $self->_query_index( $addr );
	my $result = PGP::Finger::Result->new( source => 'keyserver' );

	foreach my $id ( @ids ) {
		my $armored = $self->_retrieve_keys('0x'.$id);
		my $key = PGP::Finger::Key->new_armored(
			mail => $addr,
			data => $armored,
		);
		$key->set_attr( source => 'keyserver' );
		$key->set_attr( url => $self->url );
		$key->set_attr( keyid => $id );
		$result->add_key( $key );
	}

	return $result;
}

sub _get {
	my ( $self, %params ) = @_; 
	my $uri = URI->new( $self->url );
	$uri->query_form( \%params );
	my $request = HTTP::Request->new('GET', $uri);
	my $response = $self->_agent->request( $request );
	if( ! $response->is_success ) {
		die("keylookup for $uri failed: ".$response->status_line);
	}
	return $response;
}

sub _retrieve_keys {
	my ( $self, $id ) = @_;
	my $response = $self->_get(
		search => $id,
		op => 'get',
		exact => $self->exact,
		options => 'mr',
	);
	if( $response->content !~ /^-----BEGIN PGP PUBLIC KEY BLOCK-----/) {
		die('returned content is not a PGP public key');
	}
	return $response->content;
}

sub _query_index {
	my ( $self, $addr ) = @_;
	my @ids;
	my $response = $self->_get(
		search => $addr,
		op => 'index',
		exact => $self->exact,
		options => 'mr',
	);
	my @lines = split(/\r?\n/, $response->content);
	# info:<version>:<count>
	# pub:<keyid>:<algo>:<keylen>:<creationdate>:<expirationdate>:<flags>
	# ...
	shift(@lines);
	while( my $line = shift(@lines) ) {
		if( $line !~ /^pub:/) { next; }
		if( $line =~ /^pub:([^:]+):/) {
			push( @ids, $1 );
		} else {
			die("unknown line format: ".$line);
		}
	}
	return( @ids );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::Keyserver - gpgfinger source to query a keyserver

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
