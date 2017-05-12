use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::MockModule;
use Test::Warn;
use Test::Exception;
use MyService;

my $s = MyService->new(
    username => 'example@google.com',
    password => 'foobar',
);
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            my $res = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom+xml; charset=UTF-8 type=feed
Etag: "myetag"

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <entry gd:etag='&quot;entryetag&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <link rel="http://example.com/schema#myentry"
            type="application/atom+xml"
            href="http://example.com/myentryfeed" />
        <content type="application/atom+xml;type=feed"
            src="http://example.com/srcofcontent" />
    </entry>
</feed>
END
            $res->content_length(length($res->content));
            return $res;
        }
    );
    local $ENV{GOOGLE_DATAAPI_DEBUG} = 1;
    warnings_like {$s->myentry} [
        qr{GET http://example\.com/myentry},
        qr{200 OK},
    ];
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            my ($self, $req) = @_;
            my $res = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom+xml; charset=UTF-8 type=feed
Etag: "myetag"

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <entry gd:etag='&quot;entryetag&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <link rel="http://example.com/schema#myentry"
            type="application/atom+xml"
            href="http://example.com/myentryfeed" />
        <content type="application/atom+xml;type=feed"
            src="http://example.com/srcofcontent" />
    </entry>
</feed>
END
            $res->content_length(length($res->content));
            $res->request($req);
            return $res;
        }
    );
    local $ENV{GOOGLE_DATAAPI_DEBUG} = 1;
    warnings_like {$s->myentry} [
        qr{GET http://example\.com/myentry},
        qr{200 OK},
    ];
}
{
    local $ENV{GOOGLE_DATAAPI_DEBUG} = 1;
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            die 'oops!';
        }
    );
    throws_ok {$s->myentry} qr{request for 'http://example\.com/myentry' failed:};
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->new(500, 'Internal Server Error');
        }
    );
    throws_ok {$s->myentry} qr{request for 'http://example\.com/myentry' failed:};
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            die 'oops!';
        }
    );
    throws_ok {$s->myentry} qr{request for 'http://example\.com/myentry' failed:};
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom+xml

<?xml version="1.0" encoding="UTF-8"?>
<
END
        }
    );
    throws_ok {$s->myentry} qr{response for 'http://example\.com/myentry' is broken:};
}
{
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->parse(<<END);
200 OK
Content-Type: text/html
Content-Length: 32

<html><body>hello!</body></html>
END
        }
    );
    throws_ok {$s->myentry} qr{Content-Type of response for 'http://example.com/myentry' is not 'application/atom\+xml':  text/html};
}

done_testing

