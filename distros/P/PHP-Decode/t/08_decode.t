# Tests: parser
#
# see: more parser tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More qw(no_plan);
use PHP::Decode;
use PHP::Decode::Test;

#plan tests => 721;

sub warn_msg {
	my ($action, $fmt) = (shift, shift);
	my $msg = sprintf $fmt, @_;
	print 'WARN: ', $action, ': ', $msg, "\n";
}


while (my ($desc, $script, $want) = splice(@PHP::Decode::Test::tests, 0, 3)) {
	next if ($desc =~ /^[A-Z]:/);

	my (%skip, %with);
	my $php = PHP::Decode->new(inscript => 1,
		skip => \%skip,
		with => \%with,
		warn => \&warn_msg);

	my $stmt = $php->eval($script);
	my $res = $php->format($stmt);
	is($res, $want, "decode $desc");
}

