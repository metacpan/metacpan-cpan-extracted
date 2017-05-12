use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE HTML.Strip -%]
[% FILTER html_strip -%]
<p>The power to enact removals has ultimately fallen into the wrong hands.</p>
[%- END %]
--expect--
The power to enact removals has ultimately fallen into the wrong hands.

--test--
[% USE HTML.Strip 'strip' -%]
[% FILTER strip -%]
<a href="http://heightenedconcern.org">Even to remove attributes and their values!?</a>
[%- END %]
--expect--
Even to remove attributes and their values!?

--test--
[% USE HTML.Strip -%]
[% FILTER html_strip
    striptags = [ 'strong' 'small' ]
-%]
<strong>Even their contents!</strong>
<small>I am afraid.</small>
[%- END %]
--expect--


--test--
[% USE HTML.Strip -%]
[% FILTER html_strip
    emit_spaces = 0
-%]
<p><b>I<i>strongly</i>suggest<em>we</em><u>leave</u>immediately.</b>
[%- END %]
--expect--
Istronglysuggestweleaveimmediately.

