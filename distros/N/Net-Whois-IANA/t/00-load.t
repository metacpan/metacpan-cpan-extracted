#!perl

use Test::More tests => 5;

BEGIN {
    use_ok( 'Net::Whois::IANA' ) || print "Bail out!
";
}

diag( "Testing Net::Whois::IANA $Net::Whois::IANA::VERSION, Perl $], $^X" );
ok($Net::Whois::IANA::VERSION, "version defined");
ok(@Net::Whois::IANA::EXPORT, "we're exporting");
for my $export (@Net::Whois::IANA::EXPORT) {
	if ($export =~ /^\W/) {
		my $val = eval $export;
		ok(defined $val, "val $export");
	}
	else {
		ok(defined &$export, "sub $export");
	}
}
