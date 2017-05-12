package Rose::HTMLx::Form::Related::Metadata;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Rose::Object );

use Rose::HTMLx::Form::Related::RelInfo;

our $VERSION = '0.24';

use Rose::Object::MakeMethods::Generic (
    'scalar' => [
        qw( form relationship_data
            related_fields related_field_names )
    ],
    'scalar --get_set_init' => [
        'relationships',     'relinfo_class',
        'object_class',      'labels',
        'controller_prefix', 'field_uris',
        'related_field_map', 'sort_prefix',
        'default_sort_by',   'default_related_sort_by',
        'default_selected',  'takes_object_as_argument',
        'field_methods',
    ],
    'boolean --get_set' => [
        'show_related_values' => { default => 1 },
        'show_related_fields' => { default => 1 },
        'show_relationships'  => { default => 1 },
        'interrelate_fields'  => { default => 1 },
    ],
);

=head1 NAME

Rose::HTMLx::Form::Related::Metadata - RHTMLO Form class metadata

=head1 DESCRIPTION

Rose::HTMLx::Form::Related::Metadata interrogates and caches interrelationships
between Form and ORM classes.

You typically access an instance of this class via the metadata() method in
your Form class.

=head1 METHODS

=cut

=head2 init

Overrides base init() method to build metadata.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if (   !defined $self->form
        or !$self->form->isa('Rose::HTMLx::Form::Related') )
    {
        croak "Rose::HTMLx::Form::Related object required";
    }
    $self->_build;
    if ( $self->form->debug ) {
        dump $self;
    }
    return $self;
}

=head2 form( [I<form>] )

Get/set the Rose::HTMLx::Related::Form object.

=head2 related_field_names([I<array_ref>])

Get/set the array ref of field names representing foreign keys.

=head2 related_fields( [I<hash_ref>] )

Get/set the hash ref of related field names to RelInfo objects.

=head2 relationship_data( [I<hash_ref>] )

Get/set the hash ref of RelInfo objects, keyed by the RelInfo->name
value.

=head2 show_related_fields

Boolean indicating whether the Form should provide links to related
forms based on ORM relationships.

Default is true.

=head2 show_related_values

Boolean indicating whether the Form should
show related unique field values rather than the foreign keys
to which they refer.

Default is true.

=head2 show_relationships

Boolean indicating whether the View should provide links to related
tables based on RDBO relationship method names that do not have
corresponding field names.

=cut

=head2 init_controller_prefix

The default is undef.

=cut

sub init_controller_prefix { return undef }

=head2 init_labels 

Should return a hashref of method (field) names to labels. Useful for giving
labels to non-fields like relationship names.

=cut

sub init_labels { return {} }

=head2 init_sort_prefix

Should return a hashref of method (field) names to any strings that should
be prefixed to the name for sorting. This is to support (for example)
sorts on multi-table joins.

Default is empty hashref.

=cut

sub init_sort_prefix { {} }

=head2 init_object_class

Should return the name of the ORM object class the Form class represents.
Default is the Form class name less the C<::Form> part.

=cut

sub init_object_class {
    my $form_class = ref( shift->form );
    $form_class =~ s/::Form$//;
    return $form_class;
}

=head2 init_field_uris

Should return a hashref of field name to a URI value.

=cut

sub init_field_uris {
    return {};
}

=head2 init_default_sort_by

Should return the name of the field to sort by in (for example)
search results.

Default is null (empty string).

=cut

sub init_default_sort_by { return '' }

=head2 init_default_related_sort_by

Should return the name of the related field to sort by in (for
example) search results that join tables.

Default is null (empty string).

=cut

sub init_default_related_sort_by { return '' }

=head2 init_default_selected

Should return the name of the relationship to show as initially
active in an interface.

Default is null (emptry string).

=cut

sub init_default_selected { return '' }

=head2 init_takes_object_as_argument

Set hash ref of ORM method names in foreign_class
that take the related ORM object as a single argument.

=cut

sub init_takes_object_as_argument { return {} }

=head2 field_uri( I<field_name> )

Returns the value from field_uris() for key I<field_name> if such a key exists.
Otherwise, returns undef.

=cut

sub field_uri {
    my $self = shift;
    my $field_name = shift or croak "field_name required";
    if ( exists $self->field_uris->{$field_name} ) {
        return $self->field_uris->{$field_name};
    }
    return;
}

=head2 init_field_methods

Returns array of method names to use for rendering form. Default
is form->field_names().

You may want to override this value, especially for large forms,
in order to show only a subset of the most meaningful field values.

=cut

sub init_field_methods {
    my $self = shift;
    return $self->form->field_names;
}

=head2 init_related_field_map

Used by show_related_fields_using(), this method should return a hashref
of I<field_name> to I<method_name> where I<field_name> is a field in the Form
and I<method_name> is a method name in the foreign object_class.

The default is an empty hashref, which means that show_related_fields_using()
will take the first unique column it can find as the I<method_name>.

=cut

sub init_related_field_map { return {} }

=head2 init_relationships

You may define the Form relationships as an array ref using this method in your
subclass, or via the "relationships" key/value pair in new(). 

If you define this value explicitly, the value must be an array ref of
either Rose::HTMLx::Form::Related::RelInfo objects, or hash refs (which will
be blessed into Rose::HTMLx::Form::Related::RelInfo objects).

If not defined,
discover_relationships() is automatically called internally in new().
The default return value is undef, triggering discover_relationships. You can
turn off relationships altogether if you set it to an empty array ref,
although that begs the question of why you are using Rose::HTMLx::Form::Related
in the first place.

=cut

sub init_relationships { }

=head2 init_relinfo_class

Returns the default value 'Rose::HTMLx::Form::Related::RelInfo'.

=cut

sub init_relinfo_class {'Rose::HTMLx::Form::Related::RelInfo'}

sub _build {
    my $self = shift;

    my %related_fields;
    my %relationship_info;

    if ( !defined $self->relationships ) {
        $self->discover_relationships;
    }

    if ( ref( $self->relationships ) ne 'ARRAY' ) {
        croak "relationships() should be an ARRAY reference";
    }

RELINFO: for my $relinfo ( @{ $self->relationships } ) {

        if ( ref($relinfo) eq 'HASH' ) {
            $relinfo = bless( $relinfo, $self->relinfo_class );
        }
        if ( !ref($relinfo) or !$relinfo->isa( $self->relinfo_class ) ) {
            croak "$relinfo is not a " . $self->relinfo_class . " object";
        }

        $relationship_info{ $relinfo->name } = $relinfo;

        # skip unless explicitly defined as a FK
        # so we don't get PKs and UKs in here by mistake
        if (    $relinfo->type ne 'foreign key'
            and $relinfo->type ne 'many to one' )
        {
            next RELINFO;
        }

        if ( my $colmap = $relinfo->cmap ) {
            $relinfo->foreign_column( {} );
        FIELDNAME: for my $field_name ( @{ $self->form->field_names } ) {

                # skip unless it's in the column map
                next unless exists $colmap->{$field_name};

                # avoid condition where o2m overrides a FK
                next if exists $related_fields{$field_name};

                #warn
                #    "field_name $field_name is in cmap";

                $relinfo->foreign_column->{$field_name}
                    = $colmap->{$field_name};

                $related_fields{$field_name} = $relinfo;
            }
        }

    }

    $self->{related_fields}      = \%related_fields;
    $self->{relationship_data}   = \%relationship_info;
    $self->{related_field_names} = [ keys %related_fields ];

}

=head2 discover_relationships

This method must be overriden by model-specific subclasses. The method
should interrogate object_class() and set the array ref of relinfo_class()
objects via the relationships() mutator method.
A Rose::DB::Object-derived object that is a subclass of
Rose::DBx::Garden::Catalyst::Object will have a C<schema_class_prefix>
method, which is to be used in determining the name of the Controller
class associated with related Forms.  Specifically, the return value
of C<schema_class_prefix> will be stripped from the beginning of the
related Form's class name, and will be replaced with the value of
C<controller_prefix> if such is defined.

=cut

sub discover_relationships {
    my $class = ref( $_[0] ) || $_[0];
    croak "no relationships defined and discover_relationships() "
        . "not implemented for class $class";
}

=head2 is_related_field( I<field_name> )

Returns true if I<field_name> is a related_field().

=cut

sub is_related_field {
    my $self = shift;
    my $field_name = shift or croak "field_name required";
    return exists $self->{related_fields}->{$field_name};
}

=head2 related_field( I<field_name> )

If I<field_name> represents a foreign key or other relationship to a different
object class (and hence a different form class), then related_field() will
return a hashref with relationship summary information.

If I<field_name> does not represent a related class, will croak.

=cut 

sub related_field {
    my $self = shift;
    my $field_name = shift or croak "field_name required";

    croak "'$field_name' is not a related field"
        unless $self->is_related_field($field_name);

    return $self->{related_fields}->{$field_name};
}

=head2 has_relationship_info( I<relationship> )

Returns true if I<relationship> information is known.

=cut

sub has_relationship_info {
    my $self = shift;
    my $rel  = shift or croak "relationship object required";
    my $name = ref($rel) ? $rel->name : $rel;
    return exists $self->{relationship_data}->{$name};
}

=head2 relationship_info( I<relationship> )

Returns the same RelInfo object as related_field(), 
only using a relationship object or name instead of a field name.

=cut

sub relationship_info {
    my $self = shift;
    my $rel  = shift or croak "relationship object required";
    my $name = ref($rel) ? $rel->name : $rel;

    croak "no info for relationship '$name'"
        unless $self->has_relationship_info($name);

    return $self->{relationship_data}->{$name};
}

=head2 show_related_field_using( I<foreign_object_class>, I<field_name> )

Returns the name of a field to use for display from I<foreign_object_class>
based on a relationship using I<field_name>.

This magic is best explained via example. Say you have a 'person' object
that is related to a 'user' object. The relationship is defined in the 'user'
object as:

 person_id => person.id
 
where the id of the 'person' object is a related (foreign key) to the person_id
value of the user object. In a form display for the 'user', 
you might want to display the name of the 'person' rather than the id, 
so show_related_field_using() will look
up the first unique text field in the I<foreign_object_class> 
(in this case, the 'person' class) and return that field.

 my $field_name = $form->show_related_field_using( 'MyPerson', 'person_id' )
 
And because it's a method, you can override show_related_field_using() 
to perform different logic than simply looking up the first unique text key 
in the I<foreign_object_class>.

If no matching field is found, returns undef.

The default behaviour is to ignore I<foreign_object_class>
altogether, deferring to related_field_map() if I<field_name>
is defined there and returning undef otherwise.

Override this method in a base class
that understands how to interrogate I<foreign_object_class>.

=cut

sub show_related_field_using {
    my $self   = shift;
    my $fclass = shift or croak "foreign_object_class required";
    my $field  = shift or croak "field_name required";

    if ( exists $self->related_field_map->{$field} ) {
        return $self->related_field_map->{$field};
    }

    if ( $fclass->can('unique_value') ) {
        return 'unique_value';
    }

    return undef;
}

=head2 foreign_field_value( I<field_name>, I<object> )

Returns the value from the foreign object related to I<object> 
for the foreign column related to I<field_name>. 

Returns undef if (a) there is no
foreign field related to I<field_name> or (b) if there is
no foreign object.

Example:

 my $username = $form->foreign_field_value( 'email_address', $person );
 # $username comes from a $user record related to $person

=cut

sub foreign_field_value {
    my $self       = shift;
    my $field_name = shift or croak "field_name required";
    my $object     = shift or croak "data object required";
    return unless $self->is_related_field($field_name);
    my $info = $self->related_field($field_name) or return;
    my $foreign_field
        = $self->show_related_field_using( $info->{foreign_class},
        $field_name );
    my $method         = $info->{method};
    my $foreign_object = $object->$method;

    if ( defined $foreign_object ) {

        # special RDBOHelper and MoreHelpers method
        if ( $foreign_object->can('unique_value') ) {
            $foreign_field = 'unique_value';
        }

        return $foreign_object->$foreign_field;
    }
    else {
        return undef;
    }
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-related at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-HTMLx-Form-Related>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::HTMLx::Form::Related

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-HTMLx-Form-Related>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-HTMLx-Form-Related>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTMLx-Form-Related>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-HTMLx-Form-Related>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
