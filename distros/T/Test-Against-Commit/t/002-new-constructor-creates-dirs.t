# -*- perl -*-
# t/002-new-constructor-creates-dirs.t
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

{
    # In this block, project*, install*, testing* and results_dir
    # directories are NOT created prior to calling the constructor
    note("Several directories for testing NOT created before calling constructor");

    my $tdir2 = File::Spec->catdir($cwd, time());
    if (-d $tdir2) {
        my $removed_count = remove_tree($tdir2,
            { verbose => 1, error  => \my $err_list, safe => 1, });
    }
    make_path($tdir2, { mode => 0755 })
        or croak "Unable to create $tdir2 for testing";

    my $self;
    my $application_dir = $tdir2;
    my $project = 'goto-fatal';
    my $install = 'blead';
    my %verified = ();
    # paths_needed:
    my $project_dir = File::Spec->catdir($application_dir, $project);
    my $install_dir = File::Spec->catdir($project_dir, $install);
    my $testing_dir = File::Spec->catdir($install_dir, 'testing');
    my $results_dir = File::Spec->catdir($install_dir, 'results');

    $self = Test::Against::Commit->new( {
        application_dir         => $tdir2,
        project                 => $project,
        install                  => $install,
    } );
    ok($self, "new() returned true value");
    isa_ok($self, 'Test::Against::Commit');

    my $top_dir = $self->get_application_dir;
    is($top_dir, $tdir2, "Located top-level directory $top_dir");

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
        eval { $self->prepare_testing_directory(); };
        like($@, qr/Could\ not\ locate.*?;\ have\ you\ built\ and\ installed\ a\ perl\ executable\?/,
            "Got exception for premature prepare_testing_directory()");
    }

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
    my $removed_count = remove_tree($tdir2,
        { verbose => '', error  => \my $err_list, safe => 1, }
    );
}

done_testing();
