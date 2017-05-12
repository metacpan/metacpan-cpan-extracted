# t/12_make_defaults.t - check creation of personal defaults file
#$Id: 12_make_defaults.t 1201 2007-10-27 01:22:17Z jimk $
# defaults file
use strict;
use warnings;
use Test::More tests => 26;

BEGIN {
    use_ok( 'Pod::Multi', qw| pod2multi make_options_defaults | );
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
    use_ok( 'File::Compare' );
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

#my $prepref = _subclass_preparatory_tests($cwd);
#my $persref         = $prepref->{persref};
#my $pers_def_ref    = $prepref->{pers_def_ref};
#my %els1            = %{ $prepref->{initial_els_ref} };
#my $eumm_dir        = $prepref->{eumm_dir};
#my $mmkr_dir_ref    = $prepref->{mmkr_dir_ref};

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
    
#    copy ("$cwd/t/lib/.pod2multirc.bad", "$realhome/.pod2multirc")
#        or croak "Unable to copy bad rc file for testing";
#    ok(-f "$realhome/.pod2multirc", "bad rc file in place for testing");
#
#    eval {
#        pod2multi( source => $testpod );
#    };
#    like($@, qr{^Value of personal defaults option},
#        "pod2multi correctly failed due bad format in personal defaults file");

    my $maxwidth = 72;
    my $optionsref  = { text => { width => $maxwidth } };
    ok(make_options_defaults($optionsref), 
        "make_options_defaults called successfully");

    ok(pod2multi( source => $testpod ), "pod2multi called successfully");
    ok(-f "$tempdir/$pred{text}", "pod2text worked");
    ok(-f "$tempdir/$pred{man}", "pod2man worked");
    ok(-f "$tempdir/$pred{html}", "pod2html worked");

    my $parser;
    ok($parser = Pod::Text->new(width => $maxwidth),
        "able to create parser from installed Pod::Text");
    my $frominstalled = "$tempdir/installed.txt";
    $parser->parse_from_file($testpod, $frominstalled);
    ok(-f $frominstalled, "text version created from installed Pod::Text");
    is( compare("$tempdir/$pred{text}", $frominstalled), 0,
        "pod2multi version same as installed version");

    unlink "$realhome/.pod2multirc" 
        or croak "Unable to remove rc file after testing";
    ok(! -f "$realhome/.pod2multirc", "rc file deleted after testing");

    ok(chdir $cwd, "Changed back to original directory");
}

END { reveal_target_file($target_ref); }

