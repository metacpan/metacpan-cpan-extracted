use strict;
use warnings;

use Perl::APIReference::Generator;

die unless @ARGV >= 2;
my $apipod_file = shift @ARGV;
my $perl_version = shift @ARGV;

my $api = Perl::APIReference::Generator->parse(
  file => $apipod_file,
  perl_version => $perl_version,
);

if ($api) {
  $api->_dump_as_class();
}

