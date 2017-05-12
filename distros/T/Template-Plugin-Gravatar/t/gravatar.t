#!perl

use Template::Test;
$Template::Test::DEBUG = 1;

test_expect(\*DATA);

__DATA__
-- test --
[% USE Gravatar -%]
loaded

-- expect --
loaded

-- test --
[%- USE Gravatar -%]
[% Gravatar( email => 'whatever@wherever.whichever' ) %]

-- expect --
https://gravatar.com/avatar/?gravatar_id=a60fc0828e808b9a6a9d50f1792240c8

-- test --
[%- USE Gravatar(default => "/local.png") -%]
[% Gravatar( email => 'whatever@wherever.whichever' ) | html %]

-- expect --
https://gravatar.com/avatar/?gravatar_id=a60fc0828e808b9a6a9d50f1792240c8&amp;default=%2Flocal.png

-- test --
[%- USE Gravatar(default => "/local.png") -%]
[% Gravatar( email => ' wHatever@WHEREVER.whichever    ' ) | html %]

-- expect --
https://gravatar.com/avatar/?gravatar_id=a60fc0828e808b9a6a9d50f1792240c8&amp;default=%2Flocal.png

-- test --
[%- USE Gravatar(default => "/local.png", rating => 'X') -%]
[% Gravatar( email => 'whatever@wherever.whichever' ) %]

-- expect --
https://gravatar.com/avatar/?gravatar_id=a60fc0828e808b9a6a9d50f1792240c8&rating=X&default=%2Flocal.png

-- test --
[%- USE Gravatar(default => "/local.png") -%]
[% Gravatar( email  => 'whatever@wherever.whichever',
             rating => 'R',
             size   => 80 ) | html %]

-- expect --
https://gravatar.com/avatar/?gravatar_id=a60fc0828e808b9a6a9d50f1792240c8&amp;rating=R&amp;size=80&amp;default=%2Flocal.png

-- test --
[%- USE Gravatar(default => "/local.png",
                 border => 'AAB',
                 rating => 'PG',
                 size => 45 ) -%]
[% Gravatar( email => 'whatever@wherever.whichever' ) | html %]

-- expect --
https://gravatar.com/avatar/?gravatar_id=a60fc0828e808b9a6a9d50f1792240c8&amp;rating=PG&amp;size=45&amp;default=%2Flocal.png
