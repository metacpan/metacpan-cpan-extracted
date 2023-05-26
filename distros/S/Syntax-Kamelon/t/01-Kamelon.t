use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Syntax::Kamelon') };


my $kam = Syntax::Kamelon->new(
#.	verbose => 1,
);

ok(defined $kam, 'Creation');
my $syntax = $kam->SuggestSyntax('index.html');
ok($syntax eq 'HTML', 'SuggestSyntax');

my @syntaxes = $kam->AvailableSyntaxes;

for (@syntaxes) {
	my $lexer = $kam->GetLexer($_);
	ok(((defined $lexer) and ($lexer =~ /^HASH\(/)), "syntax: $_");
}

my $tests = @syntaxes + 3;

done_testing($tests)
