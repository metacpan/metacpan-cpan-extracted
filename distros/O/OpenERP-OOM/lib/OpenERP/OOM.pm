package OpenERP::OOM;

use warnings;
use strict;


our $VERSION = '0.44';


1; # End of OpenERP::OOM

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM

=head1 VERSION

version 0.44

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

=head1 NAME

OpenERP::OOM - OpenERP Object to Object Mapper

=head1 TUTORIAL

L<OpenERP::OOM::Tutorial> gives a walkthrough of how to use OpenERP::OOM.

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
