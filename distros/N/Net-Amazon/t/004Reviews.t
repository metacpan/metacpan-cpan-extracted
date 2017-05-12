# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon::Request::ASIN;
use Net::Amazon::Response::ASIN;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

if(! exists $ENV{NET_AMAZON_LIVE_TESTS}) {
    for(map { File::Spec->catfile($CANNED, $_) }
        qw(reviews.xml)) {
        open FILE, "<$_" or die "Cannot open $_";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

######################################################################
# Successful ASIN fetch
######################################################################
my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

my $req = Net::Amazon::Request::ASIN->new(
    asin  => '0201360683'
);

my $resp = $ua->request($req);

ok($resp->is_success(), "Successful ASIN fetch");

my $result = "";

for my $property ($resp->properties()) {
    my $reviewset = $property->review_set();
    $result .= "AVG=" . $reviewset->average_customer_rating() . "," .
               "TOT=" . $reviewset->total_reviews() . ",";
    for my $review ($reviewset->reviews()) {
        $result .= "COM=" . $review->content() . "," .
                   "SUM=" . $review->summary() . "," .
                   "RAT=" . $review->rating() . "," .
                   "LOC=" . $review->customer_location() . "," .
                   "NAM=" . $review->customer_name();
    }
}

# XXX: this information is no longer readily available.
# like($result, qr/AVG=4.5,TOT=6,COM=From.*?RAT=4,LOC=Enschede.*?,NAM=C.\sHulshof
#                                COM=Excellent.*?SUM=Perl.*?RAT=5.*?
#                                COM=I\sbought.*?SUM=Don.*?RAT=2.*?
#                 /sx, "customer reviews");
__END__

AVG=4.33,TOT=6,COM=From its corny title you might expect another one of those sleazy introductions to Perl (I can name a few), but I can happily say that this book is an exception. The overview of the language is excellent and very comprehensible. Even after reading Learning Perl and Programming Perl, I picked up some valuable tips. The chapters on Object Oriented Programming and Perl/Tk are also good. For the Perl/CGI part, you might consider reading additional material, however. All in all, a surprisingly good introduction and reference to Perl 5, both for the beginner and the more advanced programmer.,SUM=Good introduction to Perl, and great reference,RAT=4,COM=Excellent book that gets you started with lots of areas of perl. Most of the code I have tried works fine with Activestates's 523 build and with the perl development kit 1.2.4. Having code that work is rare with these books especially with Windows. I use 98 and NT and unix. This book is not a diffinitive guide to perl but it gives you a good summay in most of the important area's and enought code to get started quickly. It gave me lots of ideas on things I could use perl for. I also like "Perl 5 complete" for theory, but the code for that book is very buggy and hard to get to work. I like its detailed explanation of how things are suppose to work. "Perl Cookbook" is also excellent for how to solve problems various kinds of problems. These are the best of the perl books I have.,SUM=Perl power,RAT=5,COM=I bought this book based on the 5-star reviews - never do THAT again......long on abstract examples that don't mirror the real world, short on logical explanations for the common man(woman).. I have had several other PERL books from the local library that were much better (Castros book is good, don't believe the condescending reviews) - not for the CGI web programmer,SUM=Don't buy this book for CGI programming,RAT=2,

