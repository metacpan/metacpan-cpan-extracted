use strict;
use utf8;
use Test::More;
use Parse::JCONF;
use Parse::JCONF::Boolean qw(TRUE FALSE);

my $parser = Parse::JCONF->new();
my $res = $parser->parse_file('t/files/constants.jconf');
is_deeply($res, {
	false     => FALSE,
	not_false => TRUE,
	нуль      => undef
}, "parse constants");

done_testing;
