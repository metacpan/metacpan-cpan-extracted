use strict; use warnings;
package Plack::Middleware::Cache;
our $VERSION = '0.19';

use parent 'Plack::Middleware';

use Plack::Util;
use Plack::Util::Accessor qw(match_url cache_dir debug);

use Digest::MD5 qw(md5_hex);
use Storable qw(nstore retrieve);
use File::Path qw(make_path);;

sub call {
    my ($self, $env) = @_;
    my $match_url = $self->match_url or return;
    $match_url = [ $match_url ] unless ref $match_url;
    my $request_uri = $env->{REQUEST_URI};
    for my $regexp (@$match_url) {
        if ($request_uri =~ /$regexp/) {
            return $self->cache_response($env);
        }
    }
    return $self->app->($env);
}

sub cache_response {
    my ($self, $env) = @_;
    my $dir = $self->cache_dir || 'cache';
    my $request_uri = $env->{REQUEST_URI};
    my $digest = md5_hex($request_uri);
    my $file = "$dir/$digest";
    if (-e $file) {
        warn "Plack::Middleware::Cache found: $request_uri - $digest"
            if $self->debug;
        my $cache = retrieve($file) or die;
        my $request = Plack::Request->new($env);
        my $response = $request->new_response($cache->[0]);
        $response->headers($cache->[1]);
        $response->body($cache->[2]);
        return $response->finalize;
    }
    warn "Plack::Middleware::Cache fetch: $request_uri - $digest"
        if $self->debug;
    return Plack::Util::response_cb(
        $self->app->($env),
        sub {
            my $cache = shift;
            make_path($dir) unless -d $dir;
            return sub {
                if (not defined $_[0]) {
                    nstore $cache, $file;
                    return;
                }
                $cache->[2] ||= '';
                $cache->[2] .= $_[0];
                return $_[0];
            }
        }
    );
}

1;
