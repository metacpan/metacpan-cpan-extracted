#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

plan tests => 7;


ok( Net::DNS::Resolver::Unbound->string(), 'default configuration' );

my $resolver = Net::DNS::Resolver::Unbound->new(
	nameservers  => ['127.0.0.1', '::1'],
	prefer_v4    => 1,
	async_thread => 1
	);

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


$resolver->send('localhost');		## side effect: finalise config

eval { my $value = $resolver->config('filename') };
my ($reject_option) = split /\n/, "$@\n";
ok( $reject_option, "reject Unbound option\t[$reject_option]" );

## exercise special config options	(all rejected)
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

