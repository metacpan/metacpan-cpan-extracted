package Net::Google::AuthSub::Once;
use strict;
use warnings;

our $VERSION = '0.1.0';

use URI;
use URI::QueryParam;

use Crypt::Random 'makerandom';
use Crypt::OpenSSL::RSA;
use File::Slurp 'read_file';
use MIME::Base64;

sub new {
    my ($klass, $options) = @_;
    my $self = bless {}, $klass;
    $self->{private_key_filename} = $options->{private_key_filename};
    return $self;
}

sub get_authorization_url {
    my ($self, $next_url) = @_;
    my $google_url = URI->new("http://www.google.com/accounts/AuthSubRequest");
    $google_url->query_param('next' => $next_url);
    $google_url->query_param('scope' => 'http://www.google.com/m8/feeds/contacts');
    $google_url->query_param('session' => 0);
    $google_url->query_param('secure'  => 1);
    return $google_url;
}

sub sign_request {
    my ($self, $request, $url, $token) = @_;

    my $nonce = makerandom(Size => 64);
    my $timestamp = time;
    my $data = "GET $url $timestamp $nonce";

    my $private_key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($self->{'private_key_filename'}));

    my $sig  = encode_base64($private_key->sign($data));

    my $auth = qq{AuthSub token="$token" sigalg="rsa-sha1" data="$data" sig="$sig"};
    $request->header('Authorization', $auth);

    return;
}

1;


=head1 NAME

Net::Google::AuthSub::Once - Make one secure authenticated request to a Google service

=head1 SYNOPSYS

    my $auth = Net::Google::AuthSub::Once->new();
    redirect_to($auth->get_authorization_url('http://example.com/your-next-url'));

    # Then after the response comes back
    
    # Make a request to the Google service
    my $auth = Net::Google::AuthSub::Once->new({ private_key_filename => 'filename' });
    my $request = HTTP::Request->new(GET => 'http://www.google.com/...');
    $auth->sign_request($request);
    my $resp = $ua->request($request);

=head1 DESCRIPTION

The nice thing about this module is that you don't need to know the Google
login details of the user of your applications. You can make a secure request
to a Google service in their place.

You must add your domain on Google for using secure requests. This module only
supports secure requests.  L<https://www.google.com/accounts/ManageDomains>

Google has some information about create the private key file you need.

L<http://code.google.com/apis/gdata/docs/auth/authsub.html#Registered>

=head1 METHODS

=head2 CLASS->new($options)

=over 4

=item * private_key_filename

The filename of a private key file.

=back


=head2 $self->get_authorization_url($next_url)

Returns the authorization url that you need to redirect to. Next_url is the url that
google will redirect you to after the request was authorized.

=head2 $self->sign_request($request, $url, $token)

Signs the HTTP::Request.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright, 2010 - Peter Stuifzand

Released under the same terms as Perl itself

=cut

