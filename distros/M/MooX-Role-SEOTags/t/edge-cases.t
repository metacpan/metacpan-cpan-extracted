
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Object;

# Test missing required attributes
{
    my $error = '';
    eval {
        Object->new(
            # missing title, type, url, desc (all required via role)
        );
    };
    $error = $@;
    like($error, qr/(title|type|desc)/, 'Dies if required attribute missing');
}

# Test missing optional attribute (og_image)
{
    my $obj = Object->new(
        title => 't',
        type  => 'object',
        url   => 'https://example.com/',
        desc  => 'desc',
        # image omitted
    );
    my $og_image_tag = $obj->og_image_tag;
    is($og_image_tag, '', 'og_image_tag returns empty string if og_image missing');
}

done_testing();
