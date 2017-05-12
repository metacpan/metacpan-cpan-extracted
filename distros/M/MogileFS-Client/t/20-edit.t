#!/usr/bin/perl -w

my $NUM_TESTS;
BEGIN {
    $NUM_TESTS = 21;
}

use strict;
use Test::More;
use MogileFS::Client;
use LWP;

# Sorry, uncomment this if you intend to test/use the feature.
plan skip_all => "experimental/unfinished feature, skipping tests";
exit 0;

my $test_ns  = "humyo";
my $data     = "0123456789" x 10;
my $data_len = length $data;

my $mogc = MogileFS::Client->new(hosts  => ['127.0.0.1:7001'],
                                 domain => $test_ns);

my $key = 'edit_test_file';

my $fh;                           
eval { $fh = $mogc->new_file($key, undef, undef, { largefile => 1 } ); };

if ($@ =~ m/couldn't connect/) {
    plan skip_all => "No mogilefsd process running on 127.0.0.1:7001";
    exit 0;
} else {
    plan tests => $NUM_TESTS;
}

ok($fh, "file handle using HTTPFile");

my $wv = (print $fh $data);
is($wv, $data_len, "wrote data bytes out");
ok($fh->close, "closed successfully");

SKIP: {
    # Test that the back-end supports DAV MOVE and partial PUT
    my @urls = $mogc->get_paths($key);
    ok(scalar(@urls) > 0, "can get paths for key $key");

    skip "No DAV MOVE support - edit_file won't work", ($NUM_TESTS - 4)
        unless server_supports_dav_move($urls[0]);

    skip "No partial PUT support - edit_file won't work", ($NUM_TESTS - 4)
        unless server_supports_partial_put($urls[0]);

    # Get on with the tests

    $fh = $mogc->read_file($key);

    ok($fh, "file handle from read_file");

    my $buf;
    my $read = $fh->read($buf, $data_len);

    is($read, $data_len, "read $data_len bytes"); 
    is($buf, $data, "got back data");

    ok($fh->eof, "at EOF");

    ok($fh->close, "closed successfully");

    $fh = $mogc->edit_file($key);

    ok($fh, "file handle from edit_file");

    ok($fh->seek(0, 2), "can seek to end");
    ok($fh->binmode(), "can binmode file");

    $wv = (print $fh $data);
    is($wv, $data_len, "wrote data bytes out");
    ok($fh->close, "closed successfully");

    $fh = $mogc->read_file($key);
    $read = $fh->read($buf, ($data_len * 2));
    is($read, $data_len * 2, "read $data_len * 2 bytes"); 
    is($buf, $data . $data, "got back data");
    $fh->close;

    $fh = $mogc->edit_file($key, { overwrite => 1 });

    ok($fh, "file handle from edit_file with overwrite");

    $wv = (print $fh $data);
    is($wv, $data_len, "wrote data bytes out");
    ok($fh->close, "closed successfully");

    $fh = $mogc->read_file($key);
    $read = $fh->read($buf, $data_len);
    is($read, $data_len, "read $data_len bytes"); 
    is($buf, $data, "got back data");
    $fh->close;
}

sub server_supports_dav_move {
    my $moveFrom = shift;

    my $moveTo = $moveFrom . ".movetest";

    # Move the test url
    my $req = HTTP::Request->new(MOVE => $moveFrom);
    $req->header(Destination => $moveTo);
    my $ua = LWP::UserAgent->new;
    my $resp = $ua->request($req);
    return unless $resp->is_success;

    # Put it back
    $req = HTTP::Request->new(MOVE => $moveTo);
    $req->header(Destination => $moveFrom);
    $resp = $ua->request($req);
    return unless $resp->is_success;

    return 1;
}

sub server_supports_partial_put {
    my $url = shift;

    my $testUrl = $url . ".puttest";

    my $totalLength = 100;
    my $startData = "0" x $totalLength;

    # Create a file
    my $req = HTTP::Request->new(PUT => $testUrl);
    $req->add_content($startData);
    my $ua = LWP::UserAgent->new;
    my $resp = $ua->request($req);
    return unless $resp->is_success;

    # Overwrite the first half
    $req = HTTP::Request->new(PUT => $testUrl);
    my $partialPutEnd = $totalLength / 2;
    $req->header('Content-Range' => "bytes 0-$partialPutEnd/*");
    $req->add_content("1" x ($partialPutEnd + 1)); # range is inclusive of end offset
    $resp = $ua->request($req);
    return unless $resp->is_success;

    # Fetch the whole thing
    $resp = $ua->get($testUrl);
    my $fetchedData = $resp->content;
    my $expectedData = "1" x ($partialPutEnd + 1) . "0" x ($totalLength - ($partialPutEnd + 1));
    return unless $fetchedData eq $expectedData;

    return 1;
}
