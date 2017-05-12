# -*- mode: cperl; -*-
use Test::Base;
use Net::SSL::ExpireDate;
use FindBin;

plan tests => 7 * blocks;

filters {
    expire_date => [qw(eval)],
    begin_date  => [qw(eval)],
    not_after   => [qw(eval)],
    not_before  => [qw(eval)],
    is_expired  => [qw(eval)],
};

# Not Before: Feb  7 03:31:50 2017 GMT
# Not After : Feb  5 03:31:50 2027 GMT
our %NOT_BEFORE = (
    year      => 2017,
    month     =>  2,
    day       =>  7,
    hour      =>  3,
    minute    => 31,
    second    => 50,
    time_zone => 'UTC',
);
our %NOT_AFTER  = (
    year      => 2027,
    month     =>  2,
    day       =>  5,
    hour      =>  3,
    minute    => 31,
    second    => 50,
    time_zone => 'UTC',
);

run {
    my $block = shift;
    my $ed = Net::SSL::ExpireDate->new( file  => "$FindBin::Bin/cert.pem" );

    my $expire_date  = $ed->expire_date;
    is_deeply $expire_date,  $block->expire_date, 'expire_date';

    my $begin_date   = $ed->begin_date;
    is_deeply $begin_date,   $block->begin_date,  'begin_date';

    my $not_after    = $ed->not_after;
    is_deeply $not_after,    $block->not_after,   'not_after';

    my $not_before   = $ed->not_before;
    is_deeply $not_before,   $block->not_before,  'not_before';

    my $is_expired   = $ed->is_expired;
    is $is_expired,   $block->is_expired,         'is_expired';

    my $will_expired;
    $will_expired    = $ed->is_expired('10 years');
    is $will_expired, $block->will_expired,       'will_expired string';

    $will_expired    = $ed->is_expired(DateTime::Duration->new(years=>10));
    is $will_expired, $block->will_expired,       'will_expired DateTime::Duration';
}

__END__
=== rt.cpan.org
--- input: rt.cpan.org
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
