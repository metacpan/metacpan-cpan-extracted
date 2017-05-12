#
# This file is part of MooX-ProtectedAttributes
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::moose::myTestClass2;
use Moose;
use MooX::ProtectedAttributes;
with 't::lib::moose::myTestClassRole2';

protected_has
    'foo'  => ( is => 'rw' ),
    unless => sub  { $ENV{SKIP_WARNING} };

sub baz {789}

sub display_foo             { "DISPLAY: " . shift->foo }
sub display_role_bar        { shift->display_bar }
sub display_role_bar_direct { "DISPLAY: " . shift->bar }

sub display_indirect_bar       { shift->display_role_bar }
sub display_large_indirect_bar { shift->display_indirect_bar }

1;
