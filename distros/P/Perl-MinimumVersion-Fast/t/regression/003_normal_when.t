use strict;
use warnings;
use utf8;
use Test::More;
use Perl::MinimumVersion::Fast;
use Data::Dumper;

# normal when should be 5.010 not 5.012
# https://github.com/tokuhirom/Perl-MinimumVersion-Fast/issues/3

my $src = <<'...';
use v5.10;
given ($fruit) {
  when (/apples?/) {
    print "I like apples."
  }
  when (/oranges?/) {
    print "I don't like oranges."
  }
  default {
    print "I don't like anything"
  }
}
...

my $pmf = Perl::MinimumVersion::Fast->new(\$src);
is($pmf->minimum_version, '5.010') or diag Dumper($pmf->version_markers);


done_testing;

