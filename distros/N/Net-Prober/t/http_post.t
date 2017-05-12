=pod

=head1 NAME

t/http_post.t - Net::Prober test suite

=head1 DESCRIPTION

Try to probe hosts via HTTP POST requests

=cut

use strict;
use warnings;

use Data::Dumper;
use LWP::Online ':skip_all';
use Test::More tests => 3;

use Net::Prober;
use Net::Prober::Probe::HTTP;
use URI;

my $probe = Net::Prober::Probe::HTTP->new();
my $req = $probe->_prepare_request({
    host    => 'www.altavista.com',
    url     => '/ping.html',
    method  => 'POST',
    headers => [
        "Content-Type" => "application/json",
    ],
});

is $req->method, "POST";

is $req->uri, "http://www.altavista.com/ping.html";

#iag(Dumper($req->headers));
#iag(Dumper($req));

my $h = $req->headers;
is $h->header("Content-Type"), "application/json";
