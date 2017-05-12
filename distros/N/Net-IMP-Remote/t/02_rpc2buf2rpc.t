use strict;
use warnings;
use Test::More;

use Net::IMP qw(:DEFAULT :log);
use Net::IMP::Remote::Protocol;
use Net::IMP::Debug;
use Scalar::Util 'dualvar';
#$DEBUG=1;

my @impl;
impl: for my $impl (
    [ Storable => 'Storable' ],
    [ Sereal => 'Sereal::Encoder!0.36','Sereal::Decoder!0.36' ]
) {
    my ($name,@deps) = @$impl;
    for (@deps) {
	my ($dep,$want_version) = split('!');
	if ( ! eval "require $dep" ) {
	    diag("cannot load $dep");
	    next impl;
	} elsif ( $want_version ) {
	    no strict 'refs';
	    my $v = ${"${dep}::VERSION"};
	    if ( ! $v or $v < $want_version ) {
		diag("wrong version $dep - have $v want $want_version");
		next impl;
	    }
	}
    }
    push @impl,$name;
}

plan tests => 73*@impl;
for my $impl (@impl) {
    diag("implementation $impl");
    my $class = Net::IMP::Remote::Protocol->load_implementation($impl);
    ok($class,"loaded impl $impl");
    my $ser = $class->new;
    ok($ser,"created serializer for $impl");

    diag('init');
    my $buf = $ser->init(1);
    my $rpc = $ser->buf2rpc(\$buf);
    ok($buf eq '',"buf processed fully");
    ok(!$rpc,"init produced no rpc");

    diag('op exception');
    $buf = $ser->rpc2buf([ IMPRPC_EXCEPTION,'exceptional exception' ]);
    $rpc = $ser->buf2rpc(\$buf);
    ok($buf eq '',"buf processed fully");
    ok($rpc->[0] == IMPRPC_EXCEPTION,"dualvar op integer comparison");
    ok($rpc->[0] eq IMPRPC_EXCEPTION,"dualvar op string comparison");
    ok($rpc->[1] eq 'exceptional exception','value comparison');

    diag('op set_interface');
    $buf = $ser->rpc2buf([ IMPRPC_SET_INTERFACE, [
	IMP_DATA_STREAM,
	[ IMP_PASS, IMP_PREPASS, IMP_LOG ]
    ]]);
    $rpc = $ser->buf2rpc(\$buf);
    ok($buf eq '',"buf processed fully");
    {
	my ($op,$if) = @$rpc;
	my ($dtype,$rtypes) = @$if;
	ok($op == IMPRPC_SET_INTERFACE,"dualvar op integer comparison");
	ok($dtype == IMP_DATA_STREAM,"dualvar dtype integer comparison");
	ok($dtype eq IMP_DATA_STREAM,"dualvar dtype string comparison");
	ok($rtypes->[1] == IMP_PREPASS,"dualvar rtype integer comparison");
	ok($rtypes->[1] eq IMP_PREPASS,"dualvar rtype string comparison");
    }

    my $footype = dualvar(-2,'foo');
    for my $op ( IMPRPC_GET_INTERFACE, IMPRPC_INTERFACE ) {
	diag("op $op()");
	$buf = $ser->rpc2buf([ $op ]);
	$rpc = $ser->buf2rpc(\$buf);
	ok($buf eq '',"buf processed fully");
	my ($op,@args) = @$rpc;
	ok($op == $op,"dualvar op integer comparison");
	ok(!@args,"args empty");

	diag("op $op(...,[new_type,any])");
	$buf = $ser->rpc2buf([ $op,
	    [ IMP_DATA_STREAM, [ IMP_PASS, IMP_PREPASS ]],
	    [ $footype, undef ],
	]);
	$rpc = $ser->buf2rpc(\$buf);
	ok($buf eq '',"buf processed fully");
	($op,@args) = @$rpc;
	ok($op == $op,"dualvar op integer comparison");
	ok(@args ==2,"\@args==2");
	ok($args[0][0] == IMP_DATA_STREAM,"dualvar dtype integer comparison");
	ok($args[0][0] eq IMP_DATA_STREAM,"dualvar dtype string comparison");
	ok($args[0][1][1] == IMP_PREPASS,"dualvar rtype integer comparison");
	ok($args[0][1][1] eq IMP_PREPASS,"dualvar rtype string comparison");

	ok($args[1][0] == $footype,"new dualvar dtype integer comparison");
	ok($args[1][0] eq $footype,"new dualvar dtype string comparison");
	ok(!defined $args[1][1],"no rtypes");
    }

    diag('op new_analyzer');
    $buf = $ser->rpc2buf([ IMPRPC_NEW_ANALYZER, 2645, {
	saddr => '1.1.1.1', sport => 2162,
	caddr => '2.2.2.2', cport => 80,
    }]);
    $rpc = $ser->buf2rpc(\$buf);
    ok($buf eq '',"buf processed fully");
    {
	my ($op,$id,$ctx) = @$rpc;
	ok($op eq IMPRPC_NEW_ANALYZER,"dualvar op string comparison");
	ok($id == 2645,"value id");
	ok($ctx->{caddr} eq '2.2.2.2','value inside context');
    }

    diag('op del_analyzer');
    $buf = $ser->rpc2buf([ IMPRPC_DEL_ANALYZER, 2645 ]);
    $rpc = $ser->buf2rpc(\$buf);
    ok($buf eq '',"buf processed fully");
    {
	my ($op,$id) = @$rpc;
	ok($op eq IMPRPC_DEL_ANALYZER,"dualvar op string comparison");
	ok($id == 2645,"value id");
    }


    diag('data');
    $buf = $ser->rpc2buf([ IMPRPC_DATA, 1234,0,20,$footype,"foobar" ]);
    $rpc = $ser->buf2rpc(\$buf);
    ok($buf eq '',"buf processed fully");
    {
	my ($op,$id,$dir,$off,$type,$data) = @$rpc;
	ok($op eq IMPRPC_DATA,"dualvar op string comparison");
	ok($id == 1234,"value id");
	ok($off == 20,"value offset");
	ok($type == $footype,"value type dualvar integer comparison");
	ok($type eq $footype,"value type dualvar string comparison");
	ok($data eq 'foobar',"value data");
    }

    diag('multiple results in chunked buffer');
    $buf = $ser->rpc2buf([ IMPRPC_RESULT,1234,IMP_REPLACE,0,200,"barfoot" ]);
    my $buf2 = $ser->rpc2buf([ IMPRPC_RESULT,1234,IMP_LOG,1,160,10,IMP_LOG_INFO,"hi!" ]);
    $buf .= substr($buf2,0,1,'');
    $rpc = $ser->buf2rpc(\$buf);
    ok(length($buf) == 1,"left one byte inside buf");
    {
	my ($op,$id,$rtype,$dir,$off,$data) = @$rpc;
	ok($op == IMPRPC_RESULT,"dualvar op integer comparison");
	ok($id == 1234,"value id");
	ok($rtype == IMP_REPLACE,"value rtype dualvar integer comparison");
	ok($rtype eq IMP_REPLACE,"value rtype dualvar string comparison");
	ok($dir == 0,"value dir");
	ok($off == 200,"value offset");
	ok($data eq 'barfoot',"value data");
    }
    while ( $buf2 ne '' ) {
	$buf .= substr($buf2,0,1,'');
	$rpc = $ser->buf2rpc(\$buf) and last;
    }
    ok($buf2 eq '',"result#2 completly processed");
    ok($buf eq '',"buf processed fully");
    {
	my ($op,$id,$rtype,$dir,$off,$len,$logtype,$msg) = @$rpc;
	ok($op == IMPRPC_RESULT,"dualvar op integer comparison");
	ok($id == 1234,"value id");
	ok($rtype == IMP_LOG,"value rtype dualvar integer comparison");
	ok($dir == 1,"value dir");
	ok($off == 160,"value offset");
	ok($len == 10,"value len");
	ok($logtype == IMP_LOG_INFO,"value logtype dualvar integer comparison");
	ok($logtype eq IMP_LOG_INFO,"value logtype dualvar string comparison");
	ok($msg eq 'hi!',"value msg");
    }

    #print Dumper($rpc); use Data::Dumper;
}
