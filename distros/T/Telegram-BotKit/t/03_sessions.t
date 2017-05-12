#!/usr/bin/env perl

use Data::Dumper;

use Telegram::BotKit::Sessions;
use Test::More tests => 2;


$sess = Telegram::BotKit::Sessions->new;

$sess->set('1',
[{
	'level' => 0,
	'callback_text' => '/book',
	'screen' => 'item_select'
},
{
	'screen' => 'day_select',
	'callback_text' => 'Item 1',
	'level' => 1
}]
);

warn Dumper $sess;


ok( eq_hash 
	(
		$sess->combine_properties('1', { 
			name_of_hash_key => 'callback_texts_by_scrn', 
			first_property => 'screen',
			second_property => 'callback_text'
		}),
		{
	          'callback_texts_by_scrn' => {
	                         'item_select' => '/book',
	                         'day_select' => 'Item 1'
	                       }
	    }
	)
);


ok( eq_hash 
	(
		$sess->combine_properties_retrospective('1', { 
			name_of_hash_key => 'replies', 
			first_property => 'screen',
			second_property => 'callback_text'
		}),
		{
	          'replies' => {
	                         'item_select' => 'Item 1'
	                         # 'day_select' => undef
	                       }
	    }
	)
);


warn Dumper $sess->combine_properties_retrospective('1', { 
			name_of_hash_key => 'replies', 
			first_property => 'screen',
			second_property => 'callback_text'   # taken from next element
		});


warn Dumper $sess->get_replies_hash('1');
