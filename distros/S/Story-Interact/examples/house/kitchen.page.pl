at 'kitchen';

text "You are in the kitchen.";

unless ( location->{apple_gone} ) {
	text "There is an *apple* on the counter.";
	next_page apple => 'Pick up apple';
}

next_page living_room => 'Go to the living room';
