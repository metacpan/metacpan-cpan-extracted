use strict;
package Siesta::Subscription;
# thin link class
use Siesta::DBI;
use base 'Siesta::DBI';
__PACKAGE__->set_up_table('subscription');
__PACKAGE__->has_a( member => 'Siesta::Member' );
__PACKAGE__->has_a( list   => 'Siesta::List' );

1;
