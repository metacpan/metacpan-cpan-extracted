package UNIVERSAL::Object::ID;

use 5.008_008;

use strict;
use warnings;

use version; our $VERSION = qv("v0.1.2");

{
    package UNIVERSAL;
    use Object::ID;
}

=head1 NAME

UNIVERSAL::Object::ID - Supply a unique object identifier to every object

=head1 SYNOPSIS

    use DateTime;  # for example
    use UNIVERSAL::Object::ID;

    my $date = DateTime->now;

    print $date->object_id;

=head1 DESCRIPTION

Loading UNIVERSAL::Object::ID makes the C<< Object::ID >> role
available to every object.

Use at your own risk, polluting UNIVERSAL is not to be taken lightly.
The best place to use this module is in your own personal or internal
use code rather than a widely distributed software library.  Or you
can use L<Method::Lexical> to safely apply the UNIVERSAL effect to
just your lexical scope.

=head1 SEE ALSO

L<Object::ID>, L<Method::Lexical>

=cut

1;
