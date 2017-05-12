#!/usr/bin/perl

package ResourcePool::Resource::Redis;
use strict;
use warnings;
use Redis;

our $VERSION = 1.0;
use base qw(ResourcePool::Resource);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	my %args = @_;

	$self->{'redis'} = eval {Redis->new(%args)};
	warn $@ if $@;

	bless($self, $class);
	return $self;
}

sub close {
	my ($self) = @_;
	eval {$self->{'redis'}->quit()};
}

sub precheck {
	my ($self) = @_;
	my $rc = uc($self->{'redis'}->ping() || '') eq 'PONG';
	$rc or $self->close();
	return $rc;
}

sub postcheck {
	return 1;
}

sub get_plain_resource {
	my ($self) = @_;
	return $self->{'redis'};
}

sub DESTROY {
	my ($self) = @_;
	$self->close();
}

__END__

=head1 NAME

ResourcePool::Resource::Redis - Provides a ResourcePool wrapper for Redis.

=head1 SYNOPSIS

    use ResourcePool::Factory;
    use ResourcePool::Resource::Redis;

    my $factory = ResourcePool::Factory::Redis->new('server' => '127.0.0.1');
    my $pool = ResourcePool->new($factory);

    my $redis = $pool->get();
    $redis->set("foo", "bar);
    $pool->free($redis);

See the L<ResourcePool> documentation for more details.

=head1 SUBROUTINES

=over

=item new(%args)

Accepts the same arguments as L<Redis::new|Redis>.

=back

=head1 AUTHOR

Sebastian Nowicki <sebnow@gmail.com>

=head1 SEE ALSO

L<ResourcePool|ResourcePool> for detailed documentation and geenral information about
what a ResourcePool is.

L<Redis|Redis> for documentation on the Redis interface.

=cut

