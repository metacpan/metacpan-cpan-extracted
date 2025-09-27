# -*- perl -*-
# t/005-dryrun.t

# Presumes perl executable has been installed elsewhere on disk but does
# not assume that 'git' was used to install that perl

use strict;
use warnings;

use Test::More;
my $installed_perl;
BEGIN {
    $installed_perl = $ENV{PERL_AUTHOR_TESTING_INSTALLED_PERL};
    no warnings 'uninitialized';
    unless (-x $installed_perl) {
        plan skip_all=> "Could not locate plausible installed perl to use in testing";
    }
}

use Carp;
use Cwd;
use File::Temp ( qw| tempfile |);
use Capture::Tiny ( qw | capture_stdout | );
use Data::Dump ( qw| dd pp | );

BEGIN { use_ok( 'Test::Against::Commit' ); }

note("Presuming installed perl, testing new()");

# We can conduct testing with a real installed perl executable provided that
# we can locate one at a path like this:
#   /application_dir/project_dir/install_dir/bin/perl
# and reverse engineer the arguments for new().

# Call:
# PERL_AUTHOR_TESTING_INSTALLED_PERL=<path> \
#   prove -vb t/003-prepare-testing-directories.t

my $cwd = cwd;

{
    my $stdout = capture_stdout {
        system(qq{ $installed_perl -v | head -2 | tail -1 })
            and croak "Unable to call 'perl -v'";
    };
    chomp $stdout;
    like($stdout,
        qr/This\sis\sperl\s5,\sversion\s\d\d,\ssubversion\s\d/,
        "Got 'perl -v' output"
    );
}

my ($application_dir, $project, $install);
($application_dir, $project, $install) =
    $installed_perl =~ m{^(.*?) \/ ([^/]+) \/ ([^/]+) \/ testing \/ bin \/ perl$}x;

my $self = Test::Against::Commit->new( {
    application_dir         => $application_dir,
    project                 => $project,
    install                 => $install,
} );
ok($self, "new() returned true value");
isa_ok($self, 'Test::Against::Commit');

my ($top_dir, $project_dir, $install_dir, $testing_dir);

$top_dir = $self->get_application_dir;
is($top_dir, $application_dir, "Located top-level directory $top_dir");

$project_dir = $self->get_project_dir;
ok(-d $project_dir, "Got project directory: $project_dir");

$install_dir = $self->get_install_dir;
ok(-d $install_dir, "Got install directory: $install_dir");

$testing_dir = $self->get_testing_dir;
ok(-d $testing_dir, "Got testing directory: $testing_dir");

note("prepare_testing_directory()");

ok($self->prepare_testing_directory(),
    "prepare_testing_directory() returned true value");

my $bin_dir = $self->get_bin_dir();
ok(-d $bin_dir, "Located bin_dir at $bin_dir");

my $lib_dir = $self->get_lib_dir();
ok(-d $lib_dir, "Located lib_dir at $lib_dir");

my $this_perl = $self->get_this_perl();
ok(-x $this_perl, "Located executable perl at $this_perl");

my $this_cpan = $self->get_this_cpan();
ok(-x $this_cpan, "Located executable cpan at $this_cpan");

# While we have pre-installed perl, we have not yet installed cpanm. Hence the
# following tests should be valid.

note("fetch_cpanm() error conditions");

my $expected_cpanm = File::Spec->catfile($bin_dir, 'cpanm');

# Once we've installed cpanm (as we will do later in this file), the next two
# tests become irrelevant and should be skipped.
SKIP: {
    skip "cpanm already installed", 2
        if (-x $expected_cpanm);
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
}

note("fetch_cpanm()");

$self->fetch_cpanm();

my $this_cpanm = $self->get_this_cpanm();
is($this_cpanm, $expected_cpanm, "cpanm installed where expected");

my $expected_cpanm_dir = File::Spec->catdir($self->get_testing_dir, '.cpanm');
my $this_cpanm_dir = $self->get_cpanm_dir();
is($this_cpanm_dir, $expected_cpanm_dir, ".cpanm directory located as $this_cpanm_dir");

{
    # This method is not publicly called; it's invoked within run_cpanm().
    # I want to test it first so that I can update the directory names, names
    # of KVPs in the object; etc.

    note("setup_results_directories()");

    my %expected_results_dirs = ();
    $expected_results_dirs{analysis} = {
        file    => File::Spec->catdir($self->get_results_dir, 'analysis'),
    };
    $expected_results_dirs{storage} = {
        file    => File::Spec->catdir($self->get_results_dir, 'storage'),
    };

    for my $dir (keys %expected_results_dirs) {
        SKIP: {
            skip "$dir directory already installed", 1
            if (-d $expected_results_dirs{$dir}{file});
            local $@;
            my $method = "get_${dir}_dir";
            eval { $self->${method}(); };
            like($@,
                qr/$dir directory has not yet been defined/,
                "Got exception for as yet undefined $dir directory"
            );
        }
    }

    my $created = $self->setup_results_directories();

    for my $dir (keys %expected_results_dirs) {
        my $method = "get_${dir}_dir";
        my $rv = $self->${method}();
        ok(-d $rv, "Located $dir directory at $rv");
    }
}

{
    note("process_modules(): error conditions");

    {
        local $@;
        eval { $self->process_modules( ); };
        like($@, qr/process_modules: Must supply hash ref as argument/,
            "Got expected error message: absence of argument");
    }

    {
        local $@;
        eval { $self->process_modules( [ module_file => 'foo', title => 'not-cpan-river' ] ); };
        like($@, qr/process_modules: Must supply hash ref as argument/,
            "Got expected error message: absence of hashref");
    }

    {
        local $@;
        my $bad_element = 'foo';
        eval { $self->process_modules( { $bad_element => 'bar', title => 'not-cpan-river' } ); };
        like($@, qr/process_modules: '$bad_element' is not a valid element/,
            "Got expected error message: bad argument");
    }

    {
        local $@;
        eval { $self->process_modules( {
            module_file => 'foo',
            module_list => [ 'Foo::Bar', 'Alpha::Beta' ],
            title => 'not-cpan-river',
        } ); };
        like($@, qr/process_modules: Supply either a file for 'module_file' or an array ref for 'module_list' but not both/,
            "Got expected error message: bad mixture of arguments");
    }

    {
        local $@;
        eval { $self->process_modules( { title => 'not-cpan-river' } ); };
        like($@, qr/process_modules: Must supply one of 'module_file' or 'module_list'/,
            "Got expected error message: need one of module_file or module_list");
    }

    {
        local $@;
        my $bad_module_file = 'foo';
        eval { $self->process_modules( { module_file => $bad_module_file, title => 'not-cpan-river' } ); };
        like($@, qr/process_modules: Could not locate '$bad_module_file'/,
            "Got expected error message: module_file not found");
    }

    {
        local $@;
        eval { $self->process_modules( { module_list => "Foo::Bar", title => 'not-cpan-river' } ); };
        like($@, qr/process_modules: Must supply array ref for 'module_list'/,
            "Got expected error message: value for module_list not an array ref");
    }

    {
        local $@;
        my $list = [
            map { File::Spec->catfile($cwd, 't', 'data', 'M', 'ME', 'METATEST', $_) }
            ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
        ];
        eval {
            $self->process_modules( {
                module_list => $list,
                title => undef,
            } );
        };
        like($@, qr/Must supply value for 'title' element/,
            "Got expected error message: value for title is not defined");
    }

    {
        local $@;
        my $list = [
            map { File::Spec->catfile($cwd, 't', 'data', 'M', 'ME', 'METATEST', $_) }
            ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
        ];
        eval {
            $self->process_modules( {
                module_list => $list,
                title => '',
            } );
        };
        like($@, qr/Must supply value for 'title' element/,
            "Got expected error message: value for title is empty string");
    }
}

{
    {
        note("process_modules(): Testing via 'module_list'");
        local $@;
        my $list = [
            map { File::Spec->catfile($cwd, 't', 'data', 'M', 'ME', 'METATEST', $_) }
            ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
        ];

        my $modules_ref;
        my $stdout = capture_stdout {
            eval {
                $modules_ref = $self->process_modules( {
                    module_list => $list,
                    title       => 'one-pass-one-fail',
                    verbose     => 1,
                    dryrun      => 1,
                } );
            };
        };
        $@ ? fail("process_modules dryrun did not operate as intended: $@")
           : pass("process_modules dryrun operated as intended");
        ok(! defined $modules_ref, "dryrun: process_modules returned undefined value");
        ok(length $stdout, "STDOUT was captured");
        like($stdout, qr/Planning to process \d+ modules/ms,
            "Got expected dryrun message"
        );
    }

    {
        note("process_modules(): Testing via 'module_file'");
        local $@;
        my $list = [
            map { File::Spec->catfile($cwd, 't', 'data', 'M', 'ME', 'METATEST', $_) }
            ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
        ];
        my ($IN, $file) = tempfile('005_files_for_cpanm_XXXXX', UNLINK => 1);
        open $IN, '>', $file or croak "Could not open $file for writing";
        say $IN $_ for @{$list};
        say $IN "# Commented::Out::Module";
        close $IN or croak "Could not close $file after writing";
        ok(-f $file, "Located $file for testing");

        my $modules_ref;
        my $stdout = capture_stdout {
            eval {
                $modules_ref = $self->process_modules( {
                    module_file => $file,
                    title       => 'second-one-pass-one-fail',
                    dryrun      => 1,
                } );
            };
        };
        $@ ? fail("process_modules did not operate as intended: $@")
           : pass("process_modules operated as intended");
        ok(! defined $modules_ref, "dryrun: process_modules returned undefined value");
        ok(length $stdout, "STDOUT was captured");
        like($stdout, qr/Planning to process \d+ modules/ms,
            "Got expected dryrun message"
        );
    }

}

done_testing();
