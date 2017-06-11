use strict;
use warnings;

use Test::More;
use Test::TempDir::Tiny;
use File::Spec::Functions qw(catdir catfile);
use Module::Starter qw(Module::Starter::Smart);

my $content = <<"EOF";
I think that I shall never see,
a test as concise as this in ./t!
EOF

test_old_interface();
test_new_interface();

done_testing();

sub test_old_interface {
    my $tempdir  = tempdir();
    my $tdir     = catdir($tempdir, 't');
    my $testfile = '01.test_old_interface.t';
    my $starter  = Module::Starter::Smart->new();
    $starter->{basedir} = $tempdir;

    Module::Starter::Smart::_create_t($starter, $testfile, $content);

    file_contains_ok(catfile($tdir, $testfile), $content);
}

sub test_new_interface {
    my $tempdir   = tempdir();
    my $tdir      = catdir($tempdir, 't');
    my $xtdir     = catdir($tempdir, 'xt');
    my $testfile1 = '01.test_new_interface.t';
    my $testfile2 = '02.test_new_interface.t';
    my $starter   = Module::Starter::Smart->new();
    $starter->{basedir} = $tempdir;

    Module::Starter::Smart::_create_t($starter, 't',  $testfile1, $content);
    Module::Starter::Smart::_create_t($starter, 'xt', $testfile2, $content);

    file_contains_ok(catfile($tdir,  $testfile1), $content);
    file_contains_ok(catfile($xtdir, $testfile2), $content);
}

sub file_contains_ok {
    my $file = shift;
    my $expected_content = shift;

    SKIP: {
        skip "File '$file' does not exist or is unreadable", 1
            unless ok(-f -r $file, "File '$file' exists and is readable");

        open my $fh, '<', $file or die "Cannot open $file: $!\n";
        my $real_content = do { local $/; <$fh> };
        close $fh;

        ok($expected_content eq $real_content, "File '$file' has correct content");
    }
}
