package TrackDirty;

use 5.006;
use strict;
use warnings;
use Moose ();
use Moose::Exporter;

=head1 NAME

TrackDirty

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

Moose::Exporter->setup_import_methods(
    with_meta => [ ],
    as_is     => [ ],
    also      => 'Moose',
);


=head1 SYNOPSIS

A module for allowing objects to track their attributes changes.

This is a very cut down version of an old module MooseX::TrackDirty::Attributes 
(probably).

This code has now been relegated to the tests because the attributes have
been internalised into the module since it's so cut down and specific
to our purpose now, it's not really worth having it seperate.  If you want
this functionality, simply use the MooseX::TrackDirty::Attributes module.

In order to use this module you can use this module like you would include
Moose or if you are doing something fancy you can hook the roles in manually
yourself.

    use TrackDirty;

    has property => (is => 'ro', isa => 'Str');

    sub save {
        my $self = shift;
        if($self->is_dirty) {
            foreach my $key ($self->dirty_attributes) {
                ...
            }
            $self->mark_all_clean;
        }
    ...

=head1 METHODS

=head2 mark_all_clean

This will mark all the attributes clean.

=head2 has_dirty_attributes

Returns true if any of the attributes have been set.

=head2 all_attributes_clean

Returns true if no attributes have been touched.

=head2 dirty_attributes

Return an array of the attributes touched.

=head2 _set_dirty

Set a field as dirty.

    $self->_set_dirty('property');

=head2 init_meta

This is a function used to setup the Moose::Exporter and load in all these functions.  
If you are creating your own Moose::Exporter you should simply do thse bits yourself,

    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
            attribute => ['OpenERP::OOM::Roles::Attribute'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles( 
        for_class => $args{for_class}, 
        roles     => ['OpenERP::OOM::Roles::Class'],
    );

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

sub init_meta {
    shift;
    my %args = @_;
    
    Moose->init_meta( %args );
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
            attribute => ['OpenERP::OOM::Roles::Attribute'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles( 
        for_class => $args{for_class}, 
        roles     => ['OpenERP::OOM::Roles::Class'],
    );

}

1; # End of OpusVL::MooseX::TrackDirty
