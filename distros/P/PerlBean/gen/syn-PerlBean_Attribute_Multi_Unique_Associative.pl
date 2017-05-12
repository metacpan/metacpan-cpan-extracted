use strict;
use PerlBean::Attribute::Multi::Unique::Associative;
my $attr = PerlBean::Attribute::Multi::Unique::Associative->new( {
    method_factory_name => 'ssns_i_know_from_people',
    short_description => 'all SSNs I know from people',
} );
1;
