use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Pistachio::Html') }

my $snip = Pistachio::Html->new('Perl5', 'Github')->snippet(\"print 'Foo';");

my $expected = q|<div>
<div style="font-family:Consolas,'Liberation Mono',Courier,monospace;float:left;background-color:#eee;border-right:1px #999988 solid">
<div style="font-size:13px;color:#999988;display:block;line-height:18px;padding:0 8px;margin:0;border:0;text-align:right;border-spacing:2px">1</div>
</div>

<div style="font-family:Consolas,'Liberation Mono',Courier,monospace;padding:0 8px 0 11px;white-space:pre;font-size:13px;line-height:18px;float:left"><span style="color:#0086B3">print</span><span> </span><span style="color:#D14">&#39;Foo&#39;</span><span style="color:#333">;</span></div>
</div>
<div style="clear:both"></div>|;

ok($snip eq $expected, "Pistachio::Html::snippet() produced expected HTML");

done_testing;
