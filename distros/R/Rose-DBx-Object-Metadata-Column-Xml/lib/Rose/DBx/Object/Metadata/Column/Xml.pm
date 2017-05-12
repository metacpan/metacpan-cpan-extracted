package Rose::DBx::Object::Metadata::Column::Xml;
use strict;
use Rose::DB::Object::Metadata::Column::Text;
our @ISA = qw(Rose::DB::Object::Metadata::Column::Text);

use DBD::Oracle qw(:ora_types);

our $VERSION = '0.782';

sub type { 'xml' }

sub dbi_requires_bind_param
{
  my($self, $db) = @_;
  return $db->driver eq 'oracle' ? 1 : 0;
}

sub dbi_bind_param_attrs
{
  my($self, $db) = @_;
  return $db->driver eq 'oracle' ? ORA_XMLTYPE : undef;
}

sub select_sql
{
  my($self, $db, $table) = @_;
  if ($db) {
	  $table = $table ? "$table." : '';
	  return $db->driver eq 'oracle' ? "$table$self->{name}.getClobVal()" : "$table$self->{name}";
  } else {
  	return $self->{name};
  }
}

1;

__END__

=head1 NAME

Rose::DBx::Object::Metadata::Column::Xml - Xml binary large object column metadata.

=head1 SYNOPSIS

  use Rose::DBx::Object::Metadata::Column::Xml;

  $col = Rose::DBx::Object::Metadata::Column::Xml->new(...);
  $col->make_methods(...);
  ...

     You could add this XML type to your Rose::DB::Object::Metadata column type
  by creating your own Metadata object inherited from Rose::DB::Object::Metadata.
  See below:

  	package Model::MyObjectMetadata;
	use Mojo::Base 'Rose::DB::Object::Metadata';

	sub new {
		my $class = shift;
		my $self = $class->SUPER::new(@_);
		$self->extend_column_type_classes;
		return $self;
	}

	sub extend_column_type_classes {
		my $self = shift;
		my $ctc = {$self->column_type_classes};
		@$ctc{qw/xml xmltype ora_xmltype/}	= ('Model::Object::Metadata::Column::Xml') x 3;    # <-------------
		$self->column_type_classes(%$ctc);
		return $self;
	}

	1;


  xml, xmltype, ora_xmltype - are aliases to the XML type. You can use any other names you want.

  Model DB class may look as follows:

	package Model::DB;
	use base 'Rose::DBx::AutoReconnect'; # <------------- if you need autoreconnection

	# Use a private registry for this class
	__PACKAGE__->use_private_registry;

	# Set the default domain and type
	__PACKAGE__->default_domain('production');
	__PACKAGE__->default_type('main');

	1;

  Then you have to use your "brend new" MyObjectMetadata in your inherited from Rose::DB::Object class as below:


	package Model::Object;
	use Model::DB;
	use Model::MyObjectMetadata; # <-------------
	use Mojo::Base qw(Rose::DB::Object);

	sub init_db {return Model::DB->new_or_cached}

	sub meta_class {return "Model::ObjectMetadata"}   # <-------------

	1;


  And in Scheme class do as below:

    package Model::Scheme::AnySchemeClass;
	use base qw/Model::Object/;

	__PACKAGE__->meta->setup
	(
		table	=> 'anytablename',

		columns	=> [
			...,
			my_xml_field => { type => 'xml'},
			...
		],
		...
	);

	1;

  And that's it!

=head1 DESCRIPTION

Objects of this class store and manipulate metadata for long, variable-length character-based columns in a database.  Column metadata objects store information about columns (data type, size, etc.) and are responsible for creating object methods that manipulate column values.

This class inherits from L<Rose::DB::Object::Metadata::Column::Text>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::DB::Object::Metadata::Column::Character> documentation for more information.

=head1 METHOD MAP

=over 4

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<character|Rose::DB::Object::MakeMethods::Generic/character>, ...

=item C<get>

L<Rose::DB::Object::MakeMethods::Generic>, L<character|Rose::DB::Object::MakeMethods::Generic/character>, ...

=item C<get_set>

L<Rose::DB::Object::MakeMethods::Generic>, L<character|Rose::DB::Object::MakeMethods::Generic/character>, ...

=back

See the L<Rose::DB::Object::Metadata::Column|Rose::DB::Object::Metadata::Column/"MAKING METHODS"> documentation for an explanation of this method map.

=head1 OBJECT METHODS

=over 4

=item B<type>

Returns "xml".

=back

=head1 AUTHOR

Andrey Chergik (andrey@chergik.ru)

=head1 LICENSE

Copyright (c) 2011 by Andrey Chergik.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

1;

