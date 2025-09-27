# -*- perl -*-
# t/001-new.t
# Check module loading, creation of testing directories
# Does not presume 'git' or installation of perl executable
use strict;
use warnings;

use Test::More;
use Carp;
use Cwd;
use File::Path ( qw| make_path remove_tree | );
use File::Spec;
use File::Temp ( qw| tempdir |);
use Data::Dump ( qw| dd pp | );

BEGIN { use_ok( 'Test::Against::Commit' ); }

my $cwd = cwd();
my $tdir = File::Spec->catdir($cwd, time());
if (-d $tdir) {
    my $removed_count = remove_tree($tdir,
        { verbose => 1, error  => \my $err_list, safe => 1, });
}
make_path($tdir, { mode => 0755 })
    or croak "Unable to create $tdir for testing";

my $self;

# Error conditions for new() which can be tested by non-author users
{
    local $@;
    eval { $self = Test::Against::Commit->new([]); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for non-hashref argument");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new(); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for no argument");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new({ project => 'goto-fatal', install => 'blead' }); };
    like($@, qr/Hash ref must contain 'application_dir' element/,
        "new: Got expected error message; 'application_dir' element absent");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new({ application_dir => $tdir, project => 'goto-fatal' }); };
    like($@, qr/Hash ref must contain 'install' element/,
        "new: Got expected error message; 'install' element absent");
}

{
    local $@;
    eval { $self = Test::Against::Commit->new({ application_dir => $tdir, install => 'blead' }); };
    like($@, qr/Must supply name for project/,
        "new: Got expected error message; 'project' element absent");
}

{
    local $@;
    my $phony_dir = '/foo';
    eval { $self = Test::Against::Commit->new({
           application_dir => $phony_dir,
           install => 'blead',
           project => 'goto-fatal',
       });
    };
    like($@, qr/Could not locate application directory $phony_dir/,
        "new: Got expected error message; 'application_dir' not found");
}

{
    # In this block, project*, install*, testing* and results_dir
    # directories are created prior to calling the constructor
    note("Several directories for testing ARE created before calling constructor");

    my $tdir = File::Spec->catdir($cwd, time().'abc');
    if (-d $tdir) {
        my $removed_count = remove_tree($tdir,
            { verbose => 1, error  => \my $err_list, safe => 1, });
    }
    make_path($tdir, { mode => 0755 })
        or croak "Unable to create $tdir for testing";

    my $application_dir = $tdir;
    my $project = 'goto-fatal';
    my $install = 'blead';
    my %verified = ();
    # paths_needed:
    my $project_dir = File::Spec->catdir($application_dir, $project);
    my $install_dir = File::Spec->catdir($project_dir, $install);
    my $testing_dir = File::Spec->catdir($install_dir, 'testing');
    my $results_dir = File::Spec->catdir($install_dir, 'results');

    my @dirs_needed = ( $project_dir, $install_dir, $testing_dir, $results_dir );
    for my $dir ( @dirs_needed ) {
        unless (-d $dir) {
            make_path($dir, { mode => 0755 })
                or croak "Unable to create $dir for testing";
        }
        ok(-d $dir, "Created $dir for testing");
    }

    $self = Test::Against::Commit->new( {
        application_dir         => $tdir,
        project                 => $project,
        install                  => $install,
    } );
    ok($self, "new() returned true value");
    isa_ok($self, 'Test::Against::Commit');

    my $top_dir = $self->get_application_dir;
    is($top_dir, $tdir, "Located top-level directory $top_dir");

    $project_dir = $self->get_project_dir;
    ok(-d $project_dir, "Got project directory: $project_dir");

    $install_dir = $self->get_install_dir;
    ok(-d $install_dir, "Got install directory: $install_dir");

    $testing_dir = $self->get_testing_dir;
    ok(-d $testing_dir, "Got testing directory: $testing_dir");

    $results_dir = $self->get_results_dir;
    ok(-d $results_dir, "Got results directory: $results_dir");

    is($self->get_install(), $install, "Got expected install");

    {
        local $@;
        eval { $self->get_bin_dir(); };
        like($@, qr/bin directory has not yet been defined/,
            "Got exception for premature get_bin_dir()");
    }

    {
        local $@;
        eval { $self->get_lib_dir(); };
        like($@, qr/lib directory has not yet been defined/,
            "Got exception for premature get_lib_dir()");
    }

    {
        local $@;
        eval { $self->get_this_perl(); };
        like($@, qr/bin directory has not yet been defined/,
            "No bin dir, hence no possibility of installed perl");
    }

    {
        local $@;
        eval { $self->get_this_cpanm(); };
        like($@, qr/location of cpanm has not yet been defined/,
            "Got exception for premature get_this_cpanm()");
    }

    {
        local $@;
        eval { $self->get_cpanm_dir(); };
        like($@, qr/cpanm directory has not yet been defined/,
            "Got exception for premature get_cpanm_dir()");
    }
    chdir $cwd;
    END {
        my $removed_count = remove_tree($tdir,
            { verbose => '', error  => \my $err_list, safe => 1, }
        );
    }
}

done_testing();
