# -*- perl -*-
use strict;
use warnings;

use Test::More tests => 59;
use File::Spec;
use Net::TiVo;

# use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($INFO);


my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned", "good_eats.xml");

open FILE, "<$CANNED" or die "Cannot open $_";
my $data = join '', <FILE>;
close FILE;

my $tivo = Net::TiVo->new(host => 'dummy', mac  => 'dummy');
							
my @a;
$tivo->_parse_content($data, \@a);

ok(scalar(@a) == 1);
my $folder = $a[0];

my @shows = $folder->shows();
ok(scalar(@shows) == 5);

for my $show (@shows) {
    is($show->content_type(), "video/x-tivo-mpeg", "show content type");
    is($show->format(), "video/x-tivo-mpeg", "show format");
    is($show->name(), "Good Eats", "show name");
    is($show->channel(), 54, "show channel");
    is($show->tuner(), 0, "show tuner");
    is($show->series_id(), "SH273928", "show series id");
    is($show->in_progress(), "", "show in progress");
}

my @episodes = ('A Bird in the Pan',
                'Cheesecake',
                'Family Roast',
                'Steak Your Claim', 
                'The Dough Also Rises',
                );

my @episodes_test = sort map { $_->episode() } @shows;
ok(scalar(@episodes_test) == 5);

is_deeply(\@episodes, \@episodes_test, "shows episode test");

##################################################
## Schema update for October 2007 ################
##################################################


$CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned", "no_reservations.xml");

open FILE, "<$CANNED" or die "Cannot open $_";
$data = join '', <FILE>;
close FILE;

pop @a; $tivo = undef;
$tivo = Net::TiVo->new(host => 'dummy', mac  => 'dummy');
$tivo->_parse_content($data, \@a);

ok(scalar(@a) == 1);
$folder = $a[0];

@shows = $folder->shows();
ok(scalar(@shows) == 2);

for my $show (@shows) {
    is($show->content_type(), "video/x-tivo-raw-pes", "show content type");
    is($show->format(), "video/x-tivo-raw-pes", "show format");
    is($show->name(), "Anthony Bourdain: No Reservations", "show name");
    is($show->channel(), 27, "show channel");
    is($show->station(), "TRAV", "show channel");
    is($show->tuner(), 0, "show tuner");
    is($show->series_id(), "SH800366", "show series id");
    is($show->high_definition(), "No", "show series id");
}

@episodes = ('Malaysia', 'New Jersey');

@episodes_test = sort map { $_->episode() } @shows;
ok(scalar(@episodes_test) == 2);

is_deeply(\@episodes, \@episodes_test, "shows episode test");
