# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Syntax-Highlight-Mason.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Syntax::Highlight::Mason') };

#########################

my $mcode = <<'END';
<%doc>
test for mason highlighter
</%doc>
HTML <b>code</b> here
% my $x = 'a perl variable';
<%init>
# More perl code
$x =~ s/perl/PERL/g;
</%init>
<%args>
$x
$y => ''
</%args>
END

my $expected_result = <<'END';
<html>
<head>
<style type="text/css">
.m-tag { color: #0000ff; font-weight: bold;  }   /* mason tag             */
/* ====================================================================== *
 * Sample stylesheet for Syntax::Highlight::HTML                          *
 *                                                                        *
 * Copyright (C)2004 Sebastien Aperghis-Tramoni, All Rights Reserved.     *
 *                                                                        *
 * This file is free software; you can redistribute it and/or modify      *
 * it under the same terms as Perl itself.                                *
 * ====================================================================== */

.h-decl { color: #336699; font-style: italic; }   /* doctype declaration  */
.h-pi   { color: #336699;                     }   /* process instruction  */
.h-com  { color: #338833; font-style: italic; }   /* comment              */
.h-ab   { color: #000000; font-weight: bold;  }   /* angles as tag delim. */
.h-tag  { color: #993399; font-weight: bold;  }   /* tag name             */
.h-attr { color: #000000; font-weight: bold;  }   /* attribute name       */
.h-attv { color: #333399;                     }   /* attribute value      */
.h-ent  { color: #cc3333;                     }   /* entity               */
.h-lno  { color: #aaaaaa; background: #f7f7f7;}   /* line numbers         */
</style>

</head>
<body>
<pre>
<span class="m-tag">&lt;%doc&gt;
</span>
test for mason highlighter
<span class="m-tag">&lt;/%doc&gt;
</span>HTML <span class="h-ab">&lt;</span><span class="h-tag">b</span><span class="h-ab">&gt;</span>code<span class="h-ab">&lt;/</span><span class="h-tag">b</span><span class="h-ab">&gt;</span> here
 % <span style="color:#000;">my</span> <span style="color:#080;">$x</span> <span style="color:#000;">=</span> <span style="color:#00a;">'</span><span style="color:#00a;">a perl variable</span><span style="color:#00a;">'</span><span style="color:#000;">;</span>
<span class="m-tag">&lt;%init&gt;
</span>
<span style="color:#069;font-style:italic;"># More perl code</span>
<span style="color:#080;">$x</span> <span style="color:#000;">=~</span> <span style="color:#00a;">s/</span><span style="color:#00a;">perl</span><span style="color:#00a;">/</span><span style="color:#00a;">PERL</span><span style="color:#00a;">/</span><span style="color:#00a;">g</span><span style="color:#000;">;</span>
<span class="m-tag">&lt;/%init&gt;
</span><span class="m-tag">&lt;%args&gt;
</span>$x
$y =&gt;  &#39;&#39;
<span class="m-tag">&lt;/%args&gt;
</span></pre>
</body>
</html>
END

my $result = Syntax::Highlight::Mason->new->compile($mcode);
is($result, $expected_result, 'basic test');
