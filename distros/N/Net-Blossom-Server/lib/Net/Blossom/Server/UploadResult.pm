package Net::Blossom::Server::UploadResult;

use strictures 2;

use Net::Blossom::BlobDescriptor;
use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(descriptor created);
use Scalar::Util qw(blessed);

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(descriptor created);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    return \%args;
}

sub BUILD {
    my ($self) = @_;
    croak "descriptor is required" unless defined $self->descriptor;
    croak "descriptor must be a Net::Blossom::BlobDescriptor"
        unless blessed($self->descriptor) && $self->descriptor->isa('Net::Blossom::BlobDescriptor');

    croak "created is required" unless defined $self->created;
    croak "created must be a scalar" if ref($self->created);
    croak "created must be 0 or 1" unless $self->created =~ /\A[01]\z/;
    $self->created($self->created ? 1 : 0);

    return;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::UploadResult - Result of a Blossom blob upload

=head1 SYNOPSIS

    use Net::Blossom::Server::UploadResult;

    my $result = Net::Blossom::Server::UploadResult->new(
        descriptor => $blob,
        created    => 1,
    );

=head1 DESCRIPTION

C<Net::Blossom::Server::UploadResult> describes the outcome of a successful
upload. It keeps the blob descriptor separate from whether the blob bytes were
newly stored.

Server routing can use C<created> to choose the BUD-02 response status: C<201>
for a newly stored blob and C<200> when the blob already existed.

=head1 CONSTRUCTOR

=head2 new

    my $result = Net::Blossom::Server::UploadResult->new(%args);

Required arguments:

=over 4

=item * C<descriptor>

A C<Net::Blossom::BlobDescriptor> for the uploaded blob.

=item * C<created>

C<1> when the blob bytes were newly stored, or C<0> when the blob already
existed.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 descriptor

Returns the C<Net::Blossom::BlobDescriptor>.

=head2 created

Returns C<1> for a newly stored blob and C<0> for an existing blob.

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
