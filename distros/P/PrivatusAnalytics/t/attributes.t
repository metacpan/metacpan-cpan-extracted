use strict;
use warnings;
use utf8;
use Test::More;

use PrivatusAnalytics qw(event_data event_attrs click_data click_attr valid_click_name html_escape);

is_deeply(
    [ event_data( 'Export CSV', [ format => 'csv', source => 'toolbar' ] ) ],
    [
        'data-privatus-event'       => 'Export CSV',
        'data-privatus-prop-format' => 'csv',
        'data-privatus-prop-source' => 'toolbar'
    ],
    'an event becomes data attributes'
);

is(
    event_attrs( 'Export CSV', { format => 'csv', source => 'toolbar' } ),
    'data-privatus-event="Export CSV" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar"',
    'the spec example as HTML (hash keys sorted)'
);

is(
    event_attrs( 'Saved', b => 1, a => 2 ),
    'data-privatus-event="Saved" data-privatus-prop-b="1" data-privatus-prop-a="2"',
    'a flat list keeps its order'
);

my %name = event_data('  Export CSV  ');
is( $name{'data-privatus-event'}, 'Export CSV', 'the name is trimmed' );
%name = event_data( 'a' x 200 );
is( $name{'data-privatus-event'}, 'a' x 120, 'the name is cut to 120 characters' );

is_deeply( [ event_data( '   ', format => 'csv' ) ], [], 'a blank name gives nothing' );
is_deeply( [ event_data(undef) ],                    [], 'an undef name gives nothing' );
is( event_attrs(''), '', 'an empty name prints nothing' );

my %attrs = event_data( 'Saved', [ 'Report Type' => 'a', 'x-y' => 'b', ( 'K' x 80 ) => 'c' ] );
is( $attrs{'data-privatus-prop-report_type'},       'a', 'keys are lowercased and cleaned' );
is( $attrs{'data-privatus-prop-x_y'},               'b', 'dashes become underscores' );
is( $attrs{ 'data-privatus-prop-' . ( 'k' x 64 ) }, 'c', 'keys are cut to 64 characters' );

%attrs = event_data( 'Saved',
    [ on => \1, off => \0, count => 3, ratio => 1.5, tags => [qw(a b)], gone => undef, json => JSON::PP::true() ] );
is_deeply(
    [ @attrs{ map { "data-privatus-prop-$_" } qw(on off count ratio tags json) } ],
    [ 'true', 'false', '3', '1.5', 'a,b', 'true' ],
    'values become strings'
);
ok( !exists $attrs{'data-privatus-prop-gone'}, 'undef values are dropped' );

my @many = map { ( "p$_" => 'v' ) } 1 .. 40;
is( scalar( my @pairs = event_data( 'Saved', \@many ) ) / 2, 31, 'at most 30 props are kept' );
%attrs = event_data( 'Saved', long => 'x' x 900 );
is( length $attrs{'data-privatus-prop-long'}, 500, 'values are cut to 500 characters' );

is(
    event_attrs( 'Say "hi" <now>', note => q{a&b'c} ),
    'data-privatus-event="Say &quot;hi&quot; &lt;now&gt;" data-privatus-prop-note="a&amp;b&#39;c"',
    'every value is escaped'
);

is(
    event_attrs( 'Café', city => 'Zürich' ),
    'data-privatus-event="Café" data-privatus-prop-city="Zürich"',
    'text outside ASCII is kept'
);

is_deeply( [ click_data('pricing.cta') ], [ 'data-privatus-click' => 'pricing.cta' ], 'a valid click name' );
is( click_attr('a-b_c:d.1'), 'data-privatus-click="a-b_c:d.1"', 'click attr HTML' );
for my $bad ( '', 'has space', 'x' x 101, '<b>', undef, "line\n" ) {
    is( click_attr($bad), '',
        'an invalid click name prints nothing: '
          . ( defined $bad ? join( '', map { sprintf '%02x', ord } split //, substr $bad, 0, 12 ) : 'undef' ) );
    ok( !valid_click_name($bad), 'and is not valid' );
}

is( html_escape(q{<a href="x">'&'</a>}), '&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;', 'html_escape' );

eval { event_data( 'Saved', 'odd' ) };
like( $@, qr/hash ref, an array ref or a list of pairs/, 'a single plain value is an error' );

done_testing;
