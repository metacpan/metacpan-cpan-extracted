#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

# A minimal mock backend used to observe the frontend's self-heal logic.
# check() returns a configurable health value and re_init() records that it
# was called.
package MockBackend;

sub new {
	my ( $class, %args ) = @_;
	return bless {
		inited        => defined( $args{inited} ) ? $args{inited} : 1,
		healthy       => $args{healthy},
		reinit_called => 0,
		banned        => {},
	}, $class;
}
sub check   { return $_[0]->{healthy}; }
sub re_init { $_[0]->{reinit_called}++; return; }
sub ban     { return; }    # no-op; the ban action itself is not what we assert on
sub unban   { return; }

package main;

use Net::Firewall::BlockerHelper;

# build a frontend without initing a real backend, then inject the mock
sub fw_with_mock {
	my (%args) = @_;
	my %new_opts = ( backend => 'dummy', name => 'x', testing => 1 );
	$new_opts{self_heal} = $args{self_heal} if exists $args{self_heal};
	my $fw = Net::Firewall::BlockerHelper->new(%new_opts);
	$fw->{backend_obj} = MockBackend->new(
		healthy => $args{healthy},
		inited  => $args{inited},
	);
	return $fw;
}

# healthy setup -> no re_init
{
	my $fw = fw_with_mock( healthy => 1 );
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{backend_obj}{reinit_called}, 0, 'healthy check does not trigger re_init' );
}

# wiped setup -> re_init triggered before the ban
{
	my $fw = fw_with_mock( healthy => 0 );
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{backend_obj}{reinit_called}, 1, 'unhealthy check triggers re_init on ban' );
}

# self_heal defaults to on
{
	my $fw = fw_with_mock( healthy => 0 );
	is( $fw->{self_heal}, 1, 'self_heal defaults to 1' );
}

# self_heal => 0 at construction disables it
{
	my $fw = fw_with_mock( healthy => 0, self_heal => 0 );
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{backend_obj}{reinit_called}, 0, 'self_heal=0 disables healing' );
}

# per-call override: off for one ban even though default is on
{
	my $fw = fw_with_mock( healthy => 0 );
	$fw->ban( ban => '1.2.3.4', self_heal => 0 );
	is( $fw->{backend_obj}{reinit_called}, 0, 'per-call self_heal=0 overrides the on default' );
}

# per-call override: on for one ban even though default is off
{
	my $fw = fw_with_mock( healthy => 0, self_heal => 0 );
	$fw->ban( ban => '1.2.3.4', self_heal => 1 );
	is( $fw->{backend_obj}{reinit_called}, 1, 'per-call self_heal=1 overrides the off default' );
}

# unban self-heals too
{
	my $fw = fw_with_mock( healthy => 0 );
	$fw->unban( ban => '1.2.3.4' );
	is( $fw->{backend_obj}{reinit_called}, 1, 'unban self-heals as well' );
}

# a not-yet-inited backend is not healed
{
	my $fw = fw_with_mock( healthy => 0, inited => 0 );
	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{backend_obj}{reinit_called}, 0, 'non-inited backend is not healed' );
}

done_testing();
