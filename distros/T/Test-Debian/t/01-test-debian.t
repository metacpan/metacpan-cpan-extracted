#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

BEGIN {
    use Test::More;

    plan skip_all => 'Current system is not Debian'
        unless -r '/etc/debian_version';
    plan tests    => 16;

    use_ok 'Test::Debian';
}


system_is_debian;
package_is_installed 'dpkg';
package_isnt_installed('unknown_package_name');
package_is_installed 'dpkg | abcccc';
package_is_installed 'dddddddddddddddd | dpkg | abcccc';

(my $perl = $^V) =~ s/^v//;
(my $prev = $perl) =~ s/(\d\d)/$1 - 1/e;
(my $next = $perl) =~ s/(\d\d)/$1 + 1/e;

package_is_installed "perl (< $perl) | perl"; 
package_is_installed "perl ( =  $perl )"; 
package_is_installed "perl ( >= $perl )"; 
package_is_installed "perl ( <= $perl )"; 
package_is_installed "perl ( != $prev )"; 
package_is_installed "perl ( != $next )"; 
package_is_installed "perl ( >  $prev )"; 
package_is_installed "perl ( <  $next )"; 
package_is_installed "perl ( <  $next )|perl (= $perl)"; 
package_is_installed "perl ( >  $prev )|perl"; 

