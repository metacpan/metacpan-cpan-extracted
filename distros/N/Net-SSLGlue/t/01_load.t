use strict;
use warnings;

print "1..3\n";
for (
	[ 'Net::SMTP','SMTP' ],
	[ 'LWP','LWP::Protocol::https', 'LWP'  ],
	[ 'Net::LDAP','LDAP' ],
) {
	my $glue = pop @$_;
	my @fail = map { eval("use $_;1") ? ():($_) } @$_;
	if ( ! @fail ) {
		eval "use Net::SSLGlue::$glue";
		print $@ ? "not ok # load $glue glue failed\n": "ok # load $glue glue\n"
	} else {
		print "ok # skip $glue glue - failed to load @fail\n"
	}
}
