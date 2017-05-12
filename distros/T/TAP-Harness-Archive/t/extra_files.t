#!perl
use Test::More;
use File::Temp ();
use File::Spec::Functions qw(catfile catdir file_name_is_absolute splitdir);
use TAP::Harness::Archive;
use Archive::Tar;
plan(tests => 10);

# a temp directory to put everything in
my $temp_dir = File::Temp->newdir('tap-archive-XXXXXXXX', CLEANUP => 1, TMPDIR => 1);
my @testfiles = (catfile('t', 'foo.t'), catfile('t', 'bar.t'));
my @extra_files = (
    catfile('t', 'extra_files', 'log1.txt'),
    catfile('t', 'extra_files', 'log2.txt'),
    catfile('t', 'extra_files', 'stuff', 'svk.info'),
);

# create an archive with extra files
$file = catfile($temp_dir, 'archive.tar.gz');
$harness = TAP::Harness::Archive->new(
    {
        archive     => $file,
        verbosity   => -2,
        extra_files => \@extra_files,
    }
);
$harness->runtests(@testfiles);
ok(-e $file, 'archive.tar.gz created');
check_archive($file);

sub check_archive {
    my $archive_file = shift;
    my %tap_files;
    my $aggregator = TAP::Harness::Archive->aggregator_from_archive(
        {
            archive            => $archive_file,
            meta_yaml_callback => sub {
                my $yaml = shift;
                $yaml = $yaml->[0];

                # did we have all of the extra files?
                my $x_files = $yaml->{extra_files};
                cmp_ok(ref $x_files,      'eq', 'ARRAY', 'extra_files is an array');
                cmp_ok(scalar(@$x_files), '==', 3,       '3 extra_files recorded');
            },
        }
    );

    isa_ok($aggregator, 'TAP::Parser::Aggregator');
    cmp_ok($aggregator->total, '==', 5, "aggregator has correct total");
    my @parsers = $aggregator->parsers();
    cmp_ok(scalar @parsers, '==', 2, "correct # of parsers");
}

my $tar = Archive::Tar->new($file);
isa_ok($tar, 'Archive::Tar');
my @contents = $tar->list_files();
foreach my $extra_file (@extra_files) {
    # Archive::Tar returns file names with "/" path separator.
    # Passing it through catdir(splitdir()) will give us the
    # correct system path separator (e.g. "\" on Win32).
    my $count = grep { catdir(splitdir($_)) eq $extra_file } @contents;
    ok($count == 1, "Archive contains extra file $extra_file");
}

