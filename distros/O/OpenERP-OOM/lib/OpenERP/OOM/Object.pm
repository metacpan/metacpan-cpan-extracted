package OpenERP::OOM::Object;


use 5.010;
use Carp;
use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;
use Moose::Util::TypeConstraints;

#-------------------------------------------------------------------------------

# Set up a subtype for many2one relationships. On object retrieval, OpenERP
# presents this relationship as an array reference holding the ID and the name
# of the related object, e.g.
#
#   [ 1, 'Related object name' ]
#
# However, when updating the object OpenERP expects this to be presented back
# as a single integer containing the related object ID.

subtype 'OpenERP::OOM::Type::Many2One'
    => as 'Maybe[Int]';

coerce 'OpenERP::OOM::Type::Many2One'
    => from 'ArrayRef'
    => via { $_->[0] };
    

#-------------------------------------------------------------------------------

# Export the 'openerp_model' and 'relationship' methods

Moose::Exporter->setup_import_methods(
    with_meta => ['openerp_model', 'relationship', 'has_link'],
    also      => 'Moose',
);


#-------------------------------------------------------------------------------

sub init_meta {
    shift;
    my %args = @_;
    
    Moose->init_meta( %args, base_class => 'OpenERP::OOM::Object::Base' );
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
            class => [
                'OpenERP::OOM::Meta::Class::Trait::HasRelationship',
                'OpenERP::OOM::Meta::Class::Trait::HasLink',
            ],
            attribute => ['OpenERP::OOM::Roles::Attribute'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles( 
        for_class => $args{for_class}, 
        roles     => ['OpenERP::OOM::Roles::Class'],
    );

}


#-------------------------------------------------------------------------------

sub openerp_model {
    my ($meta, $name, %options) = @_;
    
    $meta->add_method(
        'model',
        sub {return $name},
    );
}


#-------------------------------------------------------------------------------

sub relationship {
    my ($meta, $name, %options) = @_;
    
    #carp "Adding relationship $name";
    
    $meta->relationship({
        %{$meta->relationship},
        $name => \%options
    });
    
    #say "Adding hooks";
    
    given ($options{type}) {
        when ('many2one') {
            goto &_add_rel2one;
        }
        when ('one2many') {
            goto &_add_rel2many;
        }
        when ('many2many') {
            goto &_add_rel2many;
        }
    }
}


#-------------------------------------------------------------------------------

sub _add_rel2many {
    my ($meta, $name, %options) = @_;
    
    $meta->add_attribute(
        $options{key},
        isa => 'ArrayRef',
        is  => 'rw',
    );
    
    $meta->add_method(
        $name,
        sub {
            my ($self, @args) = @_;
            my $field_name = $options{key};
            if(@args)
            {
                my @ids;
                if(ref $args[0] eq 'ARRAY')
                {
                    # they passed in an arrayref.
                    # i.e. $obj->rel([ $obj1, $obj2 ]);
                    my $objects = $args[0];
                    @ids = map { _id($_) } @$objects;
                }
                else
                {
                    # assume they passed each object in as an arg
                    # i.e. $obj->rel($obj1, $obj2);
                    @ids = map { _id($_) } @args;
                }
                $self->$field_name(\@ids);
                return unless defined wantarray; # avoid needless retrieval
            }
            return unless $self->{$field_name};
            return $self->class->schema->class($options{class})->retrieve_list($self->{$field_name});
        },
    );
}


# this method means the user can simply pass in id's as well as 
# objects.
sub _id
{
    my $var = shift;
    return ref $var ? $var->id : $var;
}


#-------------------------------------------------------------------------------

sub _add_rel2one {
    my ($meta, $name, %options) = @_;

    my $field_name = $options{key};
    $meta->add_attribute(
        $field_name,
        isa    => 'OpenERP::OOM::Type::Many2One',
        is     => 'rw',
        coerce => 1,
    );
    
    my $cache_field = '__cache_' . $field_name;
    $meta->add_attribute(
        $cache_field,
        is     => 'rw',
    );
    
    $meta->add_method(
        $name,
        sub {
            my $self = shift;
            if(@_)
            {
                my $val = shift;
                $self->$field_name($val ? _id($val) : undef);
                $self->$cache_field(undef);
                return unless defined wantarray; # avoid needless retrieval
            }
            return unless $self->{$options{key}};
            return $self->$cache_field if defined $self->$cache_field;
            my $val = $self->class->schema->class($options{class})->retrieve($self->{$options{key}});
            $self->$cache_field($val);
            return $val;
        },
    );
}


#-------------------------------------------------------------------------------

sub has_link {
    my ($meta, $name, %options) = @_;
    
    $meta->link({
        %{$meta->link},
        $name => \%options
    });
    
    given ($options{type}) {
        when ('single') {
            goto &_add_link_single;
        }
        when ('multiple') {
            goto &_add_link_multiple;
        }
    }
}


#-------------------------------------------------------------------------------

sub _add_link_single {
    my ($meta, $name, %options) = @_;
    
    $meta->add_attribute(
        $options{key},
        isa => 'Int',
        is  => 'ro',
    );
    
}


#-------------------------------------------------------------------------------

sub _add_link_multiple {
    my ($meta, $name, %options) = @_;
    
    $meta->add_attribute(
        $options{key},
        isa => 'ArrayRef',
        is  => 'ro',
    );
    
}


#-------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Object

=head1 VERSION

version 0.44

=head1 SYNOPSIS

    package Package::OpenERP::Object::Account;

    use 5.010;
    use OpenERP::OOM::Object;

    openerp_model 'account.account';

    has active => (is => 'rw', isa => 'Bool'); # Active
    has code => (is => 'rw', isa => 'Str'); # (required) Code

    ...

    relationship 'consolidated_children' => (
        key   => 'child_consol_ids',
        type  => 'many2many',
        class => 'Account',
    ); # Consolidated Children

    ...

    1;

=head1 DESCRIPTION

Use this module to create the 'objects' for your models.  It also implicitly loads
Moose too.  

The class is linked to a model in OpenERP.

=head1 NAME

OpenERP::OOM::Object

=head1 METHODS

=head2 openerp_model

Specify the model in OpenERP.

=head2 init_meta

An internal method that hooks up the Moose internals and implicitly makes your
new classes inherit from OpenERP::OOM::Object::Base.  See the 
OpenERP::OOM::Object::Base documentation for a list of the methods your objects
will have by default.

=head2 relationship

Used to specify relationships between this object and others in OpenERP.

Possible options for the type are many2one, one2many and many2many.  These
are specified in OpenERP in those terms.

=head2 has_link

Used to indicate links with other systems.  Typically this is to another table
in DBIC at the moment.

The key field is in OpenERP and is used for the ids of the objects to link to.

The class specifies a link class that is used to follow the link.  These are in
the namespace OpenERP::OOM::Link.  When class is set to DBIC this means it loads
OpenERP::OOM::Link::DBIC to follow the link to the DBIC rows.

Possible options for type are C<single> and C<multiple>.

    has_link 'details' => (
        key   => 'x_dbic_link_id',
        type  => 'single',
        class => 'DBIC',
        args  => {class => 'AuctionHouseDetails'},
    );

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
