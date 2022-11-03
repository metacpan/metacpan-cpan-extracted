#!/usr/bin/perl
# t/010_fetch_reqs.t - test bin/fetch-reqs.pl script
use strict;
use warnings;
use utf8;
use autodie;
use open ':std', ':encoding(utf8)';
use Carp qw(carp croak);
use Readonly;
use Config;
use File::Temp;
use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Slurp qw(slurp);
use Cwd qw(abs_path);

# Initial attempt at these tests in 0.3.0 didn't go over well with CPAN Testers. Container tests
# confirmed their problems but so far haven't found settings that work to capture CPAN build
# outputs both on a desktop CLI and in the the container environment. Re-enable when working...
use Test::More skip_all => 'deactivate these tests until multi-platform issues are fixed';

# configuration & constants
Readonly::Scalar my $script_name => "bin/fetch-reqs.pl";
Readonly::Scalar my $debug_mode => (exists $ENV{SYS_OSPACKAGE_DEBUG} and $ENV{SYS_OSPACKAGE_DEBUG}) ? 1 : 0;
Readonly::Array my @inc_configs => qw(installarchlib installprivlib installvendorlib installsitelib);
Readonly::Scalar my $input_dir => "t/test-inputs/".basename($0, ".t");
Readonly::Scalar my $tmpdir_template => "Sys-OsPackage-XXXXXXXXXX";
Readonly::Scalar my $new_dir_perms => oct('770');
Readonly::Scalar my $new_file_perms => oct('660');
Readonly::Scalar my $xdg_data_home => ".local/share";
Readonly::Scalar my $xdg_userdirs_conf => "user-dirs.dirs";
Readonly::Scalar my $cpan_home_subpath => ".cpan";
Readonly::Array my @cpan_home_subdirs => qw(build  CPAN prefs  sources);
Readonly::Scalar my $cpanm_home_subpath => ".cpanm";
Readonly::Array my @local_lib_dedup => qw(PERL5LIB PATH MANPATH);
Readonly::Array my @local_lib_keep => ( qw(HOME), @local_lib_dedup );
Readonly::Array my @local_lib_clear => qw(PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT);
Readonly::Array my @local_lib_vars => ( @local_lib_keep, @local_lib_clear );
Readonly::Hash my %tests => (
    existent => {
        'Acme' => {
            files => [qw(
                man/man3/Acme.3pm
                man/man3/Spiffy.3pm
                lib/perl5/Acme.pod
                lib/perl5/Acme.pm
                lib/perl5/Spiffy.pm
                lib/perl5/Spiffy.pod
                lib/perl5/Spiffy/mixin.pm
            )],
        },
        'Acme::Boom' => {
            files => [qw(
                man/man3/Acme::Boom.3pm
                lib/perl5/Acme/Boom.pm
            )],
        },
        'List::Util::MaybeXS' => {
            files => [qw(
                man/man3/List::Util::MaybeXS.3pm
                man/man3/List::Util::PP.3pm
                lib/perl5/List/Util/MaybeXS.pm
                lib/perl5/List/Util/PP.pm
            )],
        },
    },
    nonexistent => {
        # make up new non-existent module(s) if any get created in CPAN
        # "Smackme" = word play on Acme, except doesn't exist in CPAN
        Smackme => {},
    },
);
Readonly::Scalar my $tests_per_exist => 2;
Readonly::Scalar my $tests_per_nonexist => 1;
Readonly::Scalar my $flag_variants => 2; # flag variants: --notest (2)
Readonly::Scalar my $param_variants => 2; # variants by param/pipe (2)

# save original environment variables used by local::lib so it doesn't find previous build tests
my %orig_local_env;

# remove duplicates from a colon-delimited path (i.e. $PATH, $PERL5LIB, $MANPATH, etc)
# also omit directories which do not exist
sub deduplicate_path
{
    my $in_path = shift;
    my ( @path, %path_seen );
    foreach my $dir ( split /:/, $in_path ) {
        # skip dot "." for security
        if ( $dir eq "." or $dir eq "" or not defined $dir ) {
            next;
        }

        # skip if the path doesn't exist or isn't a directory
        if (not -e $dir or not -d $dir) {
            next
        }

        # convert to canonical path
        my $abs_dir = abs_path($dir);

        # add the path if it hasn't already been seen, and it exists
        if (not exists $path_seen{$abs_dir} and -d $abs_dir) {
            push @path, $abs_dir;
        }
        $path_seen{$abs_dir} = 1;
    }
    return join ':', @path;
}

# set up temporary directory
# In order to test CPAN activity, we have to contain it into its own test directory with its own configuration.
# Borrow most of the CPAN configuration from the running user/machine if available.
# Returns a hash with paths used by the test environment.
sub init_tempdir
{
    my %paths;

    # if debug mode was set by SYS_OSPACKAGE_DEBUG in environment, don't delete it after test
    $paths{temp_dir} = File::Temp->newdir(TEMPLATE => $tmpdir_template, CLEANUP => ($debug_mode ? 0 : 1),
        PERMS => $new_dir_perms, TMPDIR => 1);
    $paths{current_link} = $paths{temp_dir}."/current";
    $paths{user_home} = $paths{temp_dir};
    $paths{install_base} = $paths{current_link};

    # dump original CPAN config for this user/machine into the test directory, if it existed
    $paths{cpanm_home} = $paths{temp_dir}."/".$cpanm_home_subpath;
    make_path ($paths{cpanm_home}, { mode => $new_dir_perms });
    $paths{cpan_home} = $paths{temp_dir}."/".$xdg_data_home."/".$cpan_home_subpath;
    make_path ($paths{cpan_home}, { mode => $new_dir_perms });
    foreach my $subdir ( @cpan_home_subdirs ) {
        mkdir $paths{cpan_home}."/".$subdir, $new_dir_perms;
    }
    $ENV{NONINTERACTIVE_TESTING}=1; # prevent CPAN from prompting if it sees a tty on stdin

    # reset HOME and CPAN config to prevent interference from user environment when running manually
    $ENV{HOME} = $paths{temp_dir};
    if (not exists $ENV{TMPDIR}) {
        $ENV{TMPDIR} = $paths{temp_dir}; # capture CPAN::Shell's temporary files in our log directory
    }

    # dump paths in debug mode
    if ( $debug_mode ) {
        printf STDERR "init_tempdir: ";
        foreach my $key ( keys %paths ) {
            printf STDERR "$key = ".$paths{$key}." ";
        }
        printf STDERR "\n";
    }

    return \%paths;
}

# get test directory
# rotate in a new test directory - use "current" symlink at the same name each round
sub get_test_dir
{
    my ( $paths_ref, $test_num ) = @_;
    $debug_mode and print STDERR "get_test_dir($test_num): start";

    # generate test-specific directory path and create the directory
    my $test_path = sprintf "%s/%03d", $paths_ref->{temp_dir}, $test_num;
    mkdir $test_path, $new_dir_perms;

    # make a "current" symlink to the current test directory
    if ( -e $paths_ref->{current_link} ) {
        unlink $paths_ref->{current_link};
    }
    symlink $test_path, $paths_ref->{current_link};

    # clear %ENV variables from local::lib and XDG_* which may interfere with CPAN in a test environment
    my @xdg_env_clear = grep { /^XDG_/ } keys %ENV;
    foreach my $clearname ( @local_lib_clear, @xdg_env_clear ) {
        delete $ENV{$clearname};
    }

    # set up fake XDG config to fool File::HomeDir which CPAN uses on many systems
    $ENV{XDG_CONFIG_DIR}=$paths_ref->{current_link}."/.config";
    $ENV{XDG_DATA_HOME} = $paths_ref->{temp_dir}."/".$xdg_data_home;
    make_path ($ENV{XDG_CONFIG_DIR}, { mode => $new_dir_perms });
    my $xdg_userdirs_path = $ENV{XDG_CONFIG_DIR}."/".$xdg_userdirs_conf;
    if (open(my $userdirs_fh, ">", $xdg_userdirs_path )) {
        print $userdirs_fh "\n"; # file just needs to exist - content optional
        close $userdirs_fh or carp "couldn't close $xdg_userdirs_path";
    } else {
        carp "couldn't create $xdg_userdirs_path";
    }

    # restore original values to variables that local::lib would otherwise accumulate info from previous tests
    foreach my $varname ( sort @local_lib_keep ) {
        if ( exists $orig_local_env{$varname} ) {
            $ENV{$varname} = $orig_local_env{$varname};
        } else {
            delete $ENV{$varname};
        }
    }

    # use local::lib to set test environment
    $debug_mode and print STDERR "get_test_dir($test_num): set local::lib";
    require local::lib;
    local::lib->import('--quiet', $paths_ref->{current_link});
    my %installer_options = local::lib->installer_options_for($paths_ref->{install_base});
    foreach my $opt ( keys %installer_options ) {
        if ( defined $installer_options{$opt} ) {
            $ENV{$opt} = $installer_options{$opt};
        }
    }
    if ( $debug_mode ) {
        foreach my $varname ( sort @local_lib_vars ) {
            printf STDERR "get_test_dir(%03d): %s = %s\n", $test_num, $varname, (exists $ENV{$varname}) ? $ENV{$varname} : "undef";
        }
    }

    # deduplicate paths from local::lib
    foreach my $varname ( @local_lib_dedup ) {
        if ( exists $ENV{$varname} ) {
            $ENV{$varname} = deduplicate_path($ENV{$varname});
        }
    }

    return $paths_ref->{current_link};
}

# run test on existing module
sub test_exist
{
    my ( $paths_ref, $test_num, $mod, $params ) = @_;
    $debug_mode and print STDERR "test_exist($test_num): start";
    my $test_dir = get_test_dir($paths_ref, $test_num);

    # test install
    my $use_pipe = (( exists $params->{use_pipe}) and $params->{use_pipe});
    my $pipe_label = $use_pipe ? "pipe" : "param";
    my $use_notest = (( exists $params->{use_pipe}) and $params->{use_notest});
    my $notest_param = $use_notest ? " --notest" : "";
    my $notest_label = $use_notest ? "notest" : "test";
    my $log_file = $test_dir."/output-log";
    my $test_cmd = $use_pipe
        ? "$script_name$notest_param $mod >$log_file 2>&1"
        : "echo $mod |$script_name$notest_param >$log_file 2>&1";
    my $retval = system $test_cmd;
    my $child_error = $?;
    my $err_msg = $!;
    if ($child_error == -1) {
        printf STDERR "test %03d: failed to execute: %s\n", $test_num, $err_msg;
    } elsif ($child_error & 127) {
        printf STDERR "test %03d: child died with signal %d, %s coredump\n", $test_num,
            ($child_error & 127),  ($child_error & 128) ? 'with' : 'without';
    } elsif ($child_error != 0) {
        printf STDERR "test %03d: child exited with value %d\n", $test_num, ($child_error >> 8);
    }
    is ( $retval >> 8, 0, sprintf("%03d/%s/%s: install %s, install should work", $test_num, $pipe_label, $notest_label,
        $mod ));

    # check if tests were run as expected
    my $has_no_tests = (( exists $params->{has_no_tests}) and $params->{has_no_tests});
    SKIP: {
        skip "$mod has no tests to check", 1 if $has_no_tests;
        my $log_content = slurp($log_file);
        if ( $use_notest ) {
            ok ( not( $log_content =~ qr/Result: (PASS|FAIL)/), sprintf("%03d/%s/%s: tests inhibited as expected",
                $test_num, $pipe_label, $notest_label ));
        } else {
            ok ( $log_content =~ qr/Result: (PASS|FAIL)/, sprintf("%03d/%s/%s: tests ran as expected", $test_num,
                $pipe_label, $notest_label ));
        }
    }

    # check if expected files exist
    if (( exists $params->{files}) and ref $params->{files} eq "ARRAY" ) {
        foreach my $filepath (@{$params->{files}}) {
            ok( -e $paths_ref->{current_link}."/".$filepath, sprintf "%03d/%s/%s: found %s", $test_num,
                $pipe_label, $notest_label, $filepath );
        }
    }

    return;
}

# run test on non-existent module
sub test_nonexist
{
    my ( $paths_ref, $test_num, $mod, $params ) = @_;
    $debug_mode and print STDERR "test_nonexist($test_num): start";
    my $test_dir = get_test_dir($paths_ref, $test_num);

    # test install
    my $use_pipe = (( exists $params->{use_pipe}) and $params->{use_pipe});
    my $pipe_label = $use_pipe ? "pipe" : "param";
    my $log_file = $test_dir."/output-log";
    my $test_cmd = $use_pipe
        ? "$script_name $mod >$log_file 2>&1"
        : "echo $mod |$script_name >$log_file 2>&1";
    my $retval = system $test_cmd;
    is ( $retval >> 8, 1, sprintf("%03d/%s: non-existent %s install fails as expected", $test_num, $pipe_label,
        $mod ));
    return;
}

# count total tests for Test::More plan()
sub count_tests
{
    my $total_tests = (scalar keys %{$tests{existent}}) * $tests_per_exist * $param_variants * $flag_variants +
        (scalar keys %{$tests{nonexistent}}) * $tests_per_nonexist * $param_variants;
    foreach my $key (keys %{$tests{existent}}) {
        if (( exists $tests{existent}{$key}{files}) and ref $tests{existent}{$key}{files} eq "ARRAY" ) {
            $total_tests += (scalar @{$tests{existent}{$key}{files}}) * $param_variants * $flag_variants;
        }
    }
    return $total_tests;
}

# set up environment variables, and save specific original values
sub setup_env_vars
{
    # set @INC to base perl configuration without user paths
    my @old_inc = @INC;
    my @new_inc;
    # get base @INC/PERL5LIB from %Config
    foreach my $inc_path ( @inc_configs ) {
        if (exists $Config{$inc_path}) {
            push @new_inc, $Config{$inc_path};
        }
    }
    # bring forward @INC paths where Sys::OsPackage is found, all of them in order
    foreach my $old_path ( @old_inc ) {
        if ( -f "$old_path/Sys/OsPackage.pm" ) {
            push @new_inc, $old_path;
        }
    }
    # set @INC and PERL5LIB
    @INC = @new_inc;
    $ENV{PERL5LIB}=deduplicate_path(join ":", @INC);
    if (exists $ENV{PERLLIB}) {
        delete $ENV{PERLLIB};
    }
    $debug_mode and print STDERR "setup_env_vars: PERL5LIB=".$ENV{PERL5LIB};

    # force CPAN to install modules
    #$ENV{CPAN_OPTS}="-fi";

    # save environment variables used by local::lib to restore them each test run
    foreach my $varname ( sort @local_lib_keep ) {
        if ( exists $ENV{$varname} ) {
            $orig_local_env{$varname} = $ENV{$varname};
        }
    }
    return;
}

#
# main
#

# set up process environment, save some original env values
setup_env_vars();

# count tests
plan tests => count_tests();

# create temporary directory for tests
my $paths_ref = init_tempdir();

# run tests
my $test_num = 1;

# tests for modules that exist
foreach my $mod ( sort keys %{$tests{existent}} ) {
    my $params = $tests{existent}{$mod};
    foreach my $use_pipe ( qw(0 1) ) {
        foreach my $use_notest ( qw(0 1) ) {
            test_exist ( $paths_ref, $test_num++, $mod,
                { %$params, use_pipe => $use_pipe, use_notest => $use_notest } );
        }
    }
}

# tests for modules that do not exist
foreach my $mod ( sort keys %{$tests{nonexistent}} ) {
    my $params = $tests{nonexistent}{$mod};
    foreach my $use_pipe ( qw(0 1) ) {
        test_nonexist ( $paths_ref, $test_num++, $mod, { %$params, use_pipe => $use_pipe } );
    }
}

