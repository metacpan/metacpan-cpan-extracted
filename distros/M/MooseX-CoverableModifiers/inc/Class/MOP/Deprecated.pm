#line 1
package Class::MOP::Deprecated;
BEGIN {
  $Class::MOP::Deprecated::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Deprecated::VERSION = '2.0401';
}

use strict;
use warnings;

use Package::DeprecationManager -deprecations => {
};

1;

# ABSTRACT: Manages deprecation warnings for Class::MOP



#line 55


__END__

