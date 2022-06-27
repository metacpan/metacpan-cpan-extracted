package Mite::App::Command::compile;
use Mite::MyMoo;
extends qw(Mite::App::Command);

sub abstract {
    return "Make your code ready to run";
}

sub execute {
    my ( $self, $opts, $args ) = ( shift, @_ );

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
