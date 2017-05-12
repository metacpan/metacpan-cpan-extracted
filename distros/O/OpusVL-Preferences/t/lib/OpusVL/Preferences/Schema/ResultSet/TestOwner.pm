
package OpusVL::Preferences::Schema::ResultSet::TestOwner;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
    
extends 'DBIx::Class::ResultSet';

with 'OpusVL::Preferences::RolesFor::ResultSet::PrfOwner';

return 1;
        
