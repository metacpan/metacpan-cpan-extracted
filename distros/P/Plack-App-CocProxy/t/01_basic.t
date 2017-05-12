
use strict;
use warnings;
use Test::More;
use Plack::App::CocProxy;
use Plack::App::Proxy::Test;
use File::Temp qw(tempdir);
use Path::Class;

my $dir = dir(tempdir( CLEANUP => 1 ));

{

	my ($host, $port);
	test_proxy(
		proxy => sub { ($host, $port) = @_; Plack::App::CocProxy->new(root => '.') },
		app   => sub {
			my $env = shift;
			return [ 200, [], [ 'ok' ] ];
		},
		client => sub {
			my $cb = shift;
			$dir->subdir("foo/bar")->mkpath;
			$dir->subdir("$host/foo/bar")->mkpath;

			{
				my $req = HTTP::Request->new(GET => "http://$host:$port/index.html", [ Host => "$host:$port" ]);
				my $res = $cb->($req);
				ok $res->is_success, "success";
				is $res->content, 'ok', "remote access";
			};

			{
				my $req = HTTP::Request->new(GET => "http://$host:$port/foo/bar/test.html", [ Host => "$host:$port" ]);
				my $res = $cb->($req);
				ok $res->is_success, "success";
				is $res->content, 'ok', "remote access";
			};

			{

				my $f = $dir->file("foo/bar/test.html")->open("w");
				$f->print("111");
				$f->close;

				my $req = HTTP::Request->new(GET => "http://$host:$port/foo/bar/test.html", [ Host => "$host:$port" ]);
				my $res = $cb->($req);
				ok $res->is_success, "success 111";
			};

			{

				my $f = $dir->file("$host/test.html")->open("w");
				$f->print("222");
				$f->close;

				my $req = HTTP::Request->new(GET => "http://$host:$port/foo/bar/test.html", [ Host => "$host:$port" ]);
				my $res = $cb->($req);
				ok $res->is_success, "success 222";
			};

			{
				my $f = $dir->file("$host/foo/bar/test.html")->open("w");
				$f->print("333");
				$f->close;

				my $req = HTTP::Request->new(GET => "http://$host:$port/foo/bar/test.html", [ Host => "$host:$port" ]);
				my $res = $cb->($req);
				ok $res->is_success, "success 333";
			};

			{
				my $f = $dir->file("test.html")->open("w");
				$f->print("444");
				$f->close;

				my $req = HTTP::Request->new(GET => "http://$host:$port/foo/bar/test.html", [ Host => "$host:$port" ]);
				my $res = $cb->($req);
				ok $res->is_success, "success 444";
			};
		},
	);
};

done_testing;
