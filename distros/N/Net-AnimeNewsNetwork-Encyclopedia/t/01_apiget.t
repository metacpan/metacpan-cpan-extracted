use strict;
use Test::More;
use Test::Fake::HTTPD;
use Path::Tiny;
use Try::Tiny;
use Net::AnimeNewsNetwork::Encyclopedia;

my $httpd = run_http_server {
    my $req = shift;
    my $reports_xml = path("t/xml/reports_xml_id_155_type_anime")->absolute->slurp;
    my $api_xml = path("t/xml/api_xml_anime_4658")->absolute->slurp;
    my $path = $req->uri->path;
    if ($path eq '/reports.xml') {
        return HTTP::Response->new(200, undef, undef, $reports_xml);
    } elsif ($path eq '/api.xml') {
        return HTTP::Response->new(200, undef, undef, $api_xml);
    } else {
        return HTTP::Response->new(404);
    }
};
my $ann = Net::AnimeNewsNetwork::Encyclopedia->new(url => $httpd->endpoint);

subtest 'GET Reports API' => sub {
    try {
        my $content = $ann->get_reports(id => 155, type => 'anime');
        ok defined $content;
    } catch {
        fail $_;
    };
};

subtest 'GET Details API' => sub {
    try {
        my $content = $ann->get_details(anime => 4658);
        ok defined $content;
    } catch {
        fail $_;
    };
};

done_testing;
