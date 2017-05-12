#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    require "t/pod2html-lib.pl";
}

use strict;
use Cwd;
use File::Spec::Functions;
use Test::More tests => 1;

my $cwd = cwd();

TODO: {
    local $TODO = 'not implemented';
    convert_n_test("substlink", "substitute link", 
 "--backlink",
 "--css=style.css",
 "--header", # no styling b/c of --ccs
 "--htmldir=". catdir($cwd, 't'),
 "--noindex",
 "--podpath=t",
 "--podroot=$cwd",
 "--title=a title",
 "--quiet",
 );
}

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>a title</title>
<link rel="stylesheet" href="style.css" type="text/css" />
<meta http-equiv="content-type" content="text/html; charset=euc-jp" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body id="_podtop_">
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" valign="middle">
<big><strong><span class="_podblock_">&nbsp;a title</span></strong></big>
</td></tr>
</table>



<a href="#_podtop_"><h1 id="title">タイトル</h1></a>

<dl>

<dt id="item">アイテム</dt>
<dd>

</dd>
</dl>

<p><a href="#title">&quot;タイトル&quot;</a>, <a href="#item">&quot;アイテム&quot;</a>, <a>Foo::Bar</a></p>

<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" valign="middle">
<big><strong><span class="_podblock_">&nbsp;a title</span></strong></big>
</td></tr>
</table>

</body>

</html>


