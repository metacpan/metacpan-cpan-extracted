use strict;
use warnings;
use Test::Tester;
use Test::More tests => 6 * 3;
use Test::Crontab::Format;

# ok
for my $n( 1 .. 1 ){
    my $file = sprintf "t/eg/%02d.txt", $n;
    open my $fh, '<', $file or BAIL_OUT "cannot read test file !";
    check_test(
	sub {
	    crontab_format_ok( \ do { local $/; <$fh> } );
	    $fh->close;
	},
	{
	    ok   => 1,
	    name => "crontab format: scalar content",
	},
	"valid format"
    );
}

# not ok
for my $n( 21 .. 21 ){
    my $file = sprintf "t/eg/%02d.txt", $n;
    open my $fh, '<', $file or BAIL_OUT "cannot read test file !";
    check_test(
	sub {
	    crontab_format_ok( \ do { local $/; <$fh> } );
	    $fh->close;
	},
	{
	    ok   => 0,
	    name => "scalar content",
	},
	"invalid format"
    );
}

# empty
do {
    check_test(
	sub {
	    crontab_format_ok( \ "" );
	},
	{
	    ok   => 0,
	    name => "scalar content",
	},
	"empty content"
    );
};

__END__
