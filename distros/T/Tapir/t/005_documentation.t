use strict;
use warnings;
use FindBin;
use Test::More tests => 7;
use Test::File::Contents;
use Tapir::Documentation::NaturalDocs;
use File::Temp qw();
use File::Spec;
use File::Basename;

my $temp_dir = File::Temp->newdir();

my %build_args = (
    input_fn     => File::Spec->catfile($FindBin::Bin, 'thrift', 'example.thrift'),
    process_dir  => File::Spec->catdir($temp_dir, 'process'),
    project_dir  => File::Spec->catdir($temp_dir, 'project'),
    output_dir   => File::Spec->catdir($temp_dir, 'output'),
    prepare_only => 1,
);

Tapir::Documentation::NaturalDocs->build(%build_args);

ok -d $build_args{process_dir}, "Process directory was created";

foreach my $path (glob File::Spec->catfile($build_args{process_dir}, '*.txt')) {
    my $filename = basename($path);
    my $test_path = File::Spec->catfile($FindBin::Bin, 'docs', $filename);
    ok -e $test_path, "File $filename was an expected process file";
    files_eq_or_diff $path, $test_path, { style => 'Unified' }, "File $filename had expected content";
}
