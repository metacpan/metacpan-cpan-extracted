use Test;
use lib "lib";
BEGIN { plan tests => 18 };
use Parse::Syslog;
ok(1); # If we made it this far, we're ok.

#########################

my $parser = Parse::Syslog->new("t/yearchange-syslog", year=>2001);
open(PARSED, "<t/yearchange-parsed") or die "can't open t/yearchange-parsed: $!\n";
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
