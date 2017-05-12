package Plack::Test::MockHTTP;
use strict;
use warnings;

use Carp;
use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;
use Try::Tiny;

sub test_psgi {
    my %args = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";
    my $ua     = delete $args{ua};    # optional

    if (my @unexpected = keys %args) {
        carp "unexpected arguments passed to test_psgi: @unexpected";
    }

    my $cb = sub {
        my $req = shift;
        $req->uri->scheme('http')    unless defined $req->uri->scheme;
        $req->uri->host('localhost') unless defined $req->uri->host;

        # if we've been given a UA and there's a cookie-jar, set it
        # TODO: make sure this works with multiple cookies
        # XXX: I think it currently doesn't
        if ($ua and my $cookie_string = $ua->cookie_jar->as_string) {
            # Set-Cookie3 is an LWP-ism
            if ($cookie_string =~ m{^Set-Cookie3:\s+(.+?); }) {
                $req->header(Cookie => $1);
            }
        }

        my $env = $req->to_psgi;

        my $res = try {
            HTTP::Response->from_psgi($app->($env));
        } catch {
            HTTP::Response->from_psgi([ 500, [ 'Content-Type' => 'text/plain' ], [ $_ ] ]);
        };

        $res->request($req);
        return $res;
    };

    $client->($cb);
}

1;

__END__

=head1 NAME

Plack::Test::MockHTTP - Run mocked HTTP tests through PSGI applications

=head1 DESCRIPTION

Plack::Test::MockHTTP is a utility to run PSGI application given
HTTP::Request objects and return HTTP::Response object out of PSGI
application response. See L<Plack::Test> how to use this module.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Test>

=cut


