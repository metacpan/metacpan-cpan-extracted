package Net::ZooTool::Utils;

use Moose::Role;

use JSON::XS;
use Carp;
use Data::Dumper;
use Digest::SHA1 qw/sha1_hex/;
use WWW::Curl::Easy;

use namespace::autoclean;

our $VERSION = '0.003';

=head2
    Fetches data
    Returns hashref
=cut

sub _fetch {
    my $path = shift;
    my $auth = shift;

    my $base_url = 'zootool.com/api';

    my $url = $base_url . $path;

    my $c = WWW::Curl::Easy->new();
    $c->setopt( CURLOPT_HEADER, 0 );

    # HTTP Digest Authentication
    if ( $path =~ /login=true/ and ( defined($auth) and  $auth->user and $auth->password ) ) {
        $c->setopt(CURLOPT_HTTPAUTH, CURLAUTH_DIGEST);
        $c->setopt(CURLOPT_USERPWD, $auth->user . ':' . sha1_hex($auth->password));
    }

    $c->setopt(CURLOPT_USERAGENT, 'Net::ZooTool v0.1');

    $c->setopt(CURLOPT_URL,  $url );
    $c->setopt(CURLOPT_VERBOSE,0);


    my $response_body;
    $c->setopt( CURLOPT_WRITEDATA, \$response_body );

    # Starts the actual request
    my $retcode = $c->perform;

    if ( $retcode == 0 ) {
        my $response_code = $c->getinfo(CURLINFO_HTTP_CODE);
        # judge result and next action based on $response_code
        return JSON::XS->new->utf8->decode($response_body);
    }
    else {
        carp(   "An error happened: $retcode "
              . $c->strerror($retcode) . " "
              . $c->errbuf
              . "\n" );
    }
}


=head2
    Transforms hash to query string
    Returns string
=cut
sub _hash_to_query_string {
    my $args = shift;

    my @params = keys %$args;
    my $first  = shift @params;

    my $query_string .= "?$first=" . $args->{$first};
    foreach (@params) {
        $query_string .= "&$_=" . $args->{$_};
    }

    return $query_string;
}

1;
