#########################
# Test all constructors
#########################

use warnings;
use strict;

use Test::More tests => 16;
BEGIN { use_ok('Net::Amazon') };

my @request_types = (
['Actor'],
['Artist'],
['Author'],
['ASIN'],
['Blended'],
['BrowseNode'],
['Keyword'],
['Manufacturer'],
['MusicLabel', 'label'],
['Power'],
['Publisher'],
['Seller'],
['Similar'],
['TextStream'],
['UPC'],
);

for my $t (@request_types) {
    my $class  = $t->[0];
    my $tlower = lc($t->[0]);
    my $params = join(', ', map { "$_ => '234'" }
                     ($tlower, @$t > 1 ? $t->[1] : ()));

    #print "$class $params\n";
    my $use = "use Net::Amazon::Request::$class";
    my $new = "Net::Amazon::Request::$class->new($params)";
    ok(eval "$use; $new", 
       "$new");
print $@ if $@;
}
