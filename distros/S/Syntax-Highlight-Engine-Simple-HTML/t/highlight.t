use strict;
use warnings;
use Test::More tests => 3;
use Syntax::Highlight::Engine::Simple::HTML;
use encoding 'utf8';
binmode(STDIN,	":utf8");
binmode(STDOUT,	":utf8");
binmode(STDERR,	":utf8");

my $highlighter = Syntax::Highlight::Engine::Simple::HTML->new();
my $expected = '';
my $result = '';

### ----------------------------------------------------------------------------
### 1. Define syntax
### ----------------------------------------------------------------------------
is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' ); #01
<div class='test'>target string</div>
ORIGINAL
&lt;<span class='tag'>div class=<span class='quote'>'test'</span></span>&gt;target string&lt;<span class='tag'>/div</span>&gt;
EXPECTED

### ----------------------------------------------------------------------------
### 2. Append syntax
### ----------------------------------------------------------------------------
$highlighter->appendSyntax(
	syntax => {
		class => 'addition',
		regexp => 'target',
	}, 
);

is( $highlighter->doStr(str => <<'ORIGINAL'), $expected=<<'EXPECTED' ); #01
<div class='test'>target string</div>
ORIGINAL
&lt;<span class='tag'>div class=<span class='quote'>'test'</span></span>&gt;<span class='addition'>target</span> string&lt;<span class='tag'>/div</span>&gt;
EXPECTED

### ----------------------------------------------------------------------------
### 3. Complicate
### ----------------------------------------------------------------------------
$result = $highlighter->doStr(str => <<'ORIGINAL', tab_width => 4);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
<title>title</title>
<link href="/css/itpro/2008/common.css" rel="stylesheet" type="text/css">
<script type='text/javascript'>
<!--
var a = 'a';
//-->
</script>
</head>
<body>
"double quote out of tag"
keyword out of tag
<HtML><!-- case ignore test -->
test
</body>
</html>
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
&lt;<span class='tag'>!DOCTYPE HTML PUBLIC <span class='wquote'>"-//W3C//DTD HTML 4.01 Transitional//EN"</span>
<span class='wquote'>"http://www.w3.org/TR/html4/loose.dtd"</span></span>&gt;
&lt;<span class='tag'>html lang=<span class='wquote'>"ja"</span></span>&gt;
&lt;<span class='tag'>head</span>&gt;
&lt;<span class='tag'>meta http-equiv=<span class='wquote'>"Content-Type"</span> content=<span class='wquote'>"text/html; charset=EUC-JP"</span></span>&gt;
&lt;<span class='tag'>title</span>&gt;title&lt;<span class='tag'>/title</span>&gt;
&lt;<span class='tag'>link href=<span class='wquote'>"/css/itpro/2008/common.css"</span> rel=<span class='wquote'>"stylesheet"</span> type=<span class='wquote'>"text/css"</span></span>&gt;
&lt;<span class='tag'>script type=<span class='quote'>'text/javascript'</span></span>&gt;
<span class='comment'>&lt;!--
var a = 'a';
//--&gt;</span>
&lt;<span class='tag'>/script</span>&gt;
&lt;<span class='tag'>/head</span>&gt;
&lt;<span class='tag'>body</span>&gt;
"double quote out of tag"
keyword out of tag
&lt;<span class='tag'>HtML</span>&gt;<span class='comment'>&lt;!-- case ignore test --&gt;</span>
test
&lt;<span class='tag'>/body</span>&gt;
&lt;<span class='tag'>/html</span>&gt;
EXPECTED
