use strict;
use warnings;
use Test::More;
use Mojo::WebService::Twitter::Util qw(parse_twitter_timestamp twitter_authorize_url);
use Scalar::Util 'blessed';
use Time::Piece;

my $tw_ts = 'Fri Oct 23 17:18:19 +0100 2015';
my $parsed = parse_twitter_timestamp($tw_ts);
ok +(blessed $parsed and $parsed->isa('Time::Piece')), 'received Time::Piece object';
is $parsed->year, 2015, 'right year';
is $parsed->month, 'Oct', 'right month';
is $parsed->mday, 23, 'right day of month';
is $parsed->hms, '16:18:19', 'right time of day';

done_testing;
