use strict;
use Template::Test;

test_expect(\*DATA, undef, undef);

__DATA__
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
http://www.example.com

[%- END %]
--expect--
<p>
<a href="http://www.example.com">http://www.example.com</a>
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
ignored WikiLink

[%- END %]
--expect--
<p>
ignored WikiLink
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
forced [link]

[%- END %]
--expect--
<p>
forced link
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
[/relative/link.html see here]

[%- END %]
--expect--
<p>
<a href="/relative/link.html">see here</a>
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
[http://use.perl.org Perl Journals]

[%- END %]
--expect--
<p>
<a href="http://use.perl.org">Perl Journals</a>
</p>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
[Perl Journals http://use.perl.org]

[%- END %]
--expect--
<p>
<a href="http://use.perl.org">Perl Journals</a>
</p>
