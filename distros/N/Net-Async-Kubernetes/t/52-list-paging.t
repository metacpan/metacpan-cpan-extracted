use strict;
use warnings;
use Test::More;

use Future;
use URI;
use JSON::MaybeXS;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::Kubernetes;

# list() takes limit, continue and resourceVersion, as Kubernetes::REST's
# list does since its k74: they go out as query parameters, and the list's
# metadata (resourceVersion, continue, remainingItemCount) comes back on the
# IO::K8s::List. Before, all three failed the Future as unknown arguments, so
# a large collection could only be fetched in one response and list-then-watch
# had no collection resourceVersion to start from.
#
# The HTTP layer is faked at Net::Async::HTTP::do_request, as in
# t/23-mock-list-selectors.t, so the assertions see the URI on the wire.

my $loop = IO::Async::Loop->new;
my $JSON = JSON::MaybeXS->new(utf8 => 1);

my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mock.local' },
    credentials => { token => 'mock-token' },
    resource_map_from_cluster => 0,
);
$loop->add($kube);

sub pod {
    my ($name) = @_;
    return {
        kind => 'Pod', apiVersion => 'v1',
        metadata => { name => $name, namespace => 'default' },
        spec => { containers => [{ name => 'c', image => 'nginx' }] },
    };
}

# Pages served in order; returns the URIs requested.
sub with_pages {
    my ($pages, $code) = @_;
    my @uris;
    my @queue = @$pages;
    no warnings 'redefine';
    local *Net::Async::HTTP::do_request = sub {
        my ($http, %req) = @_;
        push @uris, $req{uri};
        my $page = shift @queue or die "no page left for $req{uri}\n";
        return Future->done(HTTP::Response->new(
            200, 'OK', ['Content-Type' => 'application/json'],
            $JSON->encode($page)));
    };
    $code->();
    return @uris;
}

sub query { return { URI->new("$_[0]")->query_form } }

subtest 'limit and continue page through a collection' => sub {
    my @pages = (
        { kind => 'PodList', apiVersion => 'v1',
          metadata => { resourceVersion => '100', continue => 'tok-2', remainingItemCount => 1 },
          items => [ pod('a'), pod('b') ] },
        { kind => 'PodList', apiVersion => 'v1',
          metadata => { resourceVersion => '100' },
          items => [ pod('c') ] },
    );
    my (@names, $first_meta);
    my @uris = with_pages(\@pages, sub {
        my $continue;
        do {
            my $list = $kube->list('Pod',
                namespace => 'default',
                limit     => 2,
                defined $continue ? (continue => $continue) : (),
            )->get;
            $first_meta //= $list->metadata;
            push @names, map { $_->metadata->name } @{ $list->items };
            $continue = $list->metadata ? $list->metadata->continue : undef;
        } while (defined $continue && length $continue);
    });

    is_deeply \@names, [qw(a b c)], 'all three pods over two pages';
    is scalar @uris, 2, 'two requests';
    is_deeply query($uris[0]), { limit => 2 }, 'first page: limit only';
    is_deeply query($uris[1]), { limit => 2, continue => 'tok-2' }, 'second page: limit and continue';
    ok $first_meta, 'the list carries its metadata';
    is $first_meta->resourceVersion, '100', 'collection resourceVersion';
    is $first_meta->continue, 'tok-2', 'continue token';
};

subtest 'resourceVersion goes out as a query parameter' => sub {
    my @uris = with_pages([
        { kind => 'PodList', apiVersion => 'v1', metadata => { resourceVersion => '7' }, items => [] },
    ], sub {
        $kube->list('Pod', namespace => 'default', resourceVersion => '0',
            labelSelector => 'app=web')->get;
    });
    is_deeply query($uris[0]), { resourceVersion => '0', labelSelector => 'app=web' },
        'resourceVersion next to a selector';
};

subtest 'an unknown argument still fails and names the new ones' => sub {
    my $f = $kube->list('Pod', limt => 2);
    ok $f->is_failed, 'misspelt limit fails';
    my ($msg) = $f->failure;
    like $msg, qr/limt/, 'names the unknown argument';
    like $msg, qr/\blimit\b/, 'lists limit among the accepted ones';
    like $msg, qr/\bcontinue\b/, 'and continue';
    like $msg, qr/\bresourceVersion\b/, 'and resourceVersion';
};

done_testing;
