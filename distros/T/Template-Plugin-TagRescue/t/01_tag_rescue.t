use strict;
use Template::Test;

test_expect(\*DATA, undef, {
    text => '<B>Bold!</B> "and" <I>Italic!</I> & <A href="http://www.cpan.org/">CPAN</A>'
});

__END__
[% USE TagRescue -%]

--test--
[% FILTER html_except_for('b','i') -%]
<B>Bold!</B> & <I>Italic!</I>
[%- END %]
--expect--
<B>Bold!</B> &amp; <I>Italic!</I>

--test--
[% FILTER html_except_for('i') -%]
<B>Bold!</B> & <I>Italic!</I>
[%- END %]
--expect--
&lt;B&gt;Bold!&lt;/B&gt; &amp; <I>Italic!</I>

--test--
[% text | html_except_for('i') %]
[% text | html_except_for('b') %]
--expect--
&lt;B&gt;Bold!&lt;/B&gt; &quot;and&quot; <I>Italic!</I> &amp; &lt;A href=&quot;http://www.cpan.org/&quot;&gt;CPAN&lt;/A&gt;
<B>Bold!</B> &quot;and&quot; &lt;I&gt;Italic!&lt;/I&gt; &amp; &lt;A href=&quot;http://www.cpan.org/&quot;&gt;CPAN&lt;/A&gt;

--test--
[% tagi = ['i']; taga = ['a']; text | html_except_for(tagi, 'b', taga) %]
--expect--
<B>Bold!</B> &quot;and&quot; <I>Italic!</I> &amp; <A href="http://www.cpan.org/">CPAN</A>

--test--
[% taglist = ['b', 'i']; text | html_except_for(taglist) %]
--expect--
<B>Bold!</B> &quot;and&quot; <I>Italic!</I> &amp; &lt;A href=&quot;http://www.cpan.org/&quot;&gt;CPAN&lt;/A&gt;

--test--
[% FILTER html_except_for() -%]
[% text %]
[%- END %]
--expect--
&lt;B&gt;Bold!&lt;/B&gt; &quot;and&quot; &lt;I&gt;Italic!&lt;/I&gt; &amp; &lt;A href=&quot;http://www.cpan.org/&quot;&gt;CPAN&lt;/A&gt;
