use strict;
use warnings;
use Test::More;
use Mojo::UserAgent::Role::Retry;
use HTTP::Date qw(time2str);

is( Mojo::UserAgent::Role::Retry::_parse_retry_after(10), 10, "valid number" );
is( Mojo::UserAgent::Role::Retry::_parse_retry_after(0),  0,  "zero" );
is( Mojo::UserAgent::Role::Retry::_parse_retry_after(undef), 0, "undef" );
is( Mojo::UserAgent::Role::Retry::_parse_retry_after(-1),    0, "neg number" );
is( Mojo::UserAgent::Role::Retry::_parse_retry_after("foo"), 0, "not number" );
is(
  Mojo::UserAgent::Role::Retry::_parse_retry_after(
    "Wed, 21 Oct 2015 07:28:00 GMT"),
  0,
  "past date"
);
is( Mojo::UserAgent::Role::Retry::_parse_retry_after( time2str( time + 100 ) ),
  100, "future date" );

done_testing;
