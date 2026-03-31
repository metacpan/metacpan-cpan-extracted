use strict;
use warnings;

use Test::More;
use TOON;

my $text = do { local $/; <DATA> };

my $toon = TOON->new;

ok(my $data = $toon->decode($text), 'Parse data');

is($data->{users}->@*, 2, 'Two elements in array');
is($data->{users}[0]{name}, 'Alice', 'Correct name');
is($data->{users}[1]{role}, 'user', 'Correct role');

my $new_text = $toon->encode($data);

is($new_text, $text, 'Round-trip successful');

done_testing;

__DATA__
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
