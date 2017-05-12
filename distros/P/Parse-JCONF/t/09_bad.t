use strict;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

my $parser = Parse::JCONF->new();
my $res = $parser->parse_file('t/files/00_fake.t');
is($res, undef, "file not exists");
isa_ok($parser->last_error, 'Parse::JCONF::Error::IO');

for ('01', '02', '03', '04', '05', '06', '07') {
	$res = $parser->parse("t/files/bad_$_.t");
	is($res, undef, "can't parse bad file bad_$_.t");
	isa_ok($parser->last_error, 'Parse::JCONF::Error::Parser');
}

done_testing;
