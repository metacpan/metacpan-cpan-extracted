package Pinwheel::Cache;

use strict;
use warnings;

use Pinwheel::Cache::Null;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(cache cache_clear cache_get cache_remove cache_set);


# By default use the Null backend
my $backend = new Pinwheel::Cache::Null;



sub cache_clear
{
    return $backend->clear();
}

sub cache_get
{
    my ($key) = @_;
    return $backend->get($key);
}

sub cache_remove
{
    my ($key, $time) = @_;
    return $backend->remove($key, $time);
}

sub cache_set
{
    my ($key, $value, $expires) = @_;
    return $backend->set($key, $value, $expires);
}

sub cache
{
    my $valuefn = pop @_;
    my ($key, $expires) = @_;
    my ($value);

    $value = $backend->get($key);
    if (!defined($value)) {
        $value = $valuefn->();
        $expires = $expires->($value) if ref($expires) eq 'CODE';
        $backend->set($key, $value, $expires);
    }
    return $value;
}

sub set_backend
{
    my ($b) = @_;
    $b = new Pinwheel::Cache::Null unless defined($b);
    $backend = $b;
}


1;

__DATA__

=head1 NAME

Pinwheel::Cache

=head1 SYNOPSIS

    use Pinwheel::Cache qw(cache cache_get cache_set);
    
    Pinwheel::Cache::set_backend(new Pinwheel::Cache::Hash);
    
    cache_set('key', 'value');
    $value = cache_get('get');
    
    cache('key', sub { 'result of complex operation' });

=head1 DESCRIPTION

Procedural caching API.

=head1 ROUTINES

=over 4

=item cache_clear()

Remove all objects from the cache.

=item cache_get( $key )

Returns the data associated with *$key*.

=item cache_set( $key, $data, [$expires_in] )

Associates *$data* with *$key* in the cache. *$expires_in* indicates
the time in seconds until this data should be erased.

=item cache_remove( $key )

Delete the data associated with the *$key* from the cache.

=item cache( $key, [$expires_in], $subroutine )

Call subroutine and store the result in the cache with *$key*.
If there is already data in the cache associated with *$key* 
then it is returned and the subroutine is not called.

=item set_backend( $backend )

Set the caching backend to use.
The backend should implement the Cache::Cache API.

=back

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

