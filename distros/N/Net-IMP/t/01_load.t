#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my (@mods,@bin);
test: for (
    [ 'Net::IMP' ],
    [ 'Net::IMP::Debug' ],
    [ 'Net::IMP::Base' ],
    [ 'Net::IMP::Pattern' ],
    [ 'Net::IMP::ProtocolPinning' ],
    [ 'Net::IMP::Filter' ],
    [ 'Net::IMP::SessionLog' ],
    [ 'Net::IMP::Cascade' ],
#    [ 'Net::IMP::HTTP_AddCSPHeader'  => 'WWW::CSP','Net::Inspect' ],
    [ 'Net::IMP::Example::LogServerCertificate' => 'Net::SSLeay' ],
    [ 'Net::IMP::Example::IRCShout' ],
    [ 'bin/imp-pcap-filter.pl' => 'Net::Inspect','Net::PcapWriter!0.721' ],
    [ 'bin/imp-relay.pl' => 'Net::Inspect','AnyEvent!6.12' ],
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
