# test for global containers in lists

use strict;
use warnings;

use Test::More tests => 2;
use Template::Flute;

my $spec = <<EOF;
<specification>
<container name="locked" class="locked" value="locked" />
<container name="unlocked" class="unlocked" value="!locked" />
<list name="mylist" iterator="mylist">
  <param name="title" class="title" />
</list>
</specification>
EOF

my $html =<<EOF;
<html>
<body>
<div>
  <span class="locked">Locked</span>
  <span class="unlocked">Unlocked</span>
</div>
<ol>
<li class="mylist">
  <span class="title">Blablabla</span>
  <span class="locked">Locked</span>
  <span class="unlocked">Unlocked</span>
</li>
</ol>
</body>
</html>
EOF

my $list = [
            { title => 1 },
            { title => 2 },
            { title => 3 },
           ];

my $flute = Template::Flute->new(
                                 template => $html,
                                 specification => $spec,
                                 values => {
                                            mylist => $list,
                                            locked => 0,
                                           },
                                );

my $out = $flute->process;

my $expected = <<EOF;
<div>
<span class="unlocked">Unlocked</span>
</div>
<ol>
<li class="mylist">
<span class="title">1</span>
<span class="unlocked">Unlocked</span>
</li>
<li class="mylist">
<span class="title">2</span>
<span class="unlocked">Unlocked</span>
</li>
<li class="mylist">
<span class="title">3</span>
<span class="unlocked">Unlocked</span>
</li>
</ol>
EOF

$expected =~ s/\n//g;

like $out, qr{\Q$expected\E}, "list is looking good";
unlike $out, qr{class="locked"};


