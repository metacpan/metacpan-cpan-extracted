at 'kitchen';

text 'You pick up the apple. It looks juicy.';

location->{apple_gone} = true;
player->carries->{apple}++;

next_page kitchen => 'Look around the kitchen';
