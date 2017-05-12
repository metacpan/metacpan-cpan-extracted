package Storm::Object;
{
  $Storm::Object::VERSION = '0.240';
}

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

use Storm::Meta::Attribute::Trait::AutoIncrement;
use Storm::Meta::Attribute::Trait::NoStorm;
use Storm::Meta::Attribute::Trait::ForeignKey;
use Storm::Meta::Attribute::Trait::PrimaryKey;
use Storm::Meta::Attribute::Trait::StormArray;

use Storm::Meta::Class::Trait::AutoTable;

use Storm::Meta::Column;
use Storm::Meta::Table;

use Storm::Role::Object;
use Storm::Role::Object::Meta::Class;
use Storm::Role::Object::Meta::Attribute;



Moose::Exporter->setup_import_methods(
    also => 'Moose',
    with_caller => [qw( storm_table has_many one_to_many many_to_many )],
    class_metaroles => {
        class => [ 'Storm::Role::Object::Meta::Class' ],
        attribute => [ 'Storm::Role::Object::Meta::Attribute' ],
    },
    role_metaroles => {
        applied_attribute => [ 'Storm::Role::Object::Meta::Attribute' ],
    },
    base_class_roles => [ 'Storm::Role::Object' ],
);

sub storm_table {
   my $caller = shift;
   my $meta   = $caller->meta;
   $meta->storm_table( @_ );
}

sub storm_label {
    my $caller = shift;
    my $meta = $caller->meta;
    $meta->storm_label( $_ );
}

sub one_to_many {
    my $caller = shift;
    my $name   = shift;
    my $meta   = $caller->meta;
    my %params = @_;
    
    $params{name} = $name;   
    $meta->one_to_many( %params );
}

sub many_to_many {
    my $caller = shift;
    my $name   = shift;
    my $meta   = $caller->meta;
    my %params = @_;
    
    $params{name} = $name;
    $meta->many_to_many( %params );
}

sub has_many {
    my $caller = shift;
    my $name   = shift;
    my $meta   = $caller->meta;
    my %params = @_;

    warn q[Storm::has_many is deprecated - ] .
    q[use Storm::one_to_many or ] .
    q[Storm::many_to_many instead.];
        

    $params{name} = $name;
    $meta->add_has_many(%params);
}

1;



__END__

=pod

=head1 NAME

Storm::Object - Build objects to use with Storm

=head1 SYNOPSIS

    package Foo;
    use Storm::Object;  # provides Moose sugar

    has 'id' => (
        isa => 'Int',
        traits => [qw( PrimaryKey AutoIncrement )],
    );

    has 'label' => (
        isa => 'Str',
    );

    has 'bar' => (
        isa => 'Bar',
        weak_ref => 1,
    )


    package Bar;

    has 'id' => (
        isa => 'Int',
        traits => [qw( PrimaryKey AutoIncrement )],
    );

    has_many 'foos' => (
        foreign_class => 'Foo',
        match_on => 'bar',
        handles => {
            foos => 'iter',
        }
    );

    has_many 'bazzes' => (
        foreign_class => 'Baz',
        junction_table => 'BazBars',
        local_match => 'bar',
        foreign_match => 'baz',
        handles => {
            bazzes => 'iter',
            add_baz => 'add',
            remove_baz => 'remove',
        }
    );

    package Baz;

    has 'id' => (
        isa => 'Int',
        traits => [qw( PrimaryKey AutoIncrement )],
    );

    has_many 'bars' => (
        foreign_class => 'Foo',
        junction_table => 'BazBars',
        local_match => 'bar',
        foreign_match => 'baz',
        handles => {
            bars => 'iter',
            add_bar => 'add',
            remove_bar => 'remove',
        }
    );


=head1 DESCRIPTION

Storm::Object is an extension of the C<Moose> object system. The purpose of
Storm::Object is to apply the necessary meta-roles Storm needs to introspect
your objects and to provide sugar for declaring relationships between Storm
enabled objects.

=head1 ROLES/META-ROLES

=over 4

=item L<Storm::Role::Object>

This role is applied to the base class.

=item L<Storm::Role::Object::Meta::Attribute>

This role is applied to the attribute meta-class.

=item L<Storm::Role::Object::Meta::Class>

This role is applied to the class meta-class.

=back

=head1 SUGAR

=over 4

=item has_many $name => %options

=over 4

=item I<foreign_class =E<gt> $class>

Set the I<foreign_class> option to the other class in the relationship.

=item I<match_on =E<gt> $attribute_name>

Use when defining a one-to-many relationsuhip. This is the name of attribute in
the foreign class used to define the relationship.

=item I<junction_table =E<gt> $table>

Use when defining a many-to-many relationship. This is the database table used
to define the relationships.

=item I<local_match =E<gt> $table>

Use when defining a many-to-many relationship. This is the column in the
I<junction_table> which is to identify the __PACKAGE__ object in the relationship.

=item I<foreign_match =E<gt> $table>

Use when defining a many-to-many relationship. This is the column in the
I<junction_table> which is to identify the foreign object in the relationship.

=back

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut