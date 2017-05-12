# -*- perl -*-
use strict;
use warnings;

use Test::More tests => 29;
use File::Spec;
use Net::TiVo;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned", "family_guy.xml");

open FILE, "<$CANNED" or die "Cannot open $_";
my $data = join '', <FILE>;
close FILE;

my $tivo = Net::TiVo->new(host => 'dummy', mac  => 'dummy');
							
my @a;
$tivo->_parse_content($data, \@a);

ok(scalar(@a) == 1);
my $folder = $a[0];

is($folder->content_type(), "x-tivo-container/folder", "folder content type");
is($folder->format(), "x-tivo-container/tivo-dvr", "folder format");
is($folder->change_date(), hex('0x44C9689C'), "folder change date");
is($folder->name(), "Family Guy", "folder title");
is($folder->total_items(), 3, "folder total items");
is($folder->item_count(), 3, "folder item count");
is($folder->item_start(), 0, "folder item start");
is($folder->global_sort(), "Yes", "folder global sort");
is($folder->sort_order(), "CaptureDate", "folder sort order");
is($folder->size(), 648019968, "folder size");
like($folder->as_string(), qr/Family Guy.*968 bytes/, "folder as_string()");

my @shows = $folder->shows();
ok(scalar(@shows) == 1);

my $show = $shows[0];
is($show->content_type(), "video/x-tivo-mpeg", "show content type");
is($show->format(), "video/x-tivo-mpeg", "show format");
is($show->name(), "Family Guy", "show name");
is($show->size(), 648019968, "show size");
is($show->duration(), 1799000, "show duration");
is($show->capture_date(), hex('0x449F2A86'), "show capture date");
is($show->episode(), "Peter's Got Woods", "show episode");
like($show->description(), qr/strain on his friendship/, "show description");
is($show->channel(), 13, "show channel");
is($show->tuner(), 0, "show tuner");
is($show->station(), "WFXT", "show station");
is($show->series_id(), "SH296001", "show series id");
is($show->program_id(), "EP2960010063", "show program id");
is($show->episode_num(), 414, "show episode number");
like($show->url(), qr/http:.*1862517/, "show URL");
like($show->as_string(), qr/Family Guy.*1862517/s, "show as_string()");
