use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Perlmazing qw(slurp md5);

my $content = slurp $0;
my $content_binary = slurp $0, 1;
my $md5 = md5 $content;
my $md5_binary = md5 $content_binary;

open my $in_binary, '<', $0 or die "Cannot read $0: $!";
binmode $in_binary;
my $data_binary = join '', <$in_binary>;
close $in_binary;

open my $in, '<', $0 or die "Cannot read $0: $!";
my $data = join '', <$in>;
close $in;

is $md5_binary, md5($data_binary), 'binary content matches';
is $md5, md5($data), 'content matches';
