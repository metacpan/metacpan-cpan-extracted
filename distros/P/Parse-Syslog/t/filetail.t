use Test;
use lib "lib";
BEGIN {
	# only test if File::Tail is installed
	eval 'require File::Tail;' or do {
		plan tests => 0;
		exit;
	};
	plan tests => 2;
};

use File::Tail;
use Parse::Syslog;
ok(1); # If we made it this far, we're ok.

my $ft = File::Tail->new(name=>'t/linux-syslog', tail=>-1);
my $parser = Parse::Syslog->new($ft, year=>2001);

open(PARSED, "<t/linux-parsed") or die "can't open t/linux-parsed: $!\n";

# read only one syslog line
$sl = $parser->next;
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

# vim: set filetype=perl:
