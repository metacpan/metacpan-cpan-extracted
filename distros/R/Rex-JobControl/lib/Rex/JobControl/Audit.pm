package Rex::JobControl::Audit;
$Rex::JobControl::Audit::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub index {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  $self->stash( rexfiles => $project->rexfiles );

  my $tasks =
    $self->minion->backend->list_jobs( 0, 200, { state => 'active' } );
  $self->stash( tasks => $tasks );

  $self->render;
}

1;
