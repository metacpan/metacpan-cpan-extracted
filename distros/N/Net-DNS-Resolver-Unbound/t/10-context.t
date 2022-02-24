#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 9;

use Net::DNS::Resolver::Unbound;

ok( Net::DNS::Resolver::Unbound->string(), 'default configuration' );


my $resolver = Net::DNS::Resolver::Unbound->new(
	async_thread => 1,
	option	     => ['verbosity', '1'] );

ok( $resolver, 'create new resolver instance' );

ok( $resolver->print(), '$resolver->print' );


my $option = 'verbosity';
my $value  = '0';
my $return = $resolver->option( $option, $value );
is( $return, undef, "resolver->option( $option, $value )" );

my $result = $resolver->option($option);
is( $result, $value, 'single-valued resolver option' );

my @result = $resolver->option($option);
is( pop(@result), $value, 'multi-valued resolver option' );


eval { my $bogus = $resolver->option('bogus') };
my ($bogus_option) = split /\n/, "$@\n";
ok( $bogus_option, "unknown Unbound option\t[$bogus_option]" );


eval { my $resolver = Net::DNS::Resolver::Unbound->new( option => {$option, $value} ); };
my ($option_usage) = split /\n/, "$@\n";
ok( $option_usage, "Unbound option usage\t[$option_usage]" );


$resolver->send('localhost');		## side effect: finalise config

eval { my $value = $resolver->config('filename') };
my ($reject_option) = split /\n/, "$@\n";
ok( $reject_option, "reject Unbound option\t[$reject_option]" );


## exercise special config options
eval { $resolver->add_ta('zone DS') };
eval { $resolver->add_ta_file('filename') };
eval { $resolver->add_ta_autr('filename') };
eval { $resolver->debug_out('filename') };
eval { $resolver->hosts('filename') };
eval { $resolver->resolv_conf('filename') };
eval { $resolver->set_fwd('127.0.0.53') };
eval { $resolver->set_stub( 'zone', '10.1.2.3', 0 ) };
eval { $resolver->set_tls(0) };
eval { $resolver->trusted_keys('filename') };


exit;

