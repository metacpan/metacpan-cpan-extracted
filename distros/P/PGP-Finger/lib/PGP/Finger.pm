package PGP::Finger;

use Moose;

# ABSTRACT: retrieve PGP keys from different sources
our $VERSION = '1.1'; # VERSION

use PGP::Finger::DNS;
use PGP::Finger::Keyserver;
use PGP::Finger::ResultSet;

has 'sources' => ( is => 'ro', isa => 'ArrayRef[PGP::Finger::Source]', lazy => 1,
	default => sub { [
		PGP::Finger::DNS->new,
		PGP::Finger::Keyserver->new,
	] },
);

sub fetch {
	my ( $self, $addr ) = @_;
	my $resultset = PGP::Finger::ResultSet->new;

	foreach my $source ( @{$self->sources} ) {
		my $result = $source->fetch( $addr );
		if( ! defined $result ) { next; }
		$resultset->add_result( $result );
	}
	return $resultset;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PGP::Finger - retrieve PGP keys from different sources

=head1 VERSION

version 1.1

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2 or later

=cut
