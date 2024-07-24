#!/usr/bin/perl
#

use strict;
use warnings;
use IO::File;
use Test::More tests => 10;

use Net::DNS::Resolver::Unbound;


ok( Net::DNS::Resolver::Unbound->string(), 'default configuration' );

my $recursive = Net::DNS::Resolver::Unbound->new( nameservers => [] );
ok( $recursive, 'create fully recursive resolver instance' );
is( scalar( $recursive->nameservers ), 0, 'empty nameserver list' );

my $resolver = Net::DNS::Resolver::Unbound->new( debug_level => 0, prefer_v4 => 1 );
ok( $resolver, 'create stub resolver instance' );


my $option = 'outgoing-port-avoid';
my $value  = '3200-3202';
my $return = $resolver->option( $option, $value );
is( $return, undef, "resolver->option( $option, $value )" );
my $single = $resolver->option($option);
is( $single, $value, 'single-valued resolver option' );

$resolver->option( $option, '3203-3205' );
$resolver->option( $option, '3206-3208' );
my @multi = $resolver->option($option);
is( scalar(@multi), 3, 'multi-valued resolver option' );

my $bogus = $resolver->option('bogus');
is( $bogus, undef, 'nonexistent resolver option' );

ok( $resolver->string(), '$resolver->string' );


my $index = $$ % 10000;
my @filename;

sub filename {
	my $filename = join '', 'file', $index++;
	close( IO::File->new( $filename, '>' ) or die $! );
	push @filename, $filename;
	return $filename;
}

END {
	unlink $_ foreach @filename;
}


## exercise context methods
eval { $resolver->option( 'verbosity',		 undef ) };
eval { $resolver->option( 'outgoing-port-avoid', '3200-3208' ) };
eval { $resolver->config(filename) };
eval { $resolver->set_fwd('::1') };
eval { $resolver->set_fwd('127.0.0.1') };
eval { $resolver->set_fwd('127.0.0.53') };
eval { $resolver->set_tls(0) };
eval { $resolver->set_stub( 'zone', '10.1.2.3', 0 ) };
eval { $resolver->resolv_conf(filename) };
eval { $resolver->hosts(filename) };
eval { $resolver->add_ta('zone DS') };
eval { $resolver->add_ta_file(filename) };
eval { $resolver->add_ta_autr(filename) };
eval { $resolver->trusted_keys(filename) };
eval { $resolver->debug_out(filename) };
eval { $resolver->debug_level(1) };
eval { $resolver->async_thread(1) };

ok( $resolver->string(), 'context rebuilt' );

exit;

