package Net::Blossom::BlobDescriptor;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(url sha256 size type uploaded nip94), {
    extra => sub { {} },
};

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my %STANDARD_FIELD = map { $_ => 1 } qw(url sha256 size type uploaded nip94);

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(url sha256 size type uploaded nip94 extra);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    return \%args;
}

sub BUILD {
    my ($self) = @_;

    for my $field (qw(url sha256 size type uploaded)) {
        croak "$field is required" unless defined $self->$field;
        croak "$field must be a scalar" if ref($self->$field);
    }
    croak "url is required" unless length $self->url;
    croak "sha256 must be 64-char lowercase hex" unless $self->sha256 =~ $HEX64;
    croak "size must be a non-negative integer"
        unless $self->size =~ /\A\d+\z/;
    croak "type is required" unless length $self->type;
    croak "uploaded must be a non-negative integer"
        unless $self->uploaded =~ /\A\d+\z/;
    _validate_nip94($self->nip94) if exists $self->{nip94};
    $self->extra({}) unless defined $self->extra;
    croak "extra must be a hash reference"
        unless ref($self->extra) eq 'HASH';
    for my $field (sort keys %{$self->extra}) {
        croak "extra must not contain standard descriptor field $field" if $STANDARD_FIELD{$field};
    }

    return;
}

sub from_hash {
    my ($class, $hash) = @_;
    croak "from_hash requires a hash reference" unless ref($hash) eq 'HASH';

    my %args;
    @args{qw(url sha256 size type uploaded)} = @{$hash}{qw(url sha256 size type uploaded)};
    $args{nip94} = $hash->{nip94} if exists $hash->{nip94};

    my %extra = %$hash;
    delete @extra{qw(url sha256 size type uploaded nip94)};
    return $class->new(%args, extra => \%extra);
}

sub get {
    my ($self, $field) = @_;
    return $self->$field if defined $field && $field =~ /\A(?:url|sha256|size|type|uploaded|nip94)\z/;
    return $self->extra->{$field};
}

sub to_hash {
    my ($self) = @_;
    my $hash = {
        %{$self->extra},
        url      => $self->url,
        sha256   => $self->sha256,
        size     => $self->size + 0,
        type     => $self->type,
        uploaded => $self->uploaded + 0,
    };
    $hash->{nip94} = $self->nip94 if defined $self->nip94;
    return $hash;
}

sub _validate_nip94 {
    my ($tags) = @_;
    croak "nip94 must be an array reference" unless ref($tags) eq 'ARRAY';

    for my $tag (@$tags) {
        croak "nip94 tags must be array references" unless ref($tag) eq 'ARRAY';
        croak "nip94 tags must contain at least a name and value" unless @$tag >= 2;

        my $name = $tag->[0];
        croak "nip94 tag names must be non-empty strings"
            unless defined $name && !ref($name) && length $name;

        for my $value (@$tag) {
            croak "nip94 tag values must be defined" unless defined $value;
            croak "nip94 tag values must be scalars" if ref($value);
        }
    }
}

1;

=pod

=head1 NAME

Net::Blossom::BlobDescriptor - Blossom blob descriptor value object

=head1 SYNOPSIS

    use Net::Blossom::BlobDescriptor;

    my $blob = Net::Blossom::BlobDescriptor->from_hash({
        url      => 'https://cdn.example.com/file',
        sha256   => $sha256,
        size     => 1234,
        type     => 'application/octet-stream',
        uploaded => 1725105921,
    });

    my $hash = $blob->to_hash;

=head1 DESCRIPTION

C<Net::Blossom::BlobDescriptor> represents the JSON descriptor returned by
Blossom upload, mirror, media, and list endpoints.

The standard descriptor fields are exposed as accessors. Unknown JSON fields are
preserved in C<extra> so callers do not lose extension data.

=head1 CONSTRUCTORS

=head2 new

    my $blob = Net::Blossom::BlobDescriptor->new(%args);

Creates a descriptor. Required arguments are C<url>, C<sha256>, C<size>,
C<type>, and C<uploaded>. Required fields must be scalar values. C<sha256> must
be lowercase 64-character hex. C<size> and C<uploaded> must be non-negative
integers.

Optional C<nip94> must be an array reference of NIP-94 tag arrays. Optional
C<extra> must be a hash reference and must not contain standard descriptor field
names.

Unknown arguments or invalid values croak.

=head2 from_hash

    my $blob = Net::Blossom::BlobDescriptor->from_hash($hashref);

Builds a descriptor from a decoded JSON hash reference. Unknown fields are moved
into C<extra>.

=head1 ACCESSORS

=head2 url

Returns the blob URL.

=head2 sha256

Returns the lowercase SHA-256 hash.

=head2 size

Returns the blob size in bytes.

=head2 type

Returns the media type.

=head2 uploaded

Returns the upload timestamp.

=head2 nip94

Returns the optional NIP-94 tag array reference.

=head2 extra

Returns the hash reference containing extension fields.

=head1 METHODS

=head2 get

    my $value = $blob->get($field);

Returns a standard descriptor field or an extension field from C<extra>.

=head2 to_hash

    my $hash = $blob->to_hash;

Returns a hash reference suitable for JSON encoding. Standard fields are
included with numeric C<size> and C<uploaded> values, extension fields are
preserved, and C<nip94> is included when present.

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
