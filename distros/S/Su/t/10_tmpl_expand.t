use Test::More tests => 29;

use lib qw(lib ../lib);
use Su::Template;

#$Su::Template::DEBUG=1;

my $ret = Su::Template::expand(<<'__HERE__');
hoge
__HERE__
##
is( $ret, "hoge\n" );

$ret = Su::Template::expand(<<'__HERE__');
% my $val = "value1";
hoge <%= $val%>
__HERE__
##
is( $ret, "hoge value1\n" );

$ret = Su::Template::expand(<<'__HERE__');
<% foreach my $v ("aa","bb","cc"){~%>
<%= $v%>
<%}~%>
xxx
yyy
zzz
__HERE__

##
is( $ret, "aa\nbb\ncc\nxxx\nyyy\nzzz\n" );

$ret = Su::Template::expand(<<'__HERE__');
<% foreach my $v ('aa','bb','cc'){~%>
<%= $v%>
<%}~%>
xxx
yyy
zzz
__HERE__

##
is( $ret, "aa\nbb\ncc\nxxx\nyyy\nzzz\n" );

$ret = Su::Template::expand(<<'__HERE__');
<%
my $vala= "a";
my $valb= "b";
%>
<%= $vala . $valb ~%>
__HERE__
##
is( $ret, "ab" );

$ret = Su::Template::expand(<<'__HERE__');
% my $val_a = "aaa";
% my $val_b = "bbb";
x <%= $val_a%> y <%= $val_b ~%> z
__HERE__
##
is( $ret, "x aaa y bbb z" );
$Su::Template::DEBUG = 0;

$ret = Su::Template::expand( <<'__HERE__', "arg" );
<%
my $val= shift;
%>
<%= $val~%>
__HERE__
##
is( $ret, "arg" );

my $t = Su::Template->new;

##
isa_ok( $t, 'Su::Template' );

##
can_ok( $t, 'expand' );

$ret = $t->expand(<<'__HERE__');
hoge
__HERE__
## Object type usage.
is( $ret, "hoge\n" );

#$Su::Template::DEBUG=1;
$ret = $t->expand("foo bar");
##
is( $ret, "foo bar" );

$ret = $t->expand("foo\nbar");
##
is( $ret, "foo\nbar" );

TODO: {
  local $TODO =
    "added return char to single line string is current limitation.";
  $ret = Su::Template::expand("hoge");
##
  is( $ret, "hoge" );
} ## end TODO:

$t = Su::Template->new;

$ret = $t->expand(<<'__HERE__');
aa<%
__HERE__

is(
  $ret, 'aa<%
'
);

# Test for escape.
$ret = $t->expand( <<'__HERE__', "aa<bb>cc'dd\"ee&ff" );
% my $arg = shift;
<%= $arg ~%>
__HERE__
##
is( $ret, "aa&lt;bb&gt;cc&apos;dd&quot;ee&amp;ff" );

# Test for not escape.
$ret = $t->expand( <<'__HERE__', "aa<bb>cc'dd\"ee&ff" );
% my $arg = shift;
<%== $arg ~%>
__HERE__
##
is( $ret, "aa<bb>cc'dd\"ee&ff" );

$ret = $t->expand("aaa'bbb");
##
is( $ret, "aaa'bbb" );

$ret = $t->expand("aaa<%= 'xx'%>bbb");
##
is( $ret, "aaaxxbbb" );

$ret = Su::Template::expand(<<'__HERE__');
% my $val = "sss";
hoge
proc=>'<%="$val"~%>',

__HERE__
##
is(
  $ret, "hoge
proc=>'sss',
"
);

$ret = $t->expand("<>");
##
is( $ret, "<>" );

$ret = $t->expand(<<'__HERE__');
<>
__HERE__
##
is( $ret, "<>\n" );

$ret = $t->expand(<<'__HERE__');
&
__HERE__

is(
  $ret, "&
"
);

$ret = $t->expand(<<'__HERE__');
% my $val = "&";
<%=$val~%>
__HERE__

is( $ret, "&amp;" );

$ret = $t->expand(<<'__HERE__');
% my $val = "&amp;";
<%=$val~%>
__HERE__

is( $ret, "&amp;" );

$ret = $t->expand(<<'__HERE__');
% my $val = "&gt;aaa&bbb&lt;";
<%=$val~%>
__HERE__

is( $ret, "&gt;aaa&amp;bbb&lt;" );

$ret = $t->expand('<%= 0 %>');
is( $ret, "0" );

$ret = $t->expand('<%= "" %>');
is( $ret, "" );

$ret = $t->expand('<%== 0 %>');
is( $ret, "0" );

$ret = $t->expand('<%== "" %>');
is( $ret, "" );
