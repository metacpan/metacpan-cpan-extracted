use Test::Arrow;
eval "use File::Find::Rule::BOM;";
Test::Arrow->plan(skip_all => "skip the no BOM test because $@") if $@;
my $arr = Test::Arrow->new;
my @foo = File::Find::Rule->bom->in('lib', 't', 'xt');
$arr->ok(scalar(@foo) == 0, 'No BOM')
    or $arr->diag(join("\t", map { "'$_' has BOM." } @foo));
$arr->done_testing;
