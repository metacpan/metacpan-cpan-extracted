#!perl
use v5.26;

use Mojo::Util qw(dumper);
use Net::PublicSuffixList;

my $suffix_list = Net::PublicSuffixList->new;

my @candidates = qw(google.com co.uk com net edu);

foreach my $candidate ( @candidates ) {
	say "$candidate: " . $suffix_list->suffix_exists( $candidate );
	}
