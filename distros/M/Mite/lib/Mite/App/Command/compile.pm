package Mite::App::Command::compile;

use feature ':5.10';
use Mouse;
use MouseX::Foreign;
extends qw(Mite::App::Command);

use Method::Signatures;
use Path::Tiny;
use Carp;

method abstract() {
    return "Make your code ready to run";
}


method execute($opts, $args) {
    return if $self->should_exit_quietly($opts);

    my $config = Mite::Config->new(
        search_for_mite_dir => $opts->{search_mite_dir}
    );
    my $project = Mite::Project->new(
        config => $config
    );
    Mite::Project->set_default( $project );

    $project->add_mite_shim;
    $project->load_directory;
    $project->write_mites;

    return;
}

1;
