# t/07_command.t - test command-line interface pod2multi
#$Id: 07_command.t 1202 2007-10-27 15:12:03Z jimk $
use strict;
use warnings;
use Test::More 
tests => 28;
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
use lib( "./t/lib" );
use_ok( 'Pod::Multi::Auxiliary', qw(
        stringify
    )
);

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
    ok(! system(
        qq{$^X -I"$cwd/blib/lib" "$cwd/blib/script/pod2multi" $testpod }
    ), "pod2multi called successfully from the command line");
    ok(-f "$tempdir/$pred{text}", "pod2text worked");
    ok(-f "$tempdir/$pred{man}", "pod2man worked");
    ok(-f "$tempdir/$pred{html}", "pod2html worked");

    ok(chdir $cwd, "Changed back to original directory");
}

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    # Note:  Everything inside qq{} must be on one line
    ok(! system(
        qq{$^X -I"$cwd/blib/lib" "$cwd/blib/script/pod2multi" $testpod This is the HTML title}
    ), "pod2multi called successfully from the command line");
    ok(-f "$tempdir/$pred{text}", "pod2text worked");
    ok(-f "$tempdir/$pred{man}", "pod2man worked");
    ok(-f "$tempdir/$pred{html}", "pod2html worked");

    # test that html title tag was set
    like(stringify("$tempdir/$pred{html}"), 
        qr{<title>This\sis\sthe\sHTML\stitle<\/title>}i,
       "HTML title tag located");

    ok(chdir $cwd, "Changed back to original directory");
}

END { reveal_target_file($target_ref); }

