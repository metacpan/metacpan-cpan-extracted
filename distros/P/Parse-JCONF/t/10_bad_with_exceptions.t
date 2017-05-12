use strict;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

my $parser = Parse::JCONF->new(autodie => 1);
eval {
	$parser->parse_file('t/files/00_fake.t');
};
isa_ok($@, 'Parse::JCONF::Error::IO');

for ('01', '02', '03', '04', '05', '06', '07') {
	eval {
		$parser->parse("t/files/bad_$_.t");
	};
	isa_ok($@, 'Parse::JCONF::Error::Parser');
}

done_testing;
