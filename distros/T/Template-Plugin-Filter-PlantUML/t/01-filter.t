#!perl -T
use 5.006;
use strict;

use Template::Test;

test_expect( \*DATA, undef, {} );

__END__
-- test --
[% USE Filter.PlantUML -%]
[% FILTER plantuml %]
  Bob -> Alice : hello
[% END %]
-- expect --
http://www.plantuml.com/plantuml/png/69NZKb1moazIqBLJSCp9J4vLi5B8ICt9oUS204a_1dy0
