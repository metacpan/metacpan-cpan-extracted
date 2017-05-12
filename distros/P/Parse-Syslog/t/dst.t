use lib 'lib';
use Parse::Syslog;
use Test;
use POSIX;
use Time::Local;

BEGIN {
	# only test if IO::Scalar is available
	eval 'require IO::Scalar;' or do {
		plan tests => 0;
		warn "IO::Scalar not available: test skipped.\n";
		exit;
	};
	if($Time::Local::VERSION lt '1.07_94') {
		warn "Time::Local too old for DST-switch code to work (is: $Time::Local::VERSION, must be: 1.07_94)";
		plan test => 0;
		exit;
	}

	plan tests => 20
};

$ENV{TZ} = 'CET-1CEST-2,M3.5.0/02:00:00,M10.5.0/03:00:00';
POSIX::tzset();

my $data = <<END;
Oct 30 01:40:00 ivr3 bla: bla
Oct 30 02:00:00 ivr3 bla: bla
Oct 30 02:20:00 ivr3 bla: bla
Oct 30 02:40:00 ivr3 bla: bla
Oct 30 02:59:58 ivr3 bla: bla
Oct 30 02:00:00 ivr3 bla: bla
Oct 30 02:20:00 ivr3 bla: bla
Oct 30 02:40:00 ivr3 bla: bla
Oct 30 03:00:00 ivr3 bla: bla
Oct 30 03:20:00 ivr3 bla: bla
END

my $file = IO::Scalar->new(\$data);

my $parser = Parse::Syslog->new($file, year=>2005);

my $result = <<END;
Sun Oct 30 01:40:00 2005
Sun Oct 30 02:00:00 2005
Sun Oct 30 02:20:00 2005
Sun Oct 30 02:40:00 2005
Sun Oct 30 02:59:58 2005
Sun Oct 30 02:00:00 2005
Sun Oct 30 02:20:00 2005
Sun Oct 30 02:40:00 2005
Sun Oct 30 03:00:00 2005
Sun Oct 30 03:20:00 2005
END
my @result = split(/\n/, $result);

my $last_t=0;
while(my $sl = $parser->next) {
	# check that we get the correct localtime where a timewarp is noticeable
	# but always an increasing timestamp
	my $lt = localtime($sl->{timestamp});
	ok($lt, shift @result);
	ok($sl->{timestamp} > $last_t);
	$last_t = $sl->{timestamp};
}

# vim: ft=perl
