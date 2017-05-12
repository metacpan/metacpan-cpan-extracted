package Net::Semantics3;

use strict;
use warnings;

use Moose;
use methods;
use JSON::XS;
use OAuth::Lite::Consumer;
use Data::Dumper;
use Switch;

use Net::Semantics3::Error;

our $VERSION = '0.1';

=head1 NAME

Net::Semantics3 

=head1 DESCRIPTION

Base for API Client interfacing with the Semantics3 APIs.

=cut

has 'api_key' => ( is => 'ro', isa => 'Str', required   => 1 );
has 'api_secret' => ( is => 'ro', isa => 'Str', required   => 1 );
#has 'api_base' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'api_base' => ( is => 'ro', isa => 'Str' );
has 'oauth_client' => ( is => 'ro', isa => 'Object', lazy_build => 1 );

method _request {
    my ( $path, $jsonParams, $verb ) = @_;

    switch ($verb) {
        case "GET"    { return  $self->_make_request('GET', $path, $jsonParams);  }
        case "PUT"    { return  $self->_make_request('PUT', $path, $jsonParams);  }
        case "POST"    { return  $self->_make_request('POST', $path, $jsonParams);  }
        case "DELETE"    { return  $self->_make_request('DELETE', $path, $jsonParams);  }
        else           {
            Net::Semantics3::Error->new(
                type => "Invalid Method Type",
                message => "Method type has to be one of POST, PUT, DELETE or GET"
            );
        }
    }
}

method _make_request {
    my $reqType = shift;
    my $reqPath = shift;
    my $reqParamsJson = shift;
    my $url = "https://api.semantics3.com/v1";

    if(defined($self->api_base)) {
        $url = $self->api_base;
    }
    $url .= '/' . $reqPath;

    my $resp;
    my $hashRef;

    my $e = eval{
        if($reqType eq "GET") {
            $resp = $self->oauth_client->request(
                method => $reqType,
                url => $url,
                params => {q => $reqParamsJson},
            );
        }
        else {
            $resp = $self->oauth_client->request(
                method => $reqType,
                url => $url,
                content => $reqParamsJson
            );
        }
    };

    if($@) {
        Net::Semantics3::Error->new(
            type => "OAuth Rqeuest failed: $@",
            message => Dumper( $resp ),
        );
    }

    if ($resp->code !~ /2\d\d/ ) {
        Net::Semantics3::Error->new(
            type => "HTTP Request resulted in error: $@",
            message => $resp->status_line . " - Error code: " . $resp->code,
        );
    }

    $e = eval { $hashRef = decode_json($resp->content) };
    if ($@) {
        Net::Semantics3::Error->new(
            type => "Could not decode JSON response: $@",
            message => $resp->status_line . " - " . $resp->content,
        );
    }
    else {
        return $hashRef;
    }

    die "Fatal Error\n";
}

#method _build_api_base { 'https://api.semantics3.com/v1' }

method _build_oauth_client {
    my $ua = LWP::UserAgent->new;
    $ua->agent( "Semantics3 Perl Lib/$VERSION" );

    my $oauthClient = OAuth::Lite::Consumer->new(
      ua => $ua,
      consumer_key => $self->api_key,
      consumer_secret => $self->api_secret,
    );

    return $oauthClient;
}


=head1 SEE ALSO

L<https://semantics3.com>, L<https://semantics3.com/docs>

=head1 AUTHOR

Sivamani Varun, varun@semantics3.com

=head1 COPYRIGHT AND LICENSE

Net-Semantics3 is Copyright (C) 2013 Semantics3 Inc.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

__PACKAGE__->meta->make_immutable;
1;
