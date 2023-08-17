#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('PM::Packages') };

my @list = PM::Packages::pm_packages( __FILE__ );

is_deeply( \@list, [ qw( Test::One Test::Two Indented ) ], "Found 3" );


package Test::One;
package Test::Two;

    package Indented;

package
    Hidden;

=pod 

    package In::POD;

=cut


__END__

package In::End;

You shouldn't see the above