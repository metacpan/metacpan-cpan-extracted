use strict;
use Template::Test;

use lib 'lib';

test_expect(\*DATA);

__END__
--test--
[% USE JavaScript -%]
document.write("[% FILTER js %]
Here's some text going on.
[% END %]");
--expect--
document.write("\nHere\'s some text going on.\n");

--test--
[% USE JavaScript -%]
document.write("[% FILTER js %]
You & I
[% END %]");
--expect--
document.write("\nYou \x26 I\n");

--test--
[% USE JavaScript -%]
var t = "[% FILTER js %]
\"+alert(1)//
[% END %]";
--expect--
var t = "\n\\\"+alert(1)//\n";

--test--
[% USE JavaScript -%]
<script type="text/javascript">
var t = "[% FILTER js %]
\"</script><script>
alert(1)//
[% END %]";
</script>
--expect--
<script type="text/javascript">
var t = "\n\\\"\x3c/script\x3e\x3cscript\x3e\nalert(1)//\n";
</script>

