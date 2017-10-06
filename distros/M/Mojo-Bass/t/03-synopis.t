
use Mojo::Bass -strict;
use Test::More;

package Cat {
  use Mojo::Bass -base;

  has name => 'Nyan';
  has ['age', 'weight'] => 4;
}

package Tiger {
  use Mojo::Bass 'Cat';

  has friend => sub { Cat->new };
  has stripes => 42;
}

package main;
use Mojo::Bass -strict;

my $mew = Cat->new(name => 'Longcat');
is($mew->age,                    4, 'default Cat age');
is($mew->age(3)->weight(5)->age, 3, 'chained mutators');
is($mew->weight,                 5, 'Cat weight as expected');

my $rawr = Tiger->new(stripes => 38, weight => 250);
my $rawr_weight = $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;
is($rawr->stripes,        38,        'Tiger stripes as expected');
is($rawr_weight,          250,       'Tiger weight as expected');
is($rawr->friend->name,   'Tacgnol', 'Tigre friend name as expected');
is($rawr->friend->weight, 4,         'Tiger friend has default weight');

ok(!$mew->can('has'),  '"has" not in symbol table');
ok(!$rawr->can('has'), '"has" not in symbol table');

done_testing;
