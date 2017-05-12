package Rex::JobControl::Nodes;
$Rex::JobControl::Nodes::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub index {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  $self->stash( rexfiles => $project->rexfiles );

  $self->render;
}

sub add_node {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  $project->add_node( { name => $self->param("nodename") } );

  $self->redirect_to( "/project/" . $project->directory );
}

1;
