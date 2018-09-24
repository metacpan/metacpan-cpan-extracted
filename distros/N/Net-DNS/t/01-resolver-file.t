# $Id: 01-resolver-file.t 1709 2018-09-07 08:03:09Z willem $

use strict;
use File::Spec;
use Test::More tests => 16;

use Net::DNS::Resolver;

local $ENV{'RES_NAMESERVERS'};
local $ENV{'RES_SEARCHLIST'};
local $ENV{'LOCALDOMAIN'};
local $ENV{'RES_OPTIONS'};


my $class = 'Net::DNS::Resolver';

my $config = File::Spec->catfile(qw(t custom.txt));		# .txt to run on Windows

{
	$class->domain('domain.default');
	my $resolver = $class->new( config_file => $config );
	ok( $resolver->isa($class), "new( config_file => '$config' )" );

	my @servers = $resolver->nameservers;
	ok( scalar(@servers), 'nameservers list populated' );
	is( $servers[0], '10.0.1.128', 'nameservers list correct' );
	is( $servers[1], '10.0.2.128', 'nameservers list correct' );

	my @search = $resolver->searchlist;
	ok( scalar(@search), 'searchlist populated' );
	is( $search[0], 'alt.net-dns.org', 'searchlist correct' );
	is( $search[1], 'ext.net-dns.org', 'searchlist correct' );

	is( $resolver->domain, 'alt.net-dns.org', 'domain correct' );

	is( $class->domain, $resolver->domain, 'initial config sets defaults' );
}


{
	$class->domain('domain.default');
	my $resolver = $class->new( config_file => $config );
	ok( $resolver->isa($class), "new( config_file => $config )" );

	my @servers = $resolver->nameservers;
	ok( scalar(@servers), 'nameservers list populated' );

	my $domain = 'alt.net-dns.org';
	my @search = $resolver->searchlist;
	ok( scalar(@search), 'searchlist populated' );
	is( shift(@search), $domain, 'searchlist correct' );

	is( $resolver->domain, $domain, 'domain correct' );

	isnt( $class->domain, $resolver->domain, 'default config unchanged' );
}


{								# file presumed not to exist
	eval { new $class( config_file => 'nonexist.txt' ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "new( config_file => ?\t[$exception]" );
}


exit;

