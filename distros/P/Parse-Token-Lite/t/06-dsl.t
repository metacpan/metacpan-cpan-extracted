use strict;
use warnings;
use lib qw(./lib ../lib);
use Test::More; # tests => 22;                      # last test to print
use Parse::Token::Lite;
use Parse::Token::Lite::Builder;
use Data::Printer;
use Data::Dumper;

my $ruleset = ruleset{
	match qr/123/ => sub{
		name 'BEGIN';
		start 'TEST';
	};

	on 'TEST' => sub{
		match qr/567/ => sub{
			name 'END';
			end 'TEST';
		};

		match qr/./ => sub{
			name 'NUM';
		};
	};
};
print Dumper $ruleset;
my $p = Parse::Token::Lite->new(rulemap=>$ruleset);

my @tokens = $p->parse("1234567");
my $names = join(',', map{$_->[0]->rule->name}@tokens);
is($names,'BEGIN,NUM,END');

done_testing;
