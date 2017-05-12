use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing;

my $content = slurp $0;
my $md5 = md5 $content;

open my $in, '<', $0 or die "Cannot read $0: $!";
binmode $in;
my $data = join '', <$in>;
close $in;

is $md5, md5($data), 'content matches';