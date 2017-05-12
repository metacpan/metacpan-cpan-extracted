package PGP::Finger::Key;

use Moose;

# ABSTRACT: class for holding and parsing pgp keys
our $VERSION = '1.1'; # VERSION

use Digest::SHA qw(sha256_hex sha224_hex);
use Digest::CRC qw(crcopenpgparmor_base64);
use MIME::Base64;

use overload
    q{""}    => sub { $_[0]->armored },
    fallback => 1;


has 'data' => ( is => 'ro' );

has 'attributes' => ( is => 'ro', isa => 'HashRef[Str]', lazy => 1,
	traits => [ 'Hash' ],
	default => sub { {} },
	handles => {
		set_attr => 'set',
		get_attr => 'get',
		has_attr => 'exists',
		has_attrs => 'count',
	},
);

has '_version' => ( is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $version;
		{
			no strict 'vars'; # is only declared in build
			$version = defined $VERSION ? $VERSION : 'head';
		}
		return 'pgpfinger ('.$version.')';
	},
);

sub merge_key {
	my ( $self, @keys ) = @_;

	foreach my $key ( @keys ) {
		$self->merge_attributes( $key->attributes );
	}
	return;
}

sub merge_attributes {
	my ( $self, $attr ) = @_;

	foreach my $name ( keys %$attr ) {
		if( ! $self->has_attr( $name ) ) {
			$self->set_attr( $name => $attr->{$name} );
		} else {
			$self->set_attr( $name => $self->get_attr($name).', '.$attr->{$name} );
		}
	}
	return;
}

sub new_armored {
	my ( $class, %options ) = @_;
	my $armored = $options{'data'};
	if( ! defined $armored ) {
		die('new_armored called without data');
	}
	
	my $b64 = '';
	my @lines = split( /\r?\n/, $armored );
	my $line;
	while( $line = shift @lines ) {
		if( $line =~ /^\s*$/ ) { next; }
		if( $line =~ /^-----BEGIN /) { last; } # here we start
		die('data before BEGIN line in PEM input');
	}
	if( ! @lines ) {
		die('end of PEM before -----BEGIN line has been found');
	}
	while( $line = shift @lines ) { # get headers if present
		if( $line =~ /:/ ) { next; }
		if( $line =~ /^\s*$/ ) { next; }
		last;
	}
	if( ! @lines ) {
		die('end of PEM before -----END line has been found');
	}
	$b64 .= $line;
	while( $line = shift @lines ) {
		if( $line =~ /^-----END /) { last; } # END
		$b64 .= $line;
	}
	if( $b64 eq '') {
		die('failed parsing PEM encoded key');
	}
	$options{'data'} = decode_base64( $b64 );

	return $class->new( %options );
}

has 'fingerprint' => ( is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_fingerprint {
	my $self = shift;
	return sha256_hex( $self->data );
}

has 'armored' => ( is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_armored {
	my $self = shift;
	my $armored = '';
	if( $self->has_attrs ) {
		$armored .= join( "\n",
			map {
				'# '.$_.': '.$self->get_attr($_)
			} keys %{$self->attributes} );
		$armored .= "\n";
	}

	my $data = encode_base64( $self->data, '' );
	$data =~ s!(.{1,64})!$1\n!g;

	my $crc = crcopenpgparmor_base64( $self->data );

	$armored .= "-----BEGIN PGP PUBLIC KEY BLOCK-----\n";
	$armored .= "Version: ".$self->_version."\n\n";
	$armored .= $data;
	$armored .= '='.$crc;
	$armored .= "-----END PGP PUBLIC KEY BLOCK-----\n";
	return $armored;
}

has 'mail' => ( is => 'ro', isa => 'Str', required => 1 );

has 'local' => ( is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $self = shift;
		my ($local) = split('@', $self->mail, 2);
		return( $local );
	},
);

has 'domain' => ( is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $self = shift;
		my (undef, $domain) = split('@', $self->mail, 2);
		return( $domain );
	},
);

has 'dns_record_name' => ( is => 'ro', isa => 'Str', lazy => 1,
	default => sub {
		my $self = shift;
		return sha224_hex($self->local).'._openpgpkey.'.$self->domain.'.';
	},
);

has 'dns_record_generic' => ( is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_dns_record_generic {
	my $self = shift;
	my $name = $self->dns_record_name;
	my $data = unpack( "H*", $self->data );
	my $num_octets = length( $self->data );

	return join(' ', $name, 'IN', 'TYPE65280', '\#', $num_octets, $data )."\n";
}

has 'dns_record_rfc' => ( is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_dns_record_rfc {
	my $self = shift;
	my $name = $self->dns_record_name;
	my $num_octets = 0;
	my $data = encode_base64( $self->data, '');

	return join(' ', $name, 'IN', 'OPENPGPKEY ', $data )."\n";
}

sub clone {
	my $self = shift;
	my $class = ref( $self );
	return $class->new(
		mail => $self->mail,
		data => $self->data,
		attributes => $self->attributes,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::Key - class for holding and parsing pgp keys

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
