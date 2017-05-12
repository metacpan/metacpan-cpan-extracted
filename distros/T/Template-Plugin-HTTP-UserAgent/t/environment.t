use strict;
use warnings;
use Template;
use Template::Test;

$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1) Opera 7.51 [ru]';
test_expect(\*DATA, { TRIM => 1 });

__DATA__
# Opera 7.51 on Windows XP
-- test --
[% USE ua = HTTP::UserAgent %]
name      = [% ua.name %]
version   = [% ua.version %]
major     = [% ua.major %]
minor     = [% ua.minor %]
os        = [% ua.os %]
ua_string = [% ua.ua_string %]
-- expect --
name      = Opera
version   = 7.51
major     = 7
minor     = 51
os        = Windows NT 5.1
ua_string = Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1) Opera 7.51 [ru]
