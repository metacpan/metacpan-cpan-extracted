use strict;
use Test::More tests => 22;

use_ok 'Regexp::Assemble::Compressed';

my $ra = Regexp::Assemble::Compressed->new;

# This is done by Regexp::Assemble.
#for my $i (0 .. 9) {
#    $ra->add($i)
#}
#is($ra->as_string, '\d', '[0-9]');
#$ra->reset;

for my $i ('a' .. 'z') {
    $ra->add($i);
}
is($ra->as_string, '[a-z]', '[a-z]');

$ra->reset;
for my $i ('a' .. 'z', 'A' .. 'Z') {
    $ra->add($i);
}
is($ra->as_string, '[A-Za-z]', '[A-Za-z]');

$ra->reset;
$ra->add('[^.]+');
is($ra->as_string, '[^.]+', '[^.]+');

$ra->reset;
$ra->add('[\dabcdef]+');
is($ra->as_string, '[\da-f]+', '[\da-f]+');

$ra->reset;
$ra->add('[a-fg-z]+');
is($ra->as_string, '[a-z]+', '[a-z]+');

$ra->reset;
$ra->add('[a-fgh-z]+');
is($ra->as_string, '[a-z]+', '[a-z]+');

$ra->reset;
$ra->add('[a-fh-z]+');
is($ra->as_string, '[a-fh-z]+', '[a-fh-z]+');

$ra->reset;
$ra->add('[a-bd-z]+');
is($ra->as_string, '[abd-z]+', '[a-bd-z]+');

$ra->reset;
$ra->add('[\x00-\xff]+');
is($ra->as_string, '[\x00-\xff]+', '[\x00-\xff]+');

$ra->reset;
$ra->add('[\Ua-z]+');
is($ra->as_string, '[\Ua-z]+', '[\Ua-z]+');

$ra->reset;
$ra->add('[\Ud-ha-c]+');
is($ra->as_string, '[\Ud-ha-c]+', '[\Ud-ha-c]+');

$ra->reset;
$ra->add('[\ua-cd-h]+');
is($ra->as_string, '[\ua-cd-h]+', '[\ua-cd-h]+');

$ra->reset;
$ra->add('[\-a]+');
is($ra->as_string, '[\-a]+', '[\-a]+');

$ra->reset;
$ra->add('[\Ua-z\E!\U0-9\E]+');
is($ra->as_string, '[!\U0-9\E\Ua-z\E]+', '[\Ua-z\E!\U0-9\E]+');

$ra->reset;
$ra->add('[a-z\p{QuotationMark}]+');
is($ra->as_string, '[\p{QuotationMark}a-z]+', '[a-z\p{...}]+');

$ra->reset;
$ra->add('[a-za-z]+');
is($ra->as_string, '[a-z]+', '[a-z]+');

$ra->reset;
$ra->add('[a-za-a]+');
is($ra->as_string, '[a-z]+', '[a-za-a]+');

$ra->reset;
$ra->add('[a-zb-c]+');
is($ra->as_string, '[a-z]+', '[a-za-a]+');

$ra->reset;
$ra->add('[a-db-h]+');
is($ra->as_string, '[a-h]+', '[a-db-h]+');

$ra->reset;
$ra->add('[aaa]+');
is($ra->as_string, '[a]+', '[aaa]+');

$ra->reset;
$ra->add('[1[:alpha:]234]+');
is($ra->as_string, '[1-4[:alpha:]]+', '[1[:alpha:]234]+');
