#!/usr/bin/perl

# Test the sending of a message

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 13;
use Parcel::Track;

use Params::Util '_INSTANCE';

sub dies_like {
    my $code = shift;
    my $regexp = _INSTANCE( shift, 'Regexp' )
        or die "Did not provide regexp to dies_like";
    eval { &$code() };
    like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}

#####################################################################
# Good Track

# Create a new Test tracker
{
    my $tracker = Parcel::Track->new( 'Test', '1234-567-890-123' );
    isa_ok( $tracker, 'Parcel::Track' );
    is( $tracker->driver->clear, 1, 'Methods via driver object' );

    is( $tracker->id, '1234567890123', 'Check tracking number' );
    is(
        $tracker->uri,
        'http://test?tracking_number=1234567890123',
        'Check tracking uri',
    );

    # Track information
    my $rv = $tracker->track;
    is_deeply(
        $rv,
        {
            from   => q{Keedi Kim},
            to     => q{CPAN},
            result => q{2015.01.27 Shipping Completed},
            htmls  => [ q{<div>dummy 1</div>}, q{<div>dummy 2</div>}, q{<div>dummy 3</div>}, ],
            descs  => [
                q{2015.01.24. 17:34 Receipt},
                q{2015.01.25. 09:00 Gwangjin Branch},
                q{2015.01.25. 13:01 Loading},
                q{2015.01.26. 15:23 Unloading},
                q{2015.01.27. 10:45 Gangdong Branch},
                q{2015.01.27. 16:13 Shipping Completed},
            ],
        },
        'Tracking information as expected',
    );
}

# Create a new KR::Test tracker
{
    my $tracker = Parcel::Track->new( 'KR::Test', '1234-567-890-123' );
    isa_ok( $tracker, 'Parcel::Track' );
    is( $tracker->driver->clear, 1, 'Methods via driver object' );

    is( $tracker->id, '1234567890123', 'Check tracking number' );
    is(
        $tracker->uri,
        'http://kr-test?tracking_number=1234567890123',
        'Check tracking uri',
    );

    # Track information
    my $rv = $tracker->track;
    is_deeply(
        $rv,
        {
            from   => q{김도형},
            to     => q{CPAN},
            result => q{2015.01.27 도착},
            htmls => [ q{<div>더미 1</div>}, q{<div>더미 2</div>}, q{<div>더미 3</div>}, ],
            descs => [
                q{2015.01.24. 17:34 접수},
                q{2015.01.25. 09:00 광진지점},
                q{2015.01.25. 13:01 상차},
                q{2015.01.26. 15:23 하차},
                q{2015.01.27. 10:45 강동지점},
                q{2015.01.27. 16:13 배송완료},
            ],
        },
        'Tracking information as expected',
    );
}

# Create a new Test tracker with private parameters
{
    my $tracker = Parcel::Track->new(
        'Test', '1234-567-890-123',
        _foo => 'private foo',
        _bar => 'private bar',
    );
    isa_ok( $tracker, 'Parcel::Track' );
    is( $tracker->driver->foo, 'private foo', 'Private Attributes via driver object' );
    is( $tracker->driver->bar, 'private bar', 'Private Attributes via driver object' );
}
