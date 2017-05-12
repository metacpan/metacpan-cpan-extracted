# $Id$
#

package Mvalve::State::Memcached;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper ();
use Digest::SHA1 ();

with 'MooseX::KeyedMutex';

subtype 'Memcached'
    => as 'Object'
        => where { 
            $_->isa('Cache::Memcached') ||
            $_->isa('Cache::Memcached::Fast') ||
            $_->isa('Cache::Memcached::libmemcached')
        }
;

coerce 'Memcached'
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
    isa => 'Memcached',
    coerce => 1,
    required => 1,
    handles => [ qw( get set remove) ]
);

sub incr {
    my ($self, $key, $value, $expr) = @_;
    $value ||= 1;
    $expr ||= 0;

    my $cache = $self->memcached;
    my $rv = $cache->incr( $key, $value, $expr);
    if (! $rv) {
        $rv = $cache->add( $key, $value, $expr);
    }
    return $rv;
}

sub decr {
    my ($self, $key, $value, $expr) = @_;
    $value ||= 1;
    $expr ||= 0;

    my $cache = $self->memcached;
    my $rv = $cache->decr( $key, $value, $expr );
    if (! $rv) {
        $rv = $cache->add( $key, -1, $expr );
    }
    return $rv;
}

around qw(get set remove incr decr) => sub {
    my ($next, $self, $key, @args) = @_;

    if (ref $key) {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        $key = Digest::SHA1::sha1_hex(Data::Dumper::Dumper($key));
    }

    $next->($self, $key, @args);
};

with 'Mvalve::State';

no Moose;

1;

__END__

=head1 NAME

Mvalve::State::Memcached - Memcached Implementation Of Mvalve::State

=head1 SYNOPSIS

  use Mvalve:

=cut
