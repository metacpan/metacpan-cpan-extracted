#!/usr/bin/perl -T
use strict;
use warnings;
use Template::Test;

{
    package t::Object;

    sub new {
        my $class = shift;
        bless {data => {@_}}, $class;
    }

    sub price { shift->{data}->{price} }
    sub date  { shift->{data}->{date} }
}

my @data = (
    { date => '2006-09-13', price => 300 },
    { date => '2006-09-14', price => 500 }
);

test_expect(
    \*DATA,
    {},
    {
        hashref => \@data,
        objects => [ map { t::Object->new(%$_) } @data ],
    }
);

__END__
-- test --
[% USE SumOf -%]
[%- FOR elem IN hashref -%]
[% elem.date  %],[% elem.price %]
[% END -%]
,[% hashref.sum_of('price') %]
-- expect --
2006-09-13,300
2006-09-14,500
,800

-- test --
[% USE SumOf -%]
[%- FOR elem IN objects -%]
[% elem.date  %],[% elem.price %]
[% END -%]
,[% objects.sum_of('price') %]
-- expect --
2006-09-13,300
2006-09-14,500
,800
