# -*- perl -*-
# t/005-tab-new.t - check module loading and create testing directory
use 5.14.0;
use warnings;
use Capture::Tiny ( qw| capture_stdout capture_stderr | );
use Carp;
use Cwd;
use File::Path 2.15 (qw| make_path |);
use File::Spec;
use File::Temp ( qw| tempfile tempdir |);
use Test::More;

BEGIN { use_ok( 'Test::Against::Build' ); }

my $cwd = cwd();
my $self;

##### new(): TESTS OF ERROR CONDITIONS #####

{
    local $@;
    eval { $self = Test::Against::Build->new([]); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for non-hashref argument");
}

{
    local $@;
    eval { $self = Test::Against::Build->new(); };
    like($@, qr/Argument to constructor must be hashref/,
        "new: Got expected error message for no argument");
}

{
    my $tdir1 = tempdir(CLEANUP => 1);
    local $@;
    eval {
        $self = Test::Against::Build->new({
            results_tree => $tdir1,
        });
    };
    like($@, qr/Hash ref must contain 'build_tree' element/,
        "new: Got expected error message; 'build_tree' element absent");
}

{
    my $tdir1 = tempdir(CLEANUP => 1);
    local $@;
    eval {
        $self = Test::Against::Build->new({
            build_tree => $tdir1,
        });
    };
    like($@, qr/Hash ref must contain 'results_tree' element/,
        "new: Got expected error message; 'results_tree' element absent");
}

{
    my $tdir1 = tempdir(CLEANUP => 1);
    local $@;
    my $phony_dir = '/foo';
    eval {
        $self = Test::Against::Build->new({
            build_tree => $tdir1,
            results_tree => $phony_dir,
        });
    };
    like($@, qr/Could not locate directory '$phony_dir' for 'results_tree'/,
        "new: Got expected error message; 'results_tree' not found");
}

{
    my $tdir1 = tempdir(CLEANUP => 1);
    local $@;
    eval {
        $self = Test::Against::Build->new({
            build_tree => $tdir1,
            results_tree => $tdir1,
        });
    };
    like($@, qr/Arguments for 'build_tree' and 'results_tree' must be different directories/,
        "new: Got expected error message; 'build_tree' and 'results_tree' are same directory");
}

##### new(): TESTS OF CORRECTLY BUILT OBJECTS #####

{
    my $tdir1 = tempdir(CLEANUP => 1);
    my $tdir2 = tempdir(CLEANUP => 1);
    setup_test_directories($tdir1, $tdir2);
    $self = Test::Against::Build->new({
        build_tree => $tdir1,
        results_tree => $tdir2,
    });
    ok(defined $self, "new() returned defined object");
    isa_ok($self, 'Test::Against::Build');
    for my $d ('bin', 'lib', '.cpanm', '.cpanreporter') {
        my $expected_dir = File::Spec->catdir($tdir1, $d);
        ok(-d $expected_dir, "new() created '$expected_dir' for '$d' as expected");
    }
    ok(-d $self->get_build_tree, "get_build_tree() returned " . $self->get_build_tree);
    ok(-d $self->get_bin_dir, "get_bin_dir() returned " . $self->get_bin_dir);
    ok(-d $self->get_lib_dir, "get_lib_dir() returned " . $self->get_lib_dir);
    ok(-d $self->get_cpanm_dir, "get_cpanm_dir() returned " . $self->get_cpanm_dir);
    ok(-d $self->get_cpanreporter_dir, "get_cpanreporter_dir() returned " . $self->get_cpanreporter_dir);
    ok(-d $self->get_results_tree, "get_results_tree() returned " . $self->get_results_tree);
    ok(-d $self->get_analysis_dir, "get_analysis_dir() returned " . $self->get_analysis_dir);
    ok(-d $self->get_buildlogs_dir, "get_buildlogs_dir() returned " . $self->get_buildlogs_dir);
    ok(-d $self->get_storage_dir, "get_storage_dir() returned " . $self->get_storage_dir);
    ok(! $self->is_perl_built, "perl executable not yet installed in " . $self->get_bin_dir);
    ok(! $self->is_cpanm_built, "cpanm executable not yet installed in " . $self->get_bin_dir);
}

{
    my $tdir1 = tempdir(CLEANUP => 1);
    my $tdir2 = tempdir(CLEANUP => 1);
    setup_test_directories($tdir1, $tdir2);
    my $stdout = capture_stdout {
        $self = Test::Against::Build->new({
            build_tree => $tdir1,
            results_tree => $tdir2,
            verbose => 1,
        });
    };
    ok(defined $self, "new() returned defined object");
    isa_ok($self, 'Test::Against::Build');
    like($stdout,
        qr/Located directory '$tdir1' for 'build_tree'/s,
        "Got expected verbose output"
    );
    like($stdout,
        qr/Located directory '$tdir2' for 'results_tree'/s,
        "Got expected verbose output"
    );
    ok(-d $self->get_build_tree, "get_build_tree() returned " . $self->get_build_tree);
    ok(-d $self->get_bin_dir, "get_bin_dir() returned " . $self->get_bin_dir);
    ok(-d $self->get_lib_dir, "get_lib_dir() returned " . $self->get_lib_dir);
    ok(-d $self->get_cpanm_dir, "get_cpanm_dir() returned " . $self->get_cpanm_dir);
    ok(-d $self->get_cpanreporter_dir, "get_cpanreporter_dir() returned " . $self->get_cpanreporter_dir);
    ok(-d $self->get_results_tree, "get_results_tree() returned " . $self->get_results_tree);
    ok(-d $self->get_analysis_dir, "get_analysis_dir() returned " . $self->get_analysis_dir);
    ok(-d $self->get_buildlogs_dir, "get_buildlogs_dir() returned " . $self->get_buildlogs_dir);
    ok(-d $self->get_storage_dir, "get_storage_dir() returned " . $self->get_storage_dir);
    ok(! $self->is_perl_built, "perl executable not yet installed in " . $self->get_bin_dir);
    ok(! $self->is_cpanm_built, "cpanm executable not yet installed in " . $self->get_bin_dir);
}

note("Set PERL_AUTHOR_TESTING_INSTALLED_PERL to run additional tests against installed 'perl' and 'cpanm'")
    unless $ENV{PERL_AUTHOR_TESTING_INSTALLED_PERL};

# Must set above envvar to a complete path ending in /bin/perl.

##### run_cpanm(): TESTS AGAINST PRE-INSTALLED perl #####

SKIP: {
    skip 'Test assumes installed perl and cpanm', 55
        unless $ENV{PERL_AUTHOR_TESTING_INSTALLED_PERL};

    note("Testing against pre-installed perl executable");

    my $good_perl = $ENV{PERL_AUTHOR_TESTING_INSTALLED_PERL};
    croak "Could not locate '$good_perl'" unless (-x $good_perl);
    my ($good_path) = $good_perl =~ s{^(.*?)/bin/perl$}{$1}r;
    my $tdir2 = tempdir(CLEANUP => 1);
    setup_test_directories_results_only($tdir2);
    $self = Test::Against::Build->new({
        build_tree => $good_path,
        results_tree => $tdir2,
    });
    ok(defined $self, "new() returned defined object");
    isa_ok($self, 'Test::Against::Build');
    for my $d ('bin', 'lib', '.cpanm', '.cpanreporter') {
        my $expected_dir = File::Spec->catdir($good_path, $d);
        ok(-d $expected_dir, "new() created '$expected_dir' for '$d' as expected");
    }
    ok(-d $self->get_build_tree, "get_build_tree() returned " . $self->get_build_tree);
    ok(-d $self->get_bin_dir, "get_bin_dir() returned " . $self->get_bin_dir);
    ok(-d $self->get_lib_dir, "get_lib_dir() returned " . $self->get_lib_dir);
    ok(-d $self->get_cpanm_dir, "get_cpanm_dir() returned " . $self->get_cpanm_dir);
    ok(-d $self->get_cpanreporter_dir, "get_cpanreporter_dir() returned " . $self->get_cpanreporter_dir);
    ok(-d $self->get_results_tree, "get_results_tree() returned " . $self->get_results_tree);
    ok(-d $self->get_analysis_dir, "get_analysis_dir() returned " . $self->get_analysis_dir);
    ok(-d $self->get_buildlogs_dir, "get_buildlogs_dir() returned " . $self->get_buildlogs_dir);
    ok(-d $self->get_storage_dir, "get_storage_dir() returned " . $self->get_storage_dir);
    ok($self->is_perl_built, "perl executable previously installed in " . $self->get_bin_dir);
    ok($self->is_cpanm_built, "cpanm executable previously installed in " . $self->get_bin_dir);

    {
        note("run_cpanm(): Error conditions");
        {
            local $@;
            eval { $self->run_cpanm( [ module_file => 'foo', title => 'not-cpan-river' ] ); };
            like($@, qr/run_cpanm: Must supply hash ref as argument/,
                "Got expected error message: absence of hashref");
        }

        {
            local $@;
            my $bad_element = 'foo';
            eval { $self->run_cpanm( { $bad_element => 'bar', title => 'not-cpan-river' } ); };
            like($@, qr/run_cpanm: '$bad_element' is not a valid element/,
                "Got expected error message: bad argument");
        }

        {
            local $@;
            eval { $self->run_cpanm( {
                module_file => 'foo',
                module_list => [ 'Foo::Bar', 'Alpha::Beta' ],
                title => 'not-cpan-river',
            } ); };
            like($@, qr/run_cpanm: Supply either a file for 'module_file' or an array ref for 'module_list' but not both/,
                "Got expected error message: bad mixture of arguments");
        }

        {
            local $@;
            my $bad_module_file = 'foo';
            eval { $self->run_cpanm( { module_file => $bad_module_file, title => 'not-cpan-river' } ); };
            like($@, qr/run_cpanm: Could not locate '$bad_module_file'/,
                "Got expected error message: module_file not found");
        }

        {
            local $@;
            eval { $self->run_cpanm( { module_list => "Foo::Bar", title => 'not-cpan-river' } ); };
            like($@, qr/run_cpanm: Must supply array ref for 'module_list'/,
                "Got expected error message: value for module_list not an array ref");
        }

        {
            local $@;
            my $list = [
                map { File::Spec->catfile($cwd, 't', 'data', $_) }
                ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
            ];
            eval {
                $self->run_cpanm( {
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
                map { File::Spec->catfile($cwd, 't', 'data', $_) }
                ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
            ];
            eval {
                $self->run_cpanm( {
                    module_list => $list,
                    title => '',
                } );
            };
            like($@, qr/Must supply value for 'title' element/,
                "Got expected error message: value for title is empty string");
        }
    }

    {
        note("run_cpanm(): Testing via 'module_list'");
        local $@;
        my $list = [
            map { File::Spec->catfile($cwd, 't', 'data', $_) }
            ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
        ];

        # TODO: Add tests which capture verbose output and match it against
        # expectations.

        my $gzipped_build_log;
        my $stdout = capture_stdout {
            $gzipped_build_log = $self->run_cpanm( {
                module_list => $list,
                title       => 'one-pass-one-fail',
                verbose     => 1,
            } );
        };
        unless ($@) {
            pass("run_cpanm operated as intended; see $gzipped_build_log for PASS/FAIL/etc.");
        }
        else {
            fail("run_cpanm did not operate as intended: $@");
        }
        ok(-f $gzipped_build_log, "Located $gzipped_build_log");
        like($stdout,
            qr/cpanm_dir:.*?\.cpanm/s,
            "run_cpanm(): Got expected verbose output: cpanm_dir"
        );
        like($stdout,
            qr/See gzipped build.log in $gzipped_build_log/s,
            "run_cpanm(): Got expected verbose output: build.log"
        );
    }

    {
        note("run_cpanm(): Testing via 'module_file'");
        local $@;
        my $list = [
            map { File::Spec->catfile($cwd, 't', 'data', $_) }
            ( qw| Phony-PASS-0.01.tar.gz Phony-FAIL-0.01.tar.gz  | )
        ];
        my ($IN, $file) = tempfile('005_files_for_cpanm_XXXXX', UNLINK => 1);
        open $IN, '>', $file or croak "Could not open $file for writing";
        say $IN $_ for @{$list};
        close $IN or croak "Could not close $file after writing";
        ok(-f $file, "Located $file for testing");
        my $gzipped_build_log = $self->run_cpanm( {
            module_file => $file,
            title       => 'second-one-pass-one-fail',
        } );
        unless ($@) {
            pass("run_cpanm operated as intended; see $gzipped_build_log for PASS/FAIL/etc.");
        }
        else {
            fail("run_cpanm did not operate as intended");
        }
        ok(-f $gzipped_build_log, "Located $gzipped_build_log");
    }

    note("analyze_cpanm_build_logs()");

    my $ranalysis_dir;
    {
        local $@;
        eval { $self = Test::Against::Build->analyze_cpanm_build_logs([]); };
        like($@, qr/analyze_cpanm_build_logs: Must supply hash ref as argument/,
            "analyze_cpanm_build_logs: Got expected error message for non-hashref argument");
    }

    {
        local $@;
        eval { $self = Test::Against::Build->analyze_cpanm_build_logs(); };
        like($@, qr/analyze_cpanm_build_logs: Must supply hash ref as argument/,
            "analyze_cpanm_build_logs: Got expected error message for no argument");
    }

    {
        local $@;
        eval { $ranalysis_dir = $self->analyze_cpanm_build_logs( [ verbose => 1 ] ); };
        like($@, qr/analyze_cpanm_build_logs: Must supply hash ref as argument/,
            "analyze_cpanm_build_logs(): Got expected error message for lack of hash ref");
    }

    my $stdout = capture_stdout {
        $ranalysis_dir = $self->analyze_cpanm_build_logs( { verbose => 1 } );
    };
    ok(-d $ranalysis_dir,
        "analyze_cpanm_build_logs() returned path to version-specific analysis directory '$ranalysis_dir'");
    like($stdout,
        qr/See results in $ranalysis_dir/s,
        "analyze_cpanm_build_logs(): Got expected verbose output: cpanm_dir"
    );

    note("analyze_json_logs()");

    my $rv;
    {
        local $@;
        eval { $rv = $self->analyze_json_logs( verbose => 1 ); };
        like($@, qr/analyze_json_logs: Must supply hash ref as argument/,
            "analyze_json_logs(): Got expected error message: absence of hash ref");
    }

    {
        local $@;
        eval { $rv = $self->analyze_json_logs( { verbose => 1, sep_char => "\t" } ); };
        like($@, qr/analyze_json_logs: Currently only pipe \('\|'\) and comma \(','\) are supported as delimiter characters/,
            "analyze_json_logs(): Got expected error message: unsupported delimiter");
    }

    my $fpsvfile = $self->analyze_json_logs( { verbose => 1 } );
    ok($fpsvfile, "analyze_json_logs() returned true value");
    ok(-f $fpsvfile, "Located '$fpsvfile'");

    my $fcsvfile = $self->analyze_json_logs( { verbose => 1 , sep_char => ',' } );
    ok($fcsvfile, "analyze_json_logs() returned true value");
    ok(-f $fcsvfile, "Located '$fcsvfile'");
}

#################### TESTING SUBROUTINES ####################

sub setup_test_directories {
    my ($tdir1, $tdir2) = @_;
    my @created = make_path(
        File::Spec->catdir($tdir1, 'bin'),
        File::Spec->catdir($tdir1, 'lib'),
        File::Spec->catdir($tdir1, '.cpanm'),
        File::Spec->catdir($tdir1, '.cpanreporter'),
        File::Spec->catdir($tdir2, 'analysis'),
        File::Spec->catdir($tdir2, 'buildlogs'),
        File::Spec->catdir($tdir2, 'storage'),
        { mode => 0711 }
    );
    return scalar @created;
}

sub setup_test_directories_results_only {
    my ($tdir2) = @_;
    my @created = make_path(
        File::Spec->catdir($tdir2, 'analysis'),
        File::Spec->catdir($tdir2, 'buildlogs'),
        File::Spec->catdir($tdir2, 'storage'),
        { mode => 0711 }
    );
    return scalar @created;
}


done_testing();

