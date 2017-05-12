#!/usr/bin/perl
# Test of Net::IMP::ProtocolPinning

use strict;
use warnings;
use Net::IMP::ProtocolPinning;
use Net::IMP;
use Net::IMP::Debug;
use Data::Dumper;
use Test::More;

$Data::Dumper::Sortkeys = 1;
$DEBUG=0; # enable for extensiv debugging

my @testdef = (
    {
	id => 'basic',
	dtype => [ IMP_DATA_STREAM, IMP_DATA_PACKET ],
	rules => [
	    { dir => 0, rxlen => 4, rx => qr/affe/ },
	    { dir => 1, rxlen => 4, rx => qr/hund/ },
	    { dir => 0, rxlen => 2, rx => qr/ok/ }
	],
	in => [
	    [0,'affe'],
	    [1,'hund'],
	    [0,'ok' ]
	],
	rv => [
	    [ IMP_PASS,0,4 ],
	    [ IMP_PASS,1,4 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },{
	id => 'wrong_dir.0',
	in => [
	    [1,'hund'],
	    [0,'affe'],
	    [0,'ok' ]
	],
	rv => [[IMP_DENY, 1, 'rule#0 data from wrong dir 1' ]],
    },{
	id => 'ignore_order',
	ignore_order => 1,
	rv => [
	    [ IMP_PASS,1,4 ],
	    [ IMP_PASS,0,4 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    }, {
	id => 'max_unbound.undef',
	dtype => [ IMP_DATA_STREAM ],
	rules => [
	    { dir => 1, rxlen => 7, rx => qr/SSH-2\.0/ }
	],
	in => [
	    [ 0,'huhu' ],
	    [ 1,"SSH-2.0-OpenSSH_5.9p1 Debian-5ubuntu1\n" ],
	],
	rv => [
	    [ IMP_PAUSE,0 ],
	    [ IMP_CONTINUE,0 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    }, {
	id => 'max_unbound.undef-packet',
	dtype => [ IMP_DATA_PACKET ],
	rules => [
	    # should match complete packet
	    { dir => 1, rxlen => 100, rx => qr/SSH-2\.0.*/ }
	],
    }, {
	id => 'max_unbound.fit.0',
	dtype => [ IMP_DATA_STREAM, IMP_DATA_PACKET ],
	max_unbound => [4,], # "huhu" fits in 4 bytes
	rv => [
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    }, {
	id => 'max_unbound.nofit',
	max_unbound => [0,],
	rv => [[IMP_DENY, 0, 'unbound buffer size=4 > max_unbound(0)' ]],
    }, {
	id => 'max_unbound.fit.1',
	dtype => [ IMP_DATA_STREAM ],
	max_unbound => [100,100],
	rules => [
	    { dir => 0, rxlen => 5, rx => qr/affe\n/ },
	    { dir => 1, rxlen => 5, rx => qr/hund\n/ },
	],
	in => [
	    [ 0,'affe' ],[0,"\njuppi"],
	    [ 1,'hu' ],[1,'nd'],[1,"\n"],
	],
	rv => [
	    [ IMP_PASS,0,5 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    }, {
	id => 'extend_match.0',
	max_unbound => [1,0],
	rules => [
	    { dir => 0, rxlen => 12, rx => qr/cloud(ella)?(ria)?/ },
	    { dir => 1, rxlen => 1, rx => qr/./ }
	],
	in => [
	    [ 0,'clou' ],
	    [ 0,'de' ],
	    [ 0,'llar' ],
	    [ 0,'iad' ],
	    [ 1,'foo' ],
	],
	rv => [
	    [ IMP_PASS,0,5 ],
	    [ IMP_PASS,0,9 ],
	    [ IMP_PASS,0,12 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    }, {
	id => 'extend_match.1',
	ignore_order => 0,
	max_unbound => [0,0],
	rules => [
	    { dir => 0, rxlen => 2, rx => qr/A+/ },
	    { dir => 0, rxlen => 10, rx => qr/B+/ }
	],
	in => [
	    [ 0,'A' ],
	    [ 0,'B' ],
	],
	rv => [
	    [ IMP_PASS,0,1 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    }, {
	id => 'extend_match.2',
	rules => [
	    { dir => 0, rxlen => 10, rx => qr/A+/ },
	    { dir => 1, rxlen => 10, rx => qr/B+/ }
	],
	in => [
	    [ 0,'A' ],
	    [ 1,'B' ],
	],
	rv => [
	    [ IMP_PASS,0,1 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },{
	id => 'extend_match.3',
	ignore_order => 1,
    },{
	id => 'extend_match.4',
	ignore_order => 0,
	rules => [
	    { dir => 0, rxlen => 6, rx => qr/AAA(BBB)?/ },
	    { dir => 0, rxlen => 6, rx => qr/CCC(DDD)?/ },
	    { dir => 1, rxlen => 1, rx => qr/./ },
	    { dir => 0, rxlen => 3, rx => qr/EEE/ },
	],
	in => [
	    [ 0,'AAAB' ],
	    [ 0,'BBC' ],
	    [ 0,'CC' ],
	    [ 1,'X' ],
	    [ 0,'DDD' ],
	],
	rv => [
	    [ IMP_PASS,0,3 ],
	    [ IMP_PASS,0,6 ],
	    [ IMP_PASS,0,9 ],
	    [ IMP_PASS,1,1 ],
	    [ IMP_DENY,0,"rule#3 did not match" ],
	],
    },{
	id => 'capture',
	max_unbound => [0,0],
	dtype => [ IMP_DATA_STREAM, IMP_DATA_PACKET ],
	rules => [ { dir => 0, rxlen => 8, rx => qr/(\w\w\w\w)\1/ } ],
	in => [[0,'toortoor']],
	rv => [
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'capture.fail',
	rules => [ { dir => 0, rxlen => 8, rx => qr/(\w\w\w\w)\1/ } ],
	in => [[0,'toorToor']],
	rv => [[IMP_DENY, 0, 'rule#0 did not match' ]],
    },
    {
	id => 'wrong_dir.1',
	ignore_order => 0,
	rules => [ { dir => 1, rxlen => 1, rx => qr/./ } ],
	in => [[0,'foo']],
	rv => [[IMP_DENY, 0, 'rule#0 data from wrong dir 0' ]],
    },
    {
	id => 'eof.0',
	dtype => [ IMP_DATA_STREAM ],
	rules => [ { dir => 1, rxlen => 2, rx => qr/../ } ],
	in => [[1,'X'],[1,'']],
	rv => [[IMP_DENY, 1, 'eof on 1 but unmatched rule#0' ]],
    },
    {
	id => 'eof.1',
	dtype => [ IMP_DATA_STREAM, IMP_DATA_PACKET ],
	rules => [
	    { dir => 1, rxlen => 1, rx => qr/A/ },
	    { dir => 1, rxlen => 1, rx => qr/B/ },
	],
	in => [[1,'A'],[1,'']],
	rv => [
	    [IMP_PASS, 1, 1 ],
	    [IMP_DENY, 1, 'eof on 1 but unmatched rule#1' ]
	],
    }, {
	id => 'eof.2',
	rules => [
	    { dir => 0, rxlen => 10, rx => qr/A+/ },
	    { dir => 1, rxlen => 1, rx => qr/B/ },
	    { dir => 0, rxlen => 10, rx => qr/C/ },
	],
	in => [
	    [ 0,'A' ],
	    [ 0,'' ],
	],
	rv => [
	    [IMP_PASS, 0, 1 ],
	    [IMP_DENY, 0, 'eof on 0 but unmatched rule#2' ]
	],
    }, {
	id => 'eof.3',
	rules => [
	    { dir => 0, rxlen => 10, rx => qr/A+/ },
	    { dir => 1, rxlen => 1, rx => qr/B/ },
	],
	in => [
	    [ 0,'A' ],
	    [ 0,'' ],
	    [ 1,'B' ],
	],
	rv => [
	    [IMP_PASS, 0, 1 ],
	    [IMP_PASS, 0, IMP_MAXOFFSET ],
	    [IMP_PASS, 1, IMP_MAXOFFSET ],
	],
    }, {
	id => 'look_ahead',
	max_unbound => [],
	dtype => [ IMP_DATA_STREAM ],
	ignore_order => 1,
	rules => [
	    { dir => 0, rxlen => 6, rx => qr/foo(?=bar)/ },
	    { dir => 1, rxlen => 6, rx => qr/bar(?=foo)/ }
	],
	in => [
	    [ 0,'fo' ], [ 0,'o' ], [ 0,'ba' ], [ 0,'rff' ],
	    [ 1,'b' ], [ 1,'arf' ], [ 1,'oobb' ],
	],
	rv => [
	    [ IMP_PAUSE,0 ],
	    [ IMP_PASS,0,3 ],             # foobar -> fwd 'foo'
	    [ IMP_CONTINUE,0 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ], # barfoo -> all done
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	]
    },
    {
	id => 'wildcard',
	max_unbound => [],
	ignore_order => 0,
	rules => [
	    { dir => 0, rxlen => 20, rx => qr/a.*b/ },
	    { dir => 1, rxlen => 20, rx => qr/C.*D/ },
	    { dir => 0, rxlen => 20, rx => qr/e.*f/ },
	    { dir => 1, rxlen => 20, rx => qr/G.*H/ },
	],
	in => [
	    [ 0,'a.b' ],
	    [ 1,'C.D' ],
	    [ 0,'e.f' ],
	    [ 1,'G.' ],
	    [ 1,'H' ],
	],
	rv => [
	    [ IMP_PASS,0,3 ],
	    [ IMP_PASS,1,3 ],
	    [ IMP_PASS,0,6 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	]
    },
    {
	id => 'dup',
	dtype => [ IMP_DATA_PACKET ],
	allow_dup => 1,
	rules => [
	    { dir => 0, rxlen => 1, rx => qr/A/ },
	    { dir => 0, rxlen => 1, rx => qr/B/ },
	    { dir => 0, rxlen => 1, rx => qr/C/ },
	],
	in => [
	    [ 0,'A' ],
	    [ 0,'B' ],
	    [ 0,'A' ],
	    [ 0,'A' ],
	    [ 0,'B' ],
	    [ 0,'C' ],
	],
	rv => [
	    [ IMP_PASS,0,1 ],
	    [ IMP_PASS,0,2 ],
	    [ IMP_PASS,0,3 ],
	    [ IMP_PASS,0,4 ],
	    [ IMP_PASS,0,5 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'reorder',
	allow_reorder => 1,
	in => [
	    [ 0,'A' ],
	    [ 0,'C' ],
	    [ 0,'B' ],
	],
	rv => [
	    [ IMP_PASS,0,1 ],
	    [ IMP_PASS,0,2 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'dup+reorder',
	allow_dup => 1,
	allow_reorder => 1,
	in => [
	    [ 0,'A' ],
	    [ 0,'C' ],
	    [ 0,'A' ],
	    [ 0,'C' ],
	    [ 0,'B' ],
	],
	rv => [
	    [ IMP_PASS,0,1 ],
	    [ IMP_PASS,0,2 ],
	    [ IMP_PASS,0,3 ],
	    [ IMP_PASS,0,4 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'more_at_end.0',
	max_unbound => [],
	ignore_order => 1,
	dtype => [ IMP_DATA_STREAM ],
	rules => [
	    { dir => 0, rxlen => 1, rx => qr/A/ },
	    { dir => 1, rxlen => 1, rx => qr/B/ },
	],
	in => [
	    [ 0,'AA' ],
	    [ 0,'AA' ],
	    [ 1,'BB' ],
	],
	rv => [
	    [ IMP_PAUSE,0 ],
	    [ IMP_PASS,0,1 ],
	    [ IMP_CONTINUE,0 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'more_at_end.1',
	max_unbound => [0,0],
	rv => [
	    [ IMP_DENY,0,'unbound buffer size=1 > max_unbound(0)' ]
	]
    },
    {
	id => 'more_at_end.2',
	max_unbound => [0,0],
	ignore_order => 1,
	dtype => [ IMP_DATA_STREAM ],
	rules => [
	    { dir => 0, rxlen => 4, rx => qr/A+/ },
	    { dir => 1, rxlen => 1, rx => qr/B/ },
	],
	in => [
	    [ 0,'AA' ],
	    [ 0,'AA' ],
	    [ 1,'BB' ],
	],
	rv => [
	    [ IMP_PASS,0,2 ],
	    [ IMP_PASS,0,4 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'more_at_end.3',
	max_unbound => [0,0],
	ignore_order => 1,
	dtype => [ IMP_DATA_STREAM ],
	rules => [
	    { dir => 0, rxlen => 1, rx => qr/A/ },
	    { dir => 0, rxlen => 10, rx => qr/B.*C/ },
	    { dir => 1, rxlen => 1, rx => qr/a/ },
	    { dir => 1, rxlen => 10, rx => qr/b.*c/ },
	],
	in => [
	    [ 0,'ABXXC' ],
	    [ 1,'abxxcxxxxxxxxxxxxxxxxxxxx' ],
	],
	rv => [
	    [ IMP_PASS,0,5 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
    {
	id => 'pause.0',
	max_unbound => [],
	rules => [
	    { dir => 0, rxlen => 1, rx => qr/A/ },
	    { dir => 1, rxlen => 1, rx => qr/B/ },
	    { dir => 1, rxlen => 1, rx => qr/C/ },
	],
	in => [
	    [ 0,'AXXXXXX' ],
	    [ 1,'B' ],
	    [ 0,'XXXXXX' ],
	    [ 1,'C' ],
	],
	rv => [
	    [ IMP_PAUSE,0 ],
	    [ IMP_PASS,0,1 ],
	    [ IMP_PASS,1,1 ],
	    [ IMP_CONTINUE,0 ],
	    [ IMP_PASS,0,IMP_MAXOFFSET ],
	    [ IMP_PASS,1,IMP_MAXOFFSET ],
	],
    },
);

my %only = map { $_ => 1 } @ARGV;
my (%glob,@tests);
my $count_tests = 0;
for(@testdef) {
    %glob = ( %glob, %$_ );
    $_->{id} or next;
    $only{ $_->{id} } or next if %only;
    push @tests, { %glob } if $_->{id};
    $count_tests += @{ $tests[-1]{dtype} };
}

plan tests => $count_tests;

my (%test,$out);
for my $test (@tests) {

    my %config = (
	rules          => $test->{rules},
	max_unbound    => $test->{max_unbound},
	ignore_order   => $test->{ignore_order},
	allow_dup      => $test->{allow_dup},
	allow_reorder  => $test->{allow_reorder},
    );
    if ( my @err = Net::IMP::ProtocolPinning->validate_cfg(%config) ) {
	diag("@err");
	fail("config[$test->{id}] not valid");
	next;
    }

    my $factory = Net::IMP::ProtocolPinning->new_factory(%config);

    for my $dtype (@{$test->{dtype}}) {
	my @rv;
	my $cb = sub {
	    debug( "callback: ".Dumper(\@_));
	    push @rv,@_
	};

	my $analyzer = $factory->new_analyzer( cb => [$cb] );

	for( @{$test->{in}} ) {
	    my ($dir,$data,$ldtype) = @$_;
	    debug("send '$data' to $dir");
	    $analyzer->data($dir,$data,0,$ldtype||$dtype);
	}

	if ( Dumper(\@rv) ne Dumper($test->{rv})) {
	    fail("$test->{id}|$dtype");
	    diag( "--- expected---\n".Dumper($test->{rv}).
		"\n--- got ---\n".Dumper(\@rv));
	    die;
	} else {
	    pass("$test->{id}|$dtype");
	}
    }
}
