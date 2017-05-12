package OpenInteract::Cache;

# $Id: Cache.pm,v 1.6 2003/04/07 02:55:57 lachoy Exp $

use strict;

# Returns: caching object (implementation-neutral)

sub new {
    my ( $pkg, @params ) = @_;
    my $class = ref $pkg || $pkg;
    my $self = bless( {}, $class );
    $self->{_cache_object} = $self->initialize( @params );
    return $self;
}


# Returns: data from the cache

sub get {
    my ( $self, $p ) = @_;

    # if the cache hasn't been initialized, bail
    return undef unless ( $self->{_cache_object} );

    my $key       = $p->{key};
    my $is_object = 0;
    my $obj_class = undef;
    my $R = OpenInteract::Request->instance;
    if ( ! $key and $p->{class} and $p->{object_id} ) {
        $key = _make_spops_idx( $p->{class}, $p->{object_id} );
        $R->DEBUG && $R->scrib( 3, "Created class+id key [$key]" );
        $obj_class = $p->{class};
        $is_object++;
        return undef  unless ( $obj_class->pre_cache_get( $p->{object_id} ) );
    }
    unless ( $key ) {
        $R->DEBUG && $R->scrib( 2, "Cache MISS (no key)" );
        return undef;
    }

    my $data = $self->get_data( $self->{_cache_object}, $key );
    unless ( $data ) {
        $R->DEBUG && $R->scrib( 2, "Cache MISS [$key]" );
        return undef;
    }

    $R->DEBUG && $R->scrib( 2, "Cache HIT [$key]" );
    if ( $is_object ) {
        return undef unless ( $obj_class->post_cache_get( $data ) );
    }
    return $data;
}

sub set {
    my ( $self, $p ) = @_;

    # if the cache hasn't been initialized, bail
    return undef unless ( $self->{_cache_object} );

    my $is_object = 0;
    my $key  = $p->{key};
    my $data = $p->{data};
    my ( $obj );
    my $R = OpenInteract::Request->instance;
    if ( _is_object( $data ) ) {
        $obj = $data;
        $key = _make_spops_idx( ref $obj, scalar( $obj->id ) );
        $R->DEBUG && $R->scrib( 2, "Created class/id key [$key]" );
        $is_object++;
        return undef  unless ( $obj->pre_cache_save );
        $data = $obj->as_data_only;
    }
    $self->set_data( $self->{_cache_object}, $key, $data, $p->{expire} );
    if ( $obj and $obj->can( 'post_cache_save' ) ) {
        return undef  if ( $obj->post_cache_save );
    }
    return 1;
}

sub clear {
    my ( $self, $p ) = @_;

    # if the cache hasn't been initialized, bail
    return undef unless ( $self->{_cache_object} );

    my $key = $p->{key};
    if ( ! $key and _is_object( $p->{data} ) ) {
        $key = _make_spops_idx( ref $p->{data}, scalar( $p->{data}->id ) );
    }
    elsif ( ! $key and $p->{class} and $p->{object_id} ) {
        $key = _make_spops_idx( $p->{class}, $p->{object_id} );
    }
    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 2, "Trying to clear cache of [$key]" );
    return $self->clear_data( $self->{_cache_object}, $key );
}


sub purge {
    my ( $self ) = @_;

    # if the cache hasn't been initialized, bail
    return undef unless ( $self->{_cache_object} );

    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 2, "Trying to purge cache of all objects" );
    return $self->purge_all( $self->{_cache_object} );
}


sub _is_object {
    my ( $item ) = @_;
    my $typeof = ref $item;
    return undef if ( ! $typeof );
    return undef if ( $typeof =~ /^(HASH|ARRAY|SCALAR)$/ );
    return 1;
}

sub _make_spops_idx {
    return join '--', $_[0], $_[1];
}

########################################
# SUBCLASS TO OVERRIDE

sub initialize  { die "Subclass must define initialize()\n" }
sub get_data    { die "Subclass must define get_data()\n" }
sub set_data    { die "Subclass must define set_data()\n" }
sub clear_data  { die "Subclass must define clear_data()\n" }
sub purge_all   { die "Subclass must define purge_all()\n" }

1;

__END__

=head1 NAME

OpenInteract::Cache -- Caches objects to avoid database hits and content to avoid template processing

=head1 SYNOPSIS

 # In $WEBSITE_DIR/conf/server.ini

 [cache_info data]
 default_expire = 600
 use            = 0
 use_spops      = 0
 class          = OpenInteract::Cache::File
 max_size       = 2000000

 # Use implicitly with built-in content caching

 sub listing {
     my ( $class, $p ) = @_;
     my %params = ( cache_key  => 'mypkg::myhandler::listing',
                    cache_time => 1800 );
     ...
     return $R->template->handler(
               {}, \%params, { name => 'mypkg::listing' } );
 }

 # Explicitly expire a cached item

 sub edit {
     my ( $class, $p ) = @_;
     ...
     eval { $object->save };
     if ( $@ ) {
         # set error message
     }
     else {
         $R->cache->clear({ key => 'mypkg::myhandler::listing' });
     }
 }

=head1 DESCRIPTION

This class is the base class for different caching implementations,
which are themselves just wrappers around various CPAN modules which
do the actual work. As a result, the module is pretty simple.

The only tricky aspect is that we use this for caching content and for
caching SPOPS objects. So there is some additional data checking not
normally in such a module.

=head1 METHODS

These are the methods for the cache. The following parameters are
passed to every method that operates on an individual cached
item. Either 'key' or 'class' and 'object_id' are required for these
methods.

=over 4

=item *

B<key>: Name under which we store data

=item *

B<class>: Class of SPOPS object

=item *

B<object_id>: ID of SPOPS object

=back

B<get( \%params )>

Returns the data in the cache associated with a key; undef if data
corresponding to the key is not found.

B<set( \%params )>

Saves the data found in the C<data> parameter into the cache,
referenced by the key C<key>. If C<data> is an SPOPS object we create
a key from its class and ID.

Parameters:

=over 4

=item *

B<data>: The data to save in the cache. This can be an SPOPS object or
HTML content.

=item *

B<expire> (optional): Time the item should sit in the cache before being
refreshed. This can be in seconds (the default) or in the "[number]
[unit]" format outlined by L<Cache::Cache|Cache::Cache>. For example,
'10 minutes'.

=back

Returns a true value if successful.

B<clear( \%params )>

Invalidates the cache for the specified item.

B<purge()>

Clears the cache of all items.

=head1 SUBCLASS METHODS

These are the methods that must be overridden by a subclass to
implement caching.

B<initialize( \%OpenInteract::Config )>

This method is called object is first created. Use it to define and
return the object that actually does the caching. It will be passed to
all successive methods (C<get_data()>, C<set_data()>, etc.).

Relevant keys in the L<OpenInteract::Config|OpenInteract::Config>
object passed in:

 cache_info->default_expire - Default expiration time for items
 cache_info->max_size       - Maximum size (in bytes) of cache
 dir->cache_content         - Root directory for content cache

B<get_data( $cache_object, $key )>

Returns an object if it is cached and 'fresh', however that
implementation defines fresh.

B<set_data( $cache_object, $data, $key, [ $expires ] )>

Returns 1 if successful, undef on failure. If C<$expires> is undefined
or is not set to a valid L<Cache::Cache|Cache::Cache> value, then the
configuration key 'cache_info.default_expire'.

B<clear_data( $cache_object, $key )>

Removes the specified data from the cache. Returns 1 if successful,
undef on failure (or inability to do so).

B<purge_all( $cache_object )>

Clears the cache of all items.

=head1 TODO

Test and get working!

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
