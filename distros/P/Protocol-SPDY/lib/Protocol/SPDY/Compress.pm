package Protocol::SPDY::Compress;
$Protocol::SPDY::Compress::VERSION = '1.001';
use strict;
use warnings;

=head1 NAME

Protocol::SPDY::Compress - handle zlib compression/decompression

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use Protocol::SPDY;

=head1 DESCRIPTION

Used internally. See L<Protocol::SPDY> instead.

=cut

use Compress::Raw::Zlib qw(Z_OK Z_SYNC_FLUSH WANT_GZIP_OR_ZLIB);
use Protocol::SPDY::Constants ':all';

=head1 METHODS

=cut

=head2 new

Instantiate - takes no parameters.

=cut

sub new { my $class = shift; bless { }, $class }

=head2 inflater

Returns an inflater object, for decompressing data.

=cut

sub inflater {
	my $self = shift;
	return $self->{inflater} if $self->{inflater};
	my ($d, $status) = Compress::Raw::Zlib::Inflate->new(
		-WindowBits => WANT_GZIP_OR_ZLIB,
		-Dictionary => ZLIB_DICTIONARY,
	);
	die "Zlib failure: $status" unless $d;
	$self->{inflater} = $d;
}

=head2 deflater

Returns a deflater object, for compressing data.

=cut

sub deflater {
	my $self = shift;
	return $self->{deflater} if $self->{deflater};
	my ($d, $status) = Compress::Raw::Zlib::Deflate->new(
		-WindowBits => 12,
		-Dictionary => ZLIB_DICTIONARY,
	);
	die "Zlib failure: $status" unless $d;
	$self->{deflater} = $d;
}

=head2 decompress

Given a scalar containing bytes, this will return the decompressed
contents as a scalar, or raise an exception on failure.

=cut

sub decompress {
	my $self = shift;
	my $data = shift;
	my $comp = $self->inflater;
	my $status = $comp->inflate($data => \my $out);
	die "Failed: $status" unless $status == Z_OK;
	$out;
}

=head2 compress

Given a scalar containing bytes, this will return the compressed
contents as a scalar, or raise an exception on failure.

=cut

sub compress {
	my $self = shift;
	my $data = shift;
	my $comp = $self->deflater;

	my $status = $comp->deflate($data => \my $start);
	die "Failed: $status" unless $status == Z_OK;
	$status = $comp->flush(\my $extra => Z_SYNC_FLUSH);
	die "Failed: $status" unless $status == Z_OK;
	return $start . $extra;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
