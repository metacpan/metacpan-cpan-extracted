use strict;
use warnings;
use Test::More;
use Test::Exception;
use Mojo::Collection;

my $c_array  = Mojo::Collection->new([0,"a","x"],[1,"b","y"],[2,"c","z"])->with_roles('+GroupBy');
my $c_hash   = Mojo::Collection->new({k=>"a",v=>1},{k=>"b",v=>2},{k=>"c",v=>1})->with_roles('+GroupBy');

# -- coderef passthrough --------------------------------------------------
my $sub = sub { 42 };
is $c_array->_make_group_sub($sub), $sub, "coderef passthrough";

# -- single scalar index on arrayrefs -------------------------------------
my $f = $c_array->_make_group_sub(1);
is $f->([0,"a","x"]), "a", "single scalar index";

# -- index 0 (defined but false) ------------------------------------------
$f = $c_array->_make_group_sub(0);
is $f->([0,"a","x"]), 0, "index 0 works (defined check)";

# -- single element arrayref ----------------------------------------------
$f = $c_array->_make_group_sub([1]);
is $f->([0,"a","x"]), "a", "single element arrayref";

# -- single scalar key on hashrefs ----------------------------------------
$f = $c_hash->_make_group_sub("k");
is $f->({k=>"a",v=>1}), "a", "single scalar key on hashref";

# -- multiple scalars (composite key) on arrayrefs ------------------------
$f = $c_array->_make_group_sub(0, 1);
my $k1 = $f->([0,"a","x"]);
my $k2 = $f->([0,"a","y"]);
my $k3 = $f->([1,"a","x"]);
is $k1, $k2, "composite key: same 0,1 values match";
isnt $k1, $k3, "composite key: different 0 values dont match";

# -- arrayref of multiple keys (composite) --------------------------------
$f = $c_array->_make_group_sub([0, 1]);
my $k4 = $f->([0,"a","x"]);
is $k1, $k4, "arrayref of keys same as multiple scalars";

# -- composite key on hashrefs --------------------------------------------
$f = $c_hash->_make_group_sub("k", "v");
my $k5 = $f->({k=>"a",v=>1});
my $k6 = $f->({k=>"a",v=>2});
my $k7 = $f->({k=>"a",v=>1});
isnt $k5, $k6, "composite hash key: different v dont match";
is   $k5, $k7, "composite hash key: same values match";

# -- bad argument ---------------------------------------------------------
dies_ok { $c_array->_make_group_sub(\"scalar_ref") } "croaks on bad argument";

# -- integration: group_by with scalar index ------------------------------
my $grouped = $c_array->group_by(1);
is_deeply $grouped->to_hash,
    { a => [[0,"a","x"]], b => [[1,"b","y"]], c => [[2,"c","z"]] },
    "group_by with scalar index";

# -- integration: group_by with composite key -----------------------------
my $c2 = Mojo::Collection->new([0,1],[0,2],[1,1],[1,2])->with_roles('+GroupBy');
$grouped = $c2->group_by([0,1]);
is scalar $grouped->to_array->@*, 4, "composite key produces 4 groups";

done_testing;
