use strict;
use Template;
use Test::Base;

plan tests => 1 * blocks;
filters { input => 'chomp', output => 'chomp' };

my $tt = Template->new;

run {
    my $block = shift;
    my $input = $block->input;
    $tt->process(\$input, {}, \my $out) or die $tt->error;
    is $out, $block->output, $block->name;
}

__END__

=== HTML without any scripting snipets
--- input
[% USE StripScripts -%]
[% FILTER stripscripts Context             => 'Document',
                       BanList             => ['br'],
                       AllowSrc            => 1,
                       AllowHref           => 1,
                       EscapeFiltered      => 0,
                       ParserOptions       => {
                           strict_names    => 1,
                           strict_comments => 1,
                       },
-%]
<html>
 <head>
  <title>script test page</title>
 </head>
 <body>
  foo
 </body>
</html>
[%- END %]
--- output
<html>
 <head>
  <title>script test page</title>
 </head>
 <body>
  foo
 </body>
</html>

=== HTML which can cause XSS
--- input
[% USE StripScripts -%]
[% FILTER stripscripts Context             => 'Document',
                       BanList             => ['br'],
                       AllowSrc            => 1,
                       AllowHref           => 1,
                       EscapeFiltered      => 0,
                       ParserOptions       => {
                           strict_names    => 1,
                           strict_comments => 1,
                       },
-%]
<html>
 <head>
  <title>script test page</title>
  <script>
   this.is.javascript.and("<this> isn't a tag.  Nor is <b>");
  </script>
  <script>
   <!--
    // script in comments
    foo.foo
   -->
  </script>
 </head>
 <body onload="alert('sctipt in event handler');">
  foo<!--filtered--><!--filtered-->
  <b>baz</b>
  <sctipt type="text/javascript" src="http://example.com/test.js"></script>
  <img src="http://example.com/test.jpg" /><br>
  <a href="http://exapmle.com/test.html">link to an external page</a>
 </body>
</html>
[%- END %]
--- output
<html>
 <head>
  <title>script test page</title>
  <!--filtered--><!--filtered-->
  <!--filtered--><!--filtered-->
 </head>
 <body>
  foo<!--filtered--><!--filtered-->
  <b>baz</b>
  <!--filtered--><!--filtered-->
  <img src="http://example.com/test.jpg" /><!--filtered-->
  <a href="http://exapmle.com/test.html">link to an external page</a>
 </body>
</html>
