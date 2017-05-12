use 5.008;
use ExtUtils::MakeMaker;

use DynaLoader;

sub have_functions {
    my ($lib, @funcs) = @_;
    my @found = ();

    $lib = "-l$lib" unless $lib =~ /^-l/;

    my $path = (DynaLoader::dl_findfile( $lib ))[0];
    if ($path) {
        my $libref = DynaLoader::dl_load_file($path);
        for my $f (@funcs) {
            my $symref = DynaLoader::dl_find_symbol($libref, $f);
            push @found, $f if defined $symref;
        }
    }

    @found;
}

sub psem_defines {
    my $lib = shift;
    my @semfunc = qw(sem_destroy sem_getvalue sem_init sem_open
                     sem_post sem_timedwait sem_trywait sem_unlink
                     sem_wait);

    return join(' ', map { '-DHAVE_' . uc($_) } have_functions($lib, @semfunc));
}

WriteMakefile(
    'NAME'          => 'POSIX::RT::Semaphore',
    'VERSION_FROM'  => 'Semaphore.pm', # finds $VERSION
    'PREREQ_PM'     => {},
    'AUTHOR'        => 'mjp <mjp@pilcrow.madison.wi.us>',
    'LIBS'          => ['-lrt'],             #
    'DEFINE'        => psem_defines('-lrt'), # redo in hints/*, if needed
    'INC'           => '-I.',
);
