# -*- mode: cperl; -*-
use Test::Base;
use Net::SSL::ExpireDate;

if ($ENV{TEST_HTTPS}) {
    plan tests => 7 * blocks;
} else {
    plan skip_all => 'set TEST_HTTPS=1 if you want to test https access';
}

filters {
    expire_date => [qw(eval)],
    begin_date  => [qw(eval)],
    not_after   => [qw(eval)],
    not_before  => [qw(eval)],
    is_expired  => [qw(eval)],
};

our %NOT_BEFORE = (
    year      => 2020,
    month     =>  3,
    day       => 23,
    hour      => 00,
    minute    => 00,
    second    => 00,
    time_zone => 'UTC'
);
our %NOT_AFTER  = (
    year      => 2022,
    month     =>  5,
    day       => 17,
    hour      => 12,
    minute    => 00,
    second    => 00,
    time_zone => 'UTC'
);

run {
    my $block = shift;
    my $ed = Net::SSL::ExpireDate->new(
        https => $block->input,
        ($block->name eq 'SNI' ? (sni => $block->sni ) : ()),
    );

    my $expire_date  = $ed->expire_date;
    is $expire_date->iso8601,  $block->expire_date->iso8601, 'expire_date';

    my $begin_date   = $ed->begin_date;
    is $begin_date->iso8601,   $block->begin_date->iso8601,  'begin_date';

    my $not_after    = $ed->not_after;
    is $not_after->iso8601,    $block->not_after->iso8601,   'not_after';

    my $not_before   = $ed->not_before;
    is $not_before->iso8601,   $block->not_before->iso8601,  'not_before';

    my $is_expired   = $ed->is_expired;
    is $is_expired,   $block->is_expired,         'is_expired';

    my $will_expired;
    $will_expired    = $ed->is_expired('10 years');
    is $will_expired, $block->will_expired,       'will_expired string';

    $will_expired    = $ed->is_expired(DateTime::Duration->new(years=>10));
    is $will_expired, $block->will_expired,       'will_expired DateTime::Duration';
}

__END__
=== badssl.com
--- input: badssl.com
--- expire_date
DateTime->new(%main::NOT_AFTER);
--- begin_date
DateTime->new(%main::NOT_BEFORE);
--- not_after
DateTime->new(%main::NOT_AFTER);
--- not_before
DateTime->new(%main::NOT_BEFORE);
--- is_expired: undef
--- will_expired: 1

=== SNI
--- input: blah-blah-blah.badssl.com
--- sni: badssl.com
--- expire_date
DateTime->new(%main::NOT_AFTER);
--- begin_date
DateTime->new(%main::NOT_BEFORE);
--- not_after
DateTime->new(%main::NOT_AFTER);
--- not_before
DateTime->new(%main::NOT_BEFORE);
--- is_expired: undef
--- will_expired: 1
