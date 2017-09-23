use strict;
use warnings;
use Test::More tests => 11;
use Syntax::Highlight::Engine::Simple;
use utf8;
binmode(STDIN,	":utf8");
binmode(STDOUT,	":utf8");
binmode(STDERR,	":utf8");

my $highlighter = Syntax::Highlight::Engine::Simple->new();
my $expected = '';
my $result = '';

### ----------------------------------------------------------------------------
### 1. Define syntax
### ----------------------------------------------------------------------------
$highlighter->setSyntax(
	syntax => [
		{
			class => 'quote',
			regexp => q@'.*?(?<!\\\\)'@,
		}, 
		{
			class => 'comment',
			regexp => '(?m)#+.*?$',
		}, 
	]
);

is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' ); #01
# comment
'inside' out
"inside" out
ORIGINAL
<span class='comment'># comment</span>
<span class='quote'>'inside'</span> out
"inside" out
EXPECTED

### ----------------------------------------------------------------------------
### 2. Append syntax
### ----------------------------------------------------------------------------
$highlighter->appendSyntax(
	syntax => {
		class => 'wquote',
		regexp => q@".*?(?<!\\\\)"@,
	}, 
);

$result = $highlighter->doStr(str => <<'ORIGINAL');
# comment
'inside' out
"inside" out
ORIGINAL

is( $result, $expected=<<'EXPECTED' ); #02
<span class='comment'># comment</span>
<span class='quote'>'inside'</span> out
<span class='wquote'>"inside"</span> out
EXPECTED

### ----------------------------------------------------------------------------
### 3. Keyword difinision with Array
### ----------------------------------------------------------------------------
$highlighter->appendSyntax(
	syntax => {
		class => 'statement',
		regexp => $highlighter->array2regexp(qw(if else return)),
	}, 
);

$result = $highlighter->doStr(str => <<'ORIGINAL');
if (1){
	return 1;
} else {
	return 2;
}
ORIGINAL

is( $result, $expected=<<'EXPECTED' ); #03
<span class='statement'>if</span> (1){
	<span class='statement'>return</span> 1;
} <span class='statement'>else</span> {
	<span class='statement'>return</span> 2;
}
EXPECTED

### ----------------------------------------------------------------------------
### 4. Convert tab to spaces
### ----------------------------------------------------------------------------
$result = $highlighter->doStr(str => <<'ORIGINAL', tab_width => 4);
if (1){
	return 1;
} else {
	return 2;
}
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
<span class='statement'>if</span> (1){
    <span class='statement'>return</span> 1;
} <span class='statement'>else</span> {
    <span class='statement'>return</span> 2;
}
EXPECTED

### ----------------------------------------------------------------------------
### 5. Multi byte(Japanese test bellow)
### ----------------------------------------------------------------------------
$result = $highlighter->doStr(str => <<'ORIGINAL', tab_width => 4);
	あいうえお"かきくけこ"さしすせそ'たちつてと'
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
    あいうえお<span class='wquote'>"かきくけこ"</span>さしすせそ<span class='quote'>'たちつてと'</span>
EXPECTED

### ----------------------------------------------------------------------------
### 6. Priority control
### ----------------------------------------------------------------------------
$highlighter = Syntax::Highlight::Engine::Simple->new();
$highlighter->setSyntax(
	syntax => [
		{
			class => 'a',
			regexp => 'test',
		}, 
		{
			class => 'b',
			regexp => 'test',
		}, 
	]
);

$result = $highlighter->doStr(str => <<'ORIGINAL');
test
test2
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
<span class='a'>test</span>
<span class='a'>test</span>2
EXPECTED

### ----------------------------------------------------------------------------
### 7. Embracement Allowance
### ----------------------------------------------------------------------------
$highlighter->appendSyntax(
	syntax => {
		class => 'c',
		regexp => 'test',
		container => 'a',
	}, 
);

$result = $highlighter->doStr(str => <<'ORIGINAL');
test
test2
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
<span class='a'><span class='c'>test</span></span>
<span class='a'><span class='c'>test</span></span>2
EXPECTED

### ----------------------------------------------------------------------------
### 8. Embracement Allowance
### ----------------------------------------------------------------------------
$highlighter->appendSyntax(
	syntax => {
		class => 'd',
		regexp => 'tes',
		container => 'a',
	}, 
);

$result = $highlighter->doStr(str => <<'ORIGINAL');
test
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
<span class='a'><span class='c'>test</span></span>
EXPECTED

### ----------------------------------------------------------------------------
### 9. doFile with Sub Class also include multi byte Charactors
### ----------------------------------------------------------------------------
$result =
	$highlighter->doFile(file => './t/testfile/2original.txt', tab_width => 4);
is( $result, '漢字');

### ----------------------------------------------------------------------------
### 10. doFile with Sub Class also include multi byte Charactors
### ----------------------------------------------------------------------------
$result =
	$highlighter->doFile(file => './t/testfile/3original.txt', tab_width => 4, encode => 'euc-jp');
is( $result, '漢字');


### ----------------------------------------------------------------------------
### 10. doFile with Sub Class also include multi byte Charactors
### ----------------------------------------------------------------------------
$result =
	$highlighter->doFile(file => './t/testfile/4original.txt', tab_width => 4, encode => 'sjis');
is( $result, '漢字');

