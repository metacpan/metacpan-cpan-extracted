
package OpenERP::OOM::Roles::Attribute;
use namespace::autoclean;
use Moose::Role;

has track_dirty     => (is => 'rw', isa => 'Bool', default => 1);
has dirty           => (is => 'ro', isa => 'Str',  predicate => 'has_dirty');

has track_attribute_helpers_dirty => 
    (is => 'rw', isa => 'Bool', default => 1);


# wrap our internal clearer
after clear_value => sub {
    my ($self, $instance) = @_;

    $instance->_mark_clean($self->name) if $self->track_dirty;
};

after install_accessors => sub {  
    my ($self, $inline) = @_;

    ### in install_accessors, installing if: $self->track_dirty
    return unless $self->track_dirty;

    my $class = $self->associated_class;
    my $name  = $self->name;

    ### is_dirty: $self->dirty || ''
    $class->add_method($self->dirty, sub { shift->_is_dirty($name) }) 
        if $self->has_dirty;

    $class->add_after_method_modifier(
        $self->clearer => sub { shift->_mark_clean($name) }
    ) if $self->has_clearer;

    # if we're set, we're dirty (cach both writer/accessor)
    $class->add_after_method_modifier(
        $self->writer => sub { shift->_mark_dirty($name) }
    ) if $self->has_writer;
    $class->add_after_method_modifier(
        $self->accessor => 
            sub { $_[0]->_mark_dirty($name) if exists $_[1] }
    ) if $self->has_accessor;

    return;
};

before _process_options => sub {
    my ($self, $name, $options) = @_;

    ### before _process_options: $name
    $options->{dirty} = $name.'_is_dirty' 
        unless exists $options->{dirty} || !$options->{lazy_build};

    return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Roles::Attribute

=head1 VERSION

version 0.44

=head1 DESCRIPTION

This code was largely taken from a version of MooseX::TrackDirty before it 
was updated to work with Moose 2.0.  Then it was cut down to suit our purposes
being uses in the Moose::Exporter.

=head1 NAME

OpenERP::OOM::Roles::Attribute - Meta attribute for implementing dirty attribute tracking

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
