package Plack::App::HostMap;
use strict;
use warnings;
use parent qw/Plack::Component/;
# ABSTRACT: Map multiple Plack apps by host 

use Carp ();
use Domain::PublicSuffix;
 
sub mount { shift->map(@_) }
 
sub map {
    my $self = shift;
    my($domain, $app) = @_;

    if(ref $domain eq 'ARRAY') { 
        $self->_map_domain($_, $app) for @$domain;
    }
    else { $self->_map_domain($domain, $app) }
}

sub _map_domain { 
    my ($self, $domain, $app) = @_;

    Carp::croak("domain cannot be empty") unless $domain;

    if($domain =~ qr/^\*\./) { 
        $self->{_dps} = 1;
    } 

    $self->{_map}->{$domain} = $app;
}

sub prepare_app { 
    my ($self) = @_;
    $self->{_dps} = Domain::PublicSuffix->new if $self->{_dps};
}

sub call {
    my ($self, $env) = @_;
 
    my $http_host = $env->{HTTP_HOST};
 
    if ($http_host and my $port = $env->{SERVER_PORT}) {
        $http_host =~ s/:$port$//;
    }

    #only enter this if there is not an exact match
    if($self->{_dps} and not $self->{_map}->{$http_host}) {
        if($self->{_cached_matches}->{$http_host}) {
            $http_host = $self->{_cached_matches}->{$http_host};
        }
        else {
            if($self->{_dps}->get_root_domain($http_host)) {
                my $suffix = $self->{_dps}->suffix;

                my ($subdomains) = $http_host =~ qr/^(.*)\.$suffix$/;
                my @domains = split qr/\./, $subdomains;

                my $match;
                while(@domains) { 
                    my $current_domain = join '.', @domains;
                    $current_domain = "*.$current_domain.$suffix";

                    if($self->{_map}->{$current_domain}) {
                        $match = $current_domain;
                        last;
                    }

                    shift @domains;
                }

                $match = $match ? $match : $http_host;
                
                #only cache if no_cache is false and we actually matched something
                if(not $self->{no_cache} and $self->{_map}->{$match}) { 
                    $self->{_cached_matches}->{$http_host} = $match;
                }

                $http_host = $match;
            }
            else { 
                warn $self->{_dps}->error;
            }
        }
    }

    return [404, [ 'Content-Type' => 'text/plain' ], [ "Not Found" ]] unless $self->{_map}->{$http_host};

    my $app = $self->{_map}->{$http_host};
    return $app->($env);
}

sub no_cache { 
    my $self = shift;

    if(@_) { 
        $self->{no_cache} = shift;
    }

    return $self->{no_cache};
}
 
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::HostMap - Map multiple Plack apps by host 

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Plack::App::HostMap;
 
    my $foo_app = sub { ... };
    my $bar_app = sub { ... };
    my $baz_app = sub { ... };
    my $foo_bar_app= sub { ... };
 
    my $host_map = Plack::App::HostMap->new;

    #map different hosts to different apps
    $host_map->map("www.foo.com" => $foo_app);
    $host_map->map("bar.com" => $bar_app);
    $host_map->map("test.baz.com" => $baz_app);

    #map multiple hosts to same app conveniently
    $host_map->map(["www.foo.com", "foo.com", "beta.foo.com"] => $foo_app);

    #map all subdomains of a host to an app
    $host_map->map("*.foo.com" => $foo_app); #will match www.foo.com, foo.com, beta.foo.com, test.foo.com, beta.test.foo.com, etc...

    #map multilevel subdomains of a host to an app
    $host_map->map("*.foo.bar.com" => $foo_bar_app); #will match test.foo.bar.com, beta.foo.bar.com, beta.test.foo.bar.com, etc...
 
    my $app = $host_map->to_app;

=head1 DESCRIPTION

Plack::App::HostMap is a PSGI application that can dispatch multiple
applications based on host name (a.k.a "virtual hosting"). L<Plack::App::URLMap> can
also dispatch applications based on host name. However, it also more versatile and can dispatch
applications based on URL paths. Because of this, if you were to use L<Plack::App::URLMap> to map
applications based on host name it would take linear time to find your app. So if you had N host name entries
to map to apps, you might have to search through N mappings before you find the right one. Because Plack::App::HostMap
is simpler and only dispatches based on host name, it can be much more efficient for this use case. Plack::App::HostMap
uses a hash to look up apps by host name, and thus instead of a linear time lookup is constant time. So if you had 2 apps
to dispatch by host name or 10,000, there shouldn't be a difference in terms of performance since hashes provide constant
time lookup.

=head1 METHODS

=head2 map

    $host_map->map("www.foo.com" => $foo_app);
    $host_map->map("bar.com" => $bar_app);

Maps a host name to a PSGI application. You can also map multiple host names to
one application at once by providing an array reference:

    $host_map->map(["www.foo.com", "foo.com", "beta.foo.com"] => $foo_app);

If you need all subdomains of a host name to map to the same app, instead of listing them all out you can do so like this:

    $host_map->map("*.foo.com" => $foo_app); #will match www.foo.com, foo.com, beta.foo.com, test.foo.com, beta.test.foo.com, etc...

This will map any subdomain of foo.com to C<$foo_app>. This way you can point new subdomains at your app without
having to update your mappings. Also, L<Plack::App::HostMap> will always match the most exact rule. For example, if you have the rules:

    $host_map->map("foo.com" => $foo_app);
    $host_map->map("*.foo.com" => $generic_foo_app);

And you request C<foo.com>, it will match the C<$foo_app>, not the C<$generic_foo_app> since there is an explicit rule for C<foo.com>. 
Also, if L<Plack::App::HostMap> cannot find an exact match for a host, L<Plack::App::HostMap> will always
match the first rule it finds. For instance, if you have these two rules:

    $host_map->map("*.beta.foo.com" => $beta_foo_app);
    $host_map->map("*.foo.com" => $foo_app);

And you request C<beta.foo.com>, it will match the C<$beta_foo_app>, not the C<$foo_app> because L<Plack::App::HostMap> will find
C<beta.foo.com> before C<foo.com> when looking for a match. 

=head2 mount

Alias for C<map>.

=head2 to_app

  my $handler = $host_map->to_app;

Returns the PSGI application code reference. Note that the
Plack::App::HostMap object is callable (by overloading the code
dereference), so returning the object itself as a PSGI application
should also work.

=head2 no_cache

    $host_map->no_cache(1);

    #or
    my $host_map = Plack::App::HostMap->new(no_cache => 1);

This method only applies if you are using the C<*.> syntax. By default, L<Plack::App::HostMap> will cache the corresponding
mappings for a domain. For instance, if you have:

    #beta.foo.com maps to *.foo.com
    beta.foo.com -> *.foo.com

Then after the first time that a url with the host C<beta.foo.com> is requested, the domain beta.foo.com will be stored in a hash as 
a key with its value being C<*.foo.com>, to specify that that's what it maps to.
If you are using the C<*.> syntax, it is strongly recommended that you do not turn this off because it could speed things up a lot since you avoid
L<Domain::PublicSuffix>'s parsing logic, as well as some regex and logic that L<Plack::App::HostMap> does to map the host to the right rule. However,
one particular reason why you might want to disable caching would be if you were pointing A LOT of domains at your app. For instance, if you have the rule:

    $host_map->map("*.foo.com" => $foo_app);

And you request many urls with different C<foo.com> subdomains. This would take up a lot
of memory since each host you requested to your app would be stored as a key in a hash. Keep in mind this would need to be very many, since even 1,000
domains wouldn't take up much memory in a perl hash. Another possible reason
to disable this would be that someone could potentially use it to crash your application/server. If you had this rule:

    $host_map->map("*.foo.com" => $foo_app);

And someone were to request many foo.com domains:

    test.foo.com
    test1.foo.com
    test2.foo.com
    ...

Then each one would be cached as a key with its value being C<foo.com>. If you are really worried about someone crashing your app, you could set L</no_cache> to 1, or instead of using
the C<*.> syntax you could list out each individual host. Note: This only applies if you are using the C<*.> syntax. If you do not use the C<*.> syntax, the hash
that is used for caching is never even used. Also, in order to avoid letting the memory of your app grow uncontrollably, L<Plack::App::HostMap> only caches hosts that
actually map to a rule that you set. This way even if caching is on, someone can not make tons of requests with different hosts to your server and crash it.

=head1 PERFORMANCE

Note: This only applies if L</no_cache> is set to 1. 
As mentioned in the L<DESCRIPTION|/"DESCRIPTION">, Plack::App::HostMap should perform
much more efficiently than L<Plack::App::URLMap> when being used for host names. One
caveat would be with the C<*.> syntax that can be used with L<map|/"map">. If you have even
just one mapping with a C<*.> in it:

    $host_map->map("*.foo.com" => $foo_app);

Then on every request where the host is not an exact match for a rule (meaning that the host either matches a C<*.> syntax rule or no rule), 
Plack::App::HostMap must call L<Domain::PublicSuffix>'s C<get_root_domain>
subroutine to parse out the root domain of the host. I can't imagine that this is very costly, but
maybe if you are receiving a lot of requests this could make a difference. Also, L<Plack::App::HostMap>
does some additional logic to map your hosts. If you find that it is the case that it is affecting your performance,
instead of using the C<*.> syntax you could list out each individual possibility:

    $host_map->map("beta.foo.com" => $foo_app);
    $host_map->map("www.foo.com" => $foo_app);
    $host_map->map("foo.com" => $foo_app);

    #or
    $host_map->map(["beta.foo.com", "www.foo.com", "foo.com"] => $foo_app);

And the result would be that lookup is back to constant time. However, you might never see a performance hit
and it might be more worth it to use the convenient syntax.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
