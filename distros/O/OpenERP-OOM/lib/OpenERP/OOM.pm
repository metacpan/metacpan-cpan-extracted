package OpenERP::OOM;

use warnings;
use strict;

=head1 NAME

OpenERP::OOM - OpenERP Object to Object Mapper

=cut

our $VERSION = '0.48';

=head1 SYNOPSIS

OpenERP::OOM (Object to Object Mapper) maps OpenERP objects to Perl objects, in
a similar way to how an ORM like DBIx::Class maps database tables to Perl classes.

Relationships between objects can be defined in Perl code so that the OpenERP
schema can be traversed using Perl method calls, and related objects can be created
by calling methods on their parent (again, this corresponds closely to the
relationship model in an ORM).

Additionally, links can be defined to join OpenERP objects with DBIx::Class
schemas, so that an OpenERP object can be augmented with additional data
structures, methods, and application logic that is held outside of OpenERP.

=head1 TUTORIAL

L<OpenERP::OOM::Tutorial> gives a walkthrough of how to use OpenERP::OOM.


=cut

1; # End of OpenERP::OOM
