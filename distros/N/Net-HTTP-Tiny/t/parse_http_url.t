use warnings;
use strict;

use Test::More tests => 169;

use Net::HTTP::Tiny ();

sub parse_ok($$) {
	my($url, $expect) = @_;
	my $res = eval { Net::HTTP::Tiny::_parse_http_url($url) };
	if(defined $res) {
		is_deeply $res, $expect, $url;
	} else {
		my $err = $@;
		ok 0, $url;
		diag $err;
	}
}

sub parse_error_ok($) {
	my($url) = @_;
	eval { Net::HTTP::Tiny::_parse_http_url($url) };
	my $file = __FILE__; my $line = __LINE__-1;
	like $@, qr/\A
		HTTP\ error:\ \<\Q$url\E\>\ is\ not\ an\ http\ URL
		\ at\ \Q$file\E\ line\ \Q$line\E\.?\n
	\z/x, $url;
}

parse_ok "http://foo.bar", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/",
};

parse_ok "http://foo.bar/", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/",
};

parse_ok "http://foo.bar/baz", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz",
};

parse_ok "http://foo.bar/baz/", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz/",
};

parse_ok "http://foo.bar/baz/quux", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz/quux",
};

parse_ok "http://foo.bar/baz/quux/wibble", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz/quux/wibble",
};

parse_ok "http://foo.bar/b%61z/L%e9on", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/b%61z/L%e9on",
};

parse_ok "http://foo.bar/baz%2Fquux/L%e9on", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz%2Fquux/L%e9on",
};

parse_ok "http://foo.bar/baz:\@quux/0-.;_~!\$&'()*+,=", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz:\@quux/0-.;_~!\$&'()*+,=",
};

parse_error_ok "http://foo.bar/baz|quux";
parse_error_ok "http://foo.bar/L\xe9on";

parse_ok "http://foo.bar/baz//quux", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz//quux",
};

parse_ok "http://foo.bar/baz?quux", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz?quux",
};

parse_ok "http://foo.bar/baz?0-.;_~!\$/&'()*+,=?quux", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz?0-.;_~!\$/&'()*+,=?quux",
};

parse_ok "HttP://foo.bar/baz", {
	host => "foo.bar",
	port => 80,
	path_and_query => "/baz",
};

parse_error_ok "htp://foo.bar/baz";
parse_error_ok "http:/baz";
parse_error_ok "://foo.bar/baz";
parse_error_ok "http//foo.bar/baz";
parse_error_ok "http:/foo.bar/baz";

parse_ok "http://foo.bar:0123/baz", {
	host => "foo.bar",
	port => 123,
	path_and_query => "/baz",
};

parse_error_ok "http://foo.bar:123a/baz";

foreach my $hostname (qw(
	womble
	FOO.BAR
	a.b.c.d.e.f.example
	a.ab.abc.a-c.a--d.example
	0.01.012.0-2.0--3.example
	foo.a
	foo.ab
	foo.abc
	foo.a-c
	foo.a--d
	foo.a1
	foo.a12
	foo.a-2
	foo.a--3
	a
	ab
	abc
	a-c
	a--d
	a1
	a12
	a-2
	a--3
	10.1.2.3
	100.0.255.1
	10.1.2.10
	10.1.2.99
	10.1.2.100
	10.1.2.199
	10.1.2.200
	10.1.2.249
	10.1.2.250
	10.1.2.255
	255.255.255.255
	[::]
	[::1]
	[123::]
	[fd12:3456:789a::3]
	[fd12:3456:789a::3:4]
	[2001:D0C0:3:4:5:6:7:8]
	[::ffff:10.1.2.3]
	[v0.oh_hai]
)) {
	parse_ok "http://$hostname", {
		host => $hostname,
		port => 80,
		path_and_query => "/",
	};
	parse_ok "http://$hostname/baz", {
		host => $hostname,
		port => 80,
		path_and_query => "/baz",
	};
	parse_ok "http://$hostname:81", {
		host => $hostname,
		port => 81,
		path_and_query => "/",
	};
}

foreach my $hostname (qw(
	w%6fmble
	foo%2ebar
	foo..bar
	foo.0
	foo.0b
	foo.0bc
	foo.0-c
	foo.0--d
	[foo.bar]
	10.01.2.3
	100.0.256.1
	[10.1.2.3]
	::
	[1:2:3:4::6:7:8:9]
	[1:2:3:4:5:6:7:8:9]
	[02001:2:3:4:5:6:7:8]
	2001:D0C0:3:4:5:6:7:8
	foo_bar.baz
)) {
	parse_error_ok "http://$hostname/baz";
}

parse_error_ok "http://\@foo.bar/baz";
parse_error_ok "http://falken\@foo.bar/baz";
parse_error_ok "http://falken:joshua\@foo.bar/baz";

1;
