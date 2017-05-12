use Test;
use lib "lib";
BEGIN {
	# only test if IO::Scalar is available
	eval 'require IO::Scalar;' or do {
		plan tests => 0;
		warn "IO::Scalar not available: test skipped.\n";
		exit;
	};
	
	plan tests => 2
};

use Parse::Syslog;
use IO::Scalar;

my $data = <<END;
Aug 12 06:55:06 hathi [LOG_NOTICE] sshd[1966]: error
END

my $file = IO::Scalar->new(\$data);

my $parser = Parse::Syslog->new($file, year=>2001);

ok(1);

$sl = $parser->next;

my $is = '';
$is .= "time    : ".(localtime($sl->{timestamp}))."\n";
$is .= "host    : $sl->{host}\n";
$is .= "program : $sl->{program}\n";
$is .= "pid     : ".(defined $sl->{pid} ? $sl->{pid} : 'undef')."\n";
$is .= "text    : $sl->{text}\n";
#print "$is";

my $shouldbe = <<END;
time    : Sun Aug 12 06:55:06 2001
host    : hathi
program : sshd
pid     : 1966
text    : error
END

ok($is, $shouldbe);

# vim: ft=perl

