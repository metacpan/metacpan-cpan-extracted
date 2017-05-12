#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::JobControl::Formular;
$Rex::JobControl::Formular::VERSION = '0.18.0';
use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use Data::Dumper;
use Cwd;
use YAML;
use File::Spec;

sub check_public {
  my ($self) = @_;

  my $project = $self->project( $self->param("project_dir") );
  $self->stash( project => $project );

  my $formular = $project->get_formular( $self->param("formular_dir") );
  $self->stash( formular => $formular );

  $self->stash( is_logged_in => $self->is_user_authenticated );

  return 1 if ( $formular->public eq "yes" );

  $self->redirect_to("/login") and return 0
    unless ( $self->is_user_authenticated );
  return 1;
}

sub prepare_stash {
  my $self = shift;

  my $project = $self->project( $self->param("project_dir") );
  $self->stash( project => $project );

  my $formular = $project->get_formular( $self->param("formular_dir") );
  $self->stash( formular => $formular );

  $self->stash( is_logged_in => $self->is_user_authenticated );
}

sub delete_data_item {
  my $self = shift;

  my $project  = $self->project( $self->param("project_dir") );
  my $formular = $project->get_formular( $self->param("formular_dir") );

  my $current_forms = $self->session("formulars") || {};
  my $to_delete_id  = $self->param("data_item");
  my $form          = $formular->formulars->[ $self->param("form_step") ];

  $self->app->log->debug("Should delete: $to_delete_id");
  splice( @{ $current_forms->{ $formular->name }->{ $form->{name} } },
    $to_delete_id, 1 );

  $self->session( formulars => $current_forms );

  $self->redirect_to( "/project/"
      . $project->directory
      . "/formular/"
      . $formular->directory
      . "/execute?form_step="
      . $self->param("form_step") );
}

sub view_formular {
  my $self = shift;

  my $project  = $self->project( $self->param("project_dir") );
  my $formular = $project->get_formular( $self->param("formular_dir") );

  my $form_step = $self->param("form_step") || 0;

  my $repeat = 0;

  if ( $form_step =~ m/^repeat\-(\d+)/ ) {
    $repeat    = 1;
    $form_step = $1;
  }

  $self->stash( repeat    => $repeat );
  $self->stash( form_step => $form_step );

  my $current_forms = $self->session("formulars") || {};

  if ( $form_step eq "cancel" ) {
    $current_forms->{ $formular->name } = {};
    $self->session( formulars => $current_forms );
    $self->redirect_to( "/project/"
        . $project->directory
        . "/formular/"
        . $formular->directory
        . "/execute?form_step=0" );
    return;
  }

  if ( $form_step < 0 ) {
    $self->redirect_to( "/project/"
        . $project->directory
        . "/formular/"
        . $formular->directory
        . "/execute?form_step=0" );
    return;
  }

  my $save_form = 0;
  my $old_step  = $form_step - 1;

  if ($repeat) {
    $old_step = $form_step;
  }

  my $current_step  = $formular->formulars->[$form_step];
  my $previous_step = $formular->formulars->[$old_step];

  my @field_names     = map { $_->{name} } @{ $previous_step->{fields} };
  my @cur_field_names = map { $_->{name} } @{ $current_step->{fields} };

  if ( $self->param("posted") && $self->param("posted") eq "1" ) {

    $save_form = 1;

    if ($save_form) {

      $current_forms->{ $formular->name } ||= {};

      my $current_form = $current_forms->{ $formular->name };
      my $form         = $formular->formulars->[$old_step];

      $current_form->{ $form->{name} } ||= {};

      my $current_form_data = $current_form->{ $form->{name} };

      if ( $self->param("form_changed") eq "1" ) {
        if ( $repeat == 0 ) {

          # new data
          my %data;
          @data{@field_names} = $self->param( [@field_names] );
          $current_forms->{ $formular->name }->{ $form->{name} } = \%data;
        }
        elsif ( $repeat == 1 ) {
          my %data;
          @data{@field_names} = $self->param( [@field_names] );
          if (
            ref $current_forms->{ $formular->name }->{ $form->{name} } ne
            "ARRAY"
            && scalar(
              keys %{
                $current_forms->{ $formular->name }->{ $current_step->{name} }
              }
            ) > 0
            )
          {
            $current_forms->{ $formular->name }->{ $form->{name} } =
              [ $current_forms->{ $formular->name }->{ $form->{name} } ];
          }
          elsif (
            ref $current_forms->{ $formular->name }->{ $form->{name} } ne
            "ARRAY" )
          {
            $current_forms->{ $formular->name }->{ $form->{name} } = [];
          }

          push @{ $current_forms->{ $formular->name }->{ $form->{name} } },
            \%data;
        }

        $self->session( formulars => $current_forms );
      }

    }

#$self->redirect_to("/project/" . $project->directory . "/formular/" . $formular->directory . "/execute?form_step=$form_step");
#return;

  }

  $self->stash( step_fields     => \@cur_field_names );
  $self->stash( formular_config => $current_step );

  if (
    ref $current_forms->{ $formular->name }->{ $current_step->{name} } eq
    "ARRAY"
    && scalar(
      @{ $current_forms->{ $formular->name }->{ $current_step->{name} } }
    ) > 0
    )
  {
    $self->stash( step_data =>
        $current_forms->{ $formular->name }->{ $current_step->{name} }->[-1] );
    $self->stash( all_step_data =>
        $current_forms->{ $formular->name }->{ $current_step->{name} } );
  }
  elsif (
    ref $current_forms->{ $formular->name }->{ $current_step->{name} } eq "HASH"
    && scalar(
      keys %{ $current_forms->{ $formular->name }->{ $current_step->{name} } }
    ) > 0
    )
  {
    $self->stash( step_data =>
        $current_forms->{ $formular->name }->{ $current_step->{name} } );
    $self->stash( all_step_data =>
        [ $current_forms->{ $formular->name }->{ $current_step->{name} } ] );
  }
  else {
    $self->stash( step_data     => {} );
    $self->stash( all_step_data => [] );
  }

  if ($repeat) {
    $self->stash( step_data => {} );
  }

  if ( $form_step >= scalar( @{ $formular->steps } ) ) {

    # form finished
    # save result in yaml file
    # and call rexfile

    $self->app->log->debug( Dumper( $current_forms->{ $formular->name } ) );

    my $cmdb_data          = $current_forms->{ $formular->name };
    my $cmdb_data_with_key = {};
    my @formulars_with_key = grep { exists $_->{key} } @{ $formular->steps };

    for my $form_with_key (@formulars_with_key) {
      if ( ref $cmdb_data->{ $form_with_key->{name} } ne "ARRAY" ) {
        $cmdb_data->{ $form_with_key->{name} } =
          [ $cmdb_data->{ $form_with_key->{name} } ];
      }
      for my $x ( @{ $cmdb_data->{ $form_with_key->{name} } } ) {
        $cmdb_data_with_key->{ $form_with_key->{name} }
          ->{ $x->{ $form_with_key->{key} } } = $x;
      }
    }

    if ( scalar @formulars_with_key > 0 ) {
      $cmdb_data = { %{$cmdb_data}, %{$cmdb_data_with_key} };
    }

    $self->minion->enqueue(
      execute_rexfile => [
        $project->directory,
        $formular->job->directory,
        ( $self->current_user ? $self->current_user->{name} : '' ),
        $cmdb_data,
        @{ $formular->servers },
      ]
    );

    $current_forms->{ $formular->name } = {};
    $self->session( formulars => $current_forms );

    $self->render("formular/formular_finished");
    return;
  }

  $self->render;
}

sub formular_new {
  my $self = shift;
  $self->render;
}

sub formular_new_create {
  my $self = shift;

  $self->app->log->debug( "Got project name: " . $self->param("project_dir") );
  $self->app->log->debug(
    "Got formular name: " . $self->param("formular_name") );

  my $formular_file = $self->param("formular_file");

  eval {
    $formular_file->move_to(
      File::Spec->catdir(
        $self->config->{upload_tmp_path},
        $formular_file->filename
      )
    );
  } or do {
    $self->flash(
      {
        title   => "Error uploading formular definition file.",
        message => "Failed to upload formular definition file. $@",
      }
    );

    return $self->redirect_to( "/project/" . $self->param("project_dir") );
  };

  eval {

    my $ref = YAML::LoadFile(
      File::Spec->catdir(
        $self->config->{upload_tmp_path},
        $formular_file->filename
      )
    );
    my $pr = $self->project( $self->param("project_dir") );

    $pr->create_formular(
      directory   => $self->param("formular_name"),
      name        => $self->param("formular_name"),
      description => $self->param("formular_description") || "",
      public      => ( $self->param("formular_public") eq "true" ? 1 : 0 ),
      job         => $self->param("formular_job"),
      servers     => [ $self->param("sel_server") ],
      steps       => $ref,
    );

    $self->flash(
      {
        title   => "Formular created",
        message => "A new formular <b>"
          . $self->param("formular_name")
          . "</b> was created.",
      }
    );

    1;
  } or do {
    $self->flash(
      {
        title   => "Error parsing YAML",
        message => "Failed parsing YAML file.<br>$@",
      }
    );
  };

  $self->redirect_to( "/project/" . $self->param("project_dir") );
}

sub view {
  my $self = shift;
  $self->render;
}

sub edit_save {
  my $self = shift;

  my $pr       = $self->project( $self->param("project_dir") );
  my $formular = $pr->get_formular( $self->param("formular_dir") );

  my $formular_file = $self->param("formular_file");

  $formular_file->move_to(
    File::Spec->catdir(
      $self->config->{upload_tmp_path},
      $formular_file->filename
    )
  ) if $formular_file->filename;

  eval {

    my $ref;

    if ( $formular_file->filename ) {
      $ref = YAML::LoadFile(
        File::Spec->catdir(
          $self->config->{upload_tmp_path},
          $formular_file->filename
        )
      );
    }

    $formular->update(
      name        => $self->param("formular_name"),
      description => $self->param("formular_description"),
      public      => ( $self->param("formular_public") eq "true" ? 1 : 0 ),
      job         => $self->param("formular_job"),
      servers     => [ $self->param("sel_server") ],
      ( $formular_file->filename ? ( steps => $ref ) : () ),
    );

    $self->flash(
      {
        title   => "Formular updated",
        message => "Formular <b>" . $formular->name . "</b> updated.",
      }
    );

    $self->redirect_to(
      "/project/" . $pr->directory . "/formular/" . $formular->directory );

    1;

  } or do {
    $self->flash(
      {
        title   => "Error updating Formular",
        message => "Formular <b>"
          . $formular->name
          . "</b> update failed.<br>$@",
      }
    );

    $self->redirect_to(
      "/project/" . $pr->directory . "/formular/" . $formular->directory );

  };
}

sub remove {
  my $self = shift;

  my $pr   = $self->project( $self->param("project_dir") );
  my $form = $pr->get_formular( $self->param("formular_dir") );

  $form->remove;

  $self->flash(
    {
      title   => "Formular removed",
      message => "Formular <b>" . $form->name . "</b> removed.",
    }
  );

  $self->redirect_to( "/project/" . $pr->directory );
}

1;
