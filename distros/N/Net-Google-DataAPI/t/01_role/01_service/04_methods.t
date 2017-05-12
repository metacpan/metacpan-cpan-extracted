use strict;
use warnings;
use Test::More;
use Test::MockModule;
use HTTP::Response;

{
    package MyEntry;
    use Any::Moose;
    with 'Net::Google::DataAPI::Role::Entry';
}
{
    package MyService;
    use Any::Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Service';

    feedurl myentry => (
        entry_class => 'MyEntry',
        default => 'http://example.com/myfeed',
    );
}
my $ua = Test::MockModule->new('LWP::UserAgent');
my $ok_res = HTTP::Response->parse(<<END);
200 OK
Content-Type: text/plain

OK
END
my $entry_res =  HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom+xml

<?xml version='1.0' encoding='utf-8'?>
<entry xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <id>http://example.com/myidurl</id>
    <title type="text">my title</title>
    <link rel="edit"
        type="application/atom+xml"
        href="http://example.com/myediturl" />
    <link rel="self"
        type="application/atom+xml"
        href="http://example.com/myselfurl" />
</entry>
END
my $feed_res =  HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom+xml

<?xml version='1.0' encoding='utf-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'>
    <entry gd:etag='&quot;myetag&quot;'>
    <id>http://example.com/myidurl</id>
    <title type="text">my title</title>
    <link rel="edit"
        type="application/atom+xml"
        href="http://example.com/myediturl" />
    <link rel="self"
        type="application/atom+xml"
        href="http://example.com/myselfurl" />
    </entry>
</feed>
END

ok my $s = MyService->new(
    username => 'example@gmail.com',
    password => 'foobar',
);

my $e = do {
    $ua->mock(request => sub { $entry_res });
    $s->add_myentry;
};

{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'GET';
            is $req->uri, 'http://example.com/myfeed?foo=bar';
            return $feed_res;
        }
    );
    ok my $feed = $s->get_feed(
        'http://example.com/myfeed',
        { foo => 'bar' },
    );
    isa_ok $feed, 'XML::Atom::Feed';
}
{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'GET';
            is $req->uri, 'http://example.com/myentry';
            return $entry_res;
        }
    );
    ok my $entry = $s->get_entry(
        'http://example.com/myentry',
    );
    isa_ok $entry, 'XML::Atom::Entry';
}
{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'POST';
            is $req->uri, 'http://example.com/myfeed';
            is $req->header('foo'), undef;
            return $entry_res;
        }
    );
    ok my $entry = $s->post(
        'http://example.com/myfeed',
        $e->to_atom,
    );
    isa_ok $entry, 'XML::Atom::Entry';
}
{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'POST';
            is $req->uri, 'http://example.com/myfeed';
            is $req->header('foo'), 'bar';
            return $entry_res;
        }
    );
    ok my $entry = $s->post(
        'http://example.com/myfeed',
        $e->to_atom,
        { foo => 'bar' },
    );
    isa_ok $entry, 'XML::Atom::Entry';
}
{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'PUT';
            is $req->uri, 'http://example.com/myediturl';
            is $req->header('If-Match'), '"myetag"';
            return $entry_res;
        }
    );
    ok my $entry = $s->put(
        {
            self => $e,
            entry => $e->to_atom,
        }
    );
    isa_ok $entry, 'XML::Atom::Entry';
}
{
    $ua->mock(request => sub {
            my ($self, $req) = @_;
            is $req->method, 'DELETE';
            is $req->uri, 'http://example.com/myediturl';
            is $req->header('If-Match'), '"myetag"';
            return $ok_res;
        }
    );
    ok my $res = $s->delete(
        {
            self => $e,
        }
    );
    ok $res->is_success;
}

done_testing;
