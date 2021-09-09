use strict;
use warnings;

package Smartcat::App::Command;
use App::Cmd::Setup -command;

use Cwd qw(abs_path);
use File::Basename;

sub opt_spec {
    return (
        #[ 'config:s' => 'Config file path' ],
        [ 'token-id:s' => 'Smartcat account id' ],
        [ 'token:s'    => 'API token' ],
        [ 'log:s'      => 'Log file path' ],
        [ 'base-url:s' => 'Base Smartcat URL' ],
        [ 'debug'      => 'Debug mode' ]
    );
}

sub project_id_opt_spec {
    return ( [ 'project-id:s' => 'Project Id' ], );
}

sub project_workdir_opt_spec {
    return ( [ 'project-workdir:s' => 'Project translation files path' ], );
}

sub file_params_opt_spec {
    return (
        [ 'filetype:s' => 'Type of translation files' ],
    );
}

sub extract_id_from_name_opt_spec {
    return (
        [ 'extract-id-from-name' => 'Extract stable external document identifiers from filenames in "name---id.ext" format for comparison and automatic renaming' ],
    );
}

sub external_tag_opt_spec {
    return (
        ['external-tag:s' => 'Set custom external tag for project. Default value: "source:Serge"']
    );
}

sub validate_file_params {
    my ( $self, $opt, $args ) = @_;
    my $rundata = $self->app->{rundata};
    $rundata->{filetype} = defined $opt->{filetype} ? $opt->{filetype} : '.po';
}

sub validate_project_id {
    my ( $self, $opt, $args ) = @_;
    my $rundata = $self->app->{rundata};
    $self->usage_error("'project_id' is required")
      unless defined $opt->{project_id};
    $rundata->{project_id} = $opt->{project_id};
}

sub validate_project_workdir {
    my ( $self, $opt, $args ) = @_;

    my $rundata = $self->app->{rundata};
    $self->app->usage_error(
"'project_workdir', which is set to '$opt->{project_workdir}', does not point to a valid directory"
    ) unless -d $opt->{project_workdir};
    $rundata->{project_workdir} = abs_path( $opt->{project_workdir} );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $app     = $self->app;
    my $rundata = $self->app->{rundata};

    if ( defined $opt->{token_id} && defined $opt->{token} ) {
        $app->{config}->{username} = $opt->{token_id};
        $app->{config}->{password} = $opt->{token};
    }

    if ( defined $opt->{base_url} ) {
        $app->{config}->{base_url} = $opt->{base_url};
    }

    if ( defined $opt->{log} ) {
        $self->usage_error(
"directory of 'log', which is set to '$opt->{log}', does not point to a valid directory"
        ) unless -d dirname( $opt->{log} ) && -w _;
        $app->{config}->{log} = $opt->{log};
    }

    $self->usage_error(
"set auth params via 'config' command first or provide options '--token-id' and '--token'"
      )
      unless ( defined $app->{config}->username
        && defined $app->{config}->password );

    $rundata->{debug} = 1 if defined $opt->{debug};

    $app->init;
}

1;
