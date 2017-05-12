use strict;
use Template::Test;

test_expect(\*DATA, undef, undef);

__DATA__
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
*this* should be *bold*

[%- END %]
--expect--
<p>
<strong>this</strong> should be <strong>bold</strong>
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
== title
/italic/ stuff

[%- END %]
--expect--
<h2>title</h2>
<p>
<em>italic</em> stuff
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
foo@bar.org

[%- END %]
--expect--
<p>
<a href="mailto:foo@bar.org">foo@bar.org</a>
</p>
