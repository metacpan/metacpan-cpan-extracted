#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Deep;
use Mojolicious;
use Mojolicious::Plugin::PlainRoutes;
use File::Temp qw/tempfile/;

sub _test_pair {
	my ($name, $msg, $autoname) = @_;

	my ($fh, $filename) = tempfile;
	print $fh q{ GET /foo -> Bar.baz };
	close $fh;

	my $app = Mojolicious->new;
	$app->plugin('PlainRoutes', {
		file => $filename,
		autoname => $autoname,
	});

	is $app->routes->children->[0]->name, $name, $msg;
}

_test_pair("foo", "no autoname", 0);

_test_pair('bar-baz', "default autoname", 1);

_test_pair('GET /foo -> bar.baz', "custom autoname", sub {
	my ($verb, $path, $controller, $action) = @_;
	return "$verb $path -> $controller.$action";
});

done_testing;
