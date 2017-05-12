#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 42;
use Test::Exception;
use Data::Dump qw( dump );

use_ok('Net::PMP::Profile');
use_ok('Net::PMP::Profile::Story');
use_ok('Net::PMP::Profile::Media');
use_ok('Net::PMP::Profile::Audio');
use_ok('Net::PMP::Profile::Video');
use_ok('Net::PMP::Profile::Image');
use_ok('Net::PMP::CollectionDoc');

my $guid = Net::PMP::CollectionDoc->create_guid();
ok( my $profile_doc = Net::PMP::Profile->new(
        guid      => $guid,
        title     => 'I am A Title',
        published => '2013-12-03T12:34:56.789Z',
        valid     => {
            from => "2013-04-11T13:21:31.598Z",
            to   => "3013-04-11T13:21:31.598Z",
        },
        byline      => 'By: John Writer and Nancy Author',
        description => 'This is a summary of the document.',
        tags        => [qw( foo bar baz )],
        itags       => [qw( abc123 )],
        hreflang    => 'en',
        author      => [qw( http://api.pmp.io/user/some-guid )],
        copyright   => [qw( http://americanpublicmedia.org/ )],
        distributor => [qw( http://api.pmp.io/organization/different-guid )],
        permission  => [qw( http://api.pmp.io/docs/some-group-guid )],
    ),
    "synopsis constructor"
);

# validation
throws_ok {
    my $bad_date = Net::PMP::Profile->new(
        title     => 'test bad date',
        published => 'no way date',
    );
}
qr/Invalid date format/i, "bad date constructor";

throws_ok {
    my $bad_locale = Net::PMP::Profile->new(
        title    => 'bad locale',
        hreflang => 'ENGLISH',
    );
}
qr/not a valid ISO639-1 value/, "bad hreflang constructor";

throws_ok {
    my $bad_valid = Net::PMP::Profile->new(
        title => 'bad valid date',
        valid => { from => 'now', to => 'then' },
    );
}
qr/Invalid date format/i, "bad valid date";

throws_ok {
    my $bad_valid = Net::PMP::Profile->new(
        title => 'bad valid date missing key',
        valid => { to => 'then' },
    );
}
qr/must contain/i, "bad valid date missing key";

throws_ok {
    my $bad_author = Net::PMP::Profile->new(
        title  => 'bad author',
        author => [qw( /foo/bar )],
    );
}
qr/not a valid href/, "bad author href";

ok( my $coll_doc = $profile_doc->as_doc(), "profile->as_doc" );
ok( $coll_doc->isa('Net::PMP::CollectionDoc'), "coll_doc isa CollectionDoc" );

#diag( dump $coll_doc );
#diag( dump $coll_doc->as_hash );

#diag( dump $profile_doc->published );

ok( $profile_doc->published->isa('DateTime'),
    "published isa DateTime object"
);

#diag( dump $coll_doc );
is_deeply(
    $coll_doc->attributes,
    {   title       => $profile_doc->title,
        published   => $profile_doc->published,
        valid       => $profile_doc->valid,
        byline      => $profile_doc->byline,
        description => $profile_doc->description,
        tags        => $profile_doc->tags,
        itags       => $profile_doc->itags,
        hreflang    => $profile_doc->hreflang,
        guid        => $profile_doc->guid,
    },
    "coll_doc attributes"
);

is_deeply(
    $coll_doc->as_hash->{links},
    {   author    => [ { href => "http://api.pmp.io/user/some-guid" } ],
        copyright => [ { href => "http://americanpublicmedia.org/" } ],
        distributor =>
            [ { href => "http://api.pmp.io/organization/different-guid" } ],
        permission => [
            {   href      => "http://api.pmp.io/docs/some-group-guid",
                operation => "read",
            },
        ],
        profile => [
            {   href  => "https://api.pmp.io/profiles/base",
                title => "Net::PMP::Profile",
            },
        ],
    },
    "collection links"
);

#diag( dump( $coll_doc->as_hash ) );
#diag( $coll_doc->as_json );

# timezone

ok( my $tzdoc = Net::PMP::Profile->new(
        guid      => $guid,
        href      => 'http://api.pmp.io/docs/' . $guid,
        title     => 'i am a PST',
        published => '1972-03-29 06:08:00 -0700',
    ),
    "new Doc in PST"
);
is( $tzdoc->as_doc->attributes->{published},
    '1972-03-29T13:08:00.000Z', "published date converted to UTC" );

# media
ok( my $audio = Net::PMP::Profile::Audio->new(
        guid        => $guid,
        href        => 'http://api.pmp.io/docs/' . $guid,
        title       => 'i am a piece of audio',
        description => 'hear me',
        enclosure   => [
            {   href => 'http://mpr.org/some/audio.mp3',
                type => 'audio/mpeg'
            },
        ]
    ),
    "audio constructor"
);

ok( my $audio_doc = $audio->as_doc(), "audio->as_doc" );

#diag( dump $audio_doc );
is_deeply(
    $audio_doc->links,
    {   enclosure => [
            {   href => 'http://mpr.org/some/audio.mp3',
                type => 'audio/mpeg',
            }
        ],
        profile => [
            {   href  => "https://api.pmp.io/profiles/audio",
                title => 'Net::PMP::Profile::Audio',
            },
        ],
    },
    "Media enclosure recognized as link"
);

throws_ok {
    my $audio = Net::PMP::Profile::Audio->new(
        guid      => $guid,
        href      => 'http://api.pmp.io/docs/' . $guid,
        title     => 'bad audio enclosure',
        enclosure => 'foo'
    );
}
qr/Validation failed for 'Net::PMP::Type::MediaEnclosures'/,
    "bad audio enclosure - string";

ok( my $audio_single_enclosure = Net::PMP::Profile::Audio->new(
        guid      => $guid,
        href      => 'http://api.pmp.io/docs/' . $guid,
        title     => 'bad audio enclosure',
        enclosure => {
            href => 'http://mpr.org/some/audio.mp3',
            type => 'audio/mpeg'
        },
    ),
    "audio constructor with single enclosure"
);

throws_ok {
    my $audio = Net::PMP::Profile::Audio->new(
        guid      => $guid,
        href      => 'http://api.pmp.io/docs/' . $guid,
        title     => 'bad audio enclosure',
        enclosure => [
            {   href => 'http://mpr.org/some/audio.mp3',
                type => 'foo'
            },
        ],
    );
}
qr/does not appear to be a valid media type/,
    "bad audio enclosure - content type";

throws_ok {
    my $audio = Net::PMP::Profile::Audio->new(
        guid      => $guid,
        href      => 'http://api.pmp.io/docs/' . $guid,
        title     => 'bad audio enclosure',
        enclosure => [ { href => 'audio.mp3', type => 'audio/mpeg' }, ],
    );
}
qr/is not a valid href/, "bad audio enclosure - href";

# make sure enclosure aliases media_meta to meta
ok( my $image_enclosure_with_media_meta = Net::PMP::Profile::Image->new(
        guid      => $guid,
        href      => 'http://api.pmp.io/docs/' . $guid,
        title     => 'image with media_meta',
        enclosure => {
            href       => 'http://mpr.org/some.jpg',
            type       => 'image/jpeg',
            media_meta => { crop => 'primary' },
        },
    ),
    "image with media_meta"
);

#diag( dump $image_enclosure_with_media_meta->as_doc );
is_deeply(
    $image_enclosure_with_media_meta->as_doc->links->{enclosure},
    [   {   href => 'http://mpr.org/some.jpg',
            type => 'image/jpeg',
            meta => { crop => 'primary' },
        }
    ],
    "media_meta => meta"
);

# subclassing

{

    package My::Profile;
    use Moose;
    extends 'Net::PMP::Profile';
    has 'misc_links' =>
        ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
}

ok( my $my_profile = My::Profile->new(
        misc_links => ['http://pmp.io/test'],
        permission => 'http://mpr.org/permission/granted',
        title      => 'i am a my::profile',
        guid       => $guid,
        href       => 'http://api.pmp.io/docs/' . $guid,
    ),
    "new My::Profile"
);
ok( my $my_doc = $my_profile->as_doc, "my_profile->as_doc" );

#diag( dump $my_doc );
is_deeply(
    $my_doc->attributes,
    { hreflang => "en", title => "i am a my::profile", guid => $guid },
    "attributes detected"
);
is_deeply(
    $my_doc->links,
    {   misc_links => [ { href => "http://pmp.io/test" } ],
        permission => [
            {   href      => "http://mpr.org/permission/granted",
                operation => 'read',
            }
        ],
        profile => [
            {   href  => "https://api.pmp.io/profiles/base",
                title => "My::Profile"
            },
        ],
    },
    "links detected"
);

is( Net::PMP::Profile::Media->get_type_from_uri('foo.jpg'),
    'image/jpeg', "get jpg type from uri path" );
is( Net::PMP::Profile::Media->get_type_from_uri('http://bar.com/foo.jpg'),
    'image/jpeg', "get jpg type from full uri" );
is( Net::PMP::Profile::Media->get_type_from_uri(
        'http://bar.com/foo.jpg?color=blue'),
    'image/jpeg',
    "get jpg type from full uri"
);

# tags array magic
ok( my $tag_magic = My::Profile->new( title => 'tag magic', tags => ['foo'] ),
    "tag_magic" );
ok( $tag_magic->add_tag('bar'), "add_tag" );
is_deeply( $tag_magic->tags, [ 'foo', 'bar' ], "tag magic push works" );
ok( my $itag_magic
        = My::Profile->new( title => 'tag magic', itags => ['foo'] ),
    "itag_magic"
);
ok( $itag_magic->add_itag('bar'), "add_itag" );
is_deeply( $itag_magic->itags, [ 'foo', 'bar' ], "itag magic push works" );

