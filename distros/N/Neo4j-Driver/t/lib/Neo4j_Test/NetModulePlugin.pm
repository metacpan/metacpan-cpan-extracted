use strict;
use warnings;
package Neo4j_Test::NetModulePlugin;

use parent 'Neo4j::Driver::Plugin';

sub new {
	my ($class, $net_module) = @_;
	bless \$net_module, $class;
}

sub register {
	my ($self, $manager) = @_;
	my $net_module = $$self;
	
	$manager->add_event_handler(
		http_adapter_factory => sub {
			my ($continue, $driver) = @_;
			return $net_module->new($driver);
		},
	);
}


1;

__END__

This is a tiny wrapper that basically simulates the old net_module
config option using the new plug-in API. It can be used like this:

my $net_module = 'Local::MyOldNetModule';
$driver->plugin( Neo4j_Test::NetModulePlugin->new($net_module) );
