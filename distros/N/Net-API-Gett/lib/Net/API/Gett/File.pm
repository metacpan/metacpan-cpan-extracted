package Net::API::Gett::File;

=head1 NAME

Net::API::Gett::File - Gett file object

=cut

use Moo;
use Carp qw(croak);
use MooX::Types::MooseLike::Base qw(Int Str);

our $VERSION = '1.06';

=head1 PURPOSE

Encapsulate Gett files.  You normally shouldn't instantiate this class on 
its own, as the library will create and return this object as appropriate.

=head1 ATTRIBUTES

These are read only attributes unless otherwise noted. 

=over 

=item filename

Scalar string.

=item fileid

Scalar string.

=item downloads

Scalar integer. The number of times this particular file has been downloaded

=item readystate

Scalar string. Signifies the state a particular file is in. See the 
L<Gett developer docs|http://ge.tt/developers> for more information.

=item getturl

Scalar string. The URL to use in a browser to access a file.

=item download

Scalar string. The URL to use to get the file contents.

=item size

Scalar integer. The size in bytes of this file.

=item created

Scalar integer. The Unix epoch time when this file was created in Gett. This value is suitable
for use in C<localtime()>.

=item sharename

Scalar string.  The share in which this file lives inside.

=item put_upload_url

Scalar string.  The url to use to upload the contents of this file using the PUT method. (This
attribute is only populated during certain times.)

=item post_upload_url

Scalar string. This url to use to upload the contents of this file using the POST method. (This
attribute is only populated during certain times.)

=item chunk_size

Scalar integer. This is the chunk size to use for file uploads. It defaults to 
1,048,576 bytes (1 MB).  This attribute is read-only.

=back

=cut

has 'filename' => (
    is => 'ro',
    isa => Str,
);

has 'fileid' => (
    is => 'ro',
    isa => Str,
);

has 'downloads' => (
    is => 'ro',
    isa => Int,
);

has 'readystate' => (
    is => 'ro',
    isa => Str,
);

has 'getturl' => (
    is => 'ro',
    isa => Str,
);

has 'download' => (
    is => 'ro',
    isa => Str,
);

has 'size' => (
    is => 'ro',
    isa => Int,
);

has 'created' => (
    is => 'ro',
    isa => Int,
);

has 'sharename' => (
    is => 'rw',
    isa => Str,
);

has 'put_upload_url' => (
    is => 'ro',
    isa => Str,
);

has 'post_upload_url' => (
    is => 'ro',
    isa => Str,
);

has 'chunk_size' => (
    is => 'rw',
    isa => Int,
    default => sub { 1_048_576; },
);

=over

=item user

L<Net::API::Gett::User> object. C<has_user()> predicate.

=back

=cut

has 'user' => (
    is => 'rw',
    predicate => 'has_user',
    isa => sub { die "$_[0] is not Net::API::Gett::User" unless ref($_[0]) =~ /User/ },
    lazy => 1,
);

=over

=item request

L<Net::API::Gett::Request> object.

=back

=cut

has 'request' => (
    is => 'rw',
    isa => sub { die "$_[0] is not Net::API::Gett::Request" unless ref($_[0]) =~ /Request/ },
    default => sub { Net::API::Gett::Request->new() },
    lazy => 1,
);

=head1 METHODS

=over

=item send_file()

This method actually uploads the file to the Gett service. This method is normally invoked by the
C<upload_file()> method, but it might be useful in combination with C<get_upload_url()>. It takes 
the following parameters:

=over

=item * a Gett put upload url

=item * data

a scalar representing the file contents which can be one of: a buffer, an L<IO::Handle> object, or a 
file pathname.

=item * encoding

an encoding scheme. By default, it uses C<:raw>.

=item * chunk_size

The maximum chunksize to load into to memory at one time.  If the file to transmit is larger than
this size, it will be dynamically streamed.

=back

Returns a true value on success.

=back

=cut

sub send_file {
    my $self = shift;
    my $url = shift;
    my $contents = shift;
    my $encoding = shift || ":raw";
    my $chunk_size = shift || $self->chunk_size || 1_048_576; # 1024 * 1024 = 1 MB

    my $fh;
    my $length;
    if ( ! ref($contents) ) {
        # $contents is scalar
        if ( ! -e $contents ) {
            # $contents doesn't point to a valid filename, 
            # assume it's a buffer

            $contents .= "";
            # Make sure this data is stringified.
            open($fh, "<", \$contents) or croak "Couldn't open a filehandle on the content buffer\n";
            binmode($fh, $encoding);
            $length = length($contents);
        }
        else {
            open($fh, "<", $contents) or croak "Couldn't open a filehandle on $contents: $!";
            binmode($fh, $encoding);
            $length = -s $contents;
        }
    }
    else {
       $fh = $contents if ref($contents) =~ /IO/;
       $length = -s $fh;
    }

    return 0 unless $fh;

    my $response = $self->request->put($url, $fh, $chunk_size, $length);

    if ( $response ) {
        return 1;
    }
    else {
        return undef;
    }
}

=over

=item get_upload_url()

This method returns a scalar PUT upload URL for the specified sharename/fileid parameters. 
Potentially useful in combination with C<send_file()>.

=back

=cut

sub get_upload_url {
    my $self = shift;
    croak "Cannot get_upload_url() without a Net::API::Gett::User object." unless $self->has_user;

    my $sharename = $self->sharename;
    my $fileid = $self->fileid;

    $self->user->login unless $self->user->has_access_token;

    my $endpoint = "/files/$sharename/$fileid/upload?accesstoken=".$self->user->access_token;

    my $response = $self->request->get($endpoint);

    if ( $response && exists $response->{'puturl'} ) {
        return $response->{'puturl'};
    }
    else {
        croak "Could not get a PUT url from $endpoint";
    }
}

=over

=item destroy()

This method destroys the file represented by the object. Returns a true value on success.

=back

=cut

sub destroy {
    my $self = shift;
    croak "Cannot destroy() without a Net::API::Gett::User object." unless $self->has_user;

    my $sharename = $self->sharename;
    my $fileid = $self->fileid;

    $self->user->login unless $self->user->has_access_token;

    my $endpoint = "/files/$sharename/$fileid/destroy?accesstoken=".$self->access_token;

    my $response = $self->request->post($endpoint);

    if ( $response ) {
        return 1;
    }
    else {
        return undef;
    }
}
        
sub _file_contents {
    my $self = shift;
    my $endpoint = $self->request->base_url . shift;

    my $response = $self->request->ua->get($endpoint);

    if ( $response->is_success ) {
        return $response->content();
    }
    else {
        croak "$endpoint said " . $response->status_line;
    }
}

=over

=item contents()

This method retrieves the contents of a this file in the Gett service.  You are responsible for 
outputting the file (if desired) with any appropriate encoding. Does not require an access token.

=back

=cut

sub contents {
    my $self = shift;
    my $sharename = $self->sharename;
    my $fileid = $self->fileid;

    return $self->_file_contents("/files/$sharename/$fileid/blob");
}

=over

=item thumbnail()

This method returns a thumbnail if the file in Gett is an image. Does not require an access token, but
is really only meaningful if the data is a valid image format file.

=back

=cut

sub thumbnail {
    my $self = shift;
    my $sharename = $self->sharename;
    my $fileid = $self->fileid;

    return $self->_file_contents("/files/$sharename/$fileid/blob/thumb");
}

=head1 SEE ALSO

L<Net::API::Gett>

=cut

1;
