use strict;
use warnings;
use Test::More;

use RDF::NS;

my %counts = ( # excluding prefix 'uri'
    20111028 => 698,
    20111031 => 700,
    20111102 => 701,
    20111124 => 709,
    20111208 => 716,
    20120124 => 733,
    20120426 => 780,
    20120521 => 791,
    20120827 => 830,
);

while ( my ($date,$number) = each(%counts) ) {
    my $ns = RDF::NS->new($date);
    is $ns->COUNT, $number, "$number prefixes at $date";
}

my $nfo1 = RDF::NS->new(20120125)->nfo;
my $nfo2 = RDF::NS->new(at => '2012-04-27')->nfo;

is $nfo1, 'http://www.semanticdesktop.org/ontologies/nfo/#', 'old prefix';
is $nfo2, 'http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#', 'prefix changed';

done_testing;
