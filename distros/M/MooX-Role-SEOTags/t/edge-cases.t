use strict;
use warnings;
use Test::More;
use FindBin '$RealBin';
use lib "$RealBin/lib";
use TestObject;

# Test missing required attributes
{
    my $error = '';
    eval {
        TestObject->new({
            # missing title, type, url, desc (all required via role)
        });
    };
    $error = $@;
    like($error, qr/(title|type|desc)/, 'Dies if required attribute missing');
}

# Test missing optional attribute (og_image)
{
    my $obj = TestObject->new({
        title => 't',
        type  => 'object',
        url   => 'https://example.com/',
        desc  => 'desc',
        # image omitted
    });
    my $og_image_tag = $obj->og_image_tag;
    is($og_image_tag, '', 'og_image_tag returns empty string if og_image missing');
}

# An alt tag must not be emitted without an image
{
    my $obj = TestObject->new({
        title => 't',
        type  => 'object',
        url   => 'https://example.com/',
        desc  => 'desc',
        # image_alt omitted
    });

    my @warnings;
    my $og_image_alt_tag;

    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $og_image_alt_tag = $obj->og_image_alt_tag;
    }

    is(
        $og_image_alt_tag,
        '',
        'og_image_alt_tag returns empty string if og_imageis undefined',
    );

    is(
        scalar @warnings,
        0,
        'og_image_alt_tag does not warn if og_image is undefined',
    );
}

# Test undefined optional attribute in Twitter image tag
{
    my $obj = TestObject->new({
        title => 't',
        type  => 'object',
        url   => 'https://example.com/',
        desc  => 'desc',
        # image omitted
    });

    my @warnings;
    my $twitter_image_tag;

    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $twitter_image_tag = $obj->twitter_image_tag;
    }

    is(
        $twitter_image_tag,
        '',
        'twitter_image_tag returns empty string if og_image is undefined',
    );

    is(
        scalar @warnings,
        0,
        'twitter_image_tag does not warn if og_image is undefined',
    );
}

# A missing image uses the standard summary card
{
    my $obj = TestObject->new({
        title => 't',
        type  => 'object',
        url   => 'https://example.com/',
        desc  => 'desc',
        # image omitted
    });

    is(
        $obj->twitter_card_tag,
        '<meta content="summary" name="twitter:card">',
        'twitter_card_tag uses summary when og_image is undefined',
    );
}

# Empty image values are treated as missing
{
    my $obj = TestObject->new({
        title => 't',
        type  => 'object',
        url   => 'https://example.com/',
        desc  => 'desc',
        image => '',
    });

    is(
        $obj->og_image_tag,
        '',
        'og_image_tag returns empty string if og_image is empty',
    );

    is(
        $obj->og_image_alt_tag,
        '',
        'og_image_alt_tag returns empty string if og_image is empty',
    );

    is(
        $obj->twitter_image_tag,
        '',
        'twitter_image_tag returns empty string if og_image is empty',
    );

    is(
        $obj->twitter_card_tag,
        '<meta content="summary" name="twitter:card">',
        'twitter_card_tag uses summary if og_image is empty',
    );
}

done_testing();
