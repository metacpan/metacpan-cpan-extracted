# ABSTRACT: pull translation files from Smartcat
use strict;
use warnings;

package Smartcat::App::Command::pull;
use Smartcat::App -command;
use Smartcat::App::Constants qw(COMPLETE);
use Smartcat::App::Utils;

use Log::Any qw($log);

sub opt_spec {
    my ($self) = @_;

    my @opts = $self->SUPER::opt_spec();

    push @opts,
      [ 'complete-documents' => 'Pull "complete" documents only' ],
      [ 'complete-projects'  => 'Pull "complete" projects only' ],
      [ 'skip-missing'       => 'Do not create (skip) missing files' ],
      [ 'mode:s'             => 'Unit export mode, available values: current, confirmed, complete; default value: current',
        { default => "current" }
      ],
      $self->project_id_opt_spec,
      $self->project_workdir_opt_spec,
      $self->file_params_opt_spec,
      ;

    return @opts;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    $self->SUPER::validate_args( $opt, $args );
    $self->validate_project_id( $opt, $args );
    $self->validate_project_workdir( $opt, $args );
    $self->validate_file_params( $opt, $args );
    $self->validate_mode( $opt, $args );

    $self->app->{rundata}->{complete_projects} =
      defined $opt->{complete_projects} ? $opt->{complete_projects} : 0;
    $self->app->{rundata}->{complete_documents} =
      defined $opt->{complete_documents} ? $opt->{complete_documents} : 0;
    $self->app->{rundata}->{skip_missing} =
      defined $opt->{skip_missing} ? $opt->{skip_missing} : 0;
}

sub validate_mode {
    my ( $self, $opt, $args ) = @_;
    my $rundata = $self->app->{rundata};
    $self->usage_error("Incorrect 'mode' value, 'current', 'confirmed', 'complete' are possible")
      if defined $opt->{mode} && $opt->{mode} !~ /current|confirmed|complete/;
    $rundata->{mode} = $opt->{mode};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $rundata = $self->app->{rundata};
    $log->info(
        sprintf(
"Running 'pull' command for project '%s' and translation files from '%s'...",
            $rundata->{project_id},
            $rundata->{project_workdir}
        )
    );

    my $project = $self->app->project_api->get_project;
    exit 1 unless $project;

    unless ( !$rundata->{complete_projects} || $project->status eq COMPLETE ) {
        $log->warn(
            sprintf(
                "Skip: project '%s' [%s] is not complete (status = %s)",
                $project->name, $project->id, $project->status
            )
        );
        exit 0;
    }

    my $documents;
    if ( $rundata->{complete_documents} ) {
        $documents = [];
        for ( @{ $project->documents } ) {
            if ( $_->status eq COMPLETE ) {
                push @$documents, $_;
            }
            else {
                $log->info(
                    sprintf(
"Skip: document '%s(%s)' [%s] is not complete (status = %s)",
                        $_->name, $_->target_language, $_->id, $_->status
                    )
                );
            }
        }
        $log->info(
            sprintf(
                "Found %d complete documents on the server",
                scalar(@$documents)
            )
        );
    }
    else {
        $documents = $project->documents;
        $log->info(
            sprintf(
                "Found %d documents on the server",
                scalar(@$documents)
            )
        );
    }

    if ( $rundata->{skip_missing} ) {
        my @existing_documents = grep {
            my $filepath = get_file_path(
                $rundata->{project_workdir},
                $_->target_language,
                $_->full_path, $rundata->{filetype});

            my $exists = -e $filepath;

            if ($rundata->{debug}) {
                my $status = $exists ? 'exists' : 'does not exist';
                $log->info(
                    sprintf("%s (%s)", $filepath, $status)
                );
            }

            # return the status
            $exists;
        } @$documents;
        $documents = \@existing_documents;
    }

    my $count = scalar(@$documents);
    if ($count == 0) {
        $log->warn('List of documents to download is empty; nothing to do.');
    } else {
        $log->info(
            sprintf(
                "Will download %d documents",
                $count
            )
        );
        $self->app->document_export_api->export_files($documents);
    }

    $log->info(
        sprintf(
"Finished 'pull' command for project '%s' and translation files from '%s'.",
            $rundata->{project_id},
            $rundata->{project_workdir}
        )
    );
}

1;
