package Plack::Middleware::Greylist;

# ABSTRACT: throttle requests with different rates based on net blocks

# RECOMMEND PREREQ: Cache::FastMmap 1.52
# RECOMMEND PREREQ: Ref::Util::XS

use v5.20;
use warnings;

use parent qw( Plack::Middleware );

use HTTP::Status    qw/ HTTP_FORBIDDEN HTTP_TOO_MANY_REQUESTS /;
use List::Util 1.29 qw/ pairs /;
use Module::Load    qw/ load /;
use Net::IP::LPM;
use Plack::Util;
use Plack::Util::Accessor qw/ default_rate rules cache file _match greylist retry_after cache_config callback /;
use Ref::Util             qw/ is_plain_arrayref is_coderef /;
use Time::Seconds         qw/ ONE_MINUTE /;

use experimental qw/ postderef signatures /;

our $VERSION = 'v0.8.1';


sub prepare_app($self) {

    $self->default_rate(-1) unless defined $self->default_rate;

    die "default_rate must be a positive integer" unless $self->default_rate =~ /^[1-9][0-9]*$/;

    my $config = $self->cache_config;
    $self->cache_config( $config //= {} ) unless defined $config;

    $config->{init_file}                //= 0;
    $config->{unlink_on_exit}           //= !$config->{init_file};
    $config->{serializer}               //= '';
    my $expiry = $config->{expire_time} //= ONE_MINUTE;

    $self->retry_after( $config->{expire_time} + 1 ) unless defined $self->retry_after;
    die "retry_after must be a positive integer greater than $expiry seconds"
      unless $self->retry_after =~ /^[1-9][0-9]*$/ && $self->retry_after > $expiry;

    unless ( $self->cache ) {

        my $file = $self->file // $config->{share_file};
        die "No cache was set" unless defined $file;
        $config->{share_file} = "$file";

        load Cache::FastMmap;
        die "Cache::FastMmap version 1.52 or newer is required" if Cache::FastMmap->VERSION < 1.52;

        my $cache = Cache::FastMmap->new(%$config);

        $self->cache(
            sub($ip) {
                return $cache->get_and_set(
                    $ip,
                    sub( $, $count, $opts ) {
                        $count //= 0;
                        return ( $count + 1, { expire_on => $opts->{expire_on} } );
                    }
                );
            }
        );

    }

    my $match = Net::IP::LPM->new;

    $self->_match( sub($ip) { $match->lookup($ip) } );

    my @blocks;

    if ( my $greylist = $self->greylist ) {
        push @blocks, ( $greylist->%* );
    }

    $self->rules( my $rules = {} );

    my %codes = ( whitelist => -1, allowed => -1, blacklist => 0, rejected => 0, norobots => 0 );
    my %types = ( ip => '', netblock => 1 );

    for my $line ( pairs @blocks ) {

        my ( $block, $rule ) = $line->@*;
        $rule = [ split /\s+/, $rule ] unless is_plain_arrayref($rule);

        my ( $rate, $type ) = $rule->@*;

        $type //= "ip";
        my $mask = $types{$type} // $type;
        $mask = $block if $mask eq "1";

        $rate //= "rejected";
        if ( exists $codes{$rate} ) {
            $mask = $rate if $mask eq "";
            $rate = $codes{$rate};
        }

        $rules->{$block} = [ $rate, $mask ];
        $match->add( $block => $block );
    }

    if ( my $fn = $self->callback ) {
        die "callback must be a code reference" unless is_coderef($fn);
    }
    else {

        $self->callback(
            sub($info) {
                my $env    = $info->{env};
                my $msg    = $info->{message};
                if ( my $log = $env->{'psgix.logger'} ) {
                    $log->( { message => $msg, level => 'warn' } );
                }
                else {
                    $env->{'psgi.errors'}->print($msg);
                }
                return 1;
            }
        );
    }

}

sub call( $self, $env ) {

    my $ip   = $env->{REMOTE_ADDR};
    my $name = $self->_match->($ip);
    my $rule = $name ? $self->rules->{$name} : [ $self->default_rate ];

    my $rate = $rule->[0];

    if ( $rate == 0 && $rule->[1] && $rule->[1] eq "norobots" ) {
        if ( $env->{PATH_INFO} eq "/robots.txt" ) {
            $rate = ONE_MINUTE;    # one request/second
        }
    }

    if ( $rate >= 0 ) {

        my $limit = $rate == 0;

        my ($hits) = $self->cache->( $rule->[1] || $ip );
        $limit = $hits > $rate ? $hits : 0;

        if ($limit) {

            my $block = $name || "default";

            if ( my $fn = $self->callback ) {
                $fn->(
                    {
                        env     => $env,
                        ip      => $ip,
                        hits    => $limit,
                        rate    => $rate,
                        block   => $block,
                        message => "Rate limiting ${ip} after ${limit}/${rate} for ${block}",
                    }
                ) or return $self->app->($env);
            }

            if ( $rate == 0 ) {

                return [ HTTP_FORBIDDEN, [], ["Forbbidden"] ];

            }
            else {

                return [
                    HTTP_TOO_MANY_REQUESTS,
                    [
                        "Retry-After" => $self->retry_after,
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

version v0.8.1

=head1 SYNOPSIS

  use Plack::Builder;

  builder {

    enable "Greylist",
      file         => sprintf('/run/user/%u/greylist', $>), # cache file
      default_rate => 250,
      greylist     => {
          '192.168.0.0/24' => 'whitelist',
          '172.16.1.0/25'  => [ 100, 'netblock' ],
      };

  }

=head1 DESCRIPTION

This middleware will apply rate limiting to requests, depending on the requestor netblock.

Hosts that exceed their configured per-minute request limit will be rejected with HTTP 429 errors.

=head2 Log Messages

Rejections will be logged with a message of the form

    Rate limiting $ip after $hits/$rate for $netblock

for example,

    Rate limiting 172.16.0.10 after 225/250 for 172.16.0.0/24

Note that the C<$netblock> for the default rate is simply "default", e.g.

    Rate limiting 192.168.0.12 after 101/100 for default

This will allow you to use something like L<fail2ban> to block repeat offenders, since bad
robots are like houseflies that repeatedly bump against closed windows.

Note, if a L</callback> is specified, then nothing will be logged, but the log message will be sent to the callback.

=head1 ATTRIBUTES

=head2 default_rate

This is the default maximum number of hits per minute before requests are rejected, for any request not in the L</greylist>.

Omitting it will disable the global rate.

=head2 retry_after

This sets the C<Retry-After> header value, in seconds. It defaults to 1 + C<expiry_time> (61) seconds, which is the
minimum allowed value.

Note that this does not enforce that a client has waited that amount of time before making a new request, as long as the
number of hits per minute is within the allowed rate.

This option was added in v0.2.0

=head2 greylist

This is a hash reference to the greylist configuration.

The keys are network blocks, and the values are an array reference of rates and the tracking type. (A string of space-
separated values can be used instead, to make it easier to directly use the configuration from something like
L<Config::General>.)

The rates are either the maximum number of requests per minute, or "whitelist" or "allowed" to not limit the network
block, or "blacklist" or "rejected" to always forbid a network block.

(The rate "-1" corresponds to "allowed", and the rate "0" corresponds to "rejected".)

A special rate code of "norobots" will reject all requests except for F</robots.txt>, which is allowed at a rate of 60
per minute.  This will allow you to block a robot but still allow the robot to access the robot rules that say it is
disallowed.

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

This is the path of the throttle count file used by the L</cache>.

It is required unless you are defining your own L</cache> or you have specified a C<share_file> in L</cache_config>.

=head2 cache_config

This is a hash reference for configuring L<Cache::FastMmap>.  If it's omitted, defaults will be used.

The following options can be configured:

=over

=item *

C<init_file>

This is boolean that configures whether L</file> will be re-initialised in startup. Unless you are preloading the
application before forking, this should be false (default).

=item *

C<unlink_on_exit>

When true, the cache file will be deleted on exit. This defaults the negation of C<init_file>.

=item *

C<expire_time>

This sets the expiration time, which defaults to 60 seconds.

The L</retry_after> attribute will default to 1 + C<expiry_time>.

=back

Note that the L</file> attribute will be used to set the C<share_file>.

See L<Cache::FastMmap/new> for more information.

This option was added in v0.5.5.

=head2 cache

This is a code reference to a function that increments the cache counter for a key (usually the IP address or net
block).

If you customise this, then you need to ensure that the counter resets or expires counts after a set period of time,
e.g. one minute.  If you use a different time interval, then you may need to adjust the L</retry_after> time.

You also need to ensure that the cache is shared between processes.

=head2 callback

This is a code reference for a function that is called when rate limits are exceeded. The function is called with a hash
reference containing the following keys:

=over

=item *

C<env>

The L<Plack> environment.

=item *

C<ip>

The IP address being blocked, generally C<$env->{REMOTE_ADDR}>.

=item *

C<hits>

This is the number of hits.

=item *

C<rate>

This is the rate limit.

=item *

C<block>

This is the network block that the C<rate> applies to, or "default".

=item *

C<message>

This is the message that would be logged.

=back

If a callback is defined, it will be used instead of logging.

The callback must return a true value to indicate that the request should be blocked. Otherwise it will still be
allowed. (Note that the hit count will still be incremented, even if the request is allowed.)

A sample callback might look something like

    callback => sub {
        my ($info) = @_;

        my $env = $info->{env};

        my $log = $env->{'psgix.logger'};
        $log->({
            level   => "warn",
            message => $info->{message},
        });

        # See Plack::Middleware::Statsd
        my $statsd = $env->{'psgix.monitor.statsd'};
        $statsd->increment( "myapp.psgi.greylist.blocked" );
        $statsd->set_add( "myapp.psgi.greplist.ips", $ip );

        return 1;
    };

The callback attribute was added in v0.6.1.

=head1 KNOWN ISSUES

This does not try and enforce any consistency or block overlapping netblocks.  It trusts L<Net::IP::LPM> to
handle any overlapping or conflicting network ranges, or to specify exceptions for larger blocks.

When configuring the L</greylist> netblocks from a configuration file using L<Config::General>, duplicate netblocks may
be merged in unexpected ways, for example

    10.0.0.0/16   60 group-1

    ...

    10.0.0.0/16  120 group-2

may be merged as something like

    '10.0.0.0/16' => [ '60 group-1', '120 group-2' ],

Some search engine robots may not respect HTTP 429 responses, and will treat these as errors. You may want to make an
exception for trusted networks that gives them a higher rate than the default.

This does not enforce consistent rates for named blocks. For example, if you specified

    '10.0.0.0/16'    => [  60, 'named-group' ],
    '172.16.0.0/16'  => [ 100, 'named-group' ],

Requests from both netblocks would be counted together, but requests from 10./16 netblock would be rejected after 60
requests. This is probably not something that you want.

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.20 or later.

Future releases may only support Perl versions released in the last ten years.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-Greylist>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-Greylist.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-Greylist/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 CONTRIBUTOR

=for stopwords Gabor Szabo

Gabor Szabo <gabor@szabgab.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2024 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
