at 'bedroom';

text "You are in the bedroom.";

text q{There is a bed. It is covered in beautiful roses and looks remarkably comfortable. You consider sleeping in the bed.};

text q{You have been here } . visited . q{ times.};

next_page sleep => 'Sleep in the bed';
next_page living_room => 'Go to the living room';
