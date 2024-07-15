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


my $option  = 'verbosity';
my $value   = '2';
my $deleted = $resolver->option( $option, undef );
is( $deleted, undef, 'delete resolver option' );

my $return = $resolver->option( $option, $value );
is( $return, undef, "resolver->option( $option, $value )" );

my $scalar = $resolver->option($option);
is( $scalar, $value, 'single-valued resolver option' );

$resolver->option( $option, $value );
my @array = $resolver->option($option);
is( scalar(@array), 2, 'multi-valued resolver option' );

my $bogus = $resolver->option('bogus');
is( $bogus, undef, 'nonexistent resolver option' );

ok( $resolver->string(), '$resolver->string' );


my $filename = "file$$";

END {
	$resolver->string;
	unlink $filename;
}
close( IO::File->new( $filename, '>' ) or die "Can't touch $filename $!" );


## exercise context methods
eval { $resolver->add_ta('zone DS') };
eval { $resolver->add_ta_file($filename) };
eval { $resolver->async_thread(1) };
eval { $resolver->config($filename) };
eval { $resolver->debug_out($filename) };
eval { $resolver->hosts($filename) };
eval { $resolver->resolv_conf($filename) };
eval { $resolver->set_fwd('::1') };
eval { $resolver->set_fwd('127.0.0.1') };
eval { $resolver->set_fwd('127.0.0.53') };
eval { $resolver->trusted_keys($filename) };

eval { $resolver->add_ta_autr($filename) };			# Unbound 1.9.0+
eval { $resolver->set_stub( 'zone', '10.1.2.3', 0 ) };
eval { $resolver->set_tls(0) };

exit;

