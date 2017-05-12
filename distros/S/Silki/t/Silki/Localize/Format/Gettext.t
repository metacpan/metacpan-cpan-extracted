use strict;
use warnings;

use Test::Most;

# For the benefit of Data::Localize
BEGIN { $ENV{ANY_MOOSE} = 'Moose' }

use DateTime;
use Silki::Localize::Format::Gettext;

my $formatter = Silki::Localize::Format::Gettext->new();

is(
    $formatter->html( 'en', ['<foo>'] ),
    '&lt;foo&gt;',
    'html escaping'
);

is(
    $formatter->quant( 'en', [ 0, 'dog', 'dogs' ] ),
    '0 dogs',
    'quant for 0'
);

is(
    $formatter->quant( 'en', [ 0, 'dog', 'dogs', 'no dogs' ] ),
    'no dogs',
    'quant for 0 with third form'
);

is(
    $formatter->quant( 'en', [ 1, 'dog', 'dogs' ] ),
    '1 dog',
    'quant for 1'
);

is(
    $formatter->quant( 'en', [ 42, 'dog', 'dogs' ] ),
    '42 dogs',
    'quant for 42'
);

throws_ok {
    $formatter->quant( 'en', [ 42, 'dog' ] );
}
qr/quant can only be called with 2 or 3 forms/,
    'quant throws an error when called with 1 form';

throws_ok {
    $formatter->quant( 'en', [ 42, 'dog', 'dogs', 'no dogs', 'doggika' ] );
}
qr/quant can only be called with 2 or 3 forms/,
    'quant throws an error when called with 4 forms';

{
    no warnings 'redefine';
    local *DateTime::today = sub {
        shift;
        return DateTime->new( @_, year => 2010, month => 4, day => 6 );
    };

    is(
        $formatter->on_date(
            'en_US', [ DateTime->new( year => 2009 ) ],
        ),
        'on Jan 1, 2009',
        'on_date for date in different year than today'
    );

    is(
        $formatter->on_date(
            'en_US', [ DateTime->new( year => 2010 ) ],
        ),
        'on Jan 1',
        'on_date for date >3 days in the past, but same year as today'
    );

    is(
        $formatter->on_date(
            'en_US', [ DateTime->new( year => 2010, month => 4, day => 3 ) ],
        ),
        'on Apr 3',
        'on_date for date 3 days in the past'
    );

    is(
        $formatter->on_date(
            'en_US', [ DateTime->new( year => 2010, month => 4, day => 4 ) ],
        ),
        'on Apr 4',
        'on_date for date 2 days in the past'
    );

    is(
        $formatter->on_date(
            'en_US', [ DateTime->new( year => 2010, month => 4, day => 5 ) ],
        ),
        'Yesterday',
        'on_date for date 1 day in the past'
    );

    is(
        $formatter->on_date(
            'en_US', [ DateTime->new( year => 2010, month => 4, day => 6 ) ],
        ),
        'Today',
        'on_date for current date'
    );
}

{
    is(
        $formatter->at_time(
            'en_US',
            [
                DateTime->new(
                    year => 2009, hour => 8, minute => 12, second => 33
                )
            ],
        ),
        'at 8:12 AM',
        'at_time for for morning - en_US'
    );

    is(
        $formatter->at_time(
            'en_US',
            [
                DateTime->new(
                    year => 2009, hour => 13, minute => 12, second => 33
                )
            ],
        ),
        'at 1:12 PM',
        'at_time for for afternoon - en_US'
    );
}

{
    is(
        $formatter->time(
            'fr_FR',
            [
                DateTime->new(
                    year => 2009, hour => 8, minute => 12, second => 33
                )
            ],
        ),
        '8:12',
        'time for for morning - fr_FR'
    );

    is(
        $formatter->time(
            'fr_FR',
            [
                DateTime->new(
                    year => 2009, hour => 13, minute => 12, second => 33
                )
            ],
        ),
        '13:12',
        'time for for afternoon - fr_FR'
    );
}

{
    no warnings 'redefine';
    local *DateTime::today = sub {
        shift;
        return DateTime->new( @_, year => 2010, month => 4, day => 6 );
    };

    is(
        $formatter->on_datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2009, hour => 13, minute => 12, second => 33
                )
            ],
        ),
        'on Jan 1, 2009 at 1:12 PM',
        'on_datetime for past year'
    );

    is(
        $formatter->on_datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2010, hour => 13, minute => 12, second => 33
                )
            ],
        ),
        'on Jan 1 at 1:12 PM',
        'on_datetime for current year'
    );

    is(
        $formatter->on_datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2010, month  => 4,  day    => 5,
                    hour => 13,   minute => 12, second => 33
                )
            ],
        ),
        'Yesterday at 1:12 PM',
        'on_datetime for yesterday'
    );

    is(
        $formatter->on_datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2010, month  => 4,  day    => 6,
                    hour => 13,   minute => 12, second => 33
                )
            ],
        ),
        'Today at 1:12 PM',
        'on_datetime for today'
    );

    is(
        $formatter->datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2009, hour => 13, minute => 12, second => 33
                )
            ],
        ),
        'Jan 1, 2009 at 1:12 PM',
        'datetime for past year'
    );

    is(
        $formatter->datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2010, hour => 13, minute => 12, second => 33
                )
            ],
        ),
        'Jan 1 at 1:12 PM',
        'datetime for current year'
    );

    is(
        $formatter->datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2010, month  => 4,  day    => 5,
                    hour => 13,   minute => 12, second => 33
                )
            ],
        ),
        'Yesterday at 1:12 PM',
        'datetime for yesterday'
    );

    is(
        $formatter->datetime(
            'en_US',
            [
                DateTime->new(
                    year => 2010, month  => 4,  day    => 6,
                    hour => 13,   minute => 12, second => 33
                )
            ],
        ),
        'Today at 1:12 PM',
        'datetime for today'
    );
}

done_testing();
