use strict;
use warnings;
use Test::Spec;
use HTTP::Request;
use HTTP::Response;
use Test::Deep;
use Test::Fatal qw(lives_ok dies_ok);
use Net::Kubernetes;
use MIME::Base64;
use Test::Mock::Wrapper 0.18;

describe "Net::Kubernetes - Authentication options" => sub {
	my $lwpMock;
	before sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
	};
	it "can be instantiated" => sub {
		new_ok( 'Net::Kubernetes' )
	};
	describe "username and password" => sub {
		my $kube;
		before sub {
			$kube = Net::Kubernetes->new(username=>'Marti', password=>'McFly');
		};
		it "includes header Authorization: Basic with created requests" => sub {
			my $req = $kube->create_request(GET => '/pods');
			ok(defined $req->header('Authorization'));
			is($req->header('Authorization'), "Basic ".encode_base64('Marti:McFly'));
		};
	};
	describe "token" => sub {
		it "includes the token string directly if its is not a filepath" => sub {
			my $kube = Net::Kubernetes->new(token=>'my_token_string');
			my $req = $kube->create_request(GET => '/pods');
			ok(defined $req->header('Authorization'));
			is($req->header('Authorization'), "Bearer my_token_string");

		};
		it "includes the token read from the provided file if path is given" => sub {
			my $kube = Net::Kubernetes->new(token=>'./t/my_token.dat');
			my $req = $kube->create_request(GET => '/pods');
			ok(defined $req->header('Authorization'));
			is($req->header('Authorization'), "Bearer this_was_read_from_a_file");
		};
		it "attempts to read from hte provided object (like IO::Handle) if passed a reference" => sub {
			open(my $fh, './t/my_token.dat');
			my $kube = Net::Kubernetes->new(token=>$fh);
			close($fh);
			my $req = $kube->create_request(GET => '/pods');
			ok(defined $req->header('Authorization'));
			is($req->header('Authorization'), "Bearer this_was_read_from_a_file");

		};
	};
};

runtests;
