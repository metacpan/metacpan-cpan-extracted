package RPC::ExtDirect::Test::Qux;

use strict;
use warnings;
no  warnings 'uninitialized';

use base 'RPC::ExtDirect::Test::Bar';

use RPC::ExtDirect Action => 'Qux';

# Redefine subs into Qux package without actually changing them
sub foo_foo : ExtDirect( 1 ) { shift; __PACKAGE__->SUPER::foo_foo(@_); }
sub foo_bar : ExtDirect( 2 ) { shift; __PACKAGE__->SUPER::foo_bar(@_); }
sub foo_baz : ExtDirect( params => [ qw( foo bar baz ) ] )
 { shift; __PACKAGE__->SUPER::foo_baz(@_); }
sub bar_foo : ExtDirect( 4 ) { shift; __PACKAGE__->SUPER::bar_foo(@_); }
sub bar_bar : ExtDirect( 5 ) { shift; __PACKAGE__->SUPER::bar_bar(@_); }
sub bar_baz : ExtDirect( formHandler ) {
    shift;
    __PACKAGE__->SUPER::bar_baz(@_);
}

1;
