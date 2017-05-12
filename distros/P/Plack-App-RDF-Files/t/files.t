use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI;
use HTTP::Request;

use Plack::App::RDF::Files;

my $alice_files = {
    'file1.ttl' => {
        location => 't/data/alice',
          size   => (stat 't/data/alice/file1.ttl')[7],
          mtime  => (stat 't/data/alice/file1.ttl')[9],
    }
};

my @tests = (
  [
    { base_dir => './t/data', base_uri => 'http://example.org/', index_property => 1 },
    [ GET => 'http://example.org/' ],
    { },
  ],
  [
    { base_dir => './t/data', base_uri => 'http://example.org/' },
    [ GET => 'http://example.org/' ],
   undef
  ],
  [
    { base_dir => './t/data', base_uri => 'http://example.org/' },
    [ GET => '/alice' ],
    $alice_files,
  ],
  [
    { base_dir => './t/data' },
    [ GET => 'http://example.com/alice' ],
   $alice_files,
  ]
);


foreach my $test (@tests) {
    my $app = Plack::App::RDF::Files->new( %{$test->[0]} );
    my $req = HTTP::Request->new(@{$test->[1]});
    my $env = req_to_psgi($req);

    my $files = $app->files($env);
    if (defined $files) {
        is_deeply $files, $test->[2];
    } else {
        is undef, $test->[2], 'no files found';
    }

    my $uri = $req->uri;
    if ($uri !~ /^http:/) {
        $uri = $app->base_uri . substr($uri,1);
    }
    $app->_uri($env);
    is $env->{'rdf.uri'}, $uri, "rdf.uri = $uri";
}

done_testing;
