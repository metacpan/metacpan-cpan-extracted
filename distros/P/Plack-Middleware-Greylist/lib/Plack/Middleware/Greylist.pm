package Plack::Middleware::Greylist;

# ABSTRACT: throttle requests with different rates based on net blocks

# RECOMMEND PREREQ: Cache::FastMmap
# RECOMMEND PREREQ: Ref::Util::XS

use v5.10;

use strict;
use warnings;

use parent qw( Plack::Middleware );

use HTTP::Status qw/ HTTP_FORBIDDEN HTTP_TOO_MANY_REQUESTS /;
use List::Util   qw/ pairs /;
use Module::Load qw/ load /;
use Net::IP::Match::Trie;
use Plack::Util;
use Plack::Util::Accessor qw/ default_rate rules cache file _match greylist /;
use Ref::Util             qw/ is_plain_arrayref /;
use Time::Seconds         qw/ ONE_MINUTE /;

our $VERSION = 'v0.1.0';


sub prepare_app {
    my ($self) = @_;

    $self->default_rate(-1) unless defined $self->default_rate;

    die "default_rate must be a positive integer" unless $self->default_rate =~ /^[1-9][0-9]*$/;

    unless ( $self->cache ) {

        my $file = $self->file // "/tmp/greylist";
        $self->file($file) unless $self->file;

        load Cache::FastMmap;

        my $cache = Cache::FastMmap->new(
            share_file  => "$file",
            init_file   => 1,
            serializer  => '',
            expire_time => ONE_MINUTE,
        );

        $self->cache(
            sub {
                my ($ip) = @_;
                return $cache->get_and_set(
                    $ip,
                    sub {
                        my ( $key, $count, $opts ) = @_;
                        $count //= 0;
                        return ( $count + 1, { expire_on => $opts->{expire_on} } );
                    }
                );
            }
        );

    }

    my $match = Net::IP::Match::Trie->new;

    $self->_match( sub { return $match->match_ip(@_) } );

    my @blocks;

    if ( my $greylist = $self->greylist ) {
        push @blocks, ( $greylist->%* );
    }

    $self->rules( my $rules = {} );

    my %codes = ( whitelist => -1, blacklist => 0 );
    my %types = ( ip        => '', netblock  => 1 );

    for my $line ( pairs @blocks ) {

        my $block = $line->key;
        my $rule  = $line->value;
        $rule = [ split /\s+/, $rule ] unless is_plain_arrayref($rule);

        my ( $rate, $type ) = $rule->@*;

        $rate //= $codes{blacklist};
        $rate = $codes{$rate} if exists $codes{$rate};

        $type //= "ip";
        my $mask = $types{$type} // $type;
        $mask = $block if $mask eq "1";

        $rules->{$block} = [ $rate, $mask ];
        $match->add( $block => [$block] );
    }

}

sub call {
    my ( $self, $env ) = @_;

    my $ip   = $env->{REMOTE_ADDR};
    my $name = $self->_match->($ip);
    my $rule = $name ? $self->rules->{$name} : [ $self->default_rate ];

    my $rate = $rule->[0];
    if ( $rate >= 0 ) {

        my $limit = $rate == 0;

        unless ($limit) {
            my ($hits) = $self->cache->( $rule->[1] || $ip );

            $limit = $hits > $rate ? $hits : 0;
        }

        if ($limit) {

            my $msg = "Rate limiting ${ip} after ${limit}/${rate}";

            if ( my $log = $env->{'psgix.logger'} ) {
                $log->( { message => $msg, level => 'warn' } );
            }
            else {
                $env->{'psgi.errors'}->print($msg);
            }

            if ( $rate == 0 ) {

                return [ HTTP_FORBIDDEN, [], ["Forbbidden"] ];

            }
            else {

                return [
                    HTTP_TOO_MANY_REQUESTS,
                    [
                        "Retry-After" => ONE_MINUTE + 1,
                    ],
                    ["Too Many Requests"]
                ];

            }
        }

    }

    return $self->app->($env);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Greylist - throttle requests with different rates based on net blocks

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  use Plack::Builder;

  builder {

    enable "Greylist",
      default_rate => 250,
      greylist     => {
          '192.168.0.0/24' => 'whitelist',
          '172.16.1.0/25'  => [ 100, 'netblock' ],
      };

  }

=head1 DESCRIPTION

This middleware will apply rate limiting to requests, depending on the requestor netblock.

Hosts that exceed their configured per-minute request limit will be rejected with HTTP 429 errors.

Rejections will be logged, which will allow you to use something like L<fail2ban> to block repeat offenders, since bad
robots are like houseflies that repeatedly bump against closed windows.

=head1 ATTRIBUTES

=head2 default_rate

This is the default maximum number of hits per minute before requests are rejected, for any request not in the L</greylist>.

Omitting it will disable the global rate.

=head2 greylist

This is a hash reference to the greylist configuration.

The keys are network blocks, and the values are an array reference of rates and the tracking type. (A string of space-
separated values can be used instead, to make it easier to directly use the configuration from something like
L<Config::General>.)

The rates are either the maximum number of requests per minute, or "whitelist" to not limit the network block, or
"blacklist" to always forbid a network block.

(The rate "-1" corresponds to "whitelist", and the rate "0" corresponds to "blacklist".)

The tracking type defaults to "ip", which applies limits to individual ips. You can also use "netblock" to apply the
limits to all hosts in that network block, or use a name so that limits are applied to all hosts in network blocks
with that name.

For example:

    {
        '127.0.0.1/32' => 'whitelist',

        '192.168.1.0/24' => 'blacklist',

        '192.168.2.0/24' => [ 100, 'ip' ],

        '192.168.3.0/24' => [  60, 'netblock' ],

        # All requests from these blocks will limited collectively

        '10.0.0.0/16'    => [  60, 'group1' ],
        '172.16.0.0/16'  => [  60, 'group1' ],
    }

Note: the network blocks shown above are examples only.

The limit may be larger than L</default_rate>, to allow hosts to exceed the default limit.

=head2 file

This is the path of the throttle count file used by the L</cache>. If omitted, a default will be set.

This does not need to be set except for running tests.

=head2 cache

This is a code reference to a function that increments the cache counter for a key (usually the IP address or net
block).

=head1 KNOWN ISSUES

This does not try and enforce any consistency or block overlapping netblocks.  It trusts L<Net::IP::Match::Trie> to
handle any overlapping or conflicting network ranges, or to specify exceptions for larger blocks.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-Greylist->
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-Greylist-.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-Greylist-/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
