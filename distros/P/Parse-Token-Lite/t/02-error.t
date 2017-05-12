use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 2;                      # last test to print
use Data::Printer;

BEGIN{
	use_ok("Parse::Token::Lite");
}


my $rules = {
	MAIN=>[{name=>'WORLD',re=>qr/world/}],
};

my $lexer = Parse::Token::Lite->new(rulemap=>$rules);
eval{ 
	$lexer->from("hello world");
};

fail('Check Implemented') if $@;

my @r;

eval{
@r = $lexer->nextToken;
};
ok ($@);

done_testing;
