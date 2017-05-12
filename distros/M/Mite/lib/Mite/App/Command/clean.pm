package Mite::App::Command::clean;

use feature ':5.10';
use Mouse;
use MouseX::Foreign;
extends qw(Mite::App::Command);

use Method::Signatures;
use Path::Tiny;
use Carp;

method abstract() {
    return "Remove compiled mite files";
}

method execute($opts, $args) {
    return if $self->should_exit_quietly($opts); 

   require Mite::Project;
    my $project = Mite::Project->default;
    $project->clean_mites;
    $project->clean_shim;

    return;
}

1;
