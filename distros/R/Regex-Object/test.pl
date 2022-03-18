use strict;
use warnings qw/FATAL/;
use utf8;

use Data::Dumper;
use Regex::Object;

'test-string' =~ /test-string/;

my $re = Regex::Object->new(
    regex => qr/text/,
);


while (my $success = 'John Doe Eric Lide Hans Zimmermann' =~ /(?<name>\w+?) (?<surname>\w+)/g) {
    print "$success\n";
}

