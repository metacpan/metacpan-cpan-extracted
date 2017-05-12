package Redis::RateLimit;
# ABSTRACT: Sliding window rate limiting with Redis
$Redis::RateLimit::VERSION = '1.0001';
use 5.14.1;
use Moo;
use Carp;
use Digest::SHA1 qw/sha1_hex/;
use File::Share qw/dist_file/;
use File::Slurp::Tiny qw/read_file/;
use JSON::MaybeXS;
use List::Util qw/any max min/;
use Redis;
use Try::Tiny;
use namespace::clean;

#pod =attr redis
#pod
#pod Redis client. If none is provided, a default is constructed for 127.0.0.1:6379.
#pod
#pod =cut

has redis => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { Redis->new },
    handles => { map +( "redis_$_" => $_ ), qw/
        eval evalsha hget keys sadd srem
    / },
);

#pod =attr prefix
#pod
#pod A prefix to be included on each redis key. This prevents collisions with
#pod multiple applications using the same Redis DB. Defaults to 'ratelimit'.
#pod
#pod =cut

has prefix => (
    is      => 'ro',
    lazy    => 1,
    default => sub { 'ratelimit' },
);

#pod =attr client_prefix
#pod
#pod Set this to a true value if using a Redis client that supports transparent
#pod prefixing. Defaults to 0.
#pod
#pod =cut

has client_prefix => (
    is      => 'ro',
    default => sub { 0 },
);

#pod =attr rules
#pod
#pod An arrayref of rules, each of which is a hashref with C<interval>, C<limit>,
#pod and optionally C<precision> values.
#pod
#pod =cut

has rules => (
    is       => 'ro',
    required => 1,
);

around BUILDARGS => sub {
    my ( $next, $self ) = splice @_, 0, 2;

    my $args = $self->$next(@_);
    my $rules = delete $args->{rules};
    $args->{rules} = [
        map [ grep defined, @{$_}{qw/interval limit precision/} ], @$rules
    ];

    return $args;
};

has _script_cache => (
    is => 'lazy',
);

sub _build__script_cache {
    my $self = shift;

    # cache scripts: { name => [ hash, script ], ... }
    my %cache =(
        check_rate_limit => [ $self->_check_limit_script ],
        check_limit_incr => [ $self->_check_limit_incr_script ],
    );
    unshift @$_, sha1_hex($$_[0]) for values %cache;

    return \%cache;
}

# Note: 1 is returned for a normal rate limited action, 2 is returned for a
# blacklisted action. Must sync with return codes in lua/check_limit.lua
sub _DENIED_NUMS { (1, 2) }

sub _read_lua {
    my ( $self, $filename ) = @_;

    my $path = dist_file('Redis-RateLimit', "$filename.lua");
    read_file($path, binmode => ':utf8');
}

sub _check_limit_script {
    my $self = shift;

    join("\n", map(
        $self->_read_lua($_), qw/
            unpack_args
            check_whitelist_blacklist
            check_limit
        /),
        'return 0'
    );
}

sub _check_limit_incr_script {
    my $self = shift;

    join("\n", map(
        $self->_read_lua($_), qw/
            unpack_args
            check_whitelist_blacklist
            check_limit
            check_incr_limit
        /),
    );
}

sub _exec {
    my ( $self, $name, @params ) = @_;

    my ( $hash, $script ) = @{ $self->_script_cache->{$name} };
    try {
        $self->redis_evalsha($hash, @params);
    }
    catch {
        croak $_ unless /NOSCRIPT/;
        $self->redis_eval($script, @params);
    };
}

has _json_encoder => (
    is      => 'ro',
    default => sub { JSON::MaybeXS->new(utf8 => 1) },
    handles => {
        json_encode => 'encode',
    },
);

has _whitelist_key => (
    is      => 'ro',
    default => sub { shift->_prefix_key(whitelist => 1) },
);

has _blacklist_key => (
    is      => 'ro',
    default => sub { shift->_prefix_key(blacklist => 1) },
);

sub _prefix_key {
    my ( $self, $key, $force ) = @_;

    my @parts = $key;

    # Support prefixing with an optional `force` argument, but omit prefix by
    # default if the client library supports transparent prefixing.
    unshift @parts, $self->prefix if $force || !$self->client_prefix;

    # The compact handles a falsy prefix
    #_.compact(parts).join ':'
    join ':', @parts;
}

sub _script_args {
    my ( $self, $keys, $weight ) = @_;
    $weight //= 1;

    my @adjusted_keys = map $self->_prefix_key($_), grep length, @$keys;
    croak "Bad keys: @$keys" unless @adjusted_keys;

    my $rules = $self->json_encode($self->rules);
    $weight = max($weight, 1);
    return (
        0+@adjusted_keys, @adjusted_keys,
        $rules, time, $weight, $self->_whitelist_key, $self->_blacklist_key,
    );
}

#pod =method check($key | \@keys)
#pod
#pod Returns true if any of the keys are rate limited.
#pod
#pod =cut

sub check {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    my $result = $self->_exec(
        check_rate_limit => $self->_script_args($keys)
    );
    return any { $result == $_ } _DENIED_NUMS;
}

#pod =method incr($key | \@keys [, $weight ])
#pod
#pod Returns true if any of the keys are rate limited, otherwise, it increments
#pod counts and returns false.
#pod
#pod =cut

sub incr {
    my ( $self, $keys, $weight ) = @_;
    $keys = [ $keys ] unless ref $keys;

    my $result = $self->_exec(
        check_limit_incr => $self->_script_args($keys, $weight)
    );
    return any { $result == $_ } _DENIED_NUMS;
}

#pod =method keys
#pod
#pod Returns all of the rate limiter's with prefixes removed.
#pod
#pod =cut

sub keys {
    my $self = shift;

    my @results = $self->redis_keys($self->_prefix_key('*'));
    my $re = $self->_prefix_key('(.+)');
    map /^$re/, @results;
}

#pod =method violated_rules($key | \@keys)
#pod
#pod Returns a list of rate limit rules violated for any of the keys, or an empty
#pod list.
#pod
#pod =cut

sub violated_rules {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    my $check_key = sub {
        my $key = shift;

        my $check_rule = sub {
            my $rule = shift;
            # Note: this mirrors precision computation in `check_limit.lua`
            # on lines 7 and 8 and count key construction on line 16
            my ( $interval, $limit, $precision ) = @$rule;
            $precision = min($precision // $interval, $interval);
            my $count_key = "$interval:$precision:";

            my $count = $self->redis_hget($self->_prefix_key($key), $count_key);
            $count //= -1;
            return unless $count >= $limit;

            return { interval => $interval, limit => $limit };
        };

        map $check_rule->($_), @{ $self->rules };
    };

    return map $check_key->($_), @$keys;
}

#pod =method limited_keys($key | \@keys)
#pod
#pod Returns a list of limited keys.
#pod
#pod =cut

sub limited_keys {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    grep $self->check($_), @$keys;
}

#pod =method whitelist($key | \@keys)
#pod
#pod Adds the keys to the whitelist so they are never rate limited.
#pod
#pod =cut

sub whitelist {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    for ( @$keys ) {
        my $key = $self->_prefix_key($_);
        $self->redis_srem($self->_blacklist_key, $key);
        $self->redis_sadd($self->_whitelist_key, $key);
    }
}

#pod =method unwhitelist($key | \@keys)
#pod
#pod Removes the keys from the whitelist.
#pod
#pod =cut

sub unwhitelist {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    for ( @$keys ) {
        my $key = $self->_prefix_key($_);
        $self->redis_srem($self->_whitelist_key, $key);
    }
}

#pod =method blacklist($key | \@keys)
#pod
#pod Adds the keys to the blacklist so they are always rate limited.
#pod
#pod =cut

sub blacklist {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    for ( @$keys ) {
        my $key = $self->_prefix_key($_);
        $self->redis_srem($self->_whitelist_key, $key);
        $self->redis_sadd($self->_blacklist_key, $key);
    }
}

#pod =method unblacklist($key | \@keys)
#pod
#pod Removes the keys from the blacklist.
#pod
#pod =cut

sub unblacklist {
    my $self = shift;
    my $keys = ref $_[0] ? shift : \@_;

    for ( @$keys ) {
        my $key = $self->_prefix_key($_);
        $self->redis_srem($self->_blacklist_key, $key);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Redis::RateLimit - Sliding window rate limiting with Redis

=for html <a
href="https://travis-ci.org/semifor/Redis-RateLimit"><img src="https://travis-ci.org/semifor/Redis-RateLimit.svg?branch=master"
alt="Build Status" /></a>

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Redis;
    use Redis::RateLimit;

    my $rules = [
        { interval => 1, limit => 5 },
        { interval => 3600, limit => 1000, precision => 100 },
    ];

    my $redis_client = Redis->new;
    my $limiter = Redis::RateLimit->new(
        redis => $redis_client,
        rules => $rules,
    );

    for ( 1..10 ) {
        say 'Is rate limited? ', $limiter->incr('127.0.0.1') ? 'true' : 'false';
    };

Output:

    Is rate limited? false
    Is rate limited? false
    Is rate limited? false
    Is rate limited? false
    Is rate limited? false
    Is rate limited? true
    Is rate limited? true
    Is rate limited? true
    Is rate limited? true
    Is rate limited? true

=head1 DESCRIPTION

A Perl library for efficient rate limiting using sliding windows stored in Redis.

This is a port of L<RateLimit.js|http://ratelimit.io/> without the non-blocking
goodness.

=head2 Features

=over 4

=item *

Uses a sliding window for a rate limit rule

=item *

Multiple rules per instance

=item *

Multiple instances of RateLimit side-by-side for different categories of users.

=item *

Whitelisting/blacklisting of keys

=back

=head2 Background

See this excellent articles on how the sliding window rate limiting with Redis
works:

=over 4

=item *

L<Introduction to Rate Limiting with Redis Part 1|http://www.dr-josiah.com/2014/11/introduction-to-rate-limiting-with.html>

=item *

L<Introduction to Rate Limiting with Redis Part 2|http://www.dr-josiah.com/2014/11/introduction-to-rate-limiting-with_26.html>

=back

For more information on the `weight` and `precision` options, see the second
blog post above.

=head2 TODO

=over 4

=item *

Port the middleware for Plack

=back

=head1 ATTRIBUTES

=head2 redis

Redis client. If none is provided, a default is constructed for 127.0.0.1:6379.

=head2 prefix

A prefix to be included on each redis key. This prevents collisions with
multiple applications using the same Redis DB. Defaults to 'ratelimit'.

=head2 client_prefix

Set this to a true value if using a Redis client that supports transparent
prefixing. Defaults to 0.

=head2 rules

An arrayref of rules, each of which is a hashref with C<interval>, C<limit>,
and optionally C<precision> values.

=head1 METHODS

=head2 check($key | \@keys)

Returns true if any of the keys are rate limited.

=head2 incr($key | \@keys [, $weight ])

Returns true if any of the keys are rate limited, otherwise, it increments
counts and returns false.

=head2 keys

Returns all of the rate limiter's with prefixes removed.

=head2 violated_rules($key | \@keys)

Returns a list of rate limit rules violated for any of the keys, or an empty
list.

=head2 limited_keys($key | \@keys)

Returns a list of limited keys.

=head2 whitelist($key | \@keys)

Adds the keys to the whitelist so they are never rate limited.

=head2 unwhitelist($key | \@keys)

Removes the keys from the whitelist.

=head2 blacklist($key | \@keys)

Adds the keys to the blacklist so they are always rate limited.

=head2 unblacklist($key | \@keys)

Removes the keys from the blacklist.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Marc Mims.

This is free software, licensed under:

  The MIT (X11) License

=cut
