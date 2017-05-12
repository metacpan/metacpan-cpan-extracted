#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Cache::Redis;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Cache::Redis - Cache plugin for the Nile framework using Redis.

=head1 SYNOPSIS
    
    # get Cache::Redis object
    my $cache = $app->plugin("Cache::Redis");
    
    $cache->set("fullname", "Ahmed Amin Elsheshtawy");

    $cache->get("fullname");

    $cache->remove("fullname");

=head1 DESCRIPTION
    
Nile::Plugin::Cache::Redis - Cache plugin for the Nile framework using Redis.

Returns the L<Cache::Redis> object. All methods of L<Cache::Redis> are supported.

Plugin settings in th config file under C<plugin> section.

    <plugin>

        <cache_redis>
            <server>localhost:6379</server>
            <namespace>cache:</namespace>
            <default_expires_in>2592000</default_expires_in>
        </cache_redis>

    </plugin>

=cut

use Nile::Plugin;
use Cache::Redis;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 set()

    $cache->set($key, $value, $expire)

Set a stuff to cache.

=head2 set_multi()

    $cache->set_multi([$key, $value, $expire], [$key, $value])

Set multiple stuffs to cache. stuffs is array reference.

=head2 get()

    my $stuff = $cache->get($key)

Get a stuff from cache.

=head2 get_multi()
    
    my $res = $cache->get_multi(@keys)

Get multiple stuffs as hash reference from cache. @keys should be array. A key is not stored on cache don't be contain $res.

=head2 remove()

    $cache->remove($key)
    
Remove stuff of key from cache.

=head2 get_or_set()

    $cache->get_or_set($key, $code, $expire)

Get a cache value for $key if it's already cached. If it's not cached then, run $code and cache $expiration seconds and return the value.

=head2 nowait_push()
    
    $cache->nowait_push

Wait all response from Redis. This is intended for $cache->nowait.

=cut

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main {
    my ($self, $arg) = @_;
    my $app = $self->app;
    my $setting = $self->setting();
    rebless => Cache::Redis->new(%{$setting});
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
