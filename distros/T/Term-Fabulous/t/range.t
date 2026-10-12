use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::Range;

sub range (%args) {
	return Term::Fabulous::Range->new( owner => 'My::Dial', max => 1, %args );
}

subtest 'checks' => sub {
	like dies { range( min          => 5, max => 5 ) },                qr/\AMy::Dial: min \(5\) must be less than max \(5\) at /,            'an empty range';
	like dies { range( step         => 0 ) },                          qr/\AMy::Dial: step must be positive, got 0 at /,                     'a zero step';
	like dies { range( step         => 'big' ) },                      qr/\AMy::Dial: step must be a finite number, got 'big'/,              'a step that is no number';
	like dies { range( value        =>  2 ) },                         qr/\AMy::Dial: value must be in 0\.\.1, got 2 at /,                   'a value outside';
	like dies { range( page_step    => -1 ) },                         qr/page_step must be positive, got -1/,                               'a negative page step';
	like dies { range( value_format => [] ) },                         qr/value_format must be a sprintf format string or a code reference/, 'a format';
	like dies { range( step         => 0.1 )->set_range( low => 1 ) }, qr/My::Dial: set_range takes min, max and step, got low/,             'unknown parts';
	like dies { range()->set_range( step => 1 ) },                  qr/My::Dial: set_range takes min and max, got step/, 'a range without a step takes no step';
	like dies { range( step => 0.1 )->set_range( step => undef ) }, qr/step must be a finite number, got undef/,         'a stepped range keeps a step';
	my $range = range( step => 0.1, value => 0.5 );
	like dies { $range->set_range( min => 2 ) }, qr/min \(2\) must be less than max \(1\)/, 'the parts are checked as a whole';
	is [ $range->min, $range->max, $range->value ], [ 0, 1, 0.5 ], 'and a failed change changes nothing';
};

subtest 'snapping to the grid' => sub {
	my $range = range( step => 0.1 );
	is [ map { $range->snapped($_) } 0.34, 0.36, 0.71, 0.7, -3, 9 ],                  [ 0.3, 0.4, 0.7, 0.7, 0, 1 ], 'float steps snap without noise, limited to the range';
	is $range->set_value(0.30000000000000004),                                        0.3,                          'a value is snapped';
	is range( min => 1, max => 2, step => 0.3 )->top_value,                           1.9,                          'the top grid value of a range that is no whole number of steps';
	is range( max => 1e-9, step => 1e-12, value => 3e-12 )->value,                    3e-12,                        'a tiny step keeps its decimals';
	is range( min => 0.5, max => 3, step => 1 )->snapped(2.2),                        2.5,                          'the grid starts at min';
	is range()->snapped(0.123),                                                       0.123,                        'without a step a value is only limited to the range';
	is [ range( min => 0.25, step => 0.1 )->decimals, range( step => 5 )->decimals ], [ 2, 0 ],                     'the decimals of step and min';
};

subtest 'moving and change reporting' => sub {
	my $range = range( max => 10, step => 1, value => 5 );
	is [ $range->move_to(7.4), $range->value ], [ 1, 7 ],  'move_to snaps and reports a change';
	is [ $range->move_to(7.2), $range->value ], [ 0, 7 ],  'no change to the same grid value';
	is [ $range->move_to(99),  $range->value ], [ 1, 10 ], 'beyond the end it stops at the end';
	is [ $range->move_by(1),   $range->value ], [ 0, 10 ], 'and moves no further';
	is [ $range->move_by(-2),  $range->value ], [ 1, 8 ],  'move_by steps';
	is [ $range->move_by( -1, 'page' ), $range->value ], [ 1, 7 ], 'and pages, a tenth of the range by default';
	$range->set_page_step(3);
	is [ $range->move_by_key('PageDown'), $range->value ],    [ 1, 4 ],  'PageDown by the page step';
	is [ $range->move_by_key('Up'), $range->value ],          [ 1, 5 ],  'Up a step';
	is [ $range->move_by_key('Home'), $range->value ],        [ 1, 0 ],  'Home to min';
	is [ $range->move_by_key('Home'), $range->value ],        [ 0, 0 ],  'Home again changes nothing';
	is [ $range->move_by_key('End'), $range->value ],         [ 1, 10 ], 'End to max';
	is $range->move_by_key('Tab'),                            undef,     'other keys are no keys of a range';
	is range( max => 5, paging => 0 )->move_by_key('PageUp'), undef,     'nor PageUp without paging';
	my $odd = range( min => 1, max => 2, step => 0.3 );
	$odd->move_by_key('End');
	is $odd->value,                                                                              1.9,         'End goes to the top grid value';
	is [ range( max => 100, step => 1 )->page_step, range( max => 1, step => 0.3 )->page_step ], [ 10, 0.3 ], 'the default page step is at least a step';
	my $stepless = range( max => 100, value => 50 );
	is [ $stepless->move_by(1), $stepless->value ], [ 1, 51 ], 'without a step a step is a hundredth of the range';
};

subtest 'set_range moves the value' => sub {
	my $range = range( max => 10, step => 1, value => 8 );
	$range->set_range( max => 5 );
	is $range->value, 5, 'into the new range';
	$range->set_range( min => 0.5 );
	is $range->value,                                                       4.5,  'and onto the new grid';
	is [ range( max => 100, value => 50 )->set_range( min => 60 )->value ], [60], 'also without a step';
};

subtest 'fraction' => sub {
	my $range = range( min => 100, max => 200, value => 150 );
	is [ $range->fraction, $range->fraction_of(125) ], [ 0.5, 0.25 ], 'where a value lies in the range';
};

subtest 'formats' => sub {
	my $range = range( max => 10, step => 0.5 );
	is $range->format_value(2.5),                      '2.5', 'by default the decimals of the grid';
	is range( max => 10, step => 1 )->format_value(3), '3',   'none for whole steps';
	$range->set_value_format('%d%%');
	is $range->format_value(7), '7%', 'a sprintf format';
	$range->set_value_format( sub ($value) { "<$value>" } );
	is $range->format_value(7), '<7>', 'a code reference gets the value';
	$range->set_value_format(undef);
	is range( max => 10, default_format => sub ( $value, $of ) { "$value of " . $of->max } )->format_value(4), '4 of 10', 'the default of the widget';
	my $percent = range( min => 100, max => 200, format_percent => 1, value_format => '%.1f%%' );
	is $percent->format_value(125), '25.0%', 'format_percent: a format gets the percent';
	$percent->set_value_format( sub ( $value, $fraction ) { "$value=$fraction" } );
	is $percent->format_value(150), '150=0.5', 'and a code reference the value and the fraction';
};

done_testing;
