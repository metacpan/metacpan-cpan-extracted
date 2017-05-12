
use Test::More tests => 19;
BEGIN { use_ok('Net::LibNIDS') };
use strict;

# use a file here to reliably test things over and over again

Net::LibNIDS::param::set_filename("t/http-test.dump");

is(Net::LibNIDS::param::get_filename(), "t/http-test.dump", "Filename is set");
ok(Net::LibNIDS::init(), "Init it...");

my $i = 0;
Net::LibNIDS::tcp_callback(\&collector );
Net::LibNIDS::run();

sub collector {
    my $stream = shift;
    if($stream->state == Net::LibNIDS::NIDS_JUST_EST()) {
	$stream->server->collect_on;
	$stream->client->collect_on;
	#these should happen just once
	is($stream->client_ip, "192.168.1.0", "Client ip is correct");
	is($stream->client_port, "64567", "Client port is correct");
	is($stream->server_ip, "192.168.1.0", "Server ip is correct");
	is($stream->server_port, "80", "Server port is correct");
    } 
    elsif($stream->state == Net::LibNIDS::NIDS_DATA()) {
	my $half_stream;
	if($stream->client->count_new) {
	    $half_stream = $stream->client;
	} else {
	    $half_stream = $stream->server;
	}
	if($i == 0) {
	    like($half_stream->data, qr{GET / HTTP/1.1}, "Inital GET");
	} elsif($i == 1) {
	    like($half_stream->data, qr{HTTP/1.1 200 OK}, "Response");
	    like($half_stream->data, qr{If you can see this, it means that the installation of }, "Got some data");
	} elsif($i == 2) {
	    like($half_stream->data, qr{inistrator is using, has nothing to do with}, "With some more data");
	    like($half_stream->data, qr{You are free to use the image below on an Apache-powered}, "and the end of that");
	} elsif($i == 3) {
	    like($half_stream->data, qr{GET /apache_pb.gif HTTP/1.1}, "Fetch the image");
	    like($half_stream->data, qr{it;q=0.62, ja-jp;q=0.59, en;q=0.97, es-es;q=0.52, es;q=0.48, da-dk;q=0.45, da;q=0.41, fi-fi;q=0.38}, "Insane ordering languages :)");
	} elsif($i == 4) {
	    like($half_stream->data, qr{HTTP/1.1 200 OK}, "Return of image gif");
	    like($half_stream->data, qr{ETag: "425698-916-3714ea9f"}, "Check etag");
	    like($half_stream->data, qr{GIF89a}, "Check beginning of GIF89");
	} elsif($i == 5) {
	    # Hex representation of the last few bytes in the file
	    like($half_stream->data, qr{\x40\x02\x04\x04\x00\x3b}, "Middle of a GIF stream - not much to check for");
	} elsif($i == 6) {
	    fail("Shouldn't be called back 6 times with data");
	}
	$i++;
    }
    elsif($stream->state == Net::LibNIDS::NIDS_CLOSE()) {
	pass("Closing the connection");
    }
}
