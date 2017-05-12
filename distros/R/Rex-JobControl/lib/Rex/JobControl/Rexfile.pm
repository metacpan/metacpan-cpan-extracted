#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::JobControl::Rexfile;
$Rex::JobControl::Rexfile::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Controller';
use Cwd;
use File::Spec;

sub prepare_stash {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  $self->stash( project => $project );

  my $rexfile = $project->get_rexfile( $self->param("rexfile_dir") );
  $self->stash( rexfile => $rexfile );
}

sub index {
  my $self = shift;
  $self->render;
}

sub rexfile_new {
  my $self = shift;
  $self->render;
}

sub rexfile_new_create {
  my $self = shift;

  $self->app->log->debug( "Got project name: " . $self->param("project_dir") );
  $self->app->log->debug( "Got rexfile name: " . $self->param("rexfile_name") );

  my $pr = $self->project( $self->param("project_dir") );

  my $rexfile_archive = $self->param("rexfile_archive");

  if ( $rexfile_archive && $rexfile_archive->filename ) {
    $self->app->log->debug(
      "This is a fileupload: " . $rexfile_archive->filename );

    if ( $self->req->is_limit_exceeded ) {

      # $ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824;
      $self->flash(
        {
          title => "File too large.",
          message =>
            "You have reached the upload file limit. You can set this limit higher in the configuration file.",
        }
      );
      return $self->redirect_to( "/project/" . $self->param("project_dir") );
    }

    if ( $rexfile_archive->filename =~ m/\.tar\.gz$/ ) {
      if ( !-d getcwd() . "/upload" ) {
        mkdir getcwd() . "/upload";
      }

      $rexfile_archive->move_to(
        File::Spec->catdir(
          $self->config->{upload_tmp_path},
          $rexfile_archive->filename
        )
      );

      $self->minion->enqueue(
        checkout_rexfile => [
          $pr->directory,
          $self->param("rexfile_name"),
          File::Spec->catdir(
            $self->config->{upload_tmp_path},
            $rexfile_archive->filename
          ),
          $self->param("rexfile_description")
        ]
      );

      $self->flash(
        {
          title => "Rexfile will be extracted in background.",
          message =>
            "Rexfile will be extracted in background. Once it it finished it will appear in the list."
        }
      );
    }
    else {
      $self->flash(
        {
          title   => "Wrong filetype",
          message => "Only .tar.gz files are allowed.",
        }
      );
      return $self->redirect_to( "/project/" . $self->param("project_dir") );
    }
  }
  else {

    $self->minion->enqueue(
      checkout_rexfile => [
        $pr->directory,              $self->param("rexfile_name"),
        $self->param("rexfile_url"), $self->param("rexfile_description")
      ]
    );

    $self->flash(
      {
        title => "Rexfile will be downloaded in background.",
        message =>
          "Rexfile will be downloaded in background. Once it it finished it will appear in the list."
      }
    );

  }

  $self->redirect_to( "/project/" . $self->param("project_dir") );
}

sub view {
  my $self = shift;
  $self->render;
}

sub reload {
  my $self = shift;

  $self->app->log->debug( "Got project name: " . $self->param("project_dir") );
  $self->app->log->debug( "Got rexfile name: " . $self->param("rexfile_name") );

  my $pr      = $self->project( $self->param("project_dir") );
  my $rexfile = $pr->get_rexfile( $self->param("rexfile_dir") );

  $rexfile->reload;

  $self->redirect_to( "/project/" . $pr->directory );
}

sub remove {
  my $self = shift;

  $self->app->log->debug( "Got project name: " . $self->param("project_dir") );
  $self->app->log->debug( "Got rexfile name: " . $self->param("rexfile_name") );

  my $pr      = $self->project( $self->param("project_dir") );
  my $rexfile = $pr->get_rexfile( $self->param("rexfile_dir") );

  $rexfile->remove;

  $self->flash(
    {
      title   => "Rexfile removed",
      message => "Rexfile <b>" . $rexfile->name . "</b> removed."
    }
  );

  $self->redirect_to( "/project/" . $pr->directory );
}

1;
