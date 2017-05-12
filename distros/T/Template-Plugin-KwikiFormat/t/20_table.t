use strict;
use Template::Test;

test_expect(\*DATA, undef, undef);

__DATA__
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
|a|table|
|with|some|
|rows|

[%- END %]
--expect--
<table class="formatter_table">
<tr>
<td>a</td>
<td>table</td>
</tr>
<tr>
<td>with</td>
<td>some</td>
</tr>
<tr>
<td>rows</td>
</tr>
</table>
--test--
[% USE KwikiFormat -%]
[% FILTER kwiki -%]
|a|table|
|/with/|*some*|
|rows|

[%- END %]
--expect--
<table class="formatter_table">
<tr>
<td>a</td>
<td>table</td>
</tr>
<tr>
<td><em>with</em></td>
<td><strong>some</strong></td>
</tr>
<tr>
<td>rows</td>
</tr>
</table>
