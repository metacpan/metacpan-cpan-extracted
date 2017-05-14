package Notes::AclEntry;

use strict;
use vars   qw( @ISA  $VERSION );

   # Note: we do not know, why _order_ of require/use _and_ inheritance
   #       is so important for proper working of method call resolution 
require        DynaLoader;
use            Notes::Object;

   # Note: we found experimentally, that Dynaloader _must_
   #       come first in inheritance statement (@ISA array)
   #       as otherwise strange things happen 
   #       (e.g. $s = new Notes::Session dies in test.pl while trying
   #        to AUTOLOAD a "new" function, even though we do
   #        not have _any_ AutoLoader related statement in our modules)
@ISA     = qw( DynaLoader
               Notes::Object
);
$VERSION =    '0.01';

bootstrap Notes::AclEntry $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Notes::AclEntry - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Notes::ACL;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Notes::ACL was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
