package Reddit::Type::User;

use 5.010001;
use common::sense;
use Moose;

has [ 	
	'name', 'id',
	'is_gold', 'is_mod',
	'has_mail', 'has_mod_mail',
	'created', 'created_utc',
	'link_karma', 'comment_karma', 
	'modhash',
]   				=> 	(
	is 			=> 'rw',
	isa 		=> 'Str',
	lazy 		=> 1,
	default 	=> '',
);	

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
