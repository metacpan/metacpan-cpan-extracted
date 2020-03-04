use Test::Arrow;
eval "use File::Find::Rule::ConflictMarker;";
Test::Arrow->plan(skip_all => "skip the no conflict test because $@") if $@;
my $arr = Test::Arrow->new;
my @files = File::Find::Rule->conflict_marker->in('lib', 't', 'xt');
$arr->ok( scalar(@files) == 0 )
    or $arr->diag(join "\t", map { "'$_' has conflict markers." } @files);
Test::Arrow->done_testing;
