use strict;
use warnings;
use utf8;
use Test::More;
use Perl6::PVIP;

my $parser = Perl6::PVIP->new();
my $ret = $parser->parse_string('3+');
is($ret, undef);
ok($parser->errstr);
note $parser->errstr();

done_testing;

