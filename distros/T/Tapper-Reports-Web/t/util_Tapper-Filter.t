use strict;
use warnings;
use Test::More;

use DateTime::Format::DateParse;


{
        package Stash;
        use Moose;

        has 'stash_element' => (is => 'rw');
        sub stash {return };
}
my $stash = Stash->new();

BEGIN { use_ok 'Tapper::Reports::Web::Util::Filter::Report' }
my $filter = Tapper::Reports::Web::Util::Filter::Report->new(context => $stash);

# /tapper/reports/date/2010-09-20/
my $filter_condition = $filter->parse_filters(['date','2010-09-20']);
is($filter_condition->{error}, undef, 'No error during parse');

is($filter_condition->{late}->[0]->{'created_at'}->{'<='},'2010-09-21 00:00:00', 'Date parsing back and forth');
is(DateTime::Format::DateParse->parse_datetime($filter_condition->{late}->[0]->{'created_at'}->{'<='}, 'GMT')->dmy('.'), '21.09.2010', 'Date parsing returns a expected date');

$filter = Tapper::Reports::Web::Util::Filter::Report->new(context => $stash);
$filter_condition = $filter->parse_filters(['date','2010-09-20', 'days','2']);
is_deeply($filter_condition->{error}, ["'date' and 'days' filter can not be used together."], 'Multiple date filter detected');


done_testing();
