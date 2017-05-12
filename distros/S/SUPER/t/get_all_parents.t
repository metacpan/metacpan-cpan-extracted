#!perl

use strict;
use warnings;

use Test::More tests => 2;

my $proxy_called;
my $parent_called;

package Parent;

sub call_me
{
	$parent_called++;
}

package Proxied;

@Proxied::ISA = 'Parent';

sub new { bless {}, shift }

package Proxy;

use SUPER;
use Scalar::Util 'blessed';

sub __get_parents
{
	my $self    = shift;
	my $proxied = $$self;

	return do { no strict 'refs'; @{ blessed( $proxied ) . '::ISA' } };
}

sub new
{
	my ($class, $proxied) = @_;
	bless \$proxied, $class;
}

sub call_me
{
	my $self = shift;
	$proxy_called++;
	return $self->SUPER();
}

package main;

my $proxied = Proxied->new();
my $proxy   = Proxy->new( $proxied );
$proxy->call_me();
ok( $proxy_called, 'Proxy should get called' );
ok( $parent_called, '... and SUPER should find parent' );
