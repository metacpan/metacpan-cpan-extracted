use strict;
use PerlBean::Attribute::Multi::Unique::Ordered;
my $attr = PerlBean::Attribute::Multi::Unique::Ordered->new( {
    method_factory_name => 'locations_in_traveling_salesman_itinerary',
    short_description => 'the locations in a traveling salesman\'s itinerary',
} );
1;
