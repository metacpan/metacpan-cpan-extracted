#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Encode qw(encode_utf8 decode_utf8);

BEGIN {
    plan tests => 5;
    use_ok( 'Net::DAVTalk::XMLParser' ) || print "Bail out!\n";
}

local $/ = undef;

for my $name (qw(numeric unicode)) {
  open(FH, "< t/testdata/$name.xml") || die "failed to find test file $name.xml";
  my $data = <FH>;
  close(FH);

  my $res = xmlToHash($data);
  is($res->{'{mdash}mdash'}{content}, "\x{2014}");
  is($res->{'{mdash}mdash'}{'@ndash'}{content}, "\x{2013}");
}
