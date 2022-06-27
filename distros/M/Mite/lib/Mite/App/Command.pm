package Mite::App::Command;
use Mite::MyMoo;
extends qw(App::Cmd::Command);

sub opt_spec {
    my ($class, $app) = (shift, @_);

    return(
      [ "search-mite-dir!" => "only look for .mite/ in the current directory",
        { default => 1 } ],
      [ "exit-if-no-mite-dir!" => "exit quietly if a .mite dir cannot be found",
        { default => 0 } ],
      $class->options($app)
    );
}


sub options {
    my ($class, $app) = (shift, @_);

    return;
}


sub should_exit_quietly {
    my ($self, $opts) = (shift, @_);

    my $config = $self->config;

    return unless $opts->{exit_if_no_mite_dir};
    return 1 if !$opts->{search_mite_dir} && !$config->dir_has_mite(".");
    return 1 if !$config->find_mite_dir;
}


sub project {
    require Mite::Project;
    return Mite::Project->default;
}

sub config {
    my $self = shift;

    return $self->project->config;
}


1;
