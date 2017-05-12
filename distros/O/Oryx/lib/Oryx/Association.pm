package Oryx::Association;

use base qw(Oryx::MetaClass);

=head1 NAME

Association - abstract base class for Association types

=head1 SYNOPSIS

 my $assoc = Oryx::Association->new($meta, $source);
  
 $assoc->source;                # association from
 $assoc->class;                 # association to
 $assoc->role;                  # name of association accessor
 $assoc->type;                  # Array, Hash, Reference etc.
 $assoc->constraint;            # Aggregate or Composition
 $assoc->is_weak; 
 $assoc->update_backrefs;
 $assoc->link_table;

=head1 DESCRIPTION

This module represents an abstract base class for Oryx association
types.

=head1 METHODS

=over

=item new( $meta, $source )

The constructor returns the correct instance of the correct
subclass based on the C<type> field of the C<$meta> hashref passed
as an argument. The C<$source> argument is the name of the class
in which this association is defined (see L<Oryx::Class>)

=cut

sub new {
    my ($class, $meta, $source) = @_;

    my $type_class = $class.'::'.$meta->{type};
    eval "use $type_class"; $class->_croak($@) if $@;

    my $self = $type_class->new({
	meta   => $meta,
	source => $source,
    });

    eval 'use '.$self->class;
    $self->_croak($@) if $@;

    no strict 'refs';
    *{$source.'::'.$self->role} = $self->_mk_accessor;

    return $self;
}

=item create

Abstract (see implementing subclasses)

=item retrieve

Abstract (see implementing subclasses)

=item update

Abstract (see implementing subclasses)

=item delete

Abstract (see implementing subclasses)

=item search

Abstract (see implementing subclasses)

=item construct

Abstract (see implementing subclasses)

=cut

sub create    { $_[0]->_croak("abstract") }
sub retrieve  { $_[0]->_croak("abstract") }
sub update    { $_[0]->_croak("abstract") }
sub delete    { $_[0]->_croak("abstract") }
sub search    { $_[0]->_croak("abstract") }
sub construct { $_[0]->_croak("abstract") }

sub _mk_accessor {
    my $assoc = shift;
    my $assoc_name = $assoc->role;
    return sub {
	my $self = shift;
	$self->{$assoc_name} = shift if @_;
	$self->{$assoc_name};
    };
}

=item source

Simple accessor to the source class in which this association is
defined.

=cut

sub source {
    my $self = shift;
    $self->{source};
}

=item class

Simple accessor to the target class with which the source class has
an associtation.

=cut

sub class {
    my $self = shift;
    unless (defined $self->{class}) {
	$self->{class} = $self->getMetaAttribute("class");
    }
    $self->{class};
}

=item role

Simple accessor to the association accessor name defined in the
source class. Defaults to the target class' table name.

=cut

sub role {
    my $self = shift;
    unless (defined $self->{role}) {
        $self->{role} = $self->getMetaAttribute("role");
	unless ($self->{role}) {
	    # set some sensible defaults for creating the accessor
	    $self->{role} = $self->class->table;
	}
    }
    $self->{role};
}

=item type

Reference, Array or Hash... defaults to Reference.

=cut

sub type {
    my $self = shift;
    unless (defined $self->{type}) {
	$self->{type} = $self->getMetaAttribute("type")
	  || 'Reference';
    }
    $self->{type};
}

=item is_weak

Simple accessor to the C<is_weak> meta-attribute. This is used
for stopping Reference association types from creating a column
in the target class for storing a reverse association.

=cut

sub is_weak { $_[0]->getMetaAttribute('is_weak') }

=item constraint

Simple accessor to the C<constraint> meta-attribute. Values are:
Aggregate or Composition ... Aggregate is the default,
Composition causes deletes to cascade.

=cut

sub constraint {
    my $self = shift;
    unless (defined $self->{constraint}) {
	$self->{constraint} = $self->getMetaAttribute("constraint")
	  || 'Aggregate';
    }
    $self->{constraint};
}

=item update_backrefs

Updates reverse Reference associations.

B<NOTE:> Currently, reverse associations are made up of two
unidirectional associations... link tables are therefore not shared.
This will be fixed.

=cut

sub update_backrefs {
    my ($self, $obj, @things) = @_;
    foreach my $rev_assoc (values %{$self->class->associations}) {
	unless ($rev_assoc->type eq 'Reference') {
	    $self->_carp(
	        'weak associations not supported for non-Reference types'
	    );
	    next;
	}
	if ($rev_assoc->class eq $self->source) {
	    my $backref = $rev_assoc->role;
	    foreach my $target (@things) {
		$target->$backref($obj);
		$target->update unless $rev_assoc->is_weak;
	    }
	}
    }
}

=item link_table

Returns a name for the link table for this association. Not relevant
for Reference associations as these don't require a link table.

This is just a shortcut for:

     $self->source->table.'_'.$self->role.'_'.$self->class->table

Override for custom association types as needed.

=cut

sub link_table {
    my $self = shift;
    return $self->source->table.'_'.$self->role.'_'.$self->class->table;
}

1;

=back

=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 THANKS TO

Andrew Sterling Hanencamp

=head1 LICENCE

This module is free software and may be used under the same terms as
Perl itself.

=cut

