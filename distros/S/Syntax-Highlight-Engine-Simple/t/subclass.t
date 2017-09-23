use strict;
use warnings;
use Test::More tests => 3;
use Syntax::Highlight::Engine::Simple;

my $highlighter;
my $expected = '';
my $result = '';

### ----------------------------------------------------------------------------
### 1. Sub class
### ----------------------------------------------------------------------------
$highlighter = Syntax::Highlight::Engine::Simple::Perl->new();
$result = $highlighter->doStr(str => <<'ORIGINAL', tab_width => 4);
if (1){
	return 1;
} else {
	return 2;
}
ORIGINAL

is( $result, $expected=<<'EXPECTED' );
<span class='keyword'>if</span> (<span class='number'>1</span>){
    <span class='keyword'>return</span> <span class='number'>1</span>;
} <span class='keyword'>else</span> {
    <span class='keyword'>return</span> <span class='number'>2</span>;
}
EXPECTED

### ----------------------------------------------------------------------------
### 2. Sub class2
### ----------------------------------------------------------------------------
$highlighter = Syntax::Highlight::Engine::Simple::HTML->new();
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

### ----------------------------------------------------------------------------
### 3. doFile with Sub Class also include multi byte Charactors
### ----------------------------------------------------------------------------
$highlighter = Syntax::Highlight::Engine::Simple::Perl->new();

$result =
	$highlighter->doFile(file => './t/testfile/original.txt', tab_width => 4);

require 5.005;
open(my $filehandle, '<'. './t/testfile/expected.txt');
binmode($filehandle, ":encoding(utf8)");
$expected = join('', <$filehandle>);
is( $result, $expected );

### ----------------------------------------------------------------------------
### Sub Class for Perl Language
### ----------------------------------------------------------------------------
package Syntax::Highlight::Engine::Simple::Perl;
use strict;
use warnings;
use base qw(Syntax::Highlight::Engine::Simple);

sub setSyntax {
	
	shift->{syntax} =
		[
			{
				class => 'quote',
				regexp => '(?<!\w)qw\(.*?(?<!\\\\)\)',
			}, 
			{
				class => 'quote',
				regexp => '(?<!\w)q(\W).*?(?<!\\\\)\1',
			}, 
			{
				class => 'quote',
				regexp => q@'.*?(?<!\\\\)'@,
			}, 
			{
				class => 'wquote',
				regexp => '(?<!\w)qq(\W).*?(?<!\\\\)\1',
			}, 
			{
				class => 'wquote',
				regexp => q@".*?(?<!\\\\)"@,
			}, 
			{
				class => 'comment',
				regexp => '(?m)#+.*?$',
			}, 
			{
				class => 'variable',
				regexp => '[\$\@\%][\w\d:]+',
			}, 
			{
				class => 'function',
				regexp => '\&[\w\d:]+',
			}, 
			{
				class => 'method',
				regexp => '(?<=->)[\w\d:]+',
			},
			{
				class => 'number',
				regexp => '\b\d+\b',
			},	
			{
				class => 'keyword',
				regexp => __PACKAGE__->array2regexp(&getStatementKeywords()),
			}, 
			{
				class => 'keyword',
				regexp => __PACKAGE__->array2regexp(&getKeywords()),
			}, 
			{
				class => 'regexp_statement',
				regexp => '(?<=(?<![\w$&])(?:s|m|y))([^\w\d\s]).+?\1.+\1',
			}, 
			{
				class => 'regexp_statement',
				regexp => '(?<=(?<![\w$&])(?:tr))([^\w\d\s]).+?\1.+\1',
			}, 
			{
				class => 'regexp_statement',
				regexp => '/.+?/',
			}, 
			{
				class => 'perlpod',
				regexp => '(?sm)^=.+?(^=cut$)',
			}, 
			{
				class => 'keyword2',
				regexp => '(?m)^=.+$',
				container => 'perlpod',
			}, 
			{
				class => 'statement',
				regexp => '(?m)^=\w+',
				container => 'keyword2',
			}, 
		];
}

sub getStatementKeywords {
	
	return (
		'continue',
		'foreach',
		'require',
		'package',
		'scalar',
		'format',
		'unless',
		'local',
		'until',
		'while',
		'elsif',
		'next',
		'last',
		'goto',
		'else',
		'redo',
		'sub',
		'for',
		'use',
		'our',
		'no',
		'if',
		'my',
		'qr',
		'qx',
#		'qq',
#		'qw',
#		'tr',
#		'm',
#		'q',
#		's',
#		'y'
	);
}

sub getKeywords {
	
	return (
		'getprotobynumber',
		'getprotobyname',
		'gethostbyaddr',
		'gethostbyname',
		'getservbyname',
		'getservbyport',
		'getnetbyaddr',
		'getnetbyname',
		'endprotoent',
		'getpeername',
		'getpriority',
		'getprotoent',
		'getsockname',
		'setpriority',
		'setprotoent',
		'endhostent',
		'endservent',
		'gethostent',
		'getservent',
		'getsockopt',
		'sethostent',
		'setservent',
		'setsockopt',
		'socketpair',
		'endnetent',
		'getnetent',
		'localtime',
		'prototype',
		'quotemeta',
		'rewinddir',
		'setnetent',
		'wantarray',
		'closedir',
		'dbmclose',
		'endgrent',
		'endpwent',
		'formline',
		'getgrent',
		'getgrgid',
		'getgrnam',
		'getlogin',
		'getpwent',
		'getpwnam',
		'getpwuid',
		'readline',
		'readlink',
		'readpipe',
		'setgrent',
		'setpwent',
		'shmwrite',
		'shutdown',
		'syswrite',
		'truncate',
		'binmode',
		'connect',
		'dbmopen',
		'defined',
		'getpgrp',
		'getppid',
		'lcfirst',
		'opendir',
		'readdir',
		'reverse',
		'seekdir',
		'setpgrp',
		'shmread',
		'sprintf',
		'symlink',
		'syscall',
		'sysopen',
		'sysread',
		'sysseek',
		'telldir',
		'ucfirst',
		'unshift',
		'waitpid',
		'accept',
		'caller',
		'chroot',
		'delete',
		'exists',
		'fileno',
		'gmtime',
		'import',
		'length',
		'listen',
		'msgctl',
		'msgget',
		'msgrcv',
		'msgsnd',
		'printf',
		'rename',
		'return',
		'rindex',
		'select',
		'semctl',
		'semget',
		'shmctl',
		'shmget',
		'socket',
		'splice',
		'substr',
		'system',
		'unlink',
		'unpack',
		'values',
		'alarm',
		'atan2',
		'bless',
		'break',
		'chdir',
		'chmod',
		'chomp',
		'chown',
		'close',
		'crypt',
		'fcntl',
		'flock',
		'index',
		'ioctl',
		'lstat',
		'mkdir',
		'print',
		'reset',
		'rmdir',
		'semop',
		'shift',
		'sleep',
		'split',
		'srand',
		'study',
		'times',
		'umask',
		'undef',
		'untie',
		'utime',
		'write',
		'bind',
		'chop',
		'dump',
		'each',
		'eval',
		'exec',
		'exit',
		'fork',
		'getc',
		'glob',
		'grep',
		'join',
		'keys',
		'kill',
		'link',
		'open',
		'pack',
		'pipe',
		'push',
		'rand',
		'read',
		'recv',
		'seek',
		'send',
		'sort',
		'sqrt',
		'stat',
		'tell',
		'tied',
		'time',
		'wait',
		'warn',
		'abs',
		'chr',
		'cos',
		'die',
		'eof',
		'exp',
		'hex',
		'int',
		'log',
		'map',
		'oct',
		'ord',
		'pop',
		'pos',
		'ref',
		'sin',
		'tie',
		'do',
		'vec',
		'lc',
		'uc',
	);
}

### ----------------------------------------------------------------------------
### Sub Class for HTML Language
### ----------------------------------------------------------------------------
package Syntax::Highlight::Engine::Simple::HTML;
use strict;
use warnings;
use base qw(Syntax::Highlight::Engine::Simple);

sub setSyntax {
	
	shift->{syntax} =
		[
			{
				class => 'tag',
				regexp => q!(?s)(?<=<).+?(?=>)!,
			},
			{
				class => 'quote',
				regexp => q!(?s)'.*?'!,
				container => 'tag',
			},
			{
				class => 'wquote',
				regexp => q!(?s)".*?"!,
				container => 'tag',
			},
			{
				class => 'number',
				regexp => '\b\d+\b',
				container => 'tag',
			},	
			{
				class => 'comment',
				regexp => '(?s)<!--.*?-->',
			},
			{
				class => 'url',
				regexp => q!s?https?://[-_.\!~*'()a-zA-Z0-9;/?:@&=+$,%#]+!,
			},
		];
}
