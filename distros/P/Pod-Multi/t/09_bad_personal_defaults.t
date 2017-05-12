# t/09_bad_personal_defaults.t - check what happens with defective personal
#$Id: 09_bad_personal_defaults.t 1201 2007-10-27 01:22:17Z jimk $
# defaults file
use strict;
use warnings;
use Test::More 
tests => 19;
# qw(no_plan);

BEGIN {
    use_ok( 'Pod::Multi' );
    use_ok( 'File::Temp', qw| tempdir | );
    use_ok( 'File::Copy' );
    use_ok( 'File::Basename' );
    use_ok( 'Carp' );
    use_ok( 'Cwd' );
    use_ok( 'File::Save::Home', qw|
        get_home_directory
        conceal_target_file
        reveal_target_file
    | );
}

my $realhome;
ok( $realhome = get_home_directory(), 
    "HOME or home-equivalent directory found on system");
my $target_ref = conceal_target_file( {
    dir     => $realhome,
    file    => '.pod2multirc',
    test    => 1,
} );

my $cwd = cwd();

my $pod = "$cwd/t/lib/s1.pod";
ok(-f $pod, "pod sample file located");
my ($name, $path, $suffix) = fileparse($pod, qr{\.pod});
my $stub = "$name$suffix";
my %pred = (
    text    => "$name.txt",
    man     => "$name.1",
    html    => "$name.html",
);

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    copy ("$cwd/t/lib/.pod2multirc.bad", "$realhome/.pod2multirc")
        or croak "Unable to copy bad rc file for testing";
    ok(-f "$realhome/.pod2multirc", "bad rc file in place for testing");

    eval {
        pod2multi( source => $testpod );
    };
    like($@, qr{^Value of personal defaults option},
        "pod2multi correctly failed due bad format in personal defaults file");

    unlink "$realhome/.pod2multirc" 
        or croak "Unable to remove bad rc file after testing";
    ok(! -f "$realhome/.pod2multirc", "bad rc file deleted after testing");

    ok(chdir $cwd, "Changed back to original directory");
}

END { reveal_target_file($target_ref); }

