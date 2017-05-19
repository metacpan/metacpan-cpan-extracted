#line 1
package Class::MOP::Mixin;
BEGIN {
  $Class::MOP::Mixin::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Mixin::VERSION = '2.0401';
}

use strict;
use warnings;

use Scalar::Util 'blessed';

sub meta {
    require Class::MOP::Class;
    Class::MOP::Class->initialize( blessed( $_[0] ) || $_[0] );
}

1;

# ABSTRACT: Base class for mixin classes



#line 62


__END__

