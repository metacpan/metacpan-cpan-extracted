=head1 NAME

t/trim.t - Net::Statsd::Server test suite

=head1 DESCRIPTION

Tests the trim function

=cut

use strict;
use warnings;
use Test::More;

use Net::Statsd::Server;

my @tests = (
    [ '   abc   ' => 'abc' ],
    [ '   def' => 'def' ],
    [ 'ghi   ' => 'ghi' ],
    [ ' abc def ghi  ' => 'abc def ghi' ],
    [ '      ' => '' ],
    [ ' ' => '' ],
    [ '' => '' ],
    [ undef, undef ],
);

plan tests => @tests * 2;

for (@tests) {
  my ($str, $expected) = @{ $_ };
  my $copy_of_str = $str;
  my $res = Net::Statsd::Server::trim($str);
  is($str, $copy_of_str, "trim() doesn't touch the original string");
  if (! defined $str) {
    is($res, $expected, "trim of undef returns undef");
  }
  else {
    is($res, $expected, "trim('$str') actually returns '$expected'");
  }
}

# END
