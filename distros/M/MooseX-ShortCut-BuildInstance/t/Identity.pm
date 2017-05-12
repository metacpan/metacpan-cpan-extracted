package Identity;
use Moose::Role;
use MooseX::StrictConstructor;
requires 'is_important';

has 'name' =>( 
		is => 'ro',
		#~ reader => 'get_name',
	);
	
no Moose::Role;
1;