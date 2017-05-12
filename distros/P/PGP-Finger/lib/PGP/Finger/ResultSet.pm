package PGP::Finger::ResultSet;

use Moose;

# ABSTRACT: object to hold and merge Result objects
our $VERSION = '1.1'; # VERSION

has 'results' => (
	is => 'ro', isa => 'ArrayRef[PGP::Finger::Result]', lazy => 1,
	traits => [ 'Array' ],
	default => sub { [] },
	handles => {
		add_result => 'push',
		count => 'count',
	},
);

sub merged_keys {
	my $self = shift;
	my %keys;

	foreach my $result ( @{$self->results} ) {
		foreach my $key ( @{$result->keys} ) {
			my $fp = $key->fingerprint;
			if( defined $keys{$fp} ) {
				$keys{$fp}->merge_key( $key );
			} else {
				$keys{$fp} = $key->clone;
			}
		}
	}

	return( values %keys );
}

sub as_string {
	my ( $self, $type ) = @_;
	$type = lc $type;
	my @keys = $self->merged_keys;
	my $result = '';

	foreach my $key ( @keys ) {
		if( $type eq 'armored' ) {
			$result .= $key->armored;
		} elsif ( $type eq 'binary' ){
			$result .= $key->data;
		} elsif ( $type eq 'generic' ){
			$result .= $key->dns_record_generic;
		} elsif ( $type eq 'rfc' ){
			$result .= $key->dns_record_rfc;
		} else {
			die('invalid output format: '.$type);
		}
	}

	return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger::ResultSet - object to hold and merge Result objects

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
