package # hide from PAUSE
	Net::Bamboo::Project;

use Moose;

use MooseX::Types::URI qw(Uri FileUri DataUri);

has bamboo	=> (isa => 'Net::Bamboo',	is => 'ro');
has key		=> (isa => 'Str',			is => 'ro');
has name	=> (isa => 'Str',			is => 'ro');
has link	=> (isa => Uri,				is => 'ro', coerce => 1);

has _plans =>
	traits		=> [ 'Hash' ],
	isa			=> 'HashRef[Net::Bamboo::Plan]',
	is			=> 'ro',
	handles		=>
	{
		plans		=> 'values',
		num_plans	=> 'count',
		plan_keys	=> 'keys',
		add_plan	=> 'set',
		plan		=> 'get',
	};

1;

