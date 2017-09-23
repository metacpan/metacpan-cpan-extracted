use strict;
use warnings;
use Test::More tests => 3;
use Syntax::Highlight::Engine::Simple;
use utf8;
binmode(STDIN,	":utf8");
binmode(STDOUT,	":utf8");
binmode(STDERR,	":utf8");

my $highlighter = Syntax::Highlight::Engine::Simple->new();
my $expected = '';
my $result = '';

### ----------------------------------------------------------------------------
### 1. Illigal overlap
### ----------------------------------------------------------------------------
$highlighter->setSyntax(
	syntax => [
		{
			class => 'a',
			regexp => "'.+?'",
		}, 
		{
			class => 'b',
			regexp => '".+?"',
			container => 'a',
		}, 
		{
			class => 'c',
			regexp => "!.+?!",
		}, 
	]
);

is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' );
'"b" !c'c!
ORIGINAL
<span class='a'>'<span class='b'>"b"</span> !c'</span>c!
EXPECTED

### ----------------------------------------------------------------------------
### 2. Multi container definition
### ----------------------------------------------------------------------------
$highlighter->setSyntax(
	syntax => [
		{
			class => 'a',
			regexp => "'.+?'",
		}, 
		{
			class => 'b',
			regexp => '".+?"',
		}, 
		{
			class => 'c',
			regexp => "!.+?!",
			container => ['a', 'b'],
		}, 
	]
);

is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' );
'aaa!c!aaa'
"bbb!c!bbb"
ORIGINAL
<span class='a'>'aaa<span class='c'>!c!</span>aaa'</span>
<span class='b'>"bbb<span class='c'>!c!</span>bbb"</span>
EXPECTED

### ----------------------------------------------------------------------------
### 3. Make sure the close anticipates open at the same position
### ----------------------------------------------------------------------------
$highlighter->setSyntax(
	syntax => [
		{
			class => 'a',
			regexp => "a",
		}, 
		{
			class => 'b',
			regexp => '".+?"',
		}, 
	]
);

is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' );
a"b"
ORIGINAL
<span class='a'>a</span><span class='b'>"b"</span>
EXPECTED
