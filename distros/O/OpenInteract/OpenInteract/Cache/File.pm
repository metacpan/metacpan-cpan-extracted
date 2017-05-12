package OpenInteract::Cache::File;

# $Id: File.pm,v 1.4 2002/09/08 20:56:46 lachoy Exp $

use strict;
use base qw( OpenInteract::Cache );
use Cache::FileCache;

$OpenInteract::Cache::File::VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

my $DEFAULT_SIZE   = 2000000;  # 10 MB -- max size of cache
my $DEFAULT_EXPIRE = 86400;    # 1 day

sub initialize {
    my ( $self, $CONFIG ) = @_;

    # Allow values that are passed in to override anything
    # set in the config object

    my $cache_dir      = $CONFIG->get_dir( 'cache_content' );
    unless ( -d $cache_dir ) {
        warn "Sorry, I cannot create a filesystem cache without a ",
             "valid directory. (Given [$cache_dir])\n";
        return undef;
    }

    my $cache_info     = $CONFIG->{cache_info}{data};
    my $max_size       = $cache_info->{max_size};
    my $default_expire = $cache_info->{default_expire};
    my $cache_depth    = $cache_info->{directory_depth};

    # If a value isn't set, use the default from the class
    # configuration above.

    $max_size       ||= $DEFAULT_SIZE;
    $default_expire ||= $DEFAULT_EXPIRE;

    my $R = OpenInteract::Request->instance;
    $R->DEBUG && $R->scrib( 1, "Using the following cache settings ",
                            "[Dir $cache_dir] [Size $max_size] ",
                            "[Expire $default_expire] [Depth $cache_depth]" );
    return Cache::FileCache->new({ default_expires_in => $default_expire,
                                   max_size           => $max_size,
                                   cache_root         => $cache_dir,
                                   cache_depth        => $cache_depth });
}


sub get_data {
    my ( $self, $cache, $key ) = @_;
    return $cache->get( $key );
}


sub set_data {
    my ( $self, $cache, $key, $data, $expires ) = @_;
    $cache->set( $key, $data, $expires );
    return 1;
}


sub clear_data {
    my ( $self, $cache, $key ) = @_;
    $cache->remove( $key );
    return 1;
}

1;

__END__

=head1 NAME

OpenInteract::Cache::File -- Implement caching in the filesystem

=head1 DESCRIPTION

Subclass of L<OpenInteract::Cache|OpenInteract::Cache> that uses the
filesystem to cache objects.

One note: if file space becomes an issue, it would be a good idea to
put this on the fastest drive (or drive array) possible.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
