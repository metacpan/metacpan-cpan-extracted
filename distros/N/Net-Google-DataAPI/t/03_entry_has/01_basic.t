use strict;
use warnings;
use Test::More;
use Test::MockModule;
use HTTP::Response;

my $ua = Test::MockModule->new('LWP::UserAgent');
my $feed_res = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'>
    <entry gd:etag='&quot;entryetag&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar hoge:baz='fuga'>piyo</hoge:foobar>
    </entry>
</feed>
END
my $feed_res_without_foobar = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'>
    <entry gd:etag='&quot;entryetag4&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar />
    </entry>
</feed>
END
my $entry_res = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<entry xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'
    gd:etag='&quot;entryetag2&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar hoge:baz='fuga'>nyoro</hoge:foobar>
    </entry>
END

my $entry_res_without_foobar = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<entry xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'
    gd:etag='&quot;entryetag3&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar />
    </entry>
END

my $entry_res_true = HTTP::Response->parse(<<END);
200 OK
Content-Type: application/atom-xml

<?xml version='1.0' encoding='UTF-8'?>
<entry xmlns='http://www.w3c.org/2005/Atom'
    xmlns:gd='http://schemas.google.com/g/2005'
    xmlns:hoge='http://example.com/schema#hoge'
    gd:etag='&quot;entryetag2&quot;'>
        <id>http://example.com/myidurl</id>
        <title type="text">my title</title>
        <link rel="edit"
            type="application/atom+xml"
            href="http://example.com/myediturl" />
        <link rel="self"
            type="application/atom+xml"
            href="http://example.com/myselfurl" />
        <hoge:foobar hoge:baz='fuga'>1</hoge:foobar>
    </entry>
END

{
    {
        package MyEntry;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
        );
    }
    {
        package MyService;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service';

        feedurl myentry => (
            entry_class => 'MyEntry',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    my $s = MyService->new;
    ok my $e = $s->myentry;
    isa_ok $e, 'MyEntry';
    ok $e->etag;
    is $e->foobar, undef, 'access entry_has attribute without getter/setter';
    is $e->foobar('hoge'), 'hoge';
    is $e->foobar, 'hoge';
}

{
    {
        package MyEntry2;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
            ns => 'hoge',
            tagname => 'foobar',
        );
    }
    {
        package MyService2;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service';
        has '+namespaces' => (
            default => sub {
                +{
                    hoge => 'http://example.com/schema#hoge',
                };
            }
        );

        feedurl myentry => (
            entry_class => 'MyEntry2',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    ok my $e = MyService2->new->myentry;
    isa_ok $e, 'MyEntry2';
    is $e->foobar, 'piyo', 'getter with from_atom';

    $ua->mock(request => sub {$entry_res});
    is $e->etag, '"entryetag"';
    is $e->foobar('nyoro'), 'nyoro';
    is $e->foobar, 'nyoro';
    is $e->etag, '"entryetag2"';
}

{
    {
        package MyEntry3;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
            from_atom => sub {
                my ($self, $atom) = @_;
                return $atom->get($self->ns('hoge'), 'foobar');
            },
            to_atom => sub {
                my ($self, $atom) = @_;
                $atom->set($self->ns('hoge'), 'foobar', $self->foobar);
            },
        );
    }
    {
        package MyService3;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service';
        has '+namespaces' => (
            default => sub {
                {
                    hoge => 'http://example.com/schema#hoge',
                };
            },
        );

        feedurl myentry => (
            entry_class => 'MyEntry3',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    my $s = MyService3->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    ok my $e = $s->myentry;
    isa_ok $e, 'MyEntry3';
    is $e->foobar, 'piyo', 'getter with from_atom';

    $ua->mock(request => sub {$entry_res});
    is $e->etag, '"entryetag"';
    is $e->foobar('nyoro'), 'nyoro';
    is $e->foobar, 'nyoro';
    is $e->etag, '"entryetag2"';
    $ua->mock(request => sub {$entry_res_without_foobar});
    is $e->foobar(''), '';
    is $e->foobar, '';
    is $e->etag, '"entryetag3"';


    $ua->mock(request => sub {$feed_res_without_foobar});
    my $e2 = $s->myentry;
    isa_ok $e2, 'MyEntry3';
    is $e2->foobar, '';
}

{
    {
        package MyEntry4;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Str',
            is => 'rw',
            ns => 'hoge',
            tagname => 'foobar',
        );
    }
    {
        package MyService4;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service';

        has '+namespaces' => (
            default => sub {
                {
                    hoge => 'http://example.com/schema#hoge',
                };
            },
        );

        feedurl myentry => (
            entry_class => 'MyEntry4',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res});
    ok my $e = MyService4->new(
        username => 'example@gmail.com',
        password => 'foobar',
    )->myentry;
    isa_ok $e, 'MyEntry4';
    is $e->foobar, 'piyo', 'getter with from_atom';

    $ua->mock(request => sub {$entry_res});
    is $e->etag, '"entryetag"';
    is $e->foobar('nyoro'), 'nyoro';
    is $e->foobar, 'nyoro';
    is $e->etag, '"entryetag2"';
}

{
    {
        package MyEntry5;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Entry';

        entry_has foobar => (
            isa => 'Bool',
            is => 'rw',
            ns => 'hoge',
            tagname => 'foobar',
            default => sub {return 0},
        );
    }
    {
        package MyService5;
        use Any::Moose;
        use Net::Google::DataAPI;
        with 'Net::Google::DataAPI::Role::Service';

        has '+namespaces' => (
            default => sub {
                {
                    hoge => 'http://example.com/schema#hoge',
                };
            },
        );

        feedurl myentry => (
            entry_class => 'MyEntry5',
            default => 'http://example.com/myentry',
        );
    }

    $ua->mock(request => sub {$feed_res_without_foobar});
    my $s = MyService5->new;
    ok my $e = $s->myentry;
    isa_ok $e, 'MyEntry5';
    ok $e->etag;
    is $e->foobar, 0;
    $ua->mock(request => sub {$entry_res_true});
    is $e->foobar(1), 1;
    is $e->foobar, 1;
}

done_testing;
