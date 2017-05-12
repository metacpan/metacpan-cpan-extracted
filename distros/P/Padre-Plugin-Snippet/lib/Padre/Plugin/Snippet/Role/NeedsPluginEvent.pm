package Padre::Plugin::Snippet::Role::NeedsPluginEvent;
use Moose::Role;

requires 'on_save_as';
requires 'new_document_from_string';

sub fire_plugin_event {
	my $orig = shift;
	my $self = shift;

	# Save the return value
	my $result = $self->$orig(@_);

	# Fire event that Padre does not implement at the moment
	$self->{ide}->plugin_manager->plugin_event('editor_changed');

	# And return the original result
	return $result;
}

# Hook up to new_document_from_string
around 'new_document_from_string' => \&fire_plugin_event;

# Hook up to on_save_as
around 'on_save_as' => \&fire_plugin_event;

no Moose::Role;
1;
