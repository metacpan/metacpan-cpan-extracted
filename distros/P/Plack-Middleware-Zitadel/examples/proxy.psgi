use strict;
use warnings;

use HTTP::Tiny;
use Plack::Builder;
use Plack::Request;
use URI;

my $issuer = $ENV{ZITADEL_ISSUER}
    or die "Set ZITADEL_ISSUER\n";
my $upstream_base = $ENV{UPSTREAM_BASE}
    or die "Set UPSTREAM_BASE, e.g. http://my-app.default.svc.cluster.local:8080\n";

my $audience = $ENV{ZITADEL_AUDIENCE};
my $required_scopes = $ENV{ZITADEL_REQUIRED_SCOPES};

my $http = HTTP::Tiny->new(timeout => 30);

my $app = sub {
    my ($env) = @_;

    my $req = Plack::Request->new($env);
    my $uri = URI->new($upstream_base);
    $uri->path($req->path_info);
    if (defined $req->query_string && length $req->query_string) {
        $uri->query($req->query_string);
    }

    my $content = '';
    if ($env->{'psgi.input'}) {
        local $/;
        $content = readline($env->{'psgi.input'}) // '';
    }

    my %headers = map { lc($_) => scalar $req->headers->header($_) } $req->headers->header_field_names;
    delete $headers{host};
    delete $headers{authorization};

    my $claims = $env->{'zitadel.claims'} || {};
    $headers{'x-zitadel-sub'} = $claims->{sub} if defined $claims->{sub};

    my $res = $http->request($req->method, $uri->as_string, {
        headers => \%headers,
        content => $content,
    });

    my @response_headers;
    while (my ($k, $v) = each %{ $res->{headers} || {} }) {
        push @response_headers, $k, $v;
    }

    return [
        $res->{status} || 502,
        \@response_headers,
        [ $res->{content} // '' ],
    ];
};

builder {
    my %opts = (
        issuer => $issuer,
    );
    $opts{audience} = $audience if defined $audience && length $audience;
    $opts{required_scopes} = [ grep { length $_ } split /\s+/, $required_scopes ]
        if defined $required_scopes && length $required_scopes;

    enable 'Plack::Middleware::Zitadel', %opts;

    $app;
};
