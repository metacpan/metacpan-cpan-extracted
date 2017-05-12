#-------------------------------------------------------------------
#
#   Sub::Contract::Cache - Implement a subroutine's cache
#
#   $Id: Cache.pm,v 1.3 2009/06/16 12:23:58 erwan_lemonnier Exp $
#

package Sub::Contract::Cache;

use strict;
use warnings;
use Carp qw(croak confess);
use Data::Dumper;
use Symbol;

our $VERSION = '0.12';

# NOTE: to speed up things, we do very little sanity control of method
# arguments, so that a key can for example be undefined though it
# should be an error. This class is to be used internally by
# Sub::Contract only. If you attempt to use it directly for other
# purpose, make sure you really need to do that, and if so, don't rely
# on Sub::Contract::Cache to validate them for you.

sub new {
    my ($class,%args) = @_;
    $class = ref $class || $class;
    my $size = delete $args{size} or croak "BUG: missing max_size";
    my $namespace = delete $args{namespace} or croak "BUG: missing namespace";

    croak "BUG: new() got unknown arguments: ".Dumper(%args) if (%args);
    croak "BUG: size should be a number" if (!defined $size || $size !~ /^\d+$/);

    # NOTE: $contract->reset() deletes this cache
    # TODO: do we want to keep previous content of cache?
    my $self = bless({},$class);
    $self->{cache} = {};
    $self->{cache_max_size} = $size;
    $self->{cache_size} = 0;
    $self->{namespace} = $namespace;

    return $self;
}

sub clear {
    my $self = shift;
    # a fast way to delete all keys in a hash
    delete @{$self->{cache}}{keys %{$self->{cache}}};
    $self->{cache_size} = 0;
}

sub has {
    my ($self,$key) = @_;
    return exists $self->{cache}->{$key};
}

sub set {
    my ($self,$key,$value) = @_;

    croak "BUG: undefined cache key".Dumper($key,$value)
	if (!defined $key);

    if ($self->{cache_size} >= $self->{cache_max_size}) {
	$self->clear;
    }

    $self->{cache}->{$key} = $value;
    $self->{cache_size}++;
}


sub get {
    my ($self,$key) = @_;
    return $self->{cache}->{$key};
}

1;

=pod

=head1 NAME

Sub::Contract::Cache - A data cache

=head1 SYNOPSIS

    my $cache = new Sub::Contract::Cache(max_size => 10000, namespace => 'foo');

    if ($cache->has($key)) {
        return $cache->get($key);
    } else {
        my $value = foo(@args);
        $cache->set($key,$value);
        return $value;
    }

=head1 DESCRIPTION

A Sub::Contract::Cache is just a data cache used by contracts to
memoize subroutine's results. Sub::Contract has its own cache
implementation for efficiency reasons.

=head1 API

=over 4

=item C<< my $cache = new(max_size => $max_size, namespace => $name) >>

Return an empty cache object that may contain up to C<$max_size>
elements and caches results from the subroutine C<$name>.

=item C<< $contract->clear([size => $max_size]) >>

Empty this cache of all its elements.

=item C<< $contract->set($key,$ref_result) >>

Add a cache entry for the key C<$key> with result C<$result>.

=item C<< $contract->has($key) >>

Return true if the cache contains a result for this key, false if not.

=item C<< $contract->get($key) >>

Return the cached result associated with key C<$key>. You must call
C<has> first to ensure that there really is a cached result for this
key. C<get> on an unknown key will return undef and not fail.

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Cache.pm,v 1.3 2009/06/16 12:23:58 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut



