package Plack::Middleware::DNSBL;

use strict;
use warnings;

use parent qw(Plack::Middleware);

our $VERSION = '0.0304';

use Carp ();
use Plack::Util::Accessor qw(cache cache_time resolver blacklists blacklisted);
use Net::DNS::Resolver;

sub prepare_app {
	my ($self) = @_;
	unless ($self->resolver) {
		$self->resolver( Net::DNS::Resolver->new );
	}

	unless ($self->blacklisted && ref $self->blacklisted eq 'CODE') {
		$self->blacklisted(sub {
			[ 500, [ 'Content-Type' => 'text/plain' ], [ '' ] ];
		});
	}

	unless ($self->blacklists && ref $self->blacklists eq 'HASH') {
		Carp::carp("'blacklists' option must contain a HASHREF value");
		$self->blacklists(+{ });
	}

	unless ($self->cache_time) {
		$self->cache_time('86400');
	}
}

sub query {
	my ($self, $address) = @_;
	my $response = $self->resolver->send($address)
		or return;

	# A Record = black listed
	foreach my $record ($response->answer) {
		return 1 if $record->type eq 'A';
	}
}

sub is_blacklisted {
	my ($self, $ip, $port) = @_;
	my $reversed = _reverse_ip($ip);

	# Check if we have a cached response
	if ($self->cache && (my $cached = $self->cache->get("dnsbl:$reversed"))) {
		return @$cached;
	}

	my ( $blacklisted, $blacklist );
	foreach (keys %{ $self->blacklists }) {
		my $address = $self->blacklists->{$_};

		$address =~ s/\$ip/$reversed/g;
		$address =~ s/\$port/$port/g;

		if ($self->query($address)) {
			$blacklist   = $_;
			$blacklisted = 1;
			last;
		}
	}

	# Caches our result
	if ($self->cache) {
		$self->cache->set("dnsbl:$reversed" => [ $blacklisted, $blacklist, 1 ],
			$self->cache_time);
	}

	return ( $blacklisted, $blacklist, 0 );
}

sub call {
	my ($self, $env) = @_;
	if (_is_ipv4($env->{REMOTE_ADDR})) {
		# Check if this IP is blacklisted
		my ($blacklisted, $blacklist, $is_cached)
			= $self->is_blacklisted($env->{REMOTE_ADDR}, $env->{SERVER_PORT});

		# If it's blacklisted, call the callback and return it's return value
		if ($blacklisted) {
			$env->{DNSBL_BLACKLISTED} = 1;
			$env->{DNSBL_BLACKLIST} = $blacklist;
			$env->{DNSBL_IS_CACHED} = $is_cached;

			return $self->blacklisted->($env, $blacklist, $is_cached);
		}
	}

	return $self->app->($env);
}


# Helper functions
sub _is_ipv4    { shift =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ }
sub _reverse_ip { join '.', reverse split /\./, shift   }

1;
__END__
=head1 NAME

Plack::Middleware::DNSBL - An IPv4 DNS Blacklist middleware for Plack

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::DNSBL;
  
  my $app = sub { ... };
  
  builder {
      enable 'DNSBL',
          blacklists => {
              'your-trusted-blacklist' => '$ip.your.trusted.blacklist',
              'ip-port-blacklist'      => '$ip.$port.ip-port.trusted.blacklist',
          };
  
      $app;
  }

=head1 DESCRIPTION

The Plack::Middleware::DNSBL middleware provides a simple yet customizable way
of blocking ill-intentionated requests from reaching your main application by
using an external blacklist.

=head1 CONFIGURATIONS

=over 4

=item blacklists

  enable 'DNSBL',
      blacklists => {
          'blacklist-name-1' => 'blacklist-query-address',
          'blacklist-name-2' => 'blacklist-query-address',
          'blacklist-name-3' => 'blacklist-query-address',
          # ...
          'blacklist-name-n' => 'blacklist-query-address',
      };

The C<blacklists> option specifies a hashref with all the blacklists' name and
query address pairs. The query address will have every C<$ip> and C<$port>
substrings replaced respectively by the C<$env>iroment's reversed IPv4 address
and server's port.

Therefore:

  enable 'DNSBL',
      blacklists => {
          'my example blacklist' => '$ip.$port.blacklist.example.com', # single quotes!
      };

Will query C<1.0.0.127.80.blacklist.example.com> for IP 127.0.0.1 acessing over
port 80.

=item blacklisted

  enable 'DNSBL',
      blacklists => { ... },
      blacklisted => sub {
          my ($env, $blacklist, $is_cached) = @_;
  
          # Do some logging here
  
          if (!$is_cached && $blacklist eq 'blacklist name') {
              warn "$blacklist matched another address!";
          }
  
          if ($ENV{DEBUG} || $ENV{FRIENDLY}) {
              return [ 200, [ 'Content-type' => 'text/html' ], [
                  "<html><body>",
                  "<h1>Hello, buddy ($env->{REMOTE_ADDR})!</h1>",
                  "<p>Looks like you're banned at $blacklist!</p>",
                  "<p>Sorry :(</p>",
                  "</body></html>",
              ] ];
          }
  
          [ 500, [ 'Content-type' => 'text/plain' ], [ "Die, spammer!" ] ];
      };

The C<blacklisted> option specifies a coderef that will be called at the first
blacklist that detect this IP as flagged, returing immediately it's return
value.

Defaults to:

  sub { [ 500, [ 'Content-Type' => 'text/plain' ], [ '' ] ] }

=item cache, cache_time

  enable 'DNSBL',
      blacklists => { ... },
      cache_time => '1h',
      cache      => $cache;

The C<cache> option specifies an object which handles C<get> and C<set> methods
for caching whether an IP is blacklisted or not. If this option is set, it
expects C<cache_time> to be a string that can be parsed by this object and
contains how long should this data be cached. Defaults to '86400' (1 day).

=item resolver

  my $my_resolver = Net::DNS::Resolver->new(
      nameservers => [ '10.1.1.128', '10.1.2.128' ],
      recurse     => 0,
      debug       => 1
  );
  
  builder {
      enable 'DNSBL',
          resolver   => $my_resolver,
          blacklists => { ... };
      $app;
  };

A L<Net::DNS::Resolver> object. Defaults to C<< Net::DNS::Resolver->new >>.

=back

=head1 WHITELISTING

There's no build-in way of whitelisting IPs or certain paths, however this can
be quickly solved by using L<Plack::Builder>'s C<enable_if>:

  builder {
      enable_if {
          !$ENV{DEBUG} && $_[0]->{REMOTE_ADDR} ne '127.0.0.1'
      } 'DNSBL', ...;
      $app;
  };

=head1 SEE ALSO

L<Net::DNS::Resolver>

=head1 AUTHOR

Victor Franco, C<< <victorfrancovl at gmail.com> >>

=head1 BUGS

Patches welcome at L<https://www.github.com/vtfrvl/plack-middleware-dnsbl>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself

