package Mite::App::Command;

use Mouse;
use MouseX::Foreign;
extends qw(App::Cmd::Command);

use Method::Signatures;


method opt_spec($class: $app) {
    return(
      [ "search-mite-dir!" => "only look for .mite/ in the current directory",
        { default => 1 } ],
      [ "exit-if-no-mite-dir!" => "exit quietly if a .mite dir cannot be found",
        { default => 0 } ],
      $class->options($app)
    );
}


method options($class: $app) {
    return;
}


method should_exit_quietly($opts) {
    my $config = $self->config;

    return unless $opts->{exit_if_no_mite_dir};
    return 1 if !$opts->{search_mite_dir} && !$config->dir_has_mite(".");
    return 1 if !$config->find_mite_dir;
}


method project() {
    require Mite::Project;
    return Mite::Project->default;
}

method config() {
    return $self->project->config;
}


1;
