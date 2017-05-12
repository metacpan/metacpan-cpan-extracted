# t/02_bad_args.t - check handling of bad arguments
#$Id: 02_bad_args.t 1201 2007-10-27 01:22:17Z jimk $
use strict;
use warnings;
use Test::More 
tests => 29;
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
    
    eval { pod2multi( source => $testpod, q{options}); };
    like($@, qr{^Must supply even number of arguments},
        "pod2multi correctly failed due to odd number of arguments");

    ok(chdir $cwd, "Changed back to original directory");
}

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    eval { pod2multi( options => {} ); };
    like($@, qr{^Must supply source file with pod},
        "pod2multi correctly failed due to lack of 'source' key-value pair");

    ok(chdir $cwd, "Changed back to original directory");
}

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    eval { pod2multi( source => 'phonyfile', options => {} ); };
    like($@, qr{^Must supply source file with pod},
        "pod2multi correctly failed due to non-existent source file");

    ok(chdir $cwd, "Changed back to original directory");
}

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    eval { pod2multi( source => $testpod, options => [] ); };
    like($@, qr{^Options must be supplied in a hash ref},
        "pod2multi correctly failed due to options in wrong ref");

    ok(chdir $cwd, "Changed back to original directory");
}

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    eval { pod2multi(
        source => $testpod, 
        options => {
            html => [
                title   => q{This is the HTML title},
            ],
        },
    ) };
    like($@, qr{^Value of option html must be a hash ref},
        "pod2multi correctly failed due to options in wrong ref");

    ok(chdir $cwd, "Changed back to original directory");
}

END { reveal_target_file($target_ref); }

