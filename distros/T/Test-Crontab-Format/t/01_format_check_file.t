use strict;
use warnings;
use Test::Tester;
use Test::More tests => 6 * 5;
use Test::Crontab::Format;

# ok
for my $n( 1 .. 1 ){
    my $file = sprintf "t/eg/%02d.txt", $n;
    check_test(
	sub {
	    crontab_format_ok( $file );
	},
	{
	    ok   => 1,
	    name => sprintf("crontab format: %s", $file),
	},
	"valid format"
    );
}

# not ok
for my $n( 21 .. 21 ){
    my $file = sprintf "t/eg/%02d.txt", $n;
    check_test(
	sub {
	    crontab_format_ok( $file );
	},
	{
	    ok   => 0,
	    name => $file,
	},
	"invalid format"
    );
}

# not readable
do {
    my $file = "inexistent/file";
    check_test(
	sub {
	    crontab_format_ok( $file );
	},
	{
	    ok   => 0,
	    name => $file,
	},
	"unreadable file"
    );
};

# directory
do {
    my $file = "lib/";
    check_test(
	sub {
	    crontab_format_ok( $file );
	},
	{
	    ok   => 0,
	    name => $file,
	},
	"is directory"
    );
};

# empty
do {
    my $file = "t/eg/empty.txt";
    check_test(
	sub {
	    crontab_format_ok( $file );
	},
	{
	    ok   => 0,
	    name => $file,
	},
	"empty file"
    );
};

__END__
