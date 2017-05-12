package StateML::Class;

$VERSION = 0.000_1;

=head1 NAME

StateML::Class - An abstract class object for StateML

=head1 SYNOPSIS

=head1 DESCRIPTION

StateML files (.stml files) support an instance-based inheritence scheme
that allows any object to inherit from one or more parent objects of
its type or of type <class>.

The object <class> is an untyped base object that allows inheritance
from objects that may carry any attribute and which will not appear
on the graph.

Someday, a <class> object may contain zero or one real objects which
will not appear on the graph but which carry attributes and values that
will be searched for.

This takes effect for all scalar attributes at run-time (as opposed to
compile time).

List attributes (<state><arc/><arc/>...</state>) are not affected
quite yet.  Not sure how to allow mixins vs. replacements in
derived objects.

The special class "#DEFAULT" is the base class of any object with no
explicit base classes.

NOTE: Not all attributes are good about searching up the class hierarchy
at this time.

=cut

use strict;

use base qw( StateML::Object ) ;

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
