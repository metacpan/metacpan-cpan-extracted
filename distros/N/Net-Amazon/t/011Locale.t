
###########################################
# Locale "de" test
# Mike Schilli, 2004 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Net::Amazon;
use Net::Amazon::Request::ASIN;
use Test::More tests => 5;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "locale.xml");
################################################################

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level => $ERROR, layout => '%F{1}-%L: %m%n'});

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    #response_dump => 1,
    locale      => 'de',
);

my $resp = $ua->search(
    asin  => "3827313783",
);

my($result) = $resp->properties();

ok($resp->is_success(), "ASIN Fetch successful");
is($result->author(), "Michael Schilli", "Author");
is($result->title(), "Go To Perl 5 .", "Title");
is($result->publisher(), "Addison-Wesley", "Publisher");
is($result->TotalOffers(), 0, "Offers");
