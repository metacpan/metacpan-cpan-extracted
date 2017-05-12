package SimpleDB::Client;
{
  $SimpleDB::Client::VERSION = '1.0600';
}

=head1 NAME

SimpleDB::Client - The network interface to the SimpleDB service.

=head1 VERSION

version 1.0600

=head1 SYNOPSIS

 use SimpleDB::Client;

 my $sdb = SimpleDB::Client->new(secret_key=>'abc', access_key=>'123');

 # create a domain
 my $hashref = $sdb->send_request('CreateDomain', {DomainName => 'my_things'});

 # insert attributes
 my $hashref = $sdb->send_request('PutAttributes', {
     DomainName             => 'my_things', 
     ItemName               => 'car',
     'Attribute.1.Name'     => 'color',
     'Attribute.1.Value'    => 'red',
     'Attribute.1.Replace'  => 'true',
 });

 # get attributes
 my $hashref = $sdb->send_request('GetAttributes', {
     DomainName             => 'my_things', 
     ItemName               => 'car',
 });

 # search attributes
 my $hashref = $sdb->send_request('Select', {
     SelectExpression       => q{select * from my_things where color = 'red'},
 });

=head1 DESCRIPTION

This class will let you quickly and easily inteface with AWS SimpleDB. It throws exceptions from L<SimpleDB::Client::Exception>. It's very light weight. Although we haven't run any benchmarks on the other modules, it should outperform any of the other Perl modules that exist today. 

=head1 METHODS

The following methods are available from this class.

=cut

use Moose;
use Digest::SHA qw(hmac_sha256_base64);
use XML::Fast;
use LWP::UserAgent;
use HTTP::Request;
use Time::HiRes qw(usleep);
use URI::Escape qw(uri_escape_utf8);
use SimpleDB::Client::Exception;
use URI;

#--------------------------------------------------------

=head2 new ( params ) 

=head3 params

A hash containing the parameters to pass in to this method.

=head4 access_key

The access key given to you from Amazon when you sign up for the SimpleDB service at this URL: L<http://aws.amazon.com/simpledb/>

=head4 secret_key

The secret access key given to you from Amazon.

=head4 simpledb_uri

The constructor that SimpleDB::Client will connect to.  Defaults to: 
   
 URI->new('https://sdb.amazonaws.com/')

=cut

#--------------------------------------------------------

=head2 access_key ( )

Returns the access key passed to the constructor.

=cut

has 'access_key' => (
    is              => 'ro',
    required        => 1,
    documentation   => 'The AWS SimpleDB access key id provided by Amazon.',
);

#--------------------------------------------------------

=head2 secret_key ( )

Returns the secret key passed to the constructor.

=cut

has 'secret_key' => (
    is              => 'ro',
    required        => 1,
    documentation   => 'The AWS SimpleDB secret access key id provided by Amazon.',
);

#--------------------------------------------------------

=head2 simpledb_uri ( )

Returns the L<URI> object passed into the constructor that SimpleDB::Client will connect to.  Defaults to: 

 URI->new('https://sdb.amazonaws.com/')

=cut

has simpledb_uri => (
    is      => 'ro',
    default => sub { URI->new('http://sdb.amazonaws.com/') },
);

#--------------------------------------------------------

=head2 user_agent ( )

Returns the L<LWP::UserAgent> object that is used to connect to SimpleDB. It's cached here so it doesn't have to be created each time. 

=cut

has user_agent => (
    is      => 'ro',
    default => sub { LWP::UserAgent->new(timeout=>30, keep_alive=>1); },
);

#--------------------------------------------------------

=head2 construct_request ( action, [ params ] )

Returns a string that contains the HTTP post data ready to make a request to SimpleDB. Normally this is only called by send_request(), but if you want to debug a SimpleDB interaction, then having access to this method is critical.

=head3 action

The action to perform on SimpleDB. See the "Operations" section of the guide located at L<http://docs.amazonwebservices.com/AmazonSimpleDB/2009-04-15/DeveloperGuide/>.

=head3 params

Any extra prameters required by the operation. The normal parameters of Action, AWSAccessKeyId, Version, Timestamp, SignatureMethod, SignatureVersion, and Signature are all automatically provided by this method.

=cut

sub construct_request {
    my ($self, $action, $params) = @_;
    my $encoding_pattern = "^A-Za-z0-9\-_.~";

    # add required parameters
    $params->{'Action'}           = $action;
    $params->{'AWSAccessKeyId'}   = $self->access_key;
    $params->{'Version'}          = '2009-04-15';
    $params->{'Timestamp'}        = sprintf("%04d-%02d-%02dT%02d:%02d:%02d.000Z", sub { ($_[5]+1900, $_[4]+1, $_[3], $_[2], $_[1], $_[0]) }->(gmtime(time)));
    $params->{'SignatureMethod'}  = 'HmacSHA256';
    $params->{'SignatureVersion'} = 2;

    # construct post data
    my $post_data;
    foreach my $name (sort {$a cmp $b} keys %{$params}) {
        $post_data .= $name . '=' . uri_escape_utf8($params->{$name}, $encoding_pattern) . '&';
    }
    chop $post_data;

    # sign the post data
    my $signature = "POST\n".$self->simpledb_uri->host."\n/\n". $post_data;
    $signature = hmac_sha256_base64($signature, $self->secret_key) . '=';
    $post_data .= '&Signature=' . uri_escape_utf8($signature, $encoding_pattern);

    my $request = HTTP::Request->new('POST', $self->simpledb_uri->as_string);
    $request->content_type("application/x-www-form-urlencoded; charset=utf-8");
    $request->content($post_data);

    return $request;
}

#--------------------------------------------------------

=head2 send_request ( action, [ params ] )

Creates a request, and then sends it to SimpleDB. The response is returned as a hash reference of the raw XML document returned by SimpleDB. Automatically attempts 5 cascading retries on connection failure.

Throws SimpleDB::Client::Exception::Response and SimpleDB::Client::Exception::Connection.

=head3 action

See create_request() for details.

=head3 params

See create_request() for details.

=cut

sub send_request {
    my ($self, $action, $params) = @_;
    my $request = $self->construct_request($action, $params);
    # loop til we get a response or throw an exception
    foreach my $retry (1..5) { 

        # make the request
        my $ua = $self->user_agent;
        my $response = $ua->request($request);

        # got a possibly recoverable error, let's retry
        if ($response->code >= 500 && $response->code < 600) {
            if ($retry < 5) {
                usleep((4 ** $retry) * 100_000);
            }
            else {
                warn $response->header('Reason');
                SimpleDB::Client::Exception::Connection->throw(error=>'Exceeded maximum retries.', status_code=>$response->code);
            }
        }

        # not a retry
        else {
            return $self->handle_response($response);
        }
    }
}

#--------------------------------------------------------

=head2 handle_response ( response ) 

Returns a hashref containing the response from SimpleDB.

Throws SimpleDB::Client::Exception::Response.

=head3 response

The L<HTTP::Response> object created by the C<send_request> method.

=cut

sub handle_response {
    my ($self, $response) = @_;
    my $tree = eval { xml2hash($response->content) };
    my (undef, $content) = each %$tree;  # discard root like XMLin
    # compatibility with SimpleDB::Class
    if (exists $content->{SelectResult} && ! $content->{SelectResult}) {
        $content->{SelectResult} = {};
    }
    # force an item list into an array
    if (exists $content->{SelectResult}{Item} && ref $content->{SelectResult}{Item} ne 'ARRAY') { 
         $content->{SelectResult}{Item} = [ $content->{SelectResult}{Item} ];
    }

    # choked reconstituing the XML, probably because it wasn't XML
    if ($@) {
        SimpleDB::Client::Exception::Response->throw(
            error       => 'Response was garbage. Confirm Net::SSLeay, XML::Parser, and XML::Simple installations.', 
            status_code => $response->code,
            response    => $response,
        );
    }

    # got a valid response
    elsif ($response->is_success) {
        return $content;
    }

    # SimpleDB gave us an error message
    else {
        SimpleDB::Client::Exception::Response->throw(
            error       => $content->{Errors}{Error}{Message},
            status_code => $response->code,
            error_code  => $content->{Errors}{Error}{Code},
            box_usage   => $content->{Errors}{Error}{BoxUsage},
            request_id  => $content->{RequestID},
            response    => $response,
        );
    }
}

=head1 PREREQS

This package requires the following modules:

L<XML::Fast>
L<LWP>
L<Time::HiRes>
L<Crypt::SSLeay>
L<Moose>
L<Digest::SHA>
L<URI>
L<Exception::Class>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/SimpleDB-Client>

=item Bug Reports

L<http://rt.cpan.org/Public/Dist/Display.html?Name=SimpleDB-Client>

=back

=head1 SEE ALSO

There are other packages you can use to access SimpleDB. I chose not to use them because I wanted something a bit more lightweight that I could build L<SimpleDB::Class> on top of so I could easily map objects to SimpleDB Domain Items. If you're looking for a low level SimpleDB accessor and for some reason this module doesn't cut the mustard, then you should check out these:

=over

=item Amazon::SimpleDB (L<http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1136>)

A complete and nicely functional low level library made by Amazon itself.

=item L<Amazon::SimpleDB>

A low level SimpleDB accessor that's in its infancy and may be abandoned, but appears to be pretty functional, and of the same scope as Amazon's own module.

=back

In addition to clients, there is at least one other API compatible server out there that basically lets you host your own SimpleDB if you don't want to put it in Amazon's cloud. It's called M/DB. You can read more about it here: L<http://gradvs1.mgateway.com/main/index.html?path=mdb>. Though I haven't tested it, since it's API compatible, you should be able to use it with both this module and L<SimpleDB::Class>.

=head1 AUTHOR

JT Smith <jt_at_plainblack_com>

I have to give credit where credit is due: SimpleDB::Client is heavily inspired by the Amazon::SimpleDB class distributed by Amazon itself (not to be confused with L<Amazon::SimpleDB> written by Timothy Appnel).

=head1 LEGAL

SimpleDB::Client is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
