package Prancer::Request::Upload;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Carp;

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub new {
    my ($class, $upload) = @_;
    return bless({ '_upload' => $upload }, $class);
}

sub filename {
    my $self = shift;
    return $self->{'_upload'}->filename();
}

sub size {
    my $self = shift;
    return $self->{'_upload'}->size();
}

sub path {
    my $self = shift;
    return $self->{'_upload'}->path();
}

sub content_type {
    my $self = shift;
    return $self->{'_upload'}->content_type();
}

1;

=head1 NAME

Prancer::Request::Upload

=head1 SYNOPSIS

Uploads come from the L<Prancer::Request> object passed to your handler. They
can be used like this:

    # in your HTML
    <form method="POST" enctype="multipart/form-data">
        <input type="file" name="foobar" />
    </form>

    # in the Prancer handler
    my $upload = $request->upload("foo");

=head1 METHODS

=over

=item size

Returns the size of uploaded file.

=item path

Returns the path to the temporary file where uploaded file is saved.

=item content_type

Returns the content type of the uploaded file.

=item filename

Returns the original filename in the client.

=back

=cut
