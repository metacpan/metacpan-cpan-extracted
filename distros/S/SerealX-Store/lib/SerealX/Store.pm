package SerealX::Store;
# ABSTRACT: Sereal based persistence for Perl data structures
our $VERSION = '0.003';

use 5.008001;
use strict;
use warnings;

use Sereal::Encoder;
use Sereal::Decoder;

# Constructor
sub new {
	my ($class, $params) = @_;
	
	my $self = {};
	if (ref $params->{encoder} eq 'HASH') {
		$self->{encoder} = Sereal::Encoder->new($params->{encoder});
	}
	if (ref $params->{decoder} eq 'HASH') {
		$self->{decoder} = Sereal::Decoder->new($params->{decoder});
	}
	
	return bless $self, $class;
}

sub store {
	my ($self, $data, $path) = @_;

	die "No file specified" unless $path;
	if (ref $self->{encoder} ne 'Sereal::Encoder') {
		$self->{encoder} = Sereal::Encoder->new();
	}
	my $encoded = $self->{encoder}->encode($data);
	open(my $fh, ">", $path) or die "Cannot open file $path: $!";
	binmode $fh;
	print $fh $encoded	or die "Cannot write to file $path: $!";
	close $fh or die "Cannot close file $path: $!";

	return 1;
}

sub retrieve {
	my ($self, $path) = @_;

	die "No file specified" unless $path;
	if (ref $self->{decoder} ne 'Sereal::Decoder') {
		$self->{decoder} = Sereal::Decoder->new();
	}
	open(my $fh, "<", $path) or die "Cannot open file $path: $!";
	binmode $fh;
	my $data;
	if (my $size = -s $fh) {
		my ($pos, $read) = 0;
		while ($pos < $size) {
			defined($read = read($fh, $data, $size - $pos, $pos))
				or die "Cannot read file $path: $!";
			$pos += $read;
		}
	}
	else {
		$data = <$fh>;
	}
	close $fh or die "Cannot close file $path: $!";
	$self->{decoder}->decode($data, my $decoded);
	
	return $decoded;
}

1;

__END__

=encoding utf8

=head1 NAME

SerealX::Store - Sereal based persistence for Perl data structures

=head1 SYNOPSIS

  use SerealX::Store;

  my $st = SerealX::Store->new();
  my $data = {
    foo => 1,
    bar => 'nut',
    baz => [1, 'barf'],
    qux => { a => 1, b => 'ugh' },
    ugh => undef
  };
  $st->store($data, "/tmp/dummy");
  my $decoded = $st->retrieve("/tmp/dummy");

=head1 DESCRIPTION

This module serializes Perl data structures using L<Sereal::Encoder> and stores
them on disk for the purpose of retrieving them at a later time. At retrieval
L<Sereal::Decoder> is used to deserialize the data.

The rationale behind this module is to eventually provide a L<Storable> like
API, while using the excellent L<Sereal> protocol for the heavy lifting.

=head1 METHODS

=head2 new

Constructor used to instantiate the object. Optionally takes a hash reference
as the frist parameter. The following options are recognised:

=over 4

=item encoder

Options to pass to the Sereal::Encoder object constructor. Its value should be
a hash reference containing any of the options that influence the behaviour of
the encoder, as described by its documentation. When this is the case, the
encoder object will be instantiated in the constructor, otherwise instantiation
would only happen when the C<store> method is called for the first time.

=item decoder

Options to pass to the Sereal::Decoder object constructor. Its format and
behaviour is equivalent to the C<encoder> option above. If its value is not a
hash reference, the decoder object will only be instantiated when the
C<retrieve> method is called for the first time.

=back

=head2 store

Given a Perl data structure and a path as arguments, will encode the data
structure into a binary string and write it to a file at the specified path.
The method will return a true value upon success or croak if no path is given
or if any other errors are encountered.
  
  $st->store($data, "/tmp/dummy");
  
=head2 retrieve

Given a path as argument, will retrieve the data from the file at the specified
path, deserialize and return it. The method will croak upon failure.

  $st->retrieve($data, "/tmp/dummy");

=head1 SEE ALSO

L<Sereal>, L<Storable>

=head1 AUTHOR

Gelu Lupaş <gvl@cpan.org>

=head1 COPYRIGHT AND LICENSE
 
Copyright (c) 2013-2014 the SerealX::Store L</AUTHOR> as listed
above.
 
This is free software, licensed under:
 
  The MIT License (MIT)

=cut
