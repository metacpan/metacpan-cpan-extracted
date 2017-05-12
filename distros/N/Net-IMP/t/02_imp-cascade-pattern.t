#!/usr/bin/perl
# Test of Net::IMP::Cascade combined with Net::IMP::Pattern

use strict;
use warnings;
use Net::IMP::Cascade;
use Net::IMP::Pattern;
use Net::IMP::Debug;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Test::More;

$DEBUG=0; # enable for extensiv debugging

# if you want to run only selected tests add test numbers to cmdline
my %only = map { $_ =>1 } @ARGV;
my @tests = (
    {
	mod => [
	    [ qr/fuck/,4,'replace','i' ],
	],
	in => 'xx shfuckt xx',
	out => 'xx shit xx',
    }, {
	mod => [
	    [ qr/shit/,4,'replace','foo' ],
	],
	in => 'xx shit xx',
	out => 'xx foo xx',
    }, {
	mod => [
	    [ qr/fuck/,4,'replace','shit' ],
	    [ qr/shit/,4,'replace','foo' ],
	],
	in => 'xx fuck xx',
	out => 'xx foo xx',
    }, {
	in => 'xx shfuckit xx',
	out => 'xx shfooit xx',
    }, {
	mod => [
	    [ qr/fuck/,4,'replace','i' ],
	    [ qr/shit/,4,'replace','foo' ],
	],
	in => 'xx shfuckt xx',
	out => 'xx foo xx',
    }, {
	mod => [
	    [ qr/shit/,4,'replace','foo' ],
	],
	in => [ 'xx sh', 'i','t xx' ],
	out => 'xx foo xx',
    }, {
	mod => [
	    [ qr/fuck/,4,'replace','i' ],
	    [ qr/shit/,4,'replace','foo' ],
	],
	in => 'xx shfuckt fuck shitxx',
	out => 'xx foo i fooxx',
    }, {
	mod => [
	    [ qr/shit/,4,'replace','foobar' ],
	    [ qr/foobar /,7,'replace','bingo' ],
	],
	in => 'xx shit i shitxx',
	out => 'xx bingoi foobarxx',
    }, {
	mod => [
	    [ qr/fuck/,4,'replace','i' ],
	    [ qr/shit/,4,'replace','foobar' ],
	    [ qr/foobar/,6,'replace','bingo' ],
	],
	in => 'xx shfuckt fuck shitxx',
	out => 'xx bingo i bingoxx',
    }
);

plan tests => @tests - keys(%only);

my (%test,$out);
TEST: for(my $i=0;$i<@tests;$i++) {
    %test = ( %test,%{$tests[$i]} ); # redefine parts of previous
    next if %only && ! $only{$i};

    my @m;
    for (@{ $test{mod} }) {
	my %config = (
	    rx       => $_->[0],
	    rxlen    => $_->[1],
	    action   => $_->[2],
	    actdata  => $_->[3]
	);
	if ( my @err = Net::IMP::Pattern->validate_cfg(%config) ) {
	    fail("config[$i] not valid");
	    diag( "@err");
	    next TEST;
	}
	push @m, Net::IMP::Pattern->new_factory(%config);
    }

    my $analyzer = Net::IMP::Cascade->new_factory( parts => \@m );
    my $filter = myFilter->new( $analyzer->new_analyzer );
    $out = '';
    my $in = $test{in};

    diag("===================== [Test#$i] ========================")
	if $DEBUG;

    eval {
	$filter->in(0,$_) for (ref($in) ? @$in:$in);
	$filter->in(0,'');
    };
    if ($@) {
	fail("cascade pattern test[$i] got exception");
	diag(Dumper({ err => $@, real_out => $out, %test }));
    } elsif ( $test{out} ne $out ) {
	fail("cascade pattern test[$i] output not expected");
	diag(Dumper({ real_out => $out, %test }));
    } else {
	pass("cascade pattern test[$i]");
    }
}



package myFilter;
use base 'Net::IMP::Filter';
sub out {
    my ($self,$dir,$data) = @_;
    $out .= $data;
}
