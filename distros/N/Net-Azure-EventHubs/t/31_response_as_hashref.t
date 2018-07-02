use strict;
use warnings;
use Test::More;
use Net::Azure::EventHubs::Request;
use LWP::UserAgent;

subtest 'html response' => sub {
    my $uri = URI->new('http://metacpan.org/search');
    $uri->query_form(q => 'Azure', size => '50'); 
    my $req = Net::Azure::EventHubs::Request->new(GET => $uri);
    $req->agent(LWP::UserAgent->new);
    my $res = $req->do;
    can_ok $res, qw/as_hashref/;
    my $data = $res->as_hashref;
    is $data, undef, 'data is undefined';
};

subtest 'json response' => sub {
    my $uri = URI->new('http://fastapi.metacpan.org/v1/release/_search');
    $uri->query_form(q => 'name:Net-Azure-EventHubs-0.02', fields => 'download_url,name'); 
    my $req = Net::Azure::EventHubs::Request->new(GET => $uri);
    $req->agent(LWP::UserAgent->new);
    my $res = $req->do;
    can_ok $res, qw/as_hashref/;
    my $data = $res->as_hashref;
    isa_ok $data, 'HASH', 'data is a HASHREF';
    is $data->{hits}{hits}[0]{fields}{name}, 'Net-Azure-EventHubs-0.02', 'matched module name is "Net-Azure-EventHubs-0.02"';
};


done_testing;