use strict;
use warnings;
use Template;
use Template::Test;

test_expect(\*DATA, { TRIM => 1 });

__DATA__
# Iceweasel on Linux
-- test --
[% USE ua = HTTP::UserAgent('Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.2.13) Gecko/20101203 Iceweasel/3.6.7 (like Firefox/3.6.13)') %]
name      = [% ua.name %]
version   = [% ua.version %]
major     = [% ua.major %]
minor     = [% ua.minor %]
os        = [% ua.os %]
ua_string = [% ua.ua_string %]
-- expect --
name      = Iceweasel
version   = 3.6.7
major     = 3
minor     = 6
os        = Linux
ua_string = Mozilla/5.0 (X11; U; Linux x86_64; fr; rv:1.9.2.13) Gecko/20101203 Iceweasel/3.6.7 (like Firefox/3.6.13)
