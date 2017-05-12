package Rex::WebUI::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# This action will render a template
sub index {
   my $self = shift;

warn "index ***********************************************";

   $self->stash(name => $self->config->{name});
   $self->stash(notification_message => 'Starting Up');

   $self->stash(recent_tasks  => $self->logbook->recent_tasks);
   $self->stash(running_tasks => $self->logbook->running_tasks);

   $self->render;
}

sub view {
   my $self = shift;
   $self->render;
}

sub notification_message {
   my $self = shift;

   my $running_tasks = $self->logbook->running_tasks;

   if ($running_tasks && scalar @$running_tasks > 0) {

   	  $self->render(json => { message => (scalar @$running_tasks) . " Tasks Running" });
   }
   else {

      $self->render(json => { message => "All Quiet"} );
   }
}

1;
