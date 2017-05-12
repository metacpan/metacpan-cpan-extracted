package Queue::Leaky::State::Memcached;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'Queue::Leaky::State::Memcached::Instance'
    => as 'Object'
        => where { 
            $_->isa('Cache::Memcached') ||
            $_->isa('Cache::Memcached::Fast') ||
            $_->isa('Cache::Memcached::libmemcached')
        }
;

coerce 'Queue::Leaky::State::Memcached::Instance'
    => from 'HashRef'
        => via {
            foreach my $module qw(Cache::Memcached::libmemcached Cache::Memcached::Fast Cache::Memcached) {
                eval { Class::MOP::load_class($module) };
                next if $@;

                return $module->new($_);
            }
        }
;
        
has 'memcached' => (
    is => 'rw',
    isa => 'Queue::Leaky::State::Memcached::Instance',
    coerce => 1,
    required => 1,
    handles => [ qw(get set remove decr) ]
);

sub incr {
    my ($self, $key, $value, $expr) = @_;

    $value ||= 1;

    my $cache = $self->memcached;
    my $rv = $cache->incr($key, $value, $expr);
    if (! $rv) {
        $rv = $cache->add($key, $value, $expr);
    }
    return $rv;
}

with 'Queue::Leaky::State';

no Moose;

1;

__END__

=head1 NAME

Queue::Leaky::State::Memcached - Memcached Implementation Of Queue::Leaky::State

=head1 SYNOPSIS

  use Queue::Leaky:

=cut
