use Test::Most;
use FindBin;
use OpusVL::SysParams;
use File::Temp ();

# setup config file

my $tmp = File::Temp->new( SUFFIX => '.conf' );
print $tmp qq{
<Model::SysParams>
    connect_info dbi:SQLite:$FindBin::Bin/simple-test.db
    connect_info colin
</Model::SysParams>
};
close $tmp;
$ENV{OPUSVL_SYSPARAMS_CONFIG} = $tmp->filename;


# now just create the object and use it.

my $params = OpusVL::SysParams->new();

$params->set('test.array', [ 1, 2, 3 ]);
eq_or_diff $params->get('test.array'), [ 1, 2, 3 ];

done_testing;
