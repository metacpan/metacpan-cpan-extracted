package Template;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ SPOPSx::Ginsu /;
	$CONF = {
		TemplateAlias => {
			class			=> __PACKAGE__,
			base_table		=> 'Template',
			isa				=> \@ISA,
			field			=> [ qw/ id field1 field2 / ],
			id_field		=> 'id',
			skip_undef		=> [ qw/ field1 field2 / ],
			as_string_order => [ qw/ id class field1 field2 / ],
			has_a			=> { SomeClass => [ 'field1' ] },
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Template (
	id		 int(11) PRIMARY KEY,
	field1	 char(255),
	field2	 int(11)
)
SQL
}

use SPOPSx::Ginsu;
use SomeClass;

##-----  Public Class Methods  -----
sub public_class_method {

}

##-----  Public Object Methods  -----
sub public_object_method {

}

##-----  Private Class Methods  -----
sub _private_class_method {

}

##-----  Private Object Methods  -----
sub _private_object_method {

}

__PACKAGE__->config_and_init;

1;
__END__

=head1 NAME

Template - A one-line description of the class goes here.

=head1 SYNOPSIS

  Some example usage of Template goes here ...

  use Template;
  $obj = MyObject->new;
  ...

=head1 DESCRIPTION

A paragraph or so describing in more detail what the class is about. It
should mention any classes that it inherits from.

=head1 ATTRIBUTES

=head2 Inherited Attributes

=over 4

=item inherited_attribute

Inherited from <some_class>.

=back

=head2 Persistent Attributes

=over 4

=item id

A <attribute_type> field used for ...

=back

=head2 Non-Persistent Attributes

=over 4

=item temp

A <attribute_type> field used for ...

=back

=head1 METHODS

=head2 Public Class Methods

=over 4

=item public_class_method

 $return_value = CLASS->public_class_method(\@example_args)

This method takes <something> as input arguments and returns <something
else>. It expects <some conditions> to be true when called. This
description should explain what the method does and what each input and
output argument means and what type it is.

=back

=head2 Public Object Methods

=over 4

=item public_object_method

 $return_value = $object->public_object_method(\@example_args)

This method takes <something> as input arguments and returns <something
else>. It expects <some conditions> to be true when called. This
description should explain what the method does and what each input and
output argument means and what type it is.

=back

=head2 Private Class Methods

=over 4

=item _private_class_method

 $return_value = CLASS->_private_class_method(\@example_args)

This method takes <something> as input arguments and returns <something
else>. It expects <some conditions> to be true when called. This
description should explain what the method does and what each input and
output argument means and what type it is. Names of private methods
begin with a '_' by convention.

=back

=head2 Private Object Methods

=over 4

=item _private_object_method

 $return_value = $object->_private_object_method(\@example_args)

This method takes <something> as input arguments and returns <something
else>. It expects <some conditions> to be true when called. This
description should explain what the method does and what each input and
output argument means and what type it is. Names of private methods
begin with a '_' by convention.

=back

=head1 CHANGE HISTORY

=over 4

=back

=head1 COPYRIGHT

Copyright (c) 2001-2004 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1)

=cut
