use strict;
use PerlBean::Attribute::Multi::Unique;
my $attr = PerlBean::Attribute::Multi::Unique->new( {
    method_factory_name => 'ssns_i_can_remember',
    short_description => 'all SSNs I can remember',
} );
1;
