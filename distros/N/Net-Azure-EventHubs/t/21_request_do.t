use strict;
use warnings;
use Test::More;
use Test::Exception;
use Net::Azure::EventHubs::Request;
use URI;
use LWP::UserAgent;

subtest 'do' => sub {
    my $uri = URI->new('http://search.cpan.org/search');
    $uri->query_form(query => 'Azure', mode => 'all'); 
    my $req = Net::Azure::EventHubs::Request->new(GET => $uri);
    $req->agent(LWP::UserAgent->new);
    isa_ok $req, 'Net::Azure::EventHubs::Request';
    isa_ok $req, 'HTTP::Request';
    can_ok $req, qw/do/;
    my $res = $req->do;
    isa_ok $res, 'Net::Azure::EventHubs::Response';
    isa_ok $res, 'HTTP::Response';
    like $res->content, qr/Net::Azure/, 'response body contains "Net::Azure"'; 
};

subtest 'do - 404' => sub {
    my $uri = URI->new('http://search.cpan.org/search');
    my $req = Net::Azure::EventHubs::Request->new(GET => $uri);
    $req->agent(LWP::UserAgent->new);
    isa_ok $req, 'Net::Azure::EventHubs::Request';
    isa_ok $req, 'HTTP::Request';
    can_ok $req, qw/do/;
    my $res;
    dies_ok {$res = $req->do} qr/not found/;
    is $res, undef, 'Response object is not defined';
};

done_testing;