use strict;
use Template::Test;

test_expect(\*DATA, { TRIM=>1 });
__END__
--test--
[% USE CSS::LESSp -%]
[% FILTER CSS::LESSp -%]
@brand_color: #4D926F;
h2 { color: @brand_color; }
[% END %]
--expect--
h2 { color: #4D926F; }