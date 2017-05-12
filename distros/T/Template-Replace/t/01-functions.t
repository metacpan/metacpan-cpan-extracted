#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';

use Template::Replace;
use FindBin;

use Data::Dumper;

#
# Prepare data directory ...
#
my $data_dir = "$FindBin::Bin/data";                       # construct path
$data_dir = $1 if $data_dir =~ m#^((?:/(?!\.\./)[^/]+)+)#; # un-taint
mkdir $data_dir unless -e $data_dir;                       # create if missing

#
# Cleanup beforehand ... no need for it so far!
#


#
# Let's have some prerequisites ...
#
my $teststr = <<EOS
This is a test-string that contains some special
characters, i.e. <tag attr="value">, &, 'string',
http://test.domain/Tag und Nacht?a=RödelDödel&b=don't know#hash
EOS
;

#
# Test filter functions with UTF-8 ...
#
is(
    Template::Replace::_filter_none($teststr),
    $teststr,
    '_filter_none with $teststr'
);
is(
    Template::Replace::_filter_xml($teststr),
<<EOS
This is a test-string that contains some special
characters, i.e. &lt;tag attr=&quot;value&quot;&gt;, &amp;, &apos;string&apos;,
http://test.domain/Tag und Nacht?a=RödelDödel&amp;b=don&apos;t know#hash
EOS
,
    '_filter_xml with $teststr'
);
is(
    Template::Replace::_filter_uri($teststr),
    'This%20is%20a%20test-string%20that%20contains%20some%20special%0Acharacters%2C%20i.e.%20%3Ctag%20attr%3D%22value%22%3E%2C%20%26%2C%20\'string\'%2C%0Ahttp%3A%2F%2Ftest.domain%2FTag%20und%20Nacht%3Fa%3DR%C3%B6delD%C3%B6del%26b%3Ddon\'t%20know%23hash%0A',
    '_filter_uri with $teststr'
);
is(
    Template::Replace::_filter_url($teststr),
    'This%20is%20a%20test-string%20that%20contains%20some%20special%0Acharacters,%20i.e.%20%3Ctag%20attr=%22value%22%3E,%20&,%20\'string\',%0Ahttp://test.domain/Tag%20und%20Nacht?a=R%C3%B6delD%C3%B6del&b=don\'t%20know%23hash%0A',
    '_filter_url with $teststr'
);






is(
    Template::Replace::_filter_none("RödelDödel"),
    "RödelDödel",
    '_filter_none with umlauts, not necessarily utf-8'
);
is(
    Template::Replace::_filter_none("„Anführungszeichen“"),
    "„Anführungszeichen“",
    '_filter_none with german quotation marks, this is utf-8'
);

is(
    Template::Replace::_filter_xml("RödelDödel"),
    "RödelDödel",
    '_filter_xml with umlauts, not necessarily utf-8'
);
is(
    Template::Replace::_filter_xml("„Anführungszeichen“"),
    "„Anführungszeichen“",
    '_filter_xml with german quotation marks, this is utf-8'
);

is(
    Template::Replace::_filter_uri("RödelDödel"),
    'R%C3%B6delD%C3%B6del',
    '_filter_uri with umlauts, not necessarily utf-8'
);
is(
    Template::Replace::_filter_uri("„Anführungszeichen“"),
    '%E2%80%9EAnf%C3%BChrungszeichen%E2%80%9C',
    '_filter_uri with german quotation marks, this is utf-8'
);

is(
    Template::Replace::_filter_url("RödelDödel"),
    'R%C3%B6delD%C3%B6del',
    '_filter_uri with umlauts, not necessarily utf-8'
);
is(
    Template::Replace::_filter_url("„Anführungszeichen“"),
    '%E2%80%9EAnf%C3%BChrungszeichen%E2%80%9C',
    '_filter_uri with german quotation marks, this is utf-8'
);



#
# Cleanup ... no need for it so far!
#

