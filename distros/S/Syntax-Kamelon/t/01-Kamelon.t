use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Syntax::Kamelon') };


my $kam = Syntax::Kamelon->new(
);

ok(defined $kam, 'Creation');

my @syntaxes = $kam->AvailableSyntaxes;

for (@syntaxes) {
	my $lexer = $kam->GetLexer($_);
	ok(((defined $lexer) and ($lexer =~ /^HASH\(/)), "syntax: $_");
}

my $tests = @syntaxes + 2;

done_testing($tests)
