#!/usr/bin/perl -w

use strict;

use Test::More skip_all => 'disabled'; #tests => 15;
__END__
BEGIN
{
  use_ok('Rose::HTML::Object');
  # Base classes?
  #use_ok('Rose::HTML::Object::Attachment::URI');
  #use_ok('Rose::HTML::Object::Attachment::Text');
  use_ok('Rose::HTML::Object::Attachment::JavaScript');
  #Rose::HTML::Object::Attachment::JavaScript::URI
  #Rose::HTML::Object::Attachment::JavaScript::Text
  use_ok('Rose::HTML::Object::Attachment::CSS');
  #Rose::HTML::Object::Attachment::CSS::URI
  #Rose::HTML::Object::Attachment::CSS::Text
}

my $o = Rose::HTML::Object->new;

$o->attach(name => 'js', uri  => '/foo/bar.js');
$o->attach(name => 'js', uri  => '/bar/baz.js');

is_deeply([ map { "$_" } $o->attachments('js') ], 
          [ '/foo/bar.js', '/bar/baz.js' ],
          'attach 1');

$o->attach(name => 'js', uri  => '/blee.js', position => 'first');

is_deeply([ map { "$_" } $o->attachments('js') ], 
          [ '/blee.js', '/foo/bar.js', '/bar/baz.js' ],
          'attach 2');

$o->attach(name => 'js', uri  => '/blah.js', position => 'last');

is_deeply([ map { "$_" } $o->attachments('js') ], 
          [ '/blee.js', '/foo/bar.js', '/bar/baz.js', '/blah.js' ],
          'attach 3');

$o->attach(name => 'js', uri  => '/middle.js', after => '/bar/baz.js');

is_deeply([ map { "$_" } $o->attachments('js') ], 
          [ '/blee.js', '/foo/bar.js', '/bar/baz.js', '/middle.js', '/blah.js' ],
          'attach 4');

$o->attach(name => 'js', uri  => '/m2.js', before => '/bar/baz.js');

is_deeply([ map { "$_" } $o->attachments('js') ], 
          [ '/blee.js', '/foo/bar.js', '/m2.js', '/bar/baz.js', '/middle.js', '/blah.js' ],
          'attach 5');

ok(ref $o->delete_attachment(name => 'js', uri => '/foo/bar.js') eq 
   'Rose::HTML::Object::Attachment::JavaScript', 'delete_attachment 1');

ok(!defined $o->delete_attachment(name => 'js', uri => 'nonesuch'), 'delete_attachment 2');

$o->delete_attachments('js');

is_deeply([ $o->attachments('js') ], [ ], 'delete_attachments 1');

$o->attach(name => 'js', uri => 'foo.js');

is_deeply([ map { $_->id } $o->attachments('js') ], [ 'foo.js' ], 'delete_attachments 1');

# Attach same thing twice
$o->attach(name => 'js', Rose::HTML::Object::Attachment::JavaScript->new(uri => 'bar.js'));
$o->attach(name => 'js', uri => 'bar.js');

is_deeply([ map { $_->id } $o->attachments('js') ], [ 'foo.js', 'bar.js' ], 'attach 6');

#
# JavaScript attachments
#

# URI

my $js = Rose::HTML::Object::Attachment::JavaScript->new(uri => '/blee.js');

is($js->uri, '/blee.js', 'js uri');
is($js->mime_type, 'text/javascript', 'js mime type');

is($js->html, '<script src="/blee.js" type="text/javascript"></script>', 'js uri html 1');
is($js->xhtml, '<script src="/blee.js" type="text/javascript" />', 'js uri xhtml 1');

is($js->html_script, '<script src="/blee.js" type="text/javascript"></script>', 'js uri html script 2');
is($js->xhtml_script, '<script src="/blee.js" type="text/javascript" />', 'js uri xhtml script 2');

my $s = $js->html_script_object;
is($s, 'Rose::HTML::Script', 'html_object');

$s = $js->xhtml_script_object;
is($s, 'Rose::HTML::Script', 'xhtml_object');

is($s->html, '<script src="/blee.js" type="text/javascript"></script>', 'js uri html 2');
is($s->xhtml, '<script src="/blee.js" type="text/javascript" />', 'js uri html 2');

# Script

$js = Rose::HTML::Object::Attachment::JavaScript->new(script => 'function foo() { return 123; }');

is($js->script, 'function foo() { return 123; }', 'js script');
is($js->text, 'function foo() { return 123; }', 'js text');

is($js->html, <<'EOF', 'js script html 1');
<script type="text/javascript">
<!--
function foo() { return 123; }
// -->
</script>
EOF

is($js->html_script, <<'EOF', 'js script html 2');
<script type="text/javascript">
<!--
function foo() { return 123; }
// -->
</script>
EOF

is($js->xhtml, <<'EOF', 'js script xhtml 1');
<script type="text/javascript"><!--//--><![CDATA[//><!--
function foo() { return 123; }
//--><!]]></script>
EOF


is($js->xhtml_script, <<'EOF', 'js script xhtml 2');
<script type="text/javascript"><!--//--><![CDATA[//><!--
function foo() { return 123; }
//--><!]]></script>
EOF

$js->support_older_browsers(0);

is($js->xhtml, <<'EOF', 'js script xhtml 3');
<script type="text/javascript">
//<![CDATA[
function foo() { return 123; }
//]]>
</script>
EOF

is($js->xhtml_script, <<'EOF', 'js script xhtml 4');
<script type="text/javascript">
//<![CDATA[
function foo() { return 123; }
//]]>
</script>
EOF

#
# CSS attachments
#

# URI

my $css = Rose::HTML::Object::Attachment::CSS->new(uri => 'main.css');

is($css->uri, 'main.css', 'css uri');
is($css->mime_type, 'text/css', 'css mime type');

is($css->html, '<link href="main.css" rel="stylesheet" type="text/css"></link>', 'css uri html 1');
is($css->xhtml, '<link href="main.css" rel="stylesheet" type="text/css" />', 'css uri xhtml 1');

is($css->html_link, '<link href="main.css" rel="stylesheet" type="text/css"></link>', 'css uri html link 2');
is($css->xhtml_link, '<link href="main.css" rel="stylesheet" type="text/css" />', 'css uri xhtml link 2');

my $s = $css->html_link_object;
is($s, 'Rose::HTML::Script', 'html_object');

$s = $css->xhtml_link_object;
is($s, 'Rose::HTML::Script', 'xhtml_object');

is($s->html, '<link href="main.css" rel="stylesheet" type="text/css"></link>', 'css uri html 2');
is($s->xhtml, '<link href="main.css" rel="stylesheet" type="text/css" />', 'css uri html 2');

# Script

$css = Rose::HTML::Object::Attachment::CSS->new(text => 'body { color: black }');

is($css->style, 'body { color: black }', 'css style');
is($css->text, 'body { color: black }', 'css text');

is($css->html, <<'EOF', 'css script html 1');
<script type="text/css">
<!--
body { color: black }
-->
</script>
EOF

is($css->html_style, <<'EOF', 'css style html 2');
<style type="text/css">
<!--
body { color: black }
-->
</style>
EOF

is($css->xhtml, <<'EOF', 'css style xhtml 1');
<style type="text/css"><!--/*--><![CDATA[/*><!--*/
body { color: black }
/*]]>*/--></style>
EOF

is($css->xhtml_style, <<'EOF', 'css style xhtml 2');
<style type="text/css"><!--/*--><![CDATA[/*><!--*/
body { color: black }
/*]]>*/--></style>
EOF

$css->support_older_browsers(0);

is($css->xhtml, <<'EOF', 'css style xhtml 3');
<style type="text/css">
<![CDATA[
body { color: black }
]]>
</style>
EOF

is($css->xhtml_style, <<'EOF', 'css style xhtml 4');
<style type="text/css">
<![CDATA[
body { color: black }
]]>
</style>
EOF

#<link rel="stylesheet" type="text/css" href="/styles/coupon_admin.css" />
#is($css->html_link, '<link type="text/css"

#<style type="text/css">
#<!--
#        ...
#-->
#</style>


# http://hixie.ch/advocacy/xhtml
#
#<style type="text/css"><!--/*--><![CDATA[/*><!--*/
#        ...
#/*]]>*/--></style>
