#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my (@mods,@bin);
test: for (
    [ 'Net::IMP::Remote' ],
    [ 'Net::IMP::Remote::Client' ],
    [ 'Net::IMP::Remote::Server' ],
    [ 'Net::IMP::Remote::Storable' ],
    [ 'Net::IMP::Remote::Sereal' => 'Sereal::Encoder!0.36','Sereal::Decoder!0.36' ],
    [ 'bin/imprpc_server.pl' => 'AnyEvent!6.12' ],
    ){
    my ($name,@deps) = @$_;
    for (@deps) {
	my ($dep,$want_version) = split('!');
	if ( ! eval "require $dep" ) {
	    diag("cannot load $dep");
	    next test;
	} elsif ( $want_version ) {
	    no strict 'refs';
	    my $v = ${"${dep}::VERSION"};
	    if ( ! $v or $v < $want_version ) {
		diag("wrong version $dep - have $v want $want_version");
		next test;
	    }
	}
    }
    if ( $name =~m{::} ) {
	push @mods,$name;
    } else {
	push @bin,$name;
    }
}

plan tests => @bin+@mods;
for (@mods) {
    eval "use $_";
    cmp_ok( $@,'eq','', "loading $_" );
}

for(@bin) {
    ok( system( $^X,'-Mblib','-cw',$_ ) == 0, "syntax check $_" );
}
