# ABSTRACT: get project details
use strict;
use warnings;

package Smartcat::App::Command::project;
use Smartcat::App -command;

sub opt_spec {
    my ($self) = @_;

    my @opts = $self->SUPER::opt_spec;
    push @opts, $self->project_id_opt_spec, [ 'list' => 'Get all projects' ];

    return @opts;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->SUPER::validate_args( $opt, $args );
    $self->usage_error(
        "'--list' option cannot be used together with '--project-id'")
      if ( defined $opt->{list} && defined $opt->{project_id} );
    $self->validate_project_id( $opt, $args ) unless defined $opt->{list};
}

sub print_project_details {
    my ( $self, $project ) = @_;

    print "Project:\n\t" . $project->name . "\n";
    print "Id:\n\t" . $project->id . "\n";
    print "Documents:\n";
    print "\t"
      . $_->name
      . "\n\t\tid: $_->{id}\n\t\tstatus: "
      . $_->status
      . "\n\t\tlanguage: "
      . $_->target_language . "\n"
      for @{ $project->documents };
    print "Target languages:\n";
    print "\t" . join( ' ', @{ $project->target_languages } ) . "\n";
    print "Status:\n\t" . $project->status . "\n";
    print "-" x 80;
    print "\n";
}

sub print_project {
    my ( $self, $project ) = @_;

    print "Project:\n\t" . $project->name . "\n";
    print "Id:\n\t" . $project->id . "\n";
    print "Number of documents:\n";
    print "\t" . @{ $project->documents } . "\n";
    print "Target languages:\n";
    print "\t" . join( ' ', @{ $project->target_languages } ) . "\n";
    print "Status:\n\t" . $project->status . "\n";
    print "-" x 80;
    print "\n";
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $api = $self->app->project_api;
    if ( defined $opt->{list} ) {
        my $projects = $api->get_all_projects;
        print "Total number of projects:\n\t" . @$projects . "\n";
        print "-" x 80;
        print "\n";
        $self->print_project($_) for @$projects;
    }
    else {
        $self->print_project_details( $api->get_project );
    }
}

1;
