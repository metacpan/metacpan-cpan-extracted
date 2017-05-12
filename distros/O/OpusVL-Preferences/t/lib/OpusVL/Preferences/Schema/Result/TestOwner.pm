
package OpusVL::Preferences::Schema::Result::TestOwner;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
    
extends 'DBIx::Class::Core';

with 'OpusVL::Preferences::RolesFor::Result::PrfOwner';
        
__PACKAGE__->table ("prf_mock_owners");
   
__PACKAGE__->add_columns
(
    id =>
	{
 		data_type         => 'integer',
		is_nullable       => 0,
		is_auto_increment => 1,
	},

	name =>
	{
		data_type   => 'varchar',
		is_nullable => 0
	},
);

__PACKAGE__->set_primary_key ('id');

__PACKAGE__->prf_owner_init;

return 1;
