use strict;
use warnings;
use Test::More;
use Test::Exception;
use Net::Azure::NotificationHubs::Request;
use HTTP::Tiny;

subtest 'html response' => sub {
    my $uri = URI->new('https://metacpan.org/search');
    $uri->query_form(q => 'Azure', size => 100); 
    my $req = Net::Azure::NotificationHubs::Request->new(GET => $uri);
    $req->agent(HTTP::Tiny->new);
    my $res;
    dies_ok { $res = $req->do } qr/Payment Required/;
    is $res, undef, 'res is undefined';
};

subtest 'json response' => sub {
    my $uri = URI->new('http://fastapi.metacpan.org/v1/release/_search');
    $uri->query_form(q => 'name:Net-Azure-Authorization-SAS-0.02', fields => 'download_url,name'); 
    my $req = Net::Azure::NotificationHubs::Request->new(GET => $uri);
    $req->agent(HTTP::Tiny->new);
    my $res = $req->do;
    can_ok $res, qw/as_hashref/;
    my $data = $res->as_hashref;
    isa_ok $data, 'HASH', 'data is a HASHREF';
    is $data->{hits}{hits}[0]{fields}{name}, 'Net-Azure-Authorization-SAS-0.02', 'matched module name is "Net-Azure-Authorization-SAS-0.02"';
};


done_testing;