#!perl
use v5.26;

use Mojo::Util qw(dumper);
use Net::PublicSuffixList;

my $suffix_list = Net::PublicSuffixList->new;

my @hosts = qw(www.google.com www.learning-perl.com abcdef);

foreach my $host ( @hosts ) {
	say dumper( $suffix_list->split_host( $host ) );
	}
