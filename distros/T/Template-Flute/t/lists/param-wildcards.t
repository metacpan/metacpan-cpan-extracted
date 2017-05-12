#! perl

use utf8;
use strict;
use warnings;
use Test::More tests => 10;
use Template::Flute;
use Data::Dumper;

my ($spec, $html, $flute, $out, $expected);

$spec =<<'XML';
<specification>
<list name="list" iterator="test">
<param name="thing" target="*" op="append"/>
</list>
</specification>
XML

$html =<<'HTML';
<html>
<ul class="test-list">
<li class="list">
 <img class="thing" alt="Alternate text: " src="http://localhost/" title="Title: " />
</li>
</ul>
</html>
HTML

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
                              values => {
                                         test => [
                                                  { thing => 'image1.png' },
                                                  { thing => 'image2.png' },
                                                  { thing => 'image3.png' },
                                                 ],
                                        });

$out = $flute->process;

my $count = 0;
while ($out =~ m/class="thing"/g) {
    $count++;
}
is $count, 3, "Found 3 things as expected";

foreach my $img (qw/image1.png image2.png image3.png/) {
    foreach my $exp ('alt="Alternate text: ',
                     'src="http://localhost/',
                     'title="Title: ') {
        my $expected = $exp . $img . q{"};
        like $out, qr/\Q$expected\E/, "$expected found in the output";
    }
}
