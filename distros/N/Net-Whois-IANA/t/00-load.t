#!perl

use Test::More tests => 5;

BEGIN {
    use_ok('Net::Whois::IANA') || print "Bail out!
";
}

if ( $ENV{AUTOMATED_TESTING} ) {
	$Net::Whois::IANA::VERSION = '1.00_testing' unless defined $Net::Whois::IANA::VERSION;
}

diag("Testing Net::Whois::IANA $Net::Whois::IANA::VERSION, Perl $], $^X");
ok( defined $Net::Whois::IANA::VERSION, "version defined" );
ok( scalar @Net::Whois::IANA::EXPORT,  "we're exporting" );

for my $export (@Net::Whois::IANA::EXPORT) {
    if ( $export =~ /^\W/ ) {
        my $val = eval $export;
        ok( defined $val, "val $export" );
    }
    else {
        ok( defined &$export, "sub $export" );
    }
}
