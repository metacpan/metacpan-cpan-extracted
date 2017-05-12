package Net::Journyx::Time;
use Moose;

extends 'Net::Journyx::Record';
with 'Net::Journyx::Object::WithAttrs';

use constant jx_record_class => 'TimeRecord';

# Fool the role into getting the right object type for attributes
no warnings 'redefine';
*object_type_for_attributes = sub { 'time_recs' };

1;
