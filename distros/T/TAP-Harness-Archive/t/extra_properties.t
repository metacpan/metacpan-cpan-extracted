#!perl
use Test::More;
use File::Temp ();
use File::Spec::Functions qw(catfile catdir file_name_is_absolute);
use TAP::Harness::Archive;
plan(tests => 5);

# a temp directory to put everything in
my $temp_dir = File::Temp->newdir('tap-archive-XXXXXXXX', CLEANUP => 1, TMPDIR => 1);
my @testfiles = (catfile('t', 'foo.t'), catfile('t', 'bar.t'));
my %extra_props = (
    name => {
        first => 'Michael',
        last  => 'Peters',
        middle => 'Ryan',
    },
    hair_color => 'brown',
    states => [qw(UT CA AL TN MD NC)],
);

# create an archive with extra files
$file = catfile($temp_dir, 'archive.tar.gz');
$harness = TAP::Harness::Archive->new({
    archive => $file, 
    verbosity => -2,
    extra_properties => \%extra_props,
});
$harness->runtests(@testfiles);
ok(-e $file, 'archive.tar.gz created');
check_archive($file);

sub check_archive {
    my $archive_file = shift;
    my %tap_files;
    my $aggregator = TAP::Harness::Archive->aggregator_from_archive(
        {
            archive              => $archive_file,
            meta_yaml_callback => sub {
                my $yaml = shift;
                $yaml = $yaml->[0];
                # did our extra_properties come through
                is_deeply($yaml->{extra_properties}, \%extra_props, 'extra_properties are correct');
            },
        }
    );

    isa_ok($aggregator, 'TAP::Parser::Aggregator');
    cmp_ok($aggregator->total, '==', 5, "aggregator has correct total");
    my @parsers = $aggregator->parsers();
    cmp_ok(scalar @parsers, '==', 2, "correct # of parsers");
}
