package Redis::DistLock;

use strict;
use warnings;

our $VERSION = '0.07';

use Digest::SHA qw( sha1_hex );
use MIME::Base64 qw( encode_base64 );
use Redis;
use Time::HiRes qw( time );

sub VERSION_CHECK()     { 1 }
sub RETRY_COUNT()       { 3 }
sub RETRY_DELAY()       { 0.2 }
sub DRIFT_FACTOR()      { 0.01 }
sub RELEASE_SCRIPT()    { '
if redis.call( "get", KEYS[1] ) == ARGV[1] then
    return redis.call( "del", KEYS[1] )
else
    return 0
end
' }
sub RELEASE_SHA1()      { sha1_hex( RELEASE_SCRIPT ) }
sub EXTEND_SCRIPT()     { '
if redis.call( "set", KEYS[1], ARGV[1], "XX", "PX", ARGV[2] ) then
    return "OK"
else
    return redis.call( "set", KEYS[1], ARGV[1], "NX", "PX", ARGV[2] )
end
' }
sub EXTEND_SHA1()       { sha1_hex( EXTEND_SCRIPT ) }

sub DESTROY {
    my $self = shift;

    # only has locks when auto release is enabled
    return if @{ $self->{locks} || [] } == 0;

    $self->release( $_ )
        for @{ $self->{locks} };
}

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref( $_[0] )
             ? %{ $_[0] }
             : @_
    ;

    my $version_check = exists( $args{version_check} )
                      ?         $args{version_check}
                      :               VERSION_CHECK
    ;

    my $logger = exists( $args{logger} )
                      ?  $args{logger}
                      :  sub { warn @_ }
    ;

    my $quorum = int( @{ $args{servers} } / 2 + 1 );
    my @servers;

    for my $server ( @{ $args{servers} } ) {
        # connect might fail
        my $redis = ref( $server )
                       ? $server
                       : eval { Redis->new( server => $server, encoding => undef ) }
        ;
        unless ( $redis ) {
            $logger->( $@ );
            next;
        }
        push( @servers, $redis );

        if ( $version_check ) {
            my $info = $redis->info();

            die( "FATAL: cannot find the right redis version (needs at least 2.6.12 -- $1, $2, $3)" )
                unless $info &&
                       $info->{redis_version} &&
                       $info->{redis_version} =~ m!\A ([0-9]+) \. ([0-9]+) \. ([0-9]+) \z!x &&
                       (
                         ( $1 >  2 ) ||
                         ( $1 == 2 && $2 >  6 ) ||
                         ( $1 == 2 && $2 == 6 && $3 >= 12 )
                       )
            ;
        }

        # load script on all servers
        my $sha1 = $redis->script_load( RELEASE_SCRIPT );

        # ensure the script is everywhere the same
        if ( $sha1 ne RELEASE_SHA1 ) {
            die( "FATAL: script load results in different checksum!" );
        }

        $sha1 = $redis->script_load( EXTEND_SCRIPT );

        if ( $sha1 ne EXTEND_SHA1 ) {
            die( "FATAL: failed to load extend script: sha1 mismatch!" );
        }
    }

    if ( @servers < $quorum ) {
        die( "FATAL: could not establish enough connections (" . int( @servers ) . " < $quorum)" );
    }

    my $self = bless( {
        servers        => \@servers,
        quorum         => $quorum,
        retry_count    => $args{retry_count} || RETRY_COUNT,
        retry_delay    => $args{retry_delay} || RETRY_DELAY,
        locks          => [],
        logger         => $logger || sub {},
        auto_release   => $args{auto_release} || 0,
    }, $class );

    return $self;
}

sub _get_random_id {
    encode_base64( join( "", map chr( int( rand() * 256 ) ), 1 .. 24 ), "" );
}

sub lock {
    my ( $self, $resource, $ttl, $value, $extend ) = @_;
    my $retry_count = $self->{retry_count};

    $value = _get_random_id()
        unless defined( $value );

    while ( $retry_count-- > 0 ) {
        my $start = time();
        my $ok = 0;

        for my $redis ( @{ $self->{servers} } ) {
            # count successful locks, response only needs to be true
            $ok += eval {
                ! $extend
                ? $redis->set( $resource, $value, "NX", "PX", $ttl * 1000 )
                : $redis->evalsha( EXTEND_SHA1, 1, $resource, $value, $ttl * 1000 )
            } ? 1 : 0;

            $self->{logger}->( $@ )
                if $@;
        }

        my $drift = $ttl * DRIFT_FACTOR + 0.002;
        my $validity = $ttl - ( time() - $start ) - $drift;

        if ( $ok >= $self->{quorum} && $validity > 0 ) {
            my $lock = {
                validity    => $validity,
                resource    => $resource,
                value       => $value,
            };

            # track lock on demand only
            push( @{ $self->{locks} }, $lock )
                if $self->{auto_release};

            return $lock;
        }

        select( undef, undef, undef, rand( $self->{retry_delay} ) );
    }

    return undef;
}

sub release {
    my $self = shift;
    my ( $resource, $value ) = @_ == 1 && ref( $_[0] )
                             ? @{ $_[0] }{ qw{ resource value } }
                             : @_
    ;

    defined or $_ = ""
        for $resource, $value;

    for my $redis ( @{ $self->{servers} } ) {
        $redis->evalsha( RELEASE_SHA1, 1, $resource, $value );
    }
}

1;

__END__

=head1 NAME

Redis::DistLock - Distributed lock manager using Redis

=head1 SYNOPSIS

  use Redis::DistLock;
  my $rd = Redis::DistLock->new( servers => [qw[ localhost:6379 ]] );
  my $mutex = $rd->lock( "foo", 10 );
  die( "failed to get a lock" )
      if ! $mutex;
  # ... critical section ...
  $rd->release( $mutex );

=head1 DESCRIPTION

This is an implementation of the Redlock algorithm using Redis for distributed
lock management. It enables lightweight distributed locks in order to prevent
cronjob overruns, help with queue processing, many workers of which only one
should run at a time, and similar situations.

B<NOTE>: This needs at least Redis version 2.6.12 which adds new options
to the C<SET> command making this implementation possible.

=head1 METHODS

=head2 new( ... )

Takes a hash or hash reference with below arguments and returns a lock manager
instance. Since this module currently does not repair initially failed
connections it checks for the majority of connections or C<die()>s.

=over 4

=item servers

Array reference with servers to connect to or L<Redis> objects to use.

=item retry_count

Maximum number of times to try to acquire the lock. Defaults to C<3>.

=item retry_delay

Maximum delay between retries in seconds. Defaults to C<0.2>.

=item version_check

Flag to check redis server version(s) in the constructor to ensure compatibility.
Defaults to C<1>.

=item logger

Optional subroutine that will be called with errors as parameter, should any occur.
By default, errors are currently just warnings. To disable pass C<undef>.

=item auto_release

Flag to enable automatic release of all locks when the lock manager instance
goes out of scope. Defaults to C<0>.

B<CAVEAT>: Ctrl-C'ing a running Perl script does not call DESTROY().
This means you will have to wait for Redis to expire your locks for you if the script is killed manually.
Even if you do implement a signal handler, it can be quite unreliable in Perl and does not guarantee
the timeliness of your locks being released.

=back

=head2 lock( $resource, $ttl )

Acquire the lock for the resource with the given time to live (in seconds)
until the lock expires. Without a value generates a 32 character base64
string based on 24 random input bytes.

=head2 lock( $resource, $ttl, $value )

Same as lock() but with a known value instead of a random string.

=head2 lock( $resource, $ttl, $value, $extend )

Same as lock(), but given C<$extend> is true it extends an existing
lock or creates a new one instead of having to unlock first.

B<NOTE>: This option is EXPERIMENTAL and might change without warning!

=head2 release( $lock )

Release the previously acquired lock.

=head2 release( $resource, $value )

Version of release() that allows to maintain state solely in Redis when
the value is known, e.g. a hostname.

=head1 SEE ALSO

=over 4

=item *

L<http://redis.io/topics/distlock>

=item *

L<Redis>

=back

=head1 DISCLAIMER

This code implements an algorithm which is currently a proposal, it was not
formally analyzed. Make sure to understand how it works before using it in
production environments.

=head1 ACKNOWLEDGMENT

This module was originally developed at Booking.com. With approval from
Booking.com, this module was released as open source, for which the authors
would like to express their gratitude.

=head1 AUTHORS

=over 4

=item *

Simon Bertrang E<lt>janus@cpan.orgE<gt>

=item *

Ryan Bastic E<lt>ryan@bastic.netE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Simon Bertrang, Ryan Bastic

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# vim: ts=4 sw=4 et:
