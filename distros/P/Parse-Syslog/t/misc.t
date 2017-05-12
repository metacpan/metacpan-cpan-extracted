use Test;
use lib "lib";
BEGIN { plan tests => 4 };
use Parse::Syslog;
ok(1); # If we made it this far, we're ok.

#########################

my $parser = Parse::Syslog->new("t/misc-syslog", year=>2002);
open(PARSED, "<t/misc-parsed") or die "can't open t/misc-parsed: $!\n";
while(my $sl = $parser->next) {
	my $is = '';
	$is .= "time    : ".(localtime($sl->{timestamp}))."\n";
	$is .= "host    : $sl->{host}\n";
	$is .= "program : $sl->{program}\n";
	$is .= "pid     : ".(defined $sl->{pid} ? $sl->{pid} : 'undef')."\n";
	$is .= "text    : $sl->{text}\n";
	$is .= "\n";
	print "$is";

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
