package Net::API::Gett::Request;

use Moo;
use Sub::Quote;
use Carp qw(croak);
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Headers;

our $VERSION = '1.06';

=head1 NAME

Net::API::Gett::Request - Gett Request object

=head1 PURPOSE

This object encapsulates requests to and from the Gett API server.

You normally shouldn't instanstiate this class on its own as the library 
will create and return this object when appropriate.

=head1 ATTRIBUTES

These are read only attributes. 

=over

=item base_url

Scalar string. Read-only. Populated at object construction. Default value: L<https://open.ge.tt/1>. 

=back

=cut

has 'base_url' => (
    is        => 'ro',
    default   => sub { 'https://open.ge.tt/1' },
);

=over

=item ua

User agent object. Read only. Populated at object construction. Uses a default L<LWP::UserAgent>.

=back

=cut

has 'ua' => (
    is => 'ro',
    default => sub { 
        my $ua = LWP::UserAgent->new(); 
        $ua->agent("Net-API-Gett/$VERSION/(Perl)"); 
        return $ua;
    },
    isa => sub { die "$_[0] is not LWP::UserAgent" unless ref($_[0])=~/UserAgent/ },
);


sub _encode {
    my $self = shift;
    my $hr = shift;

    return encode_json($hr);
}

sub _decode {
    my $self = shift;
    my $json = shift;

    return decode_json($json);
}

sub _send {
    my $self = shift;
    my $method = uc shift;
    my $endpoint = shift;
    my $data = shift;

    my $url = $self->base_url . $endpoint;

    my $req;
    if ( $method eq "POST" ) {
        if ( ref($data) eq "HASH" ) {
            $data = $self->_encode($data);
        }

        $req = POST $url, Content => $data;
    }
    elsif ( $method eq "GET" ) {
        $req = GET $url;
    }
    else {
        croak "$method is not supported.";
    }

    my $response = $self->ua->request($req);

    if ( $response->is_success ) {
        return $self->_decode($response->content());
    }
    else {
        croak "$method $url said " . $response->status_line;
    }
}

=head1 METHODS

=over

=item get()

This method uses the GET HTTP verb to fetch data from the Gett service.

Input:

=over

=item * endpoint fragment

=back

Output:

=over

=item * Perl hash ref of the JSON response from the API

=back

Gives a fatal error under any error condition.

=back

=cut

sub get {
    shift->_send('GET', @_);
}

=over

=item post()

This method uses the POST HTTP verb to send or fetch data to/from the Gett service.

Input:

=over

=item * endpoint fragment

=item * data (as a string or Perl hashref)

=back

If the data is a Perl hashref, it will be automatically encoded as JSON.

Output:

=over

=item * Perl hash ref of the JSON response from the API

=back

This method will die under any error condition.

=back

=cut

sub post {
    shift->_send('POST', @_);
}

=over

=item put()

This method uses the PUT HTTP verb to send data to the Gett service.

Input:

=over

=item * Full endpoint

=item * Data filehandle

=item * A chunksize

=item * the length of the data in bytes

=back

No automatic encoding is done this data. It is passed "as is" to the remote API.

Output:

=over

=item * A true value

=back

This method will die under any error condition.

=back

=cut

sub put {
    my $self = shift;
    my $url = shift;
    my $fh = shift;
    my $chunk_size = shift;
    my $length = shift;

    local $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

    my $header = HTTP::Headers->new;
    $header->content_length($length);

    my $req = HTTP::Request->new(
        'PUT',
        $url,
        $header,
        sub {
            my $ret = read($fh, my $chunk, $chunk_size);
            return $ret ? $chunk : ();
        },
    );

    my $response = $self->ua->request($req);

    close $fh;
    
    if ( $response->is_success ) {
        return 1;
    }
    else {
        croak "$url said " . $response->status_line;
    }
}

=head1 SEE ALSO

L<Net::API::Gett>

=cut

1;
