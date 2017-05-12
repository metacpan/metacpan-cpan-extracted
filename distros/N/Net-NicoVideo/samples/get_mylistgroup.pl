#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Net::NicoVideo::Content::NicoAPI;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $group_id = $ARGV[0] or die "usage: $0 group_id\n";

my $nnv = Net::NicoVideo->new;
my $api = $nnv->get_mylistgroup($group_id);

require Data::Dumper;
local  $Data::Dumper::Indent;
$Data::Dumper::Indent = 1;
say Data::Dumper::Dumper($api);


1;
__END__
