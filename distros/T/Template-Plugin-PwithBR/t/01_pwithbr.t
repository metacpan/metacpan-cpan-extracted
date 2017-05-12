use strict;
use Template::Test;
test_expect(\*DATA,
            undef,
            {
                text => "foo\nbar",
                para => "foo\n\nbar",
            });

__END__
--test--
[% USE PwithBR -%]
[% FILTER p_with_br -%]
foo
bar
[%- END %]
--expect--
<p>
foo<br />
bar</p>

--test--
[% USE PwithBR -%]
[% text | p_with_br %]
--expect--
<p>
foo<br />
bar</p>

--test--
[% USE PwithBR -%]
[% para | p_with_br %]
--expect--
<p>
foo
</p>

<p>
bar</p>

--test--
[% USE PwithBR -%]
[% FILTER p_with_br -%]
foo
bar

fuga
hoge
[%- END %]
--expect--
<p>
foo<br />
bar
</p>

<p>
fuga<br />
hoge</p>
