
package MooseX::WithCache::Backend::CHI;
use Moose;
use Moose::Util::TypeConstraints;

extends 'MooseX::WithCache::Backend';

class_type 'CHI::Driver';

sub _build_cache_type {
    return 'CHI::Driver';
}

around _build_methods => sub {
    my ($next, $self) = @_;
    my $methods = $next->($self);
    $methods->{cache_del} = sub {
        my ($self, $key) = @_;
        my $cache = $self->__get_cache();
        if (! $cache) {
            return ();
        }

        my $keygen = $self->cache_key_generator;
        my $cache_key = $keygen ? $keygen->generate($key) : $key;
        if (MooseX::WithCache::DEBUG()) {
            $self->cache_debug(
                "cache_del: key =",
                ($cache_key || '(null)'),
            );
        }
        return $cache->remove($cache_key);
    };
    return $methods;
};

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

MooseX::WithCache::Backend::CHI - CHI Backend

=head1 SYNOPSIS

    # This class hasn't really been tested.

=cut