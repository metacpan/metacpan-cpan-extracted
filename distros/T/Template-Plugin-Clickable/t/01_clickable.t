use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE Clickable -%]
[% FILTER clickable -%]
http://www.template-toolkit.org/
[%- END %]
--expect--
<a href="http://www.template-toolkit.org/">http://www.template-toolkit.org/</a>

--test--
[% USE Clickable -%]
[% FILTER clickable target => '_blank' -%]
http://www.template-toolkit.org/
http://www.template-toolkit.org/
[%- END %]
--expect--
<a href="http://www.template-toolkit.org/" target="_blank">http://www.template-toolkit.org/</a>
<a href="http://www.template-toolkit.org/" target="_blank">http://www.template-toolkit.org/</a>

--test--
[% USE Clickable -%]
[% FILTER clickable target => '_blank', rel => 'nofollow' -%]
http://www.template-toolkit.org/
[%- END %]
[% FILTER clickable rel => 'nofollow' -%]
http://www.template-toolkit.org/
[%- END %]
--expect--
<a href="http://www.template-toolkit.org/" target="_blank" rel="nofollow">http://www.template-toolkit.org/</a>
<a href="http://www.template-toolkit.org/" rel="nofollow">http://www.template-toolkit.org/</a>
