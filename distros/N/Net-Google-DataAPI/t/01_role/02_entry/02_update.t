use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Exception;
use HTTP::Response;

{
    package MyEntry;
    use Any::Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Entry';
    use XML::Atom::Util qw(textValue);

    feedurl child => (
        entry_class => 'MyEntry',
        rel => 'http://example.com/schema#child',
    );

    has myattr => (
        is => 'rw',
        isa => 'Str',
        trigger => sub { $_[0]->update }
    );

    around to_atom => sub {
        my ($next, $self, @args) = @_;
        my $atom = $next->($self, @args);
        $atom->set($self->ns('foobar'), 'myattr', $self->myattr) if $self->myattr;
        return $atom;
    };

    after from_atom => sub {
        my ($self) = @_;
        $self->{myattr} = textValue($self->elem, $self->ns('foobar')->{uri}, 'myattr');
    }
}
{
    package MyService;
    use Any::Moose;
    use Net::Google::DataAPI;
    with 'Net::Google::DataAPI::Role::Service';

    has '+namespaces' => (
        default => sub {
            +{ foobar => 'http://example.com/schema#foobar' }
        },
    );

    feedurl myentry => (
        default => 'http://example.com/myfeed',
        entry_class => 'MyEntry',
    );
}

my $e;
{
    my $xml = <<END;
201 Created

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <link rel="self" href="http://example.com/myentry" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry/child" />
    <foobar:myattr>hgoehgoe</foobar:myattr>
    <title>test entry</title>
</entry>
END
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->parse($xml);
        }
    );
    ok my $s = MyService->new(
        username => 'example@gmail.com',
        password => 'foobar',
    );
    ok $e = $s->add_myentry(
        {
            myattr => 'hgoehgoe',
            title => 'test entry',
        }
    );
    isa_ok $e, 'MyEntry';
    isa_ok $e->service, 'MyService';
    is $e->myattr, 'hgoehgoe';
    is $e->title, 'test entry';
}
{
    my $xml = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag_updated&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <link rel="self" href="http://example.com/myentry" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry/child" />
    <foobar:myattr>foobar</foobar:myattr>
    <title>test entry</title>
</entry>
END
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock('request' => sub {
            return HTTP::Response->parse($xml);
        }
    );
    isa_ok $e->service, 'MyService';
    is $e->myattr('foobar'), 'foobar';
    is $e->myattr, 'foobar';
    my $old_etag = $e->etag;
    is $old_etag, '"myetag_updated"';
    ok my $c = do {
        my $xml = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag2&quot;'>
    <link rel="edit" href="http://example.com/myentry2" />
    <link rel="self" href="http://example.com/myentry2" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry2/child" />
    <title>test entry</title>
</entry>
END
    my $xml2 = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag_updated_again&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <link rel="self" href="http://example.com/myentry" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry/child" />
    <foobar:myattr>foobar</foobar:myattr>
    <title>test entry</title>
</entry>
END
        my $ua = Test::MockModule->new('LWP::UserAgent');
        $ua->mock('request' => sub {
                my ($self, $req) = @_;
                if ($req->method eq 'POST' && $req->uri eq 'http://example.com/myentry/child') {
                    return HTTP::Response->parse($xml);
                } elsif ($req->method eq 'GET' && $req->uri eq 'http://example.com/myentry') {
                    return HTTP::Response->parse($xml2);
                } else { die $req->as_string };
            }
        );
        my $c = $e->add_child;
        isnt $e->etag, $old_etag;
        $c;
    };
    {
        my $xml = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag2_updated&quot;'>
    <link rel="edit" href="http://example.com/myentry2" />
    <link rel="self" href="http://example.com/myentry2" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry2/child" />
    <title>hogehoge</title>
</entry>
END
        my $xml2 = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag_updated_once_more&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <link rel="self" href="http://example.com/myentry" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry/child" />
    <foobar:myattr>foobar</foobar:myattr>
    <title>test entry</title>
</entry>
END
        my $ua = Test::MockModule->new('LWP::UserAgent');
        $ua->mock('request' => sub {
                my ($self, $req) = @_;
                if ($req->method eq 'PUT' && $req->uri eq 'http://example.com/myentry2') {
                    return HTTP::Response->parse($xml);
                } elsif ($req->method eq 'GET' && $req->uri eq 'http://example.com/myentry') {
                    return HTTP::Response->parse($xml2);
                } else { die $req->as_string };
            }
        );
        ok $c->title('hogehoge');
        is $c->title, 'hogehoge';
        is $e->etag, '"myetag_updated_once_more"';
        is $c->etag, '"myetag2_updated"';
    }
    {
        my $ua = Test::MockModule->new('LWP::UserAgent');
        $ua->mock('request' => sub {
                my ($self, $req) = @_;
                if ($req->method eq 'DELETE' && $req->uri eq 'http://example.com/myentry2') {
                    return HTTP::Response->new(400, 'Bad Request');
                }
            }
        );
        throws_ok { $c->delete } qr{Bad Request};
        is $e->etag, '"myetag_updated_once_more"';
        ok $c;
    }
    {
        my $xml2 = <<END;
200 OK

<?xml version="1.0" encoding="UTF-8"?>
<entry xmlns="http://www.w3c.org/2005/Atom"
    xmlns:foobar="http://example.com/schema#foobar"
    xmlns:gd='http://schemas.google.com/g/2005'
    gd:etag='&quot;myetag_updated_once_more_again&quot;'>
    <link rel="edit" href="http://example.com/myentry" />
    <link rel="self" href="http://example.com/myentry" />
    <link rel="http://example.com/schema#child" 
        href="http://example.com/myentry/child" />
    <foobar:myattr>foobar</foobar:myattr>
    <title>test entry</title>
</entry>
END
        my $ua = Test::MockModule->new('LWP::UserAgent');
        $ua->mock('request' => sub {
                my ($self, $req) = @_;
                if ($req->method eq 'DELETE' && $req->uri eq 'http://example.com/myentry2') {
                    return HTTP::Response->new(200, 'OK');
                } elsif ($req->method eq 'GET' && $req->uri eq 'http://example.com/myentry') {
                    return HTTP::Response->parse($xml2);
                } else { die $req->as_string };
            }
        );
        ok $c->delete;
        is $e->etag, '"myetag_updated_once_more_again"';
    }
}

done_testing;
