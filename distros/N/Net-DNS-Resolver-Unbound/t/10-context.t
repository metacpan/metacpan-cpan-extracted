#!/usr/bin/perl
#

use strict;
use warnings;
use IO::File;
use Test::More tests => 9;

use Net::DNS::Resolver::Unbound;


ok( Net::DNS::Resolver::Unbound->string(), 'default configuration' );

my $recursive = Net::DNS::Resolver::Unbound->new( nameservers => [] );
ok( $recursive, 'create fully recursive resolver instance' );
is( scalar( $recursive->nameservers ), 0, 'empty nameserver list' );

my $resolver = Net::DNS::Resolver::Unbound->new();
ok( $resolver, 'create stub resolver instance' );

ok( $resolver->string(), '$resolver->string' );


my $option = 'verbosity';
my $value  = '2';
my $return = $resolver->option( $option, $value );
is( $return, undef, "resolver->option( $option, $value )" );

my $result = $resolver->option($option);
is( $result, $value, 'single-valued resolver option' );

my @result = $resolver->option($option);
ok( scalar(@result), 'multi-valued resolver option' );

my $bogus = $resolver->option('bogus');
is( $bogus, undef, 'nonexistent resolver option' );


my $filename = "file$$";
END { unlink $filename }
close( IO::File->new( $filename, '>' ) or die "Can't create $filename $!" );


## exercise config options
$resolver->prefer_v4(1);
eval { $resolver->option( 'outgoing-port-avoid', '3200-3204' ) };
eval { $resolver->option( 'outgoing-port-avoid', '3205-3208' ) };
eval { $resolver->add_ta('zone DS') };
eval { $resolver->add_ta_file($filename) };
eval { $resolver->async_thread(1) };
eval { $resolver->config($filename) };
eval { $resolver->debug_out($filename) };
eval { $resolver->debug_level(1) };
eval { $resolver->hosts($filename) };
eval { $resolver->resolv_conf($filename) };
eval { $resolver->set_fwd('::1') };
eval { $resolver->set_fwd('127.0.0.1') };
eval { $resolver->trusted_keys($filename) };

$resolver->print;

eval { $resolver->add_ta_autr($filename) };			# Unbound 1.9.0+
eval { $resolver->set_stub( 'zone', '10.1.2.3', 0 ) };
eval { $resolver->set_tls(0) };
eval { $resolver->set_tls(undef) };

exit;

