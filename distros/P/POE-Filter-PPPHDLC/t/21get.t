# test the get interface
use POE::Filter::PPPHDLC;
use Test::More tests => 6;

my $filter = POE::Filter::PPPHDLC->new;

# test the buffer
my @frame = (
  "\x7e\xff\x7d\x23\xc0\x21\x7d\x21\x7d\x21\x7d",
  "\x20\x7d\x38\x7d\x22\x7d\x26\x7d\x20\x7d\x20",
  "\x7d\x20\x7d\x20\x7d\x23\x7d\x24\xc2\x27\x7d",
  "\x25\x7d\x26\x48\x82\xef\x7d\x39\x7d\x27\x7d",
  "\x22\x7d\x28\x7d\x22\x63\xc4\x7e"
);
$filter->get_one_start(\@frame);

my $buf = $filter->get_pending;
ok( ref $buf eq 'ARRAY', 'pending returns arrayref' );
is( $buf->[0], join('', @frame), 'pending returns correct frame' );

my $ppp_frame = "\xc0\x21\x01\x01\x00\x18\x02\x06" .
  "\x00\x00\x00\x00\x03\x04\xc2\x27\x05\x06\x48\x82" .
  "\xef\x19\x07\x02\x08\x02";
my $frames = $filter->get(\@frame);
ok( ref $frames eq 'ARRAY', 'get returns arrayref' );
ok( @$frames == 2, 'get returns only two frames' );
is( $frames->[0], $ppp_frame, 'get returns frame from buffer' );
is( $frames->[1], $ppp_frame, 'get returns new frame' );
