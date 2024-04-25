#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Net::Async::OpenExchRates;
use Syntax::Keyword::Try;

# confirm required
{

    try {
        my $failed_instance = Net::Async::OpenExchRates->new();
        fail('Should fail for missing app_id parameter');
    } catch ($error) {
        ok $error =~ /^Required parameter 'app_id' is missing/, 'app_id Required parameter check';
    }

}

# confirm default settings
{
    my $exch = Net::Async::OpenExchRates->new(app_id => 'test_app');
    my $class = Object::Pad::MOP::Class->for_class($exch);

    for my $f ($class->fields()) {
        my $name = '\\' . $f->name;
        next unless grep { /${name}/ } qw($_use_cache $_respect_api_frequency $_enable_pre_validation $_local_conversion $_keep_http_response);
        ok $f->value($exch), $f->name .' set to default 1';
    }

    my $cache_size_field = $class->get_field('$_cache_size');
    ok $cache_size_field->value($exch) == 1024, 'Cache size is set to default 1024';

    my $cache_field = $class->get_field('$_cache');
    ok ref($cache_field->value($exch)) =~ /Cache::LRU/, 'Cache is set to Cache::LRU object';

    my $base_uri_field = $class->get_field('$_base_uri');
    like $base_uri_field->value($exch), qr/https:\/\/openexchangerates.org/, 'Base uri is set https://openexchangerates.org by default';

    is
        $exch->api_query_params(),
        ['base', 'symbols', 'show_bid_ask', 'show_alternative', 'prettyprint', 'callback', 'show_inactive', 'start', 'end', 'period'],
        'API query params are complete';

    my $month_hash_field = $class->get_field('$_m_hash');
    is
        $month_hash_field->value($exch),
        {jan => 1, feb => 2, mar => 3, apr => 4, may => 5, jun => 6, jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12},
        'Month hash is accurate';
}

# confirm validators
{
    my $exch = Net::Async::OpenExchRates->new(app_id => 'test_app');
    my $class = Object::Pad::MOP::Class->for_class($exch);

    my $flatten_out_list_field = $class->get_field('$_flatten_out_list');
    my $flatten_out_list_sub = $flatten_out_list_field->value($exch);
    my @list = $flatten_out_list_sub->(['a', 'b'], 'c', ('d', 'e'), ['f']);
    is
        \@list,
        [qw(a b c d e f)],
        'Flatten out list is flattining';


    my $date_validation_field = $class->get_field('$_date_validation');
    my $date_validation_sub =  $date_validation_field->value($exch);

    my @wrong_dates = qw(2010 2010-1 20100-10-1 2010-14-01 3000-12-33 2010-01-00);
    for my $wrong_date (@wrong_dates) {
        try {
            $date_validation_sub->($wrong_date);
            fail('Should fail for wrong date');
        } catch ($error) {
            like $error, qr/Wrong date format $wrong_date/, "wrong dates are not passing $wrong_date"
        }
    }

    my @correct_dates = qw(1900-01-1 9000-12-31 4000-01-01 1990-1-1 2000-01-01);
    for my $date (@correct_dates) {
        my %date_hash = $date_validation_sub->($date);
        my @fields_exists = grep { defined $date_hash{$_} } qw(day month year);
        ok scalar(@fields_exists) == 3, "defined day,month,year for $date";
    }


    my $time_from_date_field = $class->get_field('$_time_obj_from_date_str');
    my $time_from_date_sub = $time_from_date_field->value($exch);

    my @wrong_times = ('Th, 20 Dec 2012 14:48:28 GMT', 'Thu, 20 Dec 2012 14:48:28', 'Thu, 20 Dec 14:48:28 GMT');
    for my $wrong_time (@wrong_times) {
        my $time = $time_from_date_sub->($wrong_time);
        ok !defined $time, "wrong times are not passing $wrong_time"
    }

    my @correct_times = ('Thu, 20 Dec 2012 14:48:28 GMT', 'Sat, 1 Dec 2012 14:01:00 GMT');
    for my $passing_time (@correct_times) {
        my $time = $time_from_date_sub->($passing_time);
        like ref($time), qr/Time::Moment/, "defined Time::Moment objectr for $passing_time";
    }
}

done_testing;
