use strict;
use warnings;
use lib qw(./lib);
use Test::More  tests => 11;                      # last test to print
use Data::Printer;

BEGIN{
	use_ok("Parse::Token::Lite");
}


my $rulemap = {
    MAIN=>[
    {name=>'WORLD', re=>qr/world/},
	{name=>'CHR', re=>qr/./},
    ]
};

my $lexer = Parse::Token::Lite->new(rulemap=>$rulemap);
eval{ 
	$lexer->from("hello world");
};

fail('Check Implemented') if $@;

my @r;

@r = $lexer->nextToken;
is ($r[0]->rule->name, 'CHR');
is ($r[0]->data, 'h');

@r = $lexer->nextToken;
is ($r[0]->data, 'e');

@r = $lexer->nextToken;
is ($r[0]->data, 'l');

@r = $lexer->nextToken;
is ($r[0]->data, 'l');

@r = $lexer->nextToken;
is ($r[0]->data, 'o');

@r = $lexer->nextToken;
is ($r[0]->data, ' ');

@r = $lexer->nextToken;
is ($r[0]->rule->name, 'WORLD');
is ($r[0]->data, 'world');

is $lexer->eof,1,'check EOF';

done_testing;
