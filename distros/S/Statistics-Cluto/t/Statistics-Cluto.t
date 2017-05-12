# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Statistics-Cluto.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 51;
BEGIN { use_ok('Statistics::Cluto') };


my $fail = 0;
foreach my $constname (qw(
	CLUTO_CLFUN_CLINK CLUTO_CLFUN_CLINK_W CLUTO_CLFUN_CUT CLUTO_CLFUN_E1
	CLUTO_CLFUN_G1 CLUTO_CLFUN_G1P CLUTO_CLFUN_H1 CLUTO_CLFUN_H2
	CLUTO_CLFUN_I1 CLUTO_CLFUN_I2 CLUTO_CLFUN_MMCUT CLUTO_CLFUN_NCUT
	CLUTO_CLFUN_RCUT CLUTO_CLFUN_SLINK CLUTO_CLFUN_SLINK_W
	CLUTO_CLFUN_UPGMA CLUTO_CLFUN_UPGMA_W CLUTO_COLMODEL_IDF
	CLUTO_COLMODEL_NONE CLUTO_CSTYPE_BESTFIRST CLUTO_CSTYPE_LARGEFIRST
	CLUTO_CSTYPE_LARGESUBSPACEFIRST CLUTO_DBG_APROGRESS CLUTO_DBG_CCMPSTAT
	CLUTO_DBG_CPROGRESS CLUTO_DBG_MPROGRESS CLUTO_DBG_PROGRESS
	CLUTO_DBG_RPROGRESS CLUTO_GRMODEL_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_ASYMETRIC_LINKS CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
	CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
	CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
	CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
	CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
	CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS CLUTO_GRMODEL_NONE
	CLUTO_GRMODEL_SYMETRIC_DIRECT CLUTO_GRMODEL_SYMETRIC_LINKS
	CLUTO_MEM_NOREUSE CLUTO_MEM_REUSE CLUTO_MTYPE_HEDGE CLUTO_MTYPE_HSTAR
	CLUTO_MTYPE_HSTAR2 CLUTO_OPTIMIZER_MULTILEVEL
	CLUTO_OPTIMIZER_SINGLELEVEL CLUTO_ROWMODEL_LOG CLUTO_ROWMODEL_MAXTF
	CLUTO_ROWMODEL_NONE CLUTO_ROWMODEL_SQRT CLUTO_SIM_CORRCOEF
	CLUTO_SIM_COSINE CLUTO_SIM_EDISTANCE CLUTO_SIM_EJACCARD
	CLUTO_SUMMTYPE_MAXCLIQUES CLUTO_SUMMTYPE_MAXITEMSETS CLUTO_TREE_FULL
	CLUTO_TREE_TOP CLUTO_VER_MAJOR CLUTO_VER_MINOR CLUTO_VER_SUBMINOR)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Statistics::Cluto macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


# test with dense matrix
#
# 1 1 0 1 1
# 1 0 0 1 0
# 0 1 1 0 0
# 0 0 1 0 0

$c = new Statistics::Cluto;
$rowval = [
[1, 1, 0, 0, 1],
[1, 1, 0, 1, 1],
[1, 0, 1, 1, 0],
[1, 0, 1, 0, 0]
];
ok($c->set_dense_matrix(4, 5, $rowval), "set dense matrix");

$c->set_options({
    rowmodel => CLUTO_ROWMODEL_NONE,
    colmodel => CLUTO_COLMODEL_NONE,
    rowlabels => ['row1', 'row2', 'row3', 'row4'],
    collabels => ['col1', 'col2', 'col3', 'col4', 'col5'],
    nclusters => 2,
    pretty_format => 1,
});

# VP_ClusterDirect
ok($rtn = $c->VP_ClusterDirect, "VP_ClusterDirect");
is(scalar @$rtn, 2);


# test sparse matrix setup
#
# 1 1 0 1 1
# 1 0 0 1 0
# 0 1 1 0 0
# 0 0 1 0 0

my $nrows = 4;
my $ncols = 5;
my $rowval = [
[1, 1, 2, 1, 4, 1, 5, 1],
[1, 1, 4, 1],
[2, 1, 3, 1],
[3, 1]];

my $c = new Statistics::Cluto;
$c->set_sparse_matrix($nrows, $ncols, $rowval);
is_deeply($c->{rowptr}, [0, 4, 6, 8, 9], "rowptr");
is_deeply($c->{rowind}, [0, 1, 3, 4, 0, 3, 1, 2, 2], "rowind");
is_deeply($c->{rowval}, [1, 1, 1, 1, 1, 1, 1, 1, 1], "rowval");

$c->set_options({
    rowlabels => ['row1', 'row2', 'row3', 'row4'],
    collabels => ['col1', 'col2', 'col3', 'col4', 'col5'],
    nclusters => 2,
    nfeatures => 2,
    treetype => CLUTO_TREE_FULL,
    pretty_format => 1,
});


# test for cluster_features, cluster_summaries etc.

# VP_ClusterRB
ok($rtn = $c->VP_ClusterRB, "VP_ClusterRB");
is(scalar @$rtn, 2);

# VA_Cluster
ok($rtn = $c->VA_Cluster, "VA_Cluster");
is(scalar @{$rtn->{clusters}}, 2);
is(scalar @{$rtn->{tree}}, 7);

# VA_ClusterBiased
ok($rtn = $c->VA_ClusterBiased, "VA_ClusterBiased");
is(scalar @{$rtn->{clusters}}, 2);
is(scalar @{$rtn->{tree}}, 7);

# V_GetGraph
ok(my ($growptr, $growind, $growval) = $c->V_GetGraph, "V_GetGraph");
is(scalar @$growptr, $nrows + 1);
#$c->set_raw_sparse_matrix($nrows, $nrows, $growptr, $growind, $growval);
#$rtn = $c->VP_GraphClusterRB;

# V_GetSolutionQuality
ok($rtn = $c->V_GetSolutionQuality, "V_GetSolutionQuality");

# V_ClusterStats
ok($rtn = $c->V_GetClusterStats, "V_GetClusterStats");
is(scalar @{$rtn->{clusters}}, 2);
is(scalar @{$rtn->{rows}}, 4);

# V_GetClusterFeatures
ok($rtn = $c->V_GetClusterFeatures, "V_GetClusterFeatures");
is(scalar @$rtn, 2);

# V_GetClusterSummaries
ok($rtn = $c->V_GetClusterSummaries, "V_GetClusterSummaries");
is(scalar @$rtn, 2);


# test for tree_features, tree_stats etc.

# 1 1 0 0 1
# 1 0 0 0 1
# 0 0 1 0 0
# 0 0 1 1 0
$nrows = 4;
$ncols = 5;
$rowval = [
[1, 1, 2, 1, 5, 1],
[1, 1, 5, 1],
[3, 1],
[3, 1, 4, 1]];
$c = new Statistics::Cluto;
$c->set_sparse_matrix($nrows, $ncols, $rowval);
$c->set_options({
    rowlabels => ['row1', 'row2', 'row3', 'row4', 'row5'],
    collabels => ['col1', 'col2', 'col3', 'col4', 'col5'],
    nclusters => 2,
    nfeatures => 4,
    clfun => CLUTO_CLFUN_I2,
    treetype => CLUTO_TREE_TOP,
    pretty_format => 1,
});
ok($rtn = $c->VA_Cluster);
ok($rtn = $c->V_BuildTree);
ok($rtn = $c->V_GetTreeStats, "V_GetTreeStats");
is(scalar @$rtn, 4);
ok($rtn = $c->V_GetTreeFeatures);
is(scalar @$rtn, 4);


# test scluster methods with dense matrix
# 1 9 1 1
# 9 1 1 1
# 1 1 1 9
# 1 1 9 1

$c = new Statistics::Cluto;
$rowval = [
[1, 9, 1, 1],
[9, 1, 1, 1],
[1, 1, 1, 9],
[1, 1, 9, 1],
];
$c->set_dense_matrix(4, 4, $rowval);

$c->set_options({
    nclusters => 2,
    treetype => CLUTO_TREE_FULL,
    pretty_format => 1,
});

# SP_ClusterDirect
ok($rtn = $c->SP_ClusterDirect, "SP_ClusterDirect");
is(scalar @$rtn, 2);

# SP_ClusterDirect
ok($rtn = $c->SP_ClusterRB, "SP_ClusterRB");
is(scalar @$rtn, 2);

# SA_Cluster
ok($rtn = $c->SA_Cluster, "SA_Cluster");
is(scalar @{$rtn->{clusters}}, 2);
is(scalar @{$rtn->{tree}}, 7);

# S_BuildTree
ok($rtn = $c->S_BuildTree, "S_BuildTree");
is(scalar @$rtn, 7);

# S_GetGraph
ok(($growptr, $growind, $growval) = $c->S_GetGraph, "S_GetGraph");
is(scalar @$growptr, $nrows + 1);

# S_GetSolutionQuality
ok($rtn = $c->S_GetSolutionQuality, "S_GetSolutionQuality");

# S_ClusterStats
ok($rtn = $c->S_GetClusterStats, "S_GetClusterStats");
is(scalar @{$rtn->{clusters}}, 2);
is(scalar @{$rtn->{rows}}, 4);



# test graph based clustering with dense matrix
# 1 1 0 0
# 1 1 0 0
# 0 0 1 2
# 0 0 1 1
# 1 1 1 3
# 1 1 1 2
# 0 1 4 0
# 0 1 5 0

$c = new Statistics::Cluto;
$rowval = [
[1, 1, 0, 0],
[1, 1, 0, 0],
[0, 0, 1, 2],
[0, 0, 1, 1],
[1, 1, 1, 3],
[1, 1, 1, 2],
[0, 1, 4, 0],
[0, 1, 5, 0]
];
$c->set_dense_matrix(8, 4, $rowval);

$c->set_options({
    rowmodel => CLUTO_ROWMODEL_NONE,
    colmodel => CLUTO_COLMODEL_NONE,
    nclusters => 4,
    mincomponent => 0,
    nnbrs => 2,
    pretty_format => 1,
});

# VP_GraphClusterRB
ok($rtn = $c->VP_GraphClusterRB, "VP_GraphClusterRB");
is(scalar(grep $_, @$rtn), 4);


# test scluster graph based clustering with dense matrix
# 1 9 1 1 1 1
# 9 1 1 1 1 1
# 1 1 1 9 1 1
# 1 1 9 1 1 1
# 1 1 1 1 1 9
# 1 1 1 1 9 1

$c = new Statistics::Cluto;
$rowval = [
[1, 9, 1, 1, 1, 1],
[9, 1, 1, 1, 1, 1],
[1, 1, 1, 9, 1, 1],
[1, 1, 9, 1, 1, 1],
[1, 1, 1, 1, 1, 9],
[1, 1, 1, 1, 9, 1]
];
$c->set_dense_matrix(6, 6, $rowval);

$c->set_options({
    nclusters => 4,
    nnbrs => 2,
    pretty_format => 1,
});

# SP_GraphClusterRB
ok($rtn = $c->SP_GraphClusterRB, "SP_GraphClusterRB");
is(scalar(grep $_, @$rtn), 3);

__END__
