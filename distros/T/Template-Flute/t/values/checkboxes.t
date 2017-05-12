use strict;
use warnings;
use Test::More tests => 4;
use Template::Flute;
use Data::Dumper;

# diag 'All tests will fail if args="tree" is not provided';

my $spec = <<EOF;
<specification>
<list name="items" iterator="items" class="list">
 <param name="received_check" class="received-check" op="toggle" args="tree"/>
 <param name="received" field="code"/>
</list>
</specification>
EOF

my $html = <<EOF;
<ol>
<li class="list">
 <span class="received-check">
  <input type="checkbox" name="received" value="" class="received"/>
 </span>
</li>
</ol>
EOF

my $iter = [{ code => "first",  received_check => '1' },
            { code => "second", received_check => '1' }];

my $flute = Template::Flute->new(template => $html,
                                 specification => $spec,
                                 auto_iterators => 1,
                                 values => { items => $iter });

my $out = $flute->process;
my $expected =<<'OUT';
<li class="list">
<span class="received-check">
<input class="received" name="received" type="checkbox" value="first" />
</span>
</li>
<li class="list">
<span class="received-check">
<input class="received" name="received" type="checkbox" value="second" />
</span>
</li>
OUT
$expected =~ s/\n//g;

like $out, qr/\Q$expected\E/;

$spec = <<EOF;
<specification>
<list name="items" iterator="items" class="list">
 <param name="received" field="code"/>
 <param name="received_check" class="received-check" op="toggle" args="tree"/>
</list>
</specification>
EOF

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              auto_iterators => 1,
                              values => { items => $iter });

$out = $flute->process;

like $out, qr/\Q$expected\E/;

$spec = <<EOF;
<specification>
 <value name="received_check" class="received-check" op="toggle" args="tree"/>
 <value name="received" />
</specification>
EOF

$html = <<EOF;
<span class="received-check">
<input class="received" name="received" type="checkbox" value="second" />
</span>
EOF

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              auto_iterators => 1,
                              values => { received => 'blabla',
                                          received_check => 1
                                        });

$out = $flute->process;

$expected = <<EOF;
<span class="received-check">
<input class="received" name="received" type="checkbox" value="blabla" />
</span>
EOF

$expected =~ s/\n//g;

like $out, qr/\Q$expected\E/;


$spec = <<EOF;
<specification>
 <value name="received" />
 <value name="received_check" class="received-check" op="toggle" args="tree"/>
</specification>
EOF

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              auto_iterators => 1,
                              values => { received => 'blabla',
                                          received_check => 1
                                        });

$out = $flute->process;

like $out, qr/\Q$expected\E/;

