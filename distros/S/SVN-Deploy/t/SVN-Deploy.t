use Test::More tests => 21;

use File::Spec::Functions qw/rel2abs catdir catfile/;
use File::Path qw/rmtree/;

use Data::Dumper;
 $Data::Dumper::Indent=1;

BEGIN {
    use_ok('SVN::Deploy')
        or BAIL_OUT('SVN::Deploy module load failed');
    use_ok('SVN::Repos')
        or BAIL_OUT('SVN::Ra module load failed');
};

# create tempdir
my $tempdir = File::Temp::tempdir(
    'SVN-Deploy-XXXXXX',
    DIR     => 't',
    CLEANUP => 1,
    TMPDIR  => 1,
) or BAIL_OUT('tempdir creation failed');

$repo_root = 'file:///' . rel2abs($tempdir);
$repo_root =~ s!\\!/!g;

$abs_t = rel2abs('t');

# create source and deploy repo
my $repos = SVN::Repos::open($tempdir)
    or BAIL_OUT('SVN::Repos::open failed');

my $source_repo = SVN::Repos::create(
    catdir($tempdir, 'source'), undef, undef, undef, undef
) or BAIL_OUT('source repo creation failed');

my $deploy_repo = SVN::Repos::create(
    catdir($tempdir, 'deploy'), undef, undef, undef, undef
) or BAIL_OUT('deploy repo creation failed');

# init source repo
my $ctx = SVN::Deploy::Utils::connect_cached()
    or BAIL_OUT('source context failed');

$ctx->import('t/stree', "$repo_root/source", 0)
    or BAIL_OUT('import test source failed');

# ready for testing

my $deploy    = SVN::Deploy->new(
    repo        => "$repo_root/deploy",
    cleanup_tmp => 1,
    debug       => 0,
    pwd_sub     => sub {},
);

isa_ok($deploy, 'SVN::Deploy')
    or BAIL_OUT('SVN::Deploy object creation failed');

# check get_methods
my @methods = qw/
    _init build_version deploy_version
    category_add category_delete  category_history category_list category_update
    product_add product_delete product_history product_list product_update
/;

is_deeply(
    [sort @methods],
    [sort keys %{ $deploy->get_methods }],
    "check available methods",
);

# create 2 categories
my $rc = $deploy->category_add(category => 'Cat1');
ok($rc, 'add category 1')
    or diag($deploy->lasterr);

$rc = $deploy->category_add(category =>'Cat2');
ok($rc, 'add category 2')
    or diag($deploy->lasterr);

my $perlbin = $^X =~ /\s/
            ? '"' . $^X . '"'
            : $^X;

# create a product
my %prod1_cfg = (
    category => 'Cat1',
    product  => 'Prod1',
    cfg      => {
        build  => ["[os]$perlbin " . catfile($abs_t, 'build.pl')],
        source => ["$repo_root/source/subdir1"],
        qa => {
            dest => [catdir($abs_t, 'qa')],
            pre  => ["[os]$perlbin " . catfile($abs_t, 'pre.pl')],
            post => ["[os]$perlbin " . catfile($abs_t, 'post.pl')],
        },
        prod => {
            dest => [],
            pre  => [],
            post => [],
        },
    },
);

$rc = $deploy->product_add(%prod1_cfg);
ok($rc, "add product 1")
    or diag($deploy->lasterr);

# check what was created
$rc = $deploy->category_list();
ok($rc, "get category list")
    or diag($deploy->lasterr);

is_deeply(
    $rc,
    {
        'Cat1' => ['Prod1'],
        'Cat2' => [],
    },
    'check category info',
);

$rc = $deploy->product_list(
    category => 'Cat1',
    product  => 'Prod1',
);
ok($rc, "get product info")
    or diag($deploy->lasterr);

for ( keys %{ $rc->{Prod1} } ) {
   delete $rc->{Prod1}{$_} unless exists $prod1_cfg{cfg}{$_};
}

is_deeply($rc->{Prod1}, $prod1_cfg{cfg}, 'check product info');

# rename Cat2 to Cat3
$rc = $deploy->category_update(
    category => 'Cat2',
    new_name => 'Cat3',
);
ok($rc, "rename Cat2 to Cat3")
    or diag($deploy->lasterr);

# try to delete non empty category
$rc = $deploy->category_delete(
    category => 'Cat1',
);
ok(!$rc, 'delete non empty category Cat1')
    or diag("Oops, could delete non empty category Cat1");

# delete category Cat3
$rc = $deploy->category_delete(
    category => 'Cat3',
);
ok($rc, "delete empty category Cat3")
    or diag($deploy->lasterr);

# update product
$prod1_cfg{cfg}{prod} = {
    dest => [catdir($abs_t, 'prod')],
    pre  => ["[os]$perlbin " . catfile($abs_t, 'pre.pl')],
    post => ["[os]$perlbin " . catfile($abs_t, 'post.pl')],
};
$rc = $deploy->product_update(%prod1_cfg);
ok($rc, "update product 1")
    or diag($deploy->lasterr);

# run build
$rc = $deploy->build_version(
    category => 'Cat1',
    product  => 'Prod1',
    versions => {
        "$repo_root/source/subdir1" => 1,
    },
    comment => 'first build',
);
ok($rc, "build product 1")
    or diag($deploy->lasterr);
like(
    $deploy->output(),
    qr/BUILD_OUTPUT:\s+running build.pl/,
    'build output',
);

my $build_version = $rc;

# deploy to qa
$rc = $deploy->deploy_version(
    category       => 'Cat1',
    product        => 'Prod1',
    target         => 'qa',
    version        => $build_version,
    reference_id   => '08/15',
    reference_data => {qw/arbitrary user data junk/},
    comment        => 'first qa rollout',
);

ok($rc, "deploy product 1 to qa")
    or diag($deploy->lasterr);

my $qadir = catdir($abs_t, 'qa');
my $qaok  = -f catfile($qadir, 'source11.pl')
        and -d catdir($qadir, 'subdir11')
        and -f catfile($qadir, 'subdir11', 'source111.pl')
        and -f catfile($qadir, 'subdir11', 'source112.pl');

ok($qaok, "check deployed subdir");

# check history
$rc = $deploy->category_history(
    category => 'Cat1',
    from     => 1,
    to       => 'HEAD',
);

$hist_ok = (
    $rc
    and $rc->[0]{category}                        eq 'Cat1'
    and $rc->[0]{product}                         eq 'Prod1'
    and $rc->[0]{props}{'D:target'}               eq 'qa'
    and $rc->[0]{props}{'D:action'}               eq 'deploy start'
    and $rc->[1]{props}{'D:action'}               eq 'deploy end'
    and $rc->[1]{props}{'D:reference_data'}{data} eq 'junk'
);

ok($hist_ok, "check history functions");

# delete product
$rc = $deploy->product_delete(
    category => 'Cat1',
    product  => 'Prod1',
);

ok($rc, "delete product");

# cleanup deploy dir
rmtree($qadir);
