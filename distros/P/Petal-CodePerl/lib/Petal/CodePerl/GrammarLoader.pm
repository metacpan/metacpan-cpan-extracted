use strict;
use warnings;

my $CompiledGrammar = $ENV{CODEPERL_DEV} ? 0 : 1;

# handy for being able alter the grammar during development

my $parser;

if($CompiledGrammar)
{
	require Petal::CodePerl::Parser;
	$parser = Petal::CodePerl::Parser->new;
}
else
{
	require Parse::RecDescent;

	my $petales_grammar = do "grammar" || die "No grammar";

	local $Parse::RecDescent::skip = "";
	$::RD_HINT = 1;
	#$::RD_TRACE = 1;

	$parser = Parse::RecDescent->new($petales_grammar) || die "Parser didn't compile";
}

$Petal::CodePerl::Compiler::Parser = $parser;
