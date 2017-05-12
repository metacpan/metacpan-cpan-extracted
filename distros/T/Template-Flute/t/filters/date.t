#! perl
#
# Test for date filter

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Template::Flute;
use Class::Load qw(try_load_class);

try_load_class('DateTime')
    or plan skip_all => "Missing DateTime module.";

try_load_class('DateTime::Format::ISO8601')
    or plan skip_all => "Missing DateTime::Format::ISO8601 module.";

plan tests => 9;

my ($xml, $html, $flute, $ret);

$html =  <<EOF;
<div class="text">foo</div>
EOF

# date filter
$xml = <<EOF;
<specification name="filters">
<value name="text" filter="date"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y'}}},
			      values => {text => '2011-10-30T06:07:07'});

$ret = $flute->process();

ok($ret =~ m%<div class="text">10/30/2011</div>%, "Output: $ret");

# date filter with DateTime object
my $dt = DateTime->new(year => 2011,
                       month => 10,
                       day => 30,
                   );

$flute = Template::Flute->new(specification => $xml,
                              template => $html,
                              filters => {date => {options => {format => '%m/%d/%Y'}}},
                              values => {text => $dt},
                          );

$ret = $flute->process();

ok($ret =~ m%<div class="text">10/30/2011</div>%, "Output: $ret");

# date filter with DateTime object in structure
my $xml_deep = <<EOF;
<specification name="filters">
<value name="text" field="order.date" filter="date"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $xml_deep,
                              template => $html,
                              filters => {date => {options => {format => '%m/%d/%Y'}}},
                              values => {order => {date => $dt}},
                          );

$ret = $flute->process();

ok($ret =~ m%<div class="text">10/30/2011</div>%, "Output: $ret");

# date filter (missing date)

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y'}}},
			      values => {text => ''});

like(exception{$ret = $flute->process()},
     qr/Empty date/,
     'Died as excepted on an empty date.');

my %config = (date => {
    options => {
        format => '%m/%d/%Y',
        date_text => {
            empty => 'Not yet scheduled',
        }
    },
});

$flute = Template::Flute->new(specification => $xml,
                              template => $html,
                              filters => \%config,
                              );

$ret = $flute->process();

ok($ret =~ m%<div class="text">Not yet scheduled</div>%,
   "Empty date with date text.")
    || diag "Output: $ret";

# date filter (missing date with different strict setting)

$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y',
                                                   strict => {empty => 0}}},
                              values => {text => ''},
                             });

$ret = $flute->process();

ok($ret =~ m%<div class="text"></div>%, "Output: $ret");

# date filter (invalid date)
$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y'}}},
			      values => {text => '2011-11-31T06:07:07'});

like(exception{$ret = $flute->process()},
     qr/Invalid day of month/,
     'Died as excepted on an invalid date.');

%config = (date => {
    options => {
        format => '%m/%d/%Y',
        date_text => {
            invalid => 'Invalid date',
        }
    },
});

$flute = Template::Flute->new(specification => $xml,
                              template => $html,
                              filters => \%config,
                              values => {text => '2011-11-31T06:07:07'},
                              );

$ret = $flute->process();

ok($ret =~ m%<div class="text">Invalid date</div>%, "Invalid date with date_text") || diag "Output: $ret.";

# date filter (invalid date with different strict setting)
$flute = Template::Flute->new(specification => $xml,
			      template => $html,
			      filters => {date => {options => {format => '%m/%d/%Y',
                                                   strict => {invalid => 0}}}},
			      values => {text => '2011-11-31T06:07:07'},
                              );

$ret = $flute->process();

ok($ret =~ m%<div class="text"></div>%, "Output: $ret");
