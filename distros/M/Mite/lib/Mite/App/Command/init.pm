package Mite::App::Command::init;

use feature ':5.10';

use Mouse;
use MouseX::Foreign;
extends qw(Mite::App::Command);

use Method::Signatures;
use Carp;

method usage_desc(...) {
    return "%c init %o <project name>";
}

method abstract() {
    return "Begin using mite with your project";
}

method validate_args($opt, $args) {
    $self->usage_error("init needs the name of your project") unless @$args;
}

method execute($opt, $args) {
    my $project_name = shift @$args;

    require Mite::Project;
    my $project = Mite::Project->default;
    $project->init_project($project_name);

    say sprintf "Initialized mite in %s", $project->config->mite_dir;

    return;
}

1;
