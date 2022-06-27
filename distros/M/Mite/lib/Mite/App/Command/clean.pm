package Mite::App::Command::clean;
use Mite::MyMoo;
extends qw(Mite::App::Command);

sub abstract {
    return "Remove compiled mite files";
}

sub execute {
    my ( $self, $opts, $args ) = ( shift, @_ );

    return if $self->should_exit_quietly($opts); 

    require Mite::Project;
    my $project = Mite::Project->default;
    $project->clean_mites;
    $project->clean_shim;

    return;
}

1;
