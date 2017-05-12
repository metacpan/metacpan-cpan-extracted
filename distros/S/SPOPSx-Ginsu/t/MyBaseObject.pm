package MyBaseObject;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw(SPOPSx::Ginsu MyDBI);
	$CONF = {
		ObjectAlias => {
			class			=> __PACKAGE__,
			base_table		=> 'Object',
			isa				=> \@ISA,
			field			=> [ qw/ id class / ],
			id_field		=> 'id',
			as_string_order => [ qw/ id class / ],
			increment_field => 1,
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Object (
	id int(11) AUTO_INCREMENT PRIMARY KEY,
	class  char(255),
	created timestamp(14) NOT NULL
)
SQL
}

use constant ROOT_OBJ_CLASS => __PACKAGE__;

use SPOPSx::Ginsu;

__PACKAGE__->config_and_init;

1;
__END__

=head1 NAME

MyBaseObject - Example root base class for a Ginsu hierarchy.

=head1 SYNOPSIS

=head1 DESCRIPTION

This is an example of a base class to be used as the root for a
hierarchy of Ginsu objects. A root base class must define a table with
an autoincrement id field and a 'class' field.

It must also define a method (or constant) ROOT_OBJ_CLASS which returns
the name of the class with the root table (the one with the
autoincrement id and the class).

Independent hierarchies of classes, whose objects have ids that are
unique within their own hierarchy, can be created by creating different
root classes. Each class looks exactly like this one with the following
exceptions:

(1) Each has a unique class name.
(2) Each has a unique table name.
(3) Each may inherit from a unique datasource class (e.g. MyDBI).

=head1 ATTRIBUTES

=head2 Persistent Attributes

=over 4

=item id

An auto-increment integer field which stores the object id.

=item class

A string containing the name of the object's class.

=back

=head1 METHODS

=over 4

=item ROOT_OBJ_CLASS

Returns the name of the class with the root table containing the
autoincrementing id field and the class field.

=back

=head1 BUGS / TODO

=head1 CHANGE HISTORY

=head1 COPYRIGHT

Copyright (c) 2001-2004 PSERC. All rights reserved.

=head1 AUTHORS

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  SPOPSx::Ginsu(3)
  SPOPS(3)
  SPOPS::DBI(3)
  perl(1)

=cut
