use strict;
use warnings;

use Test::More tests => 4;
use Test::Warn;
use Syntax::Highlight::Engine::Kate;

my $hl = new Syntax::Highlight::Engine::Kate();

is($hl->languagePlug( 'HTML'), 'HTML', 'Standard "HTML" should work');

subtest html => sub { 
	plan tests => 2;
	my $lang;
	warning_is { $lang = $hl->languagePlug( 'html') } q{undefined language: 'html'}, 'warn';
	is($lang, undef, 'Standard "html" should not work');
};

is($hl->languagePlug( 'HTML', 1), 'HTML', 'Insesitive "HTML" should work');

subtest html_1 => sub {
	plan tests => 2;
	my $lang;
	warning_is { $lang = $hl->languagePlug( 'html', 1) } 'substituting language HTML for html', 'warn';
	is($lang, 'HTML', 'Insesitive "html" should work');
};

