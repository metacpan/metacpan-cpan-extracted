use strict;
use warnings;
use Test::More;
use Test::Exception;
use Net::Azure::NotificationHubs::Request;
use URI;
use lib 't/lib';
use MockHTTPTiny;

subtest 'do' => sub {
    my $uri = URI->new('https://metacpan.org/search');
    $uri->query_form(q => 'Azure', size => 100); 
    my $req = Net::Azure::NotificationHubs::Request->new(GET => $uri);
    $req->agent(MockHTTPTiny->new);
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    can_ok $req, qw/do/;
    my $res = $req->do;
    isa_ok $res, 'Net::Azure::NotificationHubs::Response';
    like $res->content, qr/Net::Azure/, 'response body contains "Net::Azure"'; 
};

subtest 'do - 404' => sub {
    # Using MockHTTPTiny to ensure consistent 404 behavior without external dependencies
    my $notfound_uri = URI->new('https://azure.microsoft.com/ja-jp/pricing/details/notification-hub/');
    my $req = Net::Azure::NotificationHubs::Request->new(GET => $notfound_uri);
    $req->agent(MockHTTPTiny->new);
    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    can_ok $req, qw/do/;
    my $res;
    dies_ok { $res = $req->do } qr/not found/;
    is $res, undef, 'Response object is not defined';
};

done_testing;