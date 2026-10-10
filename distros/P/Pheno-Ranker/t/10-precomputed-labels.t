use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use IO::Compress::Gzip qw(gzip $GzipError);
use lib 'lib';
use Pheno::Ranker;
use Pheno::Ranker::CLI;
use Pheno::Ranker::IO qw(read_json write_json);

my $dir = tempdir(CLEANUP => 1);
my $reference = catfile($dir, 'reference.json');
my $target = catfile($dir, 'target.json');
my $prefix = catfile($dir, 'reference');
my $cli = Pheno::Ranker::CLI->new(pod_file => catfile('bin', 'pheno-ranker'));
my $feature = sub { +{type => {id => $_[0], label => $_[1]}} };
my $records = [
    {id => 'r1', subject => {id => 'r1'}, phenotypicFeatures => [$feature->('HP:0001250', 'Seizure'), $feature->('HP:0000006', 'Autosomal dominant inheritance')]},
    {id => 'r2', subject => {id => 'r2'}, phenotypicFeatures => [$feature->('HP:0000006', 'Autosomal dominant inheritance')]},
];
write_json({filepath => $reference, data => $records});
write_json({filepath => $target, data => {id => 'target', subject => {id => 'target'}, phenotypicFeatures => [$feature->('HP:0001250', 'Seizure')]}});

sub slurp {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/;
    return <$fh>;
}
sub run_case {
    my ($name, @input) = @_;
    my $args = $cli->parse_args(@input, '-t', $target, '--include-terms', 'phenotypicFeatures',
        '--sort-by', 'jaccard', '--max-out', 2, '--align', catfile($dir, $name), '--out-file', catfile($dir, "$name.rank.txt"));
    $args->{cli} = 0;
    Pheno::Ranker->new($args)->run;
}

run_case('fresh', '-r', $reference, '--export', $prefix);
my @kinds = qw(glob_hash ref_hash ref_binary_hash coverage_stats);
my %original = map {$_ => slurp("$prefix.$_.json")} @kinds;
my $labels = read_json("$prefix.labels.json");
is_deeply [sort keys %$labels], [sort keys %{read_json("$prefix.glob_hash.json")}], 'labels match global vector keys exactly';
ok scalar(grep {$_ eq 'Autosomal dominant inheritance'} values %$labels), 'reference labels are exported';

run_case('plain', '--prp', $prefix);
my $reexport = catfile($dir, 'reexport');
run_case('reexport', '--prp', $prefix, '--export', $reexport);
is slurp("$reexport.coverage_stats.json"), $original{coverage_stats}, 'cached export preserves coverage metadata for further reuse';
is slurp(catfile($dir, 'plain.rank.txt')), slurp(catfile($dir, 'fresh.rank.txt')), 'plain labels do not change ranking';
is slurp(catfile($dir, 'plain.target.csv')), slurp(catfile($dir, 'fresh.target.csv')), 'plain sidecar restores exact alignment';

gzip "$prefix.labels.json" => "$prefix.labels.json.gz" or die $GzipError;
unlink "$prefix.labels.json" or die $!;
run_case('gzip', '--prp', $prefix);
is slurp(catfile($dir, 'gzip.target.csv')), slurp(catfile($dir, 'fresh.target.csv')), 'gzipped sidecar restores exact alignment';
unlink "$prefix.labels.json.gz" or die $!;
run_case('legacy', '--prp', $prefix);
is slurp(catfile($dir, 'legacy.rank.txt')), slurp(catfile($dir, 'fresh.rank.txt')), 'legacy four-file exports still rank identically';
like slurp(catfile($dir, 'legacy.target.csv')), qr/;HP:0000006\r?$/m, 'legacy fallback uses CURIE, not labels leaked from a previous run';
is slurp("$prefix.$_.json"), $original{$_}, "existing $_ file stays byte-identical" for @kinds;

for my $case ([[], qr/JSON object/], [{unknown => 'label'}, qr/absent from the global vector/],
    [{(keys %$labels)[0] => []}, qr/defined scalar/]) {
    write_json({filepath => "$prefix.labels.json", data => $case->[0]});
    my $ok = eval { run_case('invalid', '--prp', $prefix); 1 };
    ok !$ok, 'invalid sidecar rejected';
    like $@, $case->[1], 'invalid sidecar explains the problem';
}
done_testing;
