
use Test::More qw(no_plan);
use RRDTool::OO;

my $aref = [
    step        => 1,
    data_source => { name      => "mydatasource",
                     type      => "GAUGE" },
    archive => { rows => 30 }
];

my $rrd = RRDTool::OO->new( file => "foo" );
$rrd->create( @{ $aref } );

ok !exists $aref->[5]->{ cfunc }, "input parameter not overwritten";

unlink "foo";
