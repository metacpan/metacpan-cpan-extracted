package builder::MyBuilder;
use strict;
use warnings;
use utf8;

use parent qw(Module::Build);
use File::Copy;
use Config;

sub new {
    my ( $self, %args ) = @_;
    $self->SUPER::new(
        %args,
        include_dirs => [qw(pvip/src/)],
        extra_linker_flags => '-Lpvip -lpvip',
    );
}

sub ACTION_code {
    my ($self) = @_;

    {
        my $cwd = Cwd::getcwd();
        chdir 'pvip';
        $self->do_system($Config{make});
        chdir $cwd;
    }

    $self->process_PL_files;

    {
        my $b = $self->cbuilder();

        my $obj_file = $b->compile(
            source               => 'bin/seis.c',
        );
        my $exe_file = $b->link_executable(objects => $obj_file);

        # script_files is set here as the resulting compiled
        # executable name varies based on operating system
        $self->script_files($exe_file);

        # Cleanup files from compilation
        $self->add_to_cleanup($obj_file, $exe_file);
    }

    $self->SUPER::ACTION_code();
}

sub ACTION_clean {
    my ($self) = @_;
    {
        my $cwd = Cwd::getcwd();
        chdir 'pvip';
        $self->do_system($Config{make}, 'clean');
        chdir $cwd;
    }
    $self->SUPER::ACTION_clean();
}

1;

