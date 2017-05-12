use Test;
use lib "lib";
BEGIN {  
	# only test if de_DE is available
	eval 'use POSIX qw(locale_h); setlocale(LC_TIME, "de_DE")' or do {
		plan tests => 0;
		warn "Locale 'de_DE' not available: locale test skipped.\n";
		exit;
	};
	
	plan tests => 4 };
use Parse::Syslog;
ok(1); # If we made it this far, we're ok.

#########################

my $parser = Parse::Syslog->new("t/locale-syslog", year=>2001, locale=>'de_DE');
open(PARSED, "<t/locale-parsed") or die "can't open t/locale-parsed: $!\n";
while(my $sl = $parser->next) {
	my $is = '';
	$is .= "time    : ".(localtime($sl->{timestamp}))."\n";
	$is .= "host    : $sl->{host}\n";
	$is .= "program : $sl->{program}\n";
	$is .= "pid     : ".(defined $sl->{pid} ? $sl->{pid} : 'undef')."\n";
	$is .= "text    : $sl->{text}\n";
	$is .= "\n";

	my $shouldbe = '';
	$shouldbe .= <PARSED>;
	$shouldbe .= <PARSED>;
	$shouldbe .= <PARSED>;
	$shouldbe .= <PARSED>;
	$shouldbe .= <PARSED>;
	$shouldbe .= <PARSED>;
	
	ok($is, $shouldbe);
}

# vim: set filetype=perl:
