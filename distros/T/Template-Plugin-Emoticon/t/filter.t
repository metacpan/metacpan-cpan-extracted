use strict;
use warnings;
use Template::Test;

test_expect(\*DATA);

__END__
[% USE Emoticon('MSN') %]

--test--
[% 'Hello ;)' | emoticon %]
--expect--
Hello <img src="http://messenger.msn.com/Resource/emoticons/wink_smile.gif" />

--test--
[% FILTER emoticon -%]
Hello ;)
[% END %]
--expect--
Hello <img src="http://messenger.msn.com/Resource/emoticons/wink_smile.gif" />

--test--
[% USE Emoticon('MSN', xhtml = 0) -%]
[% 'Hello ;)' | emoticon %]
--expect--
Hello <img src="http://messenger.msn.com/Resource/emoticons/wink_smile.gif">
