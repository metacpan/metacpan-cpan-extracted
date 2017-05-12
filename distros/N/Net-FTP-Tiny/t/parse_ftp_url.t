use warnings;
use strict;

use Test::More tests => 185;

use Net::FTP::Tiny ();

sub parse_ok($$) {
	my($url, $expect) = @_;
	my $res = eval { Net::FTP::Tiny::_parse_ftp_url($url) };
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
	eval { Net::FTP::Tiny::_parse_ftp_url($url) };
	my $file = __FILE__; my $line = __LINE__-1;
	like $@, qr/\A
		FTP\ error:\ \<\Q$url\E\>\ is\ not\ an\ ftp\ URL
		\ at\ \Q$file\E\ line\ \Q$line\E\.?\n
	/x, $url;
}

parse_ok "ftp://foo.bar", {
	host => "foo.bar",
	port => 21,
};

parse_ok "ftp://foo.bar/", {
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "",
};

parse_ok "ftp://foo.bar/baz", {
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://foo.bar/baz/", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz"],
	filename => "",
};

parse_ok "ftp://foo.bar/baz/quux", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz"],
	filename => "quux",
};

parse_ok "ftp://foo.bar/baz/quux/wibble", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz","quux"],
	filename => "wibble",
};

parse_ok "ftp://foo.bar/b%61z/L%e9on", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz"],
	filename => "L\xe9on",
};

parse_ok "ftp://foo.bar/baz%2Fquux/L%e9on", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz/quux"],
	filename => "L\xe9on",
};

parse_ok "ftp://foo.bar/baz:\@quux/0-._~!\$&'()*+,=", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz:\@quux"],
	filename => "0-._~!\$&'()*+,=",
};

parse_error_ok "ftp://foo.bar/baz;quux";
parse_error_ok "ftp://foo.bar/baz|quux";
parse_error_ok "ftp://foo.bar/L\xe9on";

parse_ok "ftp://foo.bar/baz//quux", {
	host => "foo.bar",
	port => 21,
	dirs => ["baz",""],
	filename => "quux",
};

foreach my $type (qw(a A i I d D)) {
	parse_ok "ftp://foo.bar/baz/quux;type=$type", {
		host => "foo.bar",
		port => 21,
		dirs => ["baz"],
		filename => "quux",
		type => lc($type),
	};
}

parse_error_ok "ftp://foo.bar/baz/quux;type=z";
parse_error_ok "ftp://foo.bar/baz/quux;typ%65=i";

parse_ok "FtP://foo.bar/baz", {
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_error_ok "fttp://foo.bar/baz";
parse_error_ok "ftp:/baz";
parse_error_ok "://foo.bar/baz";
parse_error_ok "ftp//foo.bar/baz";
parse_error_ok "ftp:/foo.bar/baz";

parse_ok "ftp://foo.bar:0123/baz", {
	host => "foo.bar",
	port => 123,
	dirs => [],
	filename => "baz",
};

parse_error_ok "ftp://foo.bar:123a/baz";

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
	parse_ok "ftp://$hostname", {
		host => $hostname,
		port => 21,
	};
	parse_ok "ftp://$hostname/baz", {
		host => $hostname,
		port => 21,
		dirs => [],
		filename => "baz",
	};
	parse_ok "ftp://$hostname:22", {
		host => $hostname,
		port => 22,
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
	parse_error_ok "ftp://$hostname/baz";
}

parse_ok "ftp://\@foo.bar/baz", {
	username => "",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://falken\@foo.bar/baz", {
	username => "falken",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://0Zz-._~!\$&'()*+,;=\@foo.bar/baz", {
	username => "0Zz-._~!\$&'()*+,;=",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://L%e9%6fn\@foo.bar/baz", {
	username => "L\xe9on",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_error_ok "ftp://a|b\@foo.bar/baz";
parse_error_ok "ftp://L\xe9on\@foo.bar/baz";

parse_ok "ftp://falken:\@foo.bar/baz", {
	username => "falken",
	password => "",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://falken:joshua\@foo.bar/baz", {
	username => "falken",
	password => "joshua",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://falken:0Zz-._~!\$&'()*+,;=\@foo.bar/baz", {
	username => "falken",
	password => "0Zz-._~!\$&'()*+,;=",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_ok "ftp://falken:L%e9%6fn\@foo.bar/baz", {
	username => "falken",
	password => "L\xe9on",
	host => "foo.bar",
	port => 21,
	dirs => [],
	filename => "baz",
};

parse_error_ok "ftp://falken:a|b\@foo.bar/baz";
parse_error_ok "ftp://falken:L\xe9on\@foo.bar/baz";

1;
