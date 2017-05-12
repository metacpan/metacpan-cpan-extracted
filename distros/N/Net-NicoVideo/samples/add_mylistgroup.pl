#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;
use Net::NicoVideo::Content::NicoAPI;
use Getopt::Std;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $opts = {};
getopts('d:i:o:ps:u:', $opts);
my $name = $ARGV[0] or die "usage: $0 [options...] name\n";

my $mylistgroup = Net::NicoVideo::Content::NicoAPI::MylistGroup->new({
    user_id         => $opts->{u},
    name            => $name,
    description     => $opts->{d},
    public          => ($opts->{p} ? '1' : '0'),
    default_sort    => $opts->{s},
    sort_order      => $opts->{o},
    icon_id         => $opts->{i},
    });

my $nnv = Net::NicoVideo->new;
my $api = $nnv->add_mylistgroup($mylistgroup);

require Data::Dumper;
local  $Data::Dumper::Indent;
$Data::Dumper::Indent = 1;
say Data::Dumper::Dumper($api);


1;
__END__
