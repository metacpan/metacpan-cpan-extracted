#!perl
use 5.022;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use MIME::Base64 ();
use SION;

my $file = File::Spec->catfile( ( File::Spec->splitpath(__FILE__) )[1],
    't.sion' );
open my $fh, '<:raw', $file or BAIL_OUT("cannot open $file: $!");
my $octets = do { local $/; <$fh> };
close $fh;

my $data = decode_sion($octets);

# spot checks
is ref $data, 'HASH', 'top level is a dictionary';
ok !defined $data->{nil}, 'nil';
ok SION::is_bool( $data->{bool} ) && $data->{bool}, 'bool';
is $data->{int}, -42, 'int (from hex literal)';
cmp_ok $data->{double}, '==', 42.195, 'double (from hexfloat)';
is $data->{string}, '漢字、カタカナ、ひらがなの入ったstring😇', 'string';
is $data->{url}, 'https://github.com/dankogai/', 'url is not eaten by comments';
is $data->{data},
  MIME::Base64::decode_base64(
    'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'),
  'data';
ok !utf8::is_utf8( $data->{data} ), 'data is a byte string';
isa_ok $data->{date}, 'SION::Date', 'date';
cmp_ok $data->{date}->epoch, '==', 0, 'date epoch';
isa_ok $data->{ext}, 'SION::Ext', 'ext';
is scalar @{ $data->{array} }, 7, 'array has 7 elements';
is_deeply $data->{dictionary},
  {
    array  => [],
    bool   => SION::false,
    double => 0.0,
    int    => 0,
    nil    => undef,
    object => {},
    string => '',
  },
  'nested dictionary';

# Int/Double distinction survives
my $canonical = SION->new->utf8->canonical;
my $encoded   = $canonical->encode($data);
like $encoded, qr/"int":-42\b/,                    'Int re-encoded as Int';
like $encoded, qr/"double":0x1\.518f5c28f5c29p\+5/, 'Double re-encoded as hexfloat';
like $encoded, qr/"date":\.Date\(0x0p\+0\)/,        'Date re-encoded';

# full round trip, compact and pretty
is_deeply $canonical->decode($encoded), $data, 'compact round trip';
my $pretty = SION->new->utf8->canonical->pretty->encode($data);
is_deeply $canonical->decode($pretty), $data, 'pretty round trip';

# a second round trip is stable
is $canonical->encode( $canonical->decode($encoded) ), $encoded,
  'canonical encoding is a fixed point';

done_testing;
