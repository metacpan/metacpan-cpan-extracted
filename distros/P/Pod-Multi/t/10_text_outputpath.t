# t/10_text_outputpath.t - check handling of output path  option for text
#$Id: 10_text_outputpath.t 1201 2007-10-27 01:22:17Z jimk $
use strict;
use warnings;
use Test::More 
tests => 37;
# qw(no_plan);

BEGIN {
    use_ok( 'Pod::Multi' );
    use_ok( 'File::Temp', qw| tempdir | );
    use_ok( 'File::Copy' );
    use_ok( 'File::Basename' );
    use_ok( 'Carp' );
    use_ok( 'Cwd' );
    use_ok( 'Pod::Text');
    use_ok( 'File::Compare' );
    use_ok( 'File::Save::Home', qw|
        get_home_directory
        conceal_target_file
        reveal_target_file
    | );
    use_ok( 'IO::Capture::Stderr' );
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
my $htmltitle = q(This is the HTML title);
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
    
    my $secondary_dir = "secondary";
    mkdir $secondary_dir or croak "Unable to make $secondary_dir";
    ok(-d $secondary_dir, "secondary testing directory created");
    my $textout = "$tempdir/$secondary_dir";
    ok(pod2multi(
        source => $testpod, 
        options => {
            text => {
                outputpath => $textout,
            },
        },
    ), "pod2multi completed");
    ok(-f "$textout/$pred{text}", "pod2text worked");
    ok(-f "$tempdir/$pred{man}", "pod2man worked");
    ok(-f "$tempdir/$pred{html}", "pod2html worked");

    my $parser;
    ok($parser = Pod::Text->new(),
        "able to create parser from installed Pod::Text");
    my $frominstalled = "$tempdir/installed.txt";
    $parser->parse_from_file($testpod, $frominstalled);
    ok(-f $frominstalled, "text version created from installed Pod::Text");
    is( compare("$textout/$pred{text}", $frominstalled), 0,
        "pod2multi version same as installed version");

    ok(chdir $cwd, "Changed back to original directory");
}

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    # This time, we fail to create the secondary directory,
    # then see if warning is correctly captured.

    my $secondary_dir = "secondary";
    my $textout = "$tempdir/$secondary_dir";
    my $capture = IO::Capture::Stderr->new();
    $capture->start;
    my $rv = pod2multi(
        source => $testpod, 
        options => {
            text => {
                outputpath => $textout,
            },
        },
    );
    ok($rv, "pod2multi completed");
    $capture->stop;
    like($capture->read, qr/is not a valid directory; reverting/,
        "warning about incorrect output path correctly captured");

    ok(-f "$tempdir/$pred{text}", "pod2text worked");
    ok(-f "$tempdir/$pred{man}", "pod2man worked");
    ok(-f "$tempdir/$pred{html}", "pod2html worked");

    my $parser;
    ok($parser = Pod::Text->new(),
        "able to create parser from installed Pod::Text");
    my $frominstalled = "$tempdir/installed.txt";
    $parser->parse_from_file($testpod, $frominstalled);
    ok(-f $frominstalled, "text version created from installed Pod::Text");
    is( compare("$tempdir/$pred{text}", $frominstalled), 0,
        "pod2multi version same as installed version");

    ok(chdir $cwd, "Changed back to original directory");
}

END { reveal_target_file($target_ref); }

