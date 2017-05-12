#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Net::NicoVideo::Content::NicoAPI;
use Data::Dumper;
local $Data::Dumper::Indent;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $group_id = $ARGV[0] or die "usage: $0 group_id\n";

my $nnv = Net::NicoVideo->new;
my $api = $nnv->get_mylistgroup($group_id);
if( $api->status eq 'fail' ){
    die $api->error->description;
}

my $mylistgroup = shift @{$api->mylistgroup};
$mylistgroup->name($mylistgroup->name. " modified");
say "-- registering:";
say Data::Dumper::Dumper($mylistgroup);

my $updated = $nnv->update_mylistgroup($mylistgroup);

say "-- registered:";
say Data::Dumper::Dumper($updated);


1;
__END__
