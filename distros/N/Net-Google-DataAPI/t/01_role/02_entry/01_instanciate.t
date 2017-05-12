use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Net::Google::DataAPI::Role::Entry';
}

{
    package MyService;
    use Any::Moose;
    with 'Net::Google::DataAPI::Role::Service' => {
        service => 'wise',
        source => __PACKAGE__,
    };
}
{
    package MyEntry;
    use Any::Moose;
    with 'Net::Google::DataAPI::Role::Entry';
}

my $s = MyService->new(
    username => 'example@gmail.com',
    password => 'foobar',
);

{
    ok my $e = MyEntry->new(
        service => $s,
    );
    isa_ok $e, 'MyEntry';
    ok my $atom = $e->to_atom;
    isa_ok $atom, 'XML::Atom::Entry';
}

{
    my $xml = <<END;
<?xml version="1.0" encoding="UTF-8"?>
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
    my $atom = XML::Atom::Entry->new(\$xml);
    ok my $e = MyEntry->new(
        atom => $atom,
        service => $s,
    );
    isa_ok $e, 'MyEntry';
    is $e->id, 'http://example.com/myidurl';
    is $e->title, 'my title';
    is $e->etag, '"myetag"';
    is $e->editurl, 'http://example.com/myediturl';
    is $e->selfurl, 'http://example.com/myselfurl';
}
{
    ok my $e = MyEntry->new(
        service => $s,
        title => 'my title',
    );
    isa_ok $e, 'MyEntry';
    is $e->title, 'my title';
    ok my $atom = $e->to_atom;
    isa_ok $atom, 'XML::Atom::Entry';
    is $atom->title, 'my title';
}

done_testing;
