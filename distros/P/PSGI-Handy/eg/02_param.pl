######################################################################
#
# 02_param.pl - query, body, cookie and JSON without any DB or template
#
# Run: perl -Ilib eg/02_param.pl
#
# Demonstrates:
#   Request param/param_all/params/cookie, Response json/cookie,
#   merging of query string and x-www-form-urlencoded body parameters
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use PSGI::Handy;
use HTTP::Handy;   # delivery layer (any PSGI server works)

my $app = PSGI::Handy->new;

$app->get('/search', sub {
    my $c = shift;
    my $q    = $c->param('q');
    my @tags = $c->req->param_all('tag');
    $q = '(none)' unless defined $q;
    my $body = "<h1>Search</h1>\n<p>q = $q</p>\n";
    $body .= "<p>tags = " . join(', ', @tags) . "</p>\n";
    return $c->html($body);
});

$app->post('/echo', sub {
    my $c = shift;
    my $p = $c->req->params;             # name => first value (hash reference)
    # Hand-built JSON keeps this example dependency-free; in real code,
    # encode with mb-JSON / JSON-LINQ before calling $c->json.
    my @pairs;
    my $k;
    for $k (sort keys %$p) {
        push @pairs, _json_str($k) . ':' . _json_str($p->{$k});
    }
    return $c->json('{' . join(',', @pairs) . '}');
});

$app->get('/whoami', sub {
    my $c = shift;
    my $sid = $c->req->cookie('sid');
    if (defined $sid) {
        return $c->html("<p>welcome back, session $sid</p>\n");
    }
    my $new = 'S' . int(rand(1000000));
    my $res = $c->html("<p>new session $new</p>\n");
    $res->cookie('sid', $new, path => '/', httponly => 1);
    return $res;
});

sub _json_str {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/([\\"])/\\$1/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    return '"' . $s . '"';
}

my $psgi = $app->to_app;
HTTP::Handy->run(app => $psgi, host => '127.0.0.1', port => 8080);
