package Net::Blossom::Server::BlobResult;

use strictures 2;

use Net::Blossom::BlobDescriptor;
use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(descriptor body);
use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(descriptor body);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "descriptor is required" unless defined $args{descriptor};
    croak "descriptor must be a Net::Blossom::BlobDescriptor"
        unless blessed($args{descriptor}) && $args{descriptor}->isa('Net::Blossom::BlobDescriptor');

    croak "body is required" unless exists $args{body} && defined $args{body};
    _validate_body($args{descriptor}, $args{body});

    return bless \%args, $class;
}

sub _validate_body {
    my ($descriptor, $body) = @_;

    if (!ref($body)) {
        croak "body length must match descriptor size" unless length($body) == $descriptor->size;
        return;
    }

    if (ref($body) eq 'ARRAY') {
        my $size = 0;
        for my $chunk (@$body) {
            croak "body array values must be defined" unless defined $chunk;
            croak "body array values must be scalars" if ref($chunk);
            $size += length $chunk;
        }
        croak "body length must match descriptor size" unless $size == $descriptor->size;
        return;
    }

    return if blessed($body) && ($body->can('read') || $body->can('getline'));
    croak "body must be a scalar, array reference, or stream object";
}

1;

=pod

=head1 NAME

Net::Blossom::Server::BlobResult - Result of a Blossom blob lookup

=head1 SYNOPSIS

    use Net::Blossom::Server::BlobResult;

    my $result = Net::Blossom::Server::BlobResult->new(
        descriptor => $blob,
        body       => $bytes,
    );

=head1 DESCRIPTION

C<Net::Blossom::Server::BlobResult> describes a blob available for download. It
keeps the descriptor and response body together so server routing can return the
blob bytes with headers derived from the descriptor.

=head1 CONSTRUCTOR

=head2 new

    my $result = Net::Blossom::Server::BlobResult->new(%args);

Required arguments:

=over 4

=item * C<descriptor>

A C<Net::Blossom::BlobDescriptor> for the blob.

=item * C<body>

The blob body as a scalar, an array reference of scalar chunks, or a stream
object that provides C<read> or C<getline>. Scalar and array bodies must have a
total byte length equal to C<< $descriptor->size >>. Stream bodies are not read
or buffered by this object.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 descriptor

Returns the C<Net::Blossom::BlobDescriptor>.

=head2 body

Returns the scalar, array reference, or stream object body.

=cut
