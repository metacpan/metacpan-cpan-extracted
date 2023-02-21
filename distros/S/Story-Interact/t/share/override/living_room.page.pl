at 'living_room';

text q{
	You are in the living room.
	
	Blah blah blah.
	
	You can see open doors to a bedroom and a kitchen.
};

next_page kitchen => 'Go to the kitchen';
next_page bedroom => 'Go to the bedroom';
next_page main => 'Leave the house';
