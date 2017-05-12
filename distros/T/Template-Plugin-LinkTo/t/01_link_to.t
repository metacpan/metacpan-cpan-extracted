use strict;
use Template::Test;

test_expect(\*DATA, undef, { });

__END__

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    rel => 'nofollow',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" rel="nofollow">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    class => 'myclass',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" class="myclass">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    title => 'title on link',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" title="title on link">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    img => '/images/hoge.jpg',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to"><img src="/images/hoge.jpg" /></a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    hoge => 'huga',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?hoge=huga">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to?foo=bar',
    hoge => 'huga',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to?foo=bar&in=put',
    hoge => 'huga',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;in=put&amp;hoge=huga">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to?foo=bar',
    hoge => 'huga',
    in => 'put',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga&amp;in=put">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    hoge => 'huga',
    foo => 'bar',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" target="_blank">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    target => 'foo<br />bar',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" target="foo&lt;br /&gt;bar">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    hoge => 'huga',
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?hoge=huga" target="_blank">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to?foo=bar',
    hoge => 'huga',
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga" target="_blank">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    hoge => 'huga',
    foo => 'bar',
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga" target="_blank">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to?in=put',
    hoge => 'huga',
    foo => 'bar',
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?in=put&amp;foo=bar&amp;hoge=huga" target="_blank">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    target => '_blank',
    confirm => 'Are you sure?',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" target="_blank" onclick="return confirm('Are you sure?');">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    hoge => 'huga',
    foo => 'bar',
    target => '_blank',
    confirm => 'really ?',
} -%]
[% LinkTo.link_to('"link_text<br />"', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga" target="_blank" onclick="return confirm('really ?');">&quot;link_text&lt;br /&gt;&quot;</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    target => '_blank',
    confirm => 'Are you sure?',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to" target="_blank" onclick="return confirm('Are you sure?');">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to?foo=bar',
    hoge => 'huga',
    target => '<br />',
    confirm => '<br />',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
<a href="/link/to?foo=bar&amp;hoge=huga" target="&lt;br /&gt;" onclick="return confirm('&lt;br /&gt;');">link_text</a>

--test--
[% USE LinkTo -%]
[% args = {
    href => '/link/to',
    target => '_blank',
    confirm => 'Are you sure?',
} -%]
[% LinkTo.link_to('', args) %]
--expect--
<a href="/link/to" target="_blank" onclick="return confirm('Are you sure?');"></a>

### not href

--test--
[% USE LinkTo -%]
[% args = {
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
link_text

--test--
[% USE LinkTo -%]
[% args = {
    confirm => 'Are you sure?',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
link_text

--test--
[% USE LinkTo -%]
[% args = {
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
link_text

--test--
[% USE LinkTo -%]
[% args = {
    confirm => 'Are you sure?',
    target => '_blank',
} -%]
[% LinkTo.link_to('link_text', args) %]
--expect--
link_text


