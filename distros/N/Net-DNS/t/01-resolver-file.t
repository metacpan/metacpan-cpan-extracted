#!/usr/bin/perl
# $Id: 01-resolver-file.t 1910 2023-03-30 19:16:30Z willem $
#

use strict;
use warnings;
use File::Spec;
use Test::More tests => 16;
use TestToolkit;

use Net::DNS::Resolver;

local $ENV{'RES_NAMESERVERS'};
local $ENV{'RES_SEARCHLIST'};
local $ENV{'LOCALDOMAIN'};
local $ENV{'RES_OPTIONS'};


my $class = 'Net::DNS::Resolver';

my $config = File::Spec->catfile(qw(t custom.txt));		# .txt to run on Windows


for my $resolver ( $class->new( config_file => $config ) ) {
	ok( $resolver->isa($class), "new( config_file => '$config' )" );

	my @servers = $resolver->nameservers;
	ok( scalar(@servers), 'nameservers list populated' );
	is( $servers[0], '10.0.1.128', 'nameservers list correct' );
	is( $servers[1], '10.0.2.128', 'nameservers list correct' );

	my @search = $resolver->searchlist;
	ok( scalar(@search), 'searchlist populated' );
	is( $search[0], 'alt.net-dns.org', 'searchlist correct' );
	is( $search[1], 'ext.net-dns.org', 'searchlist correct' );

	is( $resolver->domain, $search[0], 'domain correct' );

	is( $class->domain, $resolver->domain, 'initial config sets defaults' );
}


$class->domain('domain.default');

for my $resolver ( $class->new( config_file => $config ) ) {
	ok( $resolver->isa($class), "new( config_file => $config )" );

	my @servers = $resolver->nameservers;
	ok( scalar(@servers), 'nameservers list populated' );

	my @search = $resolver->searchlist;
	ok( scalar(@search), 'searchlist populated' );
	is( $search[0], 'alt.net-dns.org', 'searchlist correct' );

	is( $resolver->domain, $search[0], 'domain correct' );

	isnt( $class->domain, $resolver->domain, 'default config unchanged' );
}


exception( 'new( config_file => ?', sub { $class->new( config_file => 'nonexist.txt' ) } );

exit;

