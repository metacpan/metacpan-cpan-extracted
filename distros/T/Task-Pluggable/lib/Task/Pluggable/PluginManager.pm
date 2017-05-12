package Task::Pluggable::PluginManager;
use Module::Pluggable::Fast
	name     => 'tasks',
	search   => [ qw/Tasks Task::Pluggable::Tasks/ ],
	callback => sub{
		my $plugin = shift;
		$plugin->loaded;
	};
1;
