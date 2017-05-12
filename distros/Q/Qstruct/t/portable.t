use strict;

use Test::More qw/no_plan/;
use Math::Int64 qw/int64 uint64/;

use Qstruct;

run(
  file => "basic-nums",

  schema => q{
    i8 @0 int8;
    i16 @1 int16;
    i32 @2 int32;
    i64 @3 int64;

    u8 @4 uint8;
    u16 @5 uint16;
    u32 @6 uint32;
    u64 @7 uint64;

    f @8 float;
    d @9 double;
  },

  vals => {
    i8 => -120,
    i16 => 1,
    i32 => -2,
    i64 => Math::Int64::int64('-4611686018027317903'),

    u8 => 254,
    u16 => 0xDD00,
    u32 => 305419896,
    i64 => Math::Int64::uint64('1234605617868164317'),

    f => 123456.78125,
    d => 8.21332323200311E-22,
  },
);


run(
  file => "strings-and-arrays",

  schema => q{
    fourteenint8s @0 int8[14];
    astr_small @1 string; 
    astr_big @7 string; 
    ablob @2 blob; 
    someint32s @3 int32[];
    somestrs @4 string[]; 
    someblobs @5 blob[]; 
    dozenuint64s @6 uint64[12];
  },

  vals => {
    fourteenint8s => [ qw/0 1 2 3 4 5 6 7 8 9 1 2 3 4/ ],
    astr_small => "what up",
    astr_big => "hello world" x 500,
    ablob => "\x00".."\xFF" . "NP",
    someint32s => [ 1, 0, -1, 0x11223344, -98765432, ],
    somestrs => [ "roflcopter", "", "abcdef"x100, "np", ],
    someblobs => [ "\xFF\xFE"x1234, "", "asdf", ],
    dozenuint64s => [ 0, uint64('18446744073709551615'), 1_000_000..1_000_009, ],
  },
);


sub run {
  my (%args) = @_;

  Qstruct::load_schema("qstruct TestSchema { $args{schema} }");

  my $filename = "t/portable-msgs/$args{file}.msg";

  if ($ENV{QSTRUCT_TEST_PORTABLE_CREATE_MESSAGES}) {
    die "must be run from root dir of dist" if !-d 't/portable-msgs/';
    print "Encoding to $filename\n";
    open(my $fh, '>:raw', $filename) || die "couldn't write to $filename: $!";
    print $fh TestSchema->encode($args{vals});
    return;
  }

  my $msg = do {
    local $/;
    open(my $fh, '<:raw', $filename) || die "couldn't open $filename: $!";
    <$fh>
  };

  my $obj = TestSchema->decode($msg);

  foreach my $key (sort keys %{ $args{vals} }) {
    is_deeply($obj->$key, $args{vals}->{$key}, "$args{file}: $key");
  }
}
