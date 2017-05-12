use strict;
package Siesta::Pref;
use base 'Siesta::DBI';
__PACKAGE__->set_up_table('pref');
__PACKAGE__->has_a( plugin => 'Siesta::Plugin' );
__PACKAGE__->has_a( member => 'Siesta::Member' );

1;
