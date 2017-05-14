package Reddit::Type::User;
use 5.010001;
use common::sense;
use Moose;

has [ 	
	'display_name', 'title',
	'name', 'id',
	'created', 'created_utc',
	'over18', 'subscribers',
	'description',
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
