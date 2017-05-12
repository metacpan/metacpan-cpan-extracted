use Test::More tests => 4;
use strict;
use warnings;

use Compress::Zlib;
use POE::Filter::Zlib;
use POE::Filter::Zlib::Stream;

my @data = qw(foo bar baz);

my $zl = POE::Filter::Zlib->new;
my $zls = POE::Filter::Zlib::Stream->new;

my ($zdata, $result);

$zdata = $zl->put(\@data);
$result = $zls->get($zdata);
is_deeply (\@data, $result, "match!");
$zdata = $zl->put(\@data);
$result = $zls->get($zdata);
is_deeply (\@data, $result, "match!");

$zls = POE::Filter::Zlib::Stream->new (FlushType => Z_FINISH);
$zdata = $zls->put(\@data);
$result = $zl->get($zdata);
is_deeply (\@data, $result, "match!");
$zdata = $zls->put(\@data);
$result = $zl->get($zdata);
is_deeply (\@data, $result, "match!");

