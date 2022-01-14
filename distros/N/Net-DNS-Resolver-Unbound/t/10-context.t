#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 5;

use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new(
	async_thread => 1,
	option	     => ['logfile', 'mylog.txt'] );

ok( $resolver, 'create new resolver instance' );


my $filename = 'mylog.txt';
my $return   = $resolver->option( 'logfile', $filename );
is( $return, undef, "resolver->option( logfile, $filename )" );

my $value = $resolver->option('logfile');
is( $value, $filename, "resolver->option( logfile )" );


eval { my $value = $resolver->option('bogus') };
my ($bogus_option) = split /\n/, "$@\n";
ok( $bogus_option, "unknown Unbound option\t[$bogus_option]" );

eval { my $resolver = Net::DNS::Resolver::Unbound->new( option => {'logfile', 'mylog.txt'} ); };
my ($option_usage) = split /\n/, "$@\n";
ok( $option_usage, "Unbound option usage\t[$option_usage]" );


exit;

