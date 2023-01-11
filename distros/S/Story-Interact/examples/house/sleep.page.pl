at 'bedroom';

text 'You go to sleep.';

if ( player->carries->{apple} ) {
	text "You dream about your apple.";
}

next_page 'end' => 'End';
