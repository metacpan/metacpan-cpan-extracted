package Mite::App::Command::init;
use Mite::MyMoo;
extends qw(Mite::App::Command);

sub usage_desc {
    return "%c init %o <project name>";
}

sub abstract {
    return "Begin using mite with your project";
}

sub validate_args {
    my ( $self, $opts, $args ) = ( shift, @_ );

    $self->usage_error("init needs the name of your project") unless @$args;
}

sub execute {
    my ( $self, $opts, $args ) = ( shift, @_ );

    my $project_name = shift @$args;

    require Mite::Project;
    my $project = Mite::Project->default;
    $project->init_project($project_name);

    say sprintf "Initialized mite in %s", $project->config->mite_dir;

    return;
}

1;
