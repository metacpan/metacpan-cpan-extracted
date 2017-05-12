# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use Oracle::Loader;
my $class = 'Oracle::Loader';
my $obj = Oracle::Loader->new;

isa_ok($obj, $class);

my ($v, @a);
my @md0 = ( qw(read_definition crt_sql crt_ctl
            check_infile create load batch read_log 
            sort_array compressArray report_results report_errors
    )); 
foreach my $m (@md0) {
    $obj->$m if ($m =~ /^(get_|set_)/); 
    can_ok($obj, $m);
}
diag("Test scalar parameter methods...");
my @md1 = (    # '$' - scalar parameter
      qw (cols_ref out_fh)
); 
my %df1 = (    # default values for '$' type parameters
    cols_ref=>undef, out_fh=>undef 
);
my ($d, $n) = ("", "");
foreach my $m (@md1) {
    can_ok($class, $m);
    if (exists $df1{$m}) { $d = $df1{$m};
    } else { $d = $obj->$m; }
    if (! defined($d)) {
        is($obj->$m, $d, "$class->$m='undef'"); # check default
    } else {
        is($obj->$m, $d, "$class->$m='$d'");    # check default
    }
    if (defined($d) && $d =~ /^[\d\.]+$/) { $v = 1;
    } else { $v = 'xxx'; }
    ok($obj->$m($v),"$class->$m($v)");          # assign new value
    is($obj->$m, $v, "$class->$m=$v");          # check new value
    $obj->$m($d);                               # set back to default
}
diag("Test \$obj->param parameter methods...");
my @md2 = (    # '$' - scalar parameter
    qw(sql_fn ctl_fn dat_fn bad_fn dis_fn def_fn log_fn spool 
       dbtab dbts dbsid dbhome dbconn dbusr dbpwd ts_iext ts_next 
       db_type append drop vbm direct overwrite src_dir DirSep 
       commit  reset relax_req add_center _counter study_number
      )
);
my %df2 = (    # default values for '$' type parameters
    nothing_here => 1
);
my $pm = $obj->param; 
# print "PM = $pm\n"; 
foreach my $m (@md2) {
    can_ok($pm, $m);
    if (exists $df2{$m}) { $d = $df2{$m};
    } else { $d = $pm->$m; }
    if (! defined($d)) {
        is($pm->$m, $d, "$class->$m='undef'"); # check default
    } else {
        is($pm->$m, $d, "$class->$m='$d'");    # check default
    }
    if (defined($d) && $d =~ /^[\d\.]+$/) { $v = 1;
    } else { $v = 'xxx'; }
    ok($pm->$m($v),"$class->$m($v)");          # assign new value
    is($pm->$m, $v,"$class->$m=$v");           # check new value
    $pm->$m($d);                               # set back to default
}
diag("Test \$obj->conn parameter methods...");
my @md3 = (    # '@' - array parameter
    qw(Oracle CSV)
);
my %df3 = (    # default values for '@' type parameters
    Oracle=>[], CSV=>[]
);
$pm = $obj->conn; 
foreach my $m (@md3) {
    can_ok($pm, $m); 
    if (exists $df3{$m}) { $d = $df3{$m};
    } else { $d = $pm->$m; }
    $n = $pm->$m; 
    if (! defined($d)) {
        is_deeply($n, $d, "$class->$m='undef'"); # check default
    } else {
        is_deeply($n, $d, "$class->$m='$d'");    # check default
    }
    $v = [1,2,3];
    $pm->$m($v);                                # assign new value
    eq_array($pm->$m, $v, "$pm->$m=$v");        # check new value
    $pm->$m($d);                                # set back to default
}
diag("Test Oracle variables...");
my $ohd = $ENV{ORACLE_HOME};
my $sid = $ENV{ORACLE_SID}; 
my $slr = "";
   $slr = join '/', $ohd, 'bin','sqlldr' if $ohd; 
ok(-d $ohd, "OracleHome=$ohd") if $ohd; 
ok(-f $slr, "Loader=$slr"); 
$obj->param->dbsid($sid);
$obj->param->dbhome($ohd); 
$obj->param->dbusr('scott');
$obj->param->dbpwd('tiger');

1;

