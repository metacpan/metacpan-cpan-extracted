package Mojolicious::Plugin::ReverseProxy;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Transaction::HTTP;
use Mojo::UserAgent;
use Mojo::URL;
use Carp qw(croak);

# let's have our own private unadulterated useragent
# instead of using the shared one from app. Who knows
# what all the others are doing to the poor thing.

my $ua = Mojo::UserAgent->new(cookie_jar => Mojo::UserAgent::CookieJar->new(ignore => sub { 1 }));

our $VERSION = '0.705';

my $make_req = sub {
    my $c = shift;
    my $dest_url = Mojo::URL->new(shift);
    my $mount_point = shift;
    my $tx = Mojo::Transaction::HTTP->new( req=> $c->req->clone );
    my $url = $tx->req->url;
    $url->scheme($dest_url->scheme);
    $url->host($dest_url->host);
    $url->port($dest_url->port);
    if ($mount_point){
        my $req_path = $url->path;
        $req_path =~ s[^\Q${mount_point}\E/*][];
        $url->path($req_path);
    }
    $tx->req->headers->header('Host',$url->host_port);
    return $tx;
};

sub register {
    my $self = shift;
    my $app = shift;
    my $conf = shift;
    if ($conf->{helper_name}){
        die "helper_name is no more. In Mojolicious::Plugin::ReverseProxy 0.6 the API changed radically. Please check the docs.";
    }
    my $dest_url = $conf->{destination_url} or die "the destination_url parameter is mandatory";
    my $req_processor = $conf->{req_processor};
    my $res_processor = $conf->{res_processor};
    my $routes = $conf->{routes} || $app->routes;
    my $mount_point = $conf->{mount_point} || '';
    $mount_point =~ s{/$}{};
    my $log = $app->log;

    $routes->any($mount_point.'/*catchall' => { catchall => '' })->to(cb => sub {
        my $c = shift;
        $c->render_later;
        my $tx = $c->$make_req($dest_url,$mount_point);
        $req_processor->($c,$tx->req) if ref $req_processor eq 'CODE';
        # if we call $c->rendered in the preprocessor,
        # we are done ...
        return if $c->stash('mojo.finished');
        $ua->start($tx, sub {
             my ($ua,$tx) = @_;
             my $res = $tx->res;
             $res_processor->($c,$res) if ref $res_processor eq 'CODE';
             $c->tx->res($res);
             $c->rendered;
        });
    });
}

1;

__END__

=head1 Mojolicious::Plugin::ReverseProxy
 
 package ProxyFun;
 use Mojo::Base 'Mojolicious';

 sub startup {
    my $app = shift;

    $app->plugin('Mojolicious::Plugin::ReverseProxy',{
        # mandatory
        destination_url => 'http://www.oetiker.ch',
        # optional
        routes => $app->routes, # default 
        mount_point => '/', # default
        req_processor => sub { 
            my ($c,$req) = @_; 
            # do something to the request object prior
            # to passing it on to the destination_url
            # maybe fix the Origin or Referer headers
            for (qw(Origin Referer)){
                my $value = $req->headers->header($_) or next;
                if ( $value =~ s{http://www.oetiker.ch}{http://localhost:3000} ){
                    $req->headers->header($_,$value);   
                }
            }                
        },
        res_processor => sub {
            my ($c,$res) = @_;
            # do something to the response object prior
            # to passing it on to the client
            # maybe fixing the location header
            # or absolute URLs in the body
            if (my $location = $res->headers->location){
                if ( $location =~ s{http://www.oetiker.ch}{http://localhost:3000} ){
                    $res->headers->location($location); 
                }
            }
            if ($res->headers->content_type =~ m{text/html} and my $body = $res->body){
                if ( $body =~ s{http://www.oetiker.ch}{http://localhost:3000}g){
                    $res->body($body);
                    $res->headers->content_length(length($body));
                }
            }
        },
    }
 }

=head1 DESCRIPTION

The Mojolicious::Plugin::ReverseProxy lets your register a proxy route. The
module is rather mindless in the sense that it does not try to help you with
fixing headers or content to actually work with the proxy, apart from the
C<Host> header.

What makes this Plugin really useful, is that you can supply a
C<req_processor> and a C<res_processor> callback which will act on the
request prior to passing it on to the destination and on the response prior
to returning it to the client respectively.

The plugin takes the following options:

=over

=item destination_url

Where should the proxy connect to

  destination_url => 'http://www.oetiker.ch'

=item routes (defaults to app->routes)

the routes object to use for adding the proxy route

=item mount_point (defaults to /)

under which path should the proxy appear.

=item req_processor

Can be pointed to an anonymous subroutine which is called prior to handing
control over to the user agent.

If you render the page in the C<req_processor callback>, the page will be
returned immediately without calling the C<destination_url>

=item res_processor

Can be pointed to an anonymous subroutine which is called prior to rendering the response.

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2014

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
