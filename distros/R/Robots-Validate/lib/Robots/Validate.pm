package Robots::Validate;

# ABSTRACT: Validate that IP addresses are associated with known robots

use v5.24;

use Moo 1;

use Algorithm::AhoCorasick::SearchMachine;
use File::ShareDir qw( dist_file );
use File::Slurper  qw( read_binary );
use List::Util     1.33 qw( all any none );
use Net::DNS::Resolver;
use Net::IP qw( ip_expand_address ip_is_ipv4 ip_is_ipv6 ip_splitprefix );
use Net::IP::LPM;
use PerlX::Maybe qw( maybe );
use Ref::Util qw( is_plain_arrayref is_plain_hashref is_regexpref );
use Scalar::Util 1.18 qw( refaddr );
use Sub::Util 1.40 qw( set_subname );
use TOML::Tiny 0.20 ();
use Try::Tiny;
use Types::Common qw( ArrayRef Bool ConsumerOf Enum HashRef InstanceOf Maybe PositiveInt );

# RECOMMEND PREREQ: CHI 0.40
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

use experimental qw( lexical_subs signatures );

use namespace::autoclean;

our $VERSION = 'v0.4.3';


has resolver => (
    is      => 'bare',
    isa     => InstanceOf ['Net::DNS::Resolver'],
    builder => 1,
    handles => {
        _dns_query  => 'query',
        _dns_search => 'search',
    },
);

sub _build_resolver($self) {
    return Net::DNS::Resolver->new;
}


has max_forward_lookups => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 4,
);


has networks => (
    is      => 'bare',
    isa     => InstanceOf ['Net::IP::LPM'],
    builder => 1,
    handles => {
        _add_string   => 'add',
        _match_string => 'lookup',
    },
);

sub _build_networks($self) {
    return Net::IP::LPM->new;
}

has _validators => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    builder  => sub($self) { return {} },
);

has _agents => (
    is       => 'lazy',
    isa      => InstanceOf [qw/ Algorithm::AhoCorasick::SearchMachine Algorithm::AhoCorasick::XS /],
    init_arg => undef,
    builder  => \&_build_agents,
);

sub _build_agents($self) {
    # We need to ensure the validators are initialised with the rules
    $self->_init_validators_from_config;

    my @names = keys $self->_validators->%*;


    if ( eval { require "Algorithm::AhoCorasick::XS" } ) {

        *_first_match = set_subname "_first_match", sub( $self, $str ) {
            return $self->_agents->first_match($str)
        };

        *_all_matches = set_subname "_all_matches", sub( $self, $str ) {
            return $self->_agents->matches($str)
        };

        return Algorithm::AhoCorasick::XS->new(\@names);

    }
    else {

        *_first_match = set_subname "_first_match", sub( $self, $str ) {
            my $match;
            $self->_agents->feed($str, sub( $, $name ) { $match //= $name }  );
            return $match;
        };

        *_all_matches = set_subname "_all_matches", sub( $self, $str ) {
            my @matches;
            $self->_agents->feed($str, sub( $, $name ) { push @matches, $name; return undef } );
            return @matches;
        };

        return Algorithm::AhoCorasick::SearchMachine->new(@names);

    }


}


has config => (
    is     => 'lazy',
    isa    => ArrayRef [HashRef],
    coerce => sub($ref) {

        return $ref if is_plain_arrayref($ref);

        unless ( is_plain_hashref($ref) ) {
            my $toml = read_binary("$ref");
            $ref = _from_toml($toml);
        }

        if ( is_plain_hashref($ref) ) {

            state sub _normalise( $key, $val ) {
                my %item = $val->%*;
                $item{name}   //= $key;
                for my $key (qw/ agents network /) {
                    $item{$key} = [ $item{$key} ] unless !exists $item{$key} || is_plain_arrayref( $item{$key} );
                }
                return \%item;
            }

            return [ map { _normalise( $_ => $ref->{$_} ) } sort keys $ref->%* ];
        }

        return $ref;
    },
    builder => sub($self) {
        return dist_file( __PACKAGE__ =~ s/::/-/gr, 'robots.toml' );
    }
);


has index => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    builder  => sub($self) { return {} },
);



has locked => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
);


has cache => (
    is        => 'ro',
    isa       => ConsumerOf ['CHI::Driver::Role::Universal'],
    predicate => 1,
);


has cache_options => (
    is     => 'lazy',
    isa    => Maybe [HashRef],
    coerce => sub($val) {
        return $val if is_plain_hashref($val);
        return { expires_in => "$val" } if defined $val;
        return undef;
    },
    builder => 1,
);

sub _build_cache_options($) {
    return {};
}


has validation_mode => (
    is      => 'ro',
    isa     => Enum [qw/ first relaxed strict /],
    default => 'relaxed',
);


has max_matches => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 4,
);


sub validate( $self, $ip, $agent = undef, $opts = undef ) {

    if ( is_plain_hashref($agent) && !$opts ) {
        ( $agent, $opts ) = ( $opts, $agent );
        $agent //= $opts->{agent}; # DEPRECATED
    }

    if ( is_plain_hashref($ip) && !$agent ) {
        $agent = $ip->{HTTP_USER_AGENT};
        $ip   =  $ip->{REMOTE_ADDR};
    }

    if ( !$opts->{no_cache} && $self->has_cache ) {
        return $self->_cache_compute( $ip, $agent, $opts // { } );
    }

    return $self->_revalidate( $ip, $agent // "" );
}

# Note: we implement our own _cache_compute method rather than use the CHI compute method so that we can modify the
# caching options based on the value.

use constant _GET_OPTS => ( qw/ expire_if busy_lock / );

sub _cache_compute( $self, $ip, $agent, $opts ) {

    my $key = join( $;, $ip, $agent // '' );

    my $cache = $self->cache;

    my %set_opts = $self->cache_options->%*;
    my %get_opts = map { maybe $_ => delete $set_opts{$_} // undef } _GET_OPTS;

    $opts->{cache_failure} //= delete $set_opts{cache_failure};

    my $value = $cache->get( $key, %get_opts );
    unless ( defined $value ) {

        $value = $self->_revalidate( $ip, $agent // "" );
        if ( $value || $opts->{cache_failure} ) {
            $set_opts{expires_in} = $opts->{cache_failure}
              if !$value && $opts->{cache_failure} && $opts->{cache_failure} ne "1";
            $cache->set( $key, $value, \%set_opts );
        }

    }

    return $value;
}

sub _revalidate( $self, @args ) {
    my $mode = $self->validation_mode;
    my $method = $self->can("_${mode}_revalidate") or die "Unsupported mode: '${mode}'";
    return $self->$method(@args);
}

sub _first_revalidate( $self, $ip, $agent ) {

    if ( $agent ne "" ) {

        $self->_agents; # ensure agents are instantiated

        if ( my $str = $self->_first_match( lc $agent ) ) {
            my $res = $self->_validators->{$str}->($ip);
            my $rule = $res && $self->index->{$res};
            if ( $rule && $rule->{ignore} ) {
                return undef;
            }
            return $res && [ $res => $str ];
        }

    }
    else {
        my $res = $self->_match_ip($ip);
        if ($res) {
            return [ $res => undef ];
        }
        return $res;
    }

    return undef;
}

sub _relaxed_revalidate( $self, $ip, $agent ) {

    if ( $agent ne "" ) {

        $self->_agents; # ensure agents are instantiated

        my %seen;
        my $fails = 0;

        my @matches = $self->_all_matches( lc $agent );
        splice @matches, $self->max_matches;
        for my $str (@matches) {
            my $fn = $self->_validators->{$str};
            next if exists $seen{ refaddr $fn };
            my $res = $seen{ refaddr $fn } = $fn->($ip);
            unless ($res) {
                $fails++ if defined $res;
                next;
            }
            my $rule = $res && $self->index->{$res};
            if ( $rule && $rule->{ignore} ) {
                return undef;
            }
            return $res && [ $res => $str ];
        }

        return "" if $fails;

    }
    else {
        my $res = $self->_match_ip($ip);
        if ($res) {
            return [ $res => undef ];
        }
        return $res;
    }

    return undef;
}

sub _strict_revalidate( $self, $ip, $agent ) {

    if ( $agent ne "" ) {

        $self->_agents;    # ensure agents are instantiated

        my %seen;
        my @checks;

        my @matches = $self->_all_matches( lc $agent );
        splice @matches, $self->max_matches;
        for my $str (@matches) {
            my $fn = $self->_validators->{$str};
            next if exists $seen{ refaddr $fn };
            my $res = $seen{ refaddr $fn } = $fn->($ip);
            next unless defined $res;
            my $rule = $res && $self->index->{$res};
            next if $rule && $rule->{ignore};
            push @checks, $res && [ $res => $str ];
        }

        if (@checks) {
            if ( all { !!$_ } @checks ) {
                return $checks[0];
            }
            else {
                return "";
            }
        }

    }
    else {
        my $res = $self->_match_ip($ip);
        if ($res) {
            return [ $res => undef ];
        }
        return $res;
    }

    return undef;
}


sub bad_robot( $self, $ip, $agent = undef, $opts = undef ) {
    my $value = $self->validate( $ip, $agent, $opts );
    return defined($value) ? !$value : undef;
}

sub _add_rule( $self, $rule ) {

    die "The rules are locked" if $self->locked;

    my $name = lc $rule->{name};
    die "A rule name is required" unless defined $name;

    my @fns;

    if ( $rule->{ignore} ) {

        push @fns, set_subname "_ignore_${name}", sub($) { 1 };

    }
    else {

        my $domain  = $rule->{domain};
        my $network = $rule->{network};

        if ($network) {

            $self->_add_network( $_, $name ) for ( $network->@* );

            push @fns, set_subname "_check_ip_${name}", sub($ip) { $self->_check_ip( $name, $ip ) };
        }

        if ($domain) {

            state sub _to_regexp($domain) {
                return $domain if is_regexpref($domain);
                my ($re) = $domain =~ m[ \A / (.+) / \z ]x;
                $re //= quotemeta($domain) . '\z';
                return qr/${re}/an;
            }

            my $fn;

            if ( is_plain_arrayref($domain) ) {
                my @res = map { _to_regexp($_) } $domain->@*;
                $fn = sub($ip) { $self->_check_dns( $name => \@res, $ip ) };
            }
            else {
                my $re = _to_regexp($domain);
                $fn = sub($ip) { $self->_check_dns( $name => $re, $ip ) };
            }

            push @fns, set_subname "_check_dns_${name}", $fn;
        }
    }

    if (@fns) {
        my $type = $rule->{match} // "any";

        # TODO: add option for partial matching where false returns undef, i.e. "yes or unknown"

        my $fn = set_subname "_verify_${name}", (

            ( @fns == 1 )
            ? sub($ip) { $fns[0]->($ip) and $name }
            : (

                $type eq "any"
                ? sub($ip) {
                    any { $_->($ip) } @fns and $name;
                  }
                : sub($ip) {
                    all { $_->($ip) } @fns and $name;
                }
            )
        );

        my $validators = $self->_validators;

        if ( my $agents = $rule->{agents} ) {
            for my $str ( map { lc $_ } $agents->@* ) {
                die "string ${str} already exists in the rules" if exists $validators->{$str};
                $validators->{$str} = $fn;
            }
        }
        else {
            # TODO add support for matching on IP
            die "an agent substring is required";
        }

        $self->index->{$name} = $rule;

    }
    else {

        die "no rules found for ${name}";

    }

}

sub _add_network( $self, $cidr, $name ) {
    try {
        $self->_add_string( $cidr, $name );
    }
    catch {
        die "add_string failed for '$cidr' with '$name': $_";
    };
}

sub _match_ip( $self, $ip ) {
    return $self->_match_string( $ip );
}

sub _check_ip( $self, $name, $ip ) {
    my $check = $self->_match_ip($ip);
    return $name if $check && $check eq $name;
    return undef;
}

# The canonical form used to compare addresses: everything is mapped into the
# ::ffff: IPv6 space already used for Net::Patricia (see _match_ip), then fully
# expanded.  Net::DNS renders an AAAA address as "2001:db8:0:0:0:0:0:7", which
# never string-equals the "2001:db8::7" a web server puts in REMOTE_ADDR, so
# comparing the two textually is not meaningful without this.
sub _normalise_ip($ip) {
    return undef unless defined $ip && length $ip;
    $ip = "::ffff:" . ip_expand_address( $ip, 4 ) if ip_is_ipv4($ip);
    return undef unless ip_is_ipv6($ip);      # ip_expand_address does not validate
    return ip_expand_address( $ip, 6 );
}

# Build the reverse-lookup name here rather than passing an address literal to
# the resolver and relying on it to special-case one.  Net::DNS::Question does
# convert a literal, but Net::DNS::Resolver::Mock -- the resolver the tests use
# -- only does so for IPv4, so relying on that behaviour makes the IPv6 path
# untestable.  Being explicit also stops a hostname that merely looks like an
# address from being silently reinterpreted.
sub _arpa($norm) {
    ( my $nibbles = $norm ) =~ s/://g;
    if ( $nibbles =~ /\A0{20}ffff([[:xdigit:]]{8})\z/a ) {    # IPv4-mapped
        return join( ".", reverse map { hex } $1 =~ /(..)/g ) . ".in-addr.arpa";
    }
    return join( ".", reverse split //, $nibbles ) . ".ip6.arpa";
}

sub _check_dns( $self, $name, $domain, $ip ) {

    my $wanted = _normalise_ip($ip) // return undef;

    my $reply = $self->_dns_query( _arpa($wanted), "PTR" ) or return undef;

    my @hostnames = grep { !!$_ }
      map { $_->can("ptrdname") && $_->ptrdname } $reply->answer;


    if ( is_plain_arrayref($domain) ) {
        my @domains = $domain->@* or return undef;

        if ( @domains == 1 ) {
            $domain = $domains[0];
        }
        else {
            my $re = "(" . join( "|",  @domains ) . ")";
            $domain = qr/$re/n;
        }
    }

    my @matched = grep { $_ =~ $domain } @hostnames;

    return "" unless @matched;

    splice @matched, $self->max_forward_lookups;

    # Only a record of the client's own family can confirm it, so ask for one
    # type rather than both: an IPv4 client normalises into ::ffff:/96.
    my $type = $wanted =~ /\A0000:0000:0000:0000:0000:ffff:/ ? "A" : "AAAA";

    for my $hostname (@matched) {

        my $forward = $self->_dns_query( $hostname, $type ) or next;

        return $name
          if any { ( _normalise_ip($_) // "" ) eq $wanted }
          map    { $_->address }
          grep   { $_->can("address") } $forward->answer;
    }

    return "";
}

sub _init_validators_from_config($self) {
    for my $rule ( $self->config->@* ) {
        $self->_add_rule( { $rule->%* } );
    }
    $self->_set_locked(1);
}

BEGIN {

    if ( eval { require "TOML::XS" } ) {
        *_from_toml = sub($toml) { TOML::XS::from_toml($toml)->get() };
    }
    else {
        *_from_toml = \&TOML::Tiny::from_toml;
    }
}


1;

__END__

=pod

=encoding UTF-8

=for stopwords CIDR GoogleBot TOML dotless googlebot iMessage superstrings validator yacybot

=head1 NAME

Robots::Validate - Validate that IP addresses are associated with known robots

=head1 VERSION

version v0.4.3

=head1 SYNOPSIS

  use Robots::Validate;

  my $rv = Robots::Validate->new;

  ...

  if ( my $res = $rs->validate( $ip, $user_agent ) ) {
     ...
  }

=head1 DESCRIPTION

This module allows one to validate a robot user-agent string against the IP addresses.

=head1 ATTRIBUTES

=head2 resolver

This is the L<Net::DNS::Resolver> object used for DNS lookups.

This can only be set via the constructor.

=head2 max_forward_lookups

The maximum number of hostnames from the reverse-DNS answer that will be forward-confirmed in a single L</validate> call.
The defaults is C<4>.

An external party controls the reverse zone for its own address, and how many names the C<PTR> lookup returns.
Without a limit, validation costs one forward lookup per name, each for a distinct name and so each a cache miss resolved against the authoritative servers for the domain the rule names.

Raise this only if a robot you match legitimately publishes more than four C<PTR> records for one address.

This was added in version v0.3.11.

=head2 networks

This is a L<Net::Patricia> object used for matching networks.

This can only be set via the constructor.

Note that internally IPv4 addresses are converted to IPv6 addresses.

=head2 config

This is an array reference of rule configurations.
Each item is a hash reference with the following keys:

=over

=item name

This is a short string with the rule name.
It is required.

This name will be transformed into lowercase.

=item agents

This is an array reference of short strings to match against user-agent strings.
It is required.

Case will be ignored, so "GoogleBot" and "googlebot" are the same.

=item domain

This is a string or array reference of short strings with the domain suffix. e.g. C<.crawl.example.com>,
or with a regular expression C</\.crawl\.example\.com$/>.

It is important that domain suffixes begin with an initial dot.  For
cases where an entire domain name should match, use a regular
expression that anchors the beginning of the string,
e.g. C</^crawl\.example\.com$/>.
Otherwise an imposter domain matching the dotless-suffix would be validated, e.g.
C<imposter-crawl.example.com>.

Also note that the TOML format will require slashes to be escaped, e.g.

    domain = "/\\.google(bot)?\\.com$/"

=item network

This is an array reference of CIDR network blocks.

=item match

This specifies the match type.

The possible values are:

=over

=item any

An agent is verified if either the C<domain> or the C<network> match.
This is the default when unspecified.

=item all

An agent is verified is both the C<domain> and the C<network> match.

=back

=item ignore

If this is set to a true value, then no validation will be done and the user-agent will treated as unknown.

Use this to flag user-agent strings that get matched as a bot and then fail, e.g.
applications like iMessage include fake bots in their user-agent strings, e.g.

     facebookexternalhit/1.1 Facebot Twitterbot/1.0

They do this so that servers will respond with metadata that they may not server to  web browsers.
These will show up as bad bots without this feature.

This feature may not work when the L</validation_mode> is not C<relaxed>.

=back

Note that either C<domain> or C<network> can be omitted.

If the constructor is passed a hash reference, then it is coerced into an array reference of the values, sorted by keys,
where the key is added to the C<name> if it is not already specified.  (The C<agents> and C<network> values will be
coerced into array references.)

If the constructor is passed anything else, it is assumed to be the filename of a TOML file with the configuration.

There is a utility in the distribution F<devel/rebuild-robots-config> that will normalise the file and update
network information about robots.

Users are encouraged to copy the F<share/robots.toml> file from the
distribution and maintain a separate file with rules that are suited
to their application.

Users are also encouraged to submit new and updated rules back to the maintainers. See L</SOURCE>.

=head2 index

This is a hash reference where the keys are rule names and the values are the rules from L</config>.

=head2 locked

This is a boolean to indicate that internal data structures for matching agents have been built, and the rules are locked.

=head2 cache

This is an optional L<CHI> cache used for matching IP addresses and user-agent strings.

See the L</SECURITY CONSIDERATIONS> section for improving the safety of the cache.

=head2 has_cache

This indicates that there is a L</cache>.

=head2 cache_options

This is an optional hash reference of L</cache> options to pass to L<CHI/compute>, e.g.

    { expires_in => '8 hours' }

Plain strings are assumed to be C<expires_in> values.

=head2 validation_mode

This is the validation mode.

=over

=item first

The validator will look at the first matches in the user-agent string and test only that.

Setting this to false is faster but removes the ability to handle overlapping user-agent strings.

=item relaxed

This is the default mode.

The validator will look at the first L</max_matches> matches in the user-agent string and test that any of them are valid.

This feature is useful for handling crawlers that sometimes include the names of other crawlers in their user-agent strings.

=item strict

The validator will look at the first L</max_matches> matches in the user-agent string and test that all of them are valid.

This feature will reject legitimate crawlers that include the names of other crawlers in their user-agent strings.

=back

This was added in version v0.3.12.

=head2 max_matches

The maximum number of matches to check.

When matches are checked using reverse-DNS, then each request match may add an additional lookup.
Without this limit, an attacker can force many DNS lookups by inserting multiple matching agent names.

The default is C<4>.

This is ignored when the L</validation_mode> is C<first>.

This was added in version v0.3.11.

=head1 METHODS

=head2 validate

  my $result = $rv->validate( $ip, $agent, \%opts );

Alternatively, you can pass in a L<Plack> environment:

  my $result = $rv->validate($env);

This method attempts to validate that an IP address C<$ip> is associated with a known robot identified by the C<$agent>.

If C<$ip> is in a known list of network addresses, then it succeeds.

Otherwise it attempts to validate that an IP address belongs to a known
robot by first looking up the hostname that corresponds to the IP address,
and then validating that the hostname resolves to that IP address.
It then checks if the hostname is associated with a
known web robot.

A fake robot (one where the user-agent claims to be something that
does not match the IP address or resolved hostname) returns a defined
but false value.

An unknown user-agent returns C<undef>.

Successful checks return an array reference containing the C<name> and the matching substring.

The rule can be looked up from the L</index> attribute.

You can specify the following C<%opts>:

=over

=item no_cache

Do not check the L</cache>.

=item cache_failure

By default, failures are not cached.

When this is set to true, failures are cached.

Any value other than "1" is assumed to be an L<CHI/expires_in> option for setting the cache.

See L</SECURITY CONSIDERATIONS> before enabling this feature.

This has no meaning if there is no cache or the C<no_cache> option is set.

This was added in version v0.3.4.
This can also be specified in the L</cache_options> as of v0.3.5.

=item agent

Specify the C<$agent>, for backwards-compatibility with versions before v0.3.0.

This is deprecated and will be removed from a future version.

=back

=head2 bad_robot

    $rv->bad_robot( $env, \%opts ) and ...

This is a wrapper around L</validate> that returns true when it fails validation.

It will return C<undef> when the result is unknown.

This was added in version v0.3.5.

Note that a C<relaxed> L</validation_mode> mode means that a validated robot that impersonates another robot in their user-agent, e.g.

    "TelegramBot (like TwitterBot)"

will not be classified as a bad robot.

=head1 KNOWN ISSUES

Many of these rules are not documented, but have been guessed from web traffic.

Bots that use cloud services without documenting what hosts they use are not added here.

Decentralised bots such as yacybot cannot be verified.

The networks used by some robots do not consistently support reverse DNS lookups, and may randomly fail.

=head1 SECURITY CONSIDERATIONS

When using the L</cache>, ensure that it is configured to expire the
data by setting L<CHI/expires_in> and digest the keys by setting
L<CHI/max_key_length> to 0.  This is to keep the cache from growing
too large, and to reduce the likelihood of cache backend
vulnerabilities being exploited through user-agent strings.

When setting the C<cache_failure> option, be aware that cached failures may need a shorter expiration time.

When specifying a C<domain> for verification rules, ensure that there
is an initial dot in the suffix, or that the regular expression
matches the entire domain name.  Otherwise imposter domains with the
same suffix will be validated.

When the C<network> list contains cloud addresses, it is important to
regularly update the addresses from the documented information, as an
imposter can use abandoned cloud IP addresses.

=head1 SEE ALSO

The file F<robots.toml> included with this distribution contains links to documented rules.

The TOML specification can be found at L<https://toml.io>.

=begin :readme

=head1 append:REQUIREMENTS

L<CHI> is required to use the caching features.

L<Algorithm::AhoCorasick::XS> and L<TOML::XS> will be used if they are available.

=end :readme

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Robots-Validate>
and may be cloned from L<https://github.com/robrwo/Robots-Validate.git>

=head1 SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Robots-Validate/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

Some of the development of this module was sponsored by Science Photo Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
