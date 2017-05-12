#!perl -T

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
	use_ok( 'TRD::Velocity' );
}

my $result;
$result = &test_param();
ok( $result, 'test_param' );
$result = &test_if();
ok( $result, 'test_if' );
$result = &test_foreach();
ok( $result, 'test_foreach' );
$result = &test_escape();
ok( $result, 'test_escape' );
$result = &test_escape2();
ok( $result, 'test_escape2' );
$result = &test_unescape();
ok( $result, 'test_unescape' );

sub test_param {
	my $velo = new TRD::Velocity;
	my $templ = 'TEST=${test}';
	$velo->setTemplateData( $templ );
	$velo->set( 'test', 'OK' );
	my $doc = $velo->marge();

	if( $doc eq 'TEST=OK' ){
		1;
	} else {
		undef;
	}
}

sub test_if {
	my $velo = new TRD::Velocity;
	my $templ= 'TEST=#if( $test eq \'OK\' )OK#elseNG#end';
	$velo->setTemplateData( $templ );
	$velo->set( 'test', 'OK' );
	my $doc = $velo->marge();

	if( $doc eq 'TEST=OK' ){
		1;
	} else {
		undef;
	}
}
	
sub test_foreach {
	my $velo = new TRD::Velocity;
	my $templ= 'TEST=#foreach( $item in $items )${item.value}#end';
	$velo->setTemplateData( $templ );

	my $items;
	for( my $i=0; $i<10; $i++ ){
		my $item = { 'value' => 'OK'. ($i+1) };
		push( @{$items}, $item );
	}
	$velo->set( 'items', $items );
	my $doc = $velo->marge();

	if( $doc eq 'TEST=OK1OK2OK3OK4OK5OK6OK7OK8OK9OK10' ){
		# ok
		1;
	} else {
		# ng
		undef;
	}
}

sub test_escape {
	my $velo = new TRD::Velocity;
	my $templ= 'TEST=${test}';
	$velo->setTemplateData( $templ );

	my $test = qq!<>&'"!;
	$velo->set( 'test', $test );

	my $doc = $velo->marge();

#	print STDERR "doc=${doc}\n";

	if( $doc eq 'TEST=&lt;&gt;&amp;&#39;&quot;' ){
		# ok
		1;
	} else {
		# ng
		undef;
	}
}

sub test_escape2 {
	my $velo = new TRD::Velocity;
	my $templ= 'TEST=${test}.escape()';
	$velo->setTemplateData( $templ );

	my $test = qq!<>&'"!;
	$velo->set( 'test', $test );

	my $doc = $velo->marge();

#	print STDERR "doc=${doc}\n";

	if( $doc eq 'TEST=&lt;&gt;&amp;&#39;&quot;' ){
		# ok
		1;
	} else {
		# ng
		undef;
	}
}

sub test_unescape {
	my $velo = new TRD::Velocity;
	my $templ= 'TEST=${test}.unescape()';
	$velo->setTemplateData( $templ );

	my $test = qq!<>&'"!;
	$velo->set( 'test', $test );

	my $doc = $velo->marge();

#	print STDERR "doc=${doc}\n";

	if( $doc eq 'TEST=<>&\'"' ){
		# ok
		1;
	} else {
		# ng
		undef;
	}
}

