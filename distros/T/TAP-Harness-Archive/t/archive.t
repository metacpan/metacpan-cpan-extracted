#!perl
use Test::More;
use File::Temp ();
use File::Spec::Functions qw(catfile catdir file_name_is_absolute);
use TAP::Harness::Archive;
plan(tests => 65);

# test creation
eval { TAP::Harness::Archive->new() };
like($@, qr/You must provide the name of the archive to create!/);
eval { TAP::Harness::Archive->new({archive => 'foo.bar'}) };
like($@, qr/Archive is not a known format type!/);

# a temp directory to put everything in
my $temp_dir = File::Temp->newdir('tap-archive-XXXXXXXX', CLEANUP => 1, TMPDIR => 1);
my @testfiles = map { catfile('t', $_) } qw(foo.t bar.t);

# first a .tar file
$file = catfile($temp_dir, 'archive.tar');
$harness = TAP::Harness::Archive->new({archive => $file, verbosity => -2});
$harness->runtests(@testfiles);
ok(-e $file, 'archive.tar created');
check_archive($file);

# now a .tar.gz
$file = catfile($temp_dir, 'archive.tar.gz');
$harness = TAP::Harness::Archive->new({archive => $file, verbosity => -2});
$harness->runtests(@testfiles);
ok(-e $file, 'archive.tar.gz created');
check_archive($file);

# now a simple directory
my $dir = File::Temp->newdir('tap-archive-XXXXXXXX', CLEANUP => 1, TMPDIR => 1);
$harness = TAP::Harness::Archive->new({archive => $dir, verbosity => -2});
$harness->runtests(@testfiles);
ok(!-e catfile($dir, 'archive.tar.gz'), "no archive.tar.gz created");
check_archive($dir);

sub check_archive {
    my $archive_file = shift;
    my %tap_files;
    my $aggregator = TAP::Harness::Archive->aggregator_from_archive(
        {
            archive              => $archive_file,
            made_parser_callback => sub {
                my ($parser, $filename, $full_path) = @_;
                isa_ok($parser, 'TAP::Parser');
                $tap_files{$filename} = 1;
                ok(-e $full_path, 'full path file exists');
                ok(file_name_is_absolute($full_path), 'full path is absolute');
            },
            meta_yaml_callback => sub {
                my $yaml = shift;
                $yaml = $yaml->[0];
                ok(exists $yaml->{start_time}, 'meta.yml: start_time exists');
                ok(exists $yaml->{stop_time},  'meta.yml: stop_time exists');
                ok(exists $yaml->{file_order}, 'meta.yml: file_order exists');
                ok(exists $yaml->{file_attributes}, 'meta.yml: file_attributes exists');
            },
        }
    );

    isa_ok($aggregator, 'TAP::Parser::Aggregator');
    cmp_ok($aggregator->total, '==', 5, "aggregator has correct total");
    cmp_ok(scalar keys %tap_files, '==', 2, "correct number of files in archive $archive_file");
    foreach my $f (@testfiles) {
        ok($tap_files{$f}, "file $f in archive $archive_file");
    }

    my @parsers = $aggregator->parsers();
    cmp_ok(scalar @parsers, '==', 2, "correct # of parsers");
    cmp_ok($parsers[0]->passed(), '==', 3, "foo.t passed 3");
    cmp_ok($parsers[0]->failed(), '==', 0, "foo.t failed 0");
    cmp_ok($parsers[1]->passed(), '==', 2, "bar.t passed 2");
    cmp_ok($parsers[1]->failed(), '==', 0, "bar.t failed 0");
}

