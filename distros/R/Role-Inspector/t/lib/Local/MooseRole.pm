package Local::MooseRole;

use Moose::Role;

has attr => (
	is      => 'ro',
	writer  => 'set_attr',
	clearer => 'clear_attr',
	handles => [ 'delegated' ],
);

sub meth { 42 }

requires qw( req );

1;
