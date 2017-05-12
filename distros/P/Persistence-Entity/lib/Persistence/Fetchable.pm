package Persistence::Fetchable;

use strict;
use warnings;

use vars qw($VERSION);
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

use Abstract::Meta::Class ':all';
use base 'Exporter';
use Carp 'confess';

use constant LAZY   => 0;
use constant EAGER  => 1;

$VERSION = 0.02;

@EXPORT_OK = qw(LAZY EAGER);
%EXPORT_TAGS = (all => \@EXPORT_OK);

abstract_class;

=head1 NAME

Persistence::Fetchable - Fetching method base class.

=cut

=head1 SYNOPSIS

Abstract class.

=head1 DESCRIPTION

Represents a base class for attributes that use eager or lazy fetch methods.

=head1 EXPORT

LAZY EAGER by ':all' tag.

=head2 ATTRIBUTES

=over

=item fetch_method

LAZY, EAGER

=cut

has '$.fetch_method' => (default => LAZY);

=back

=head2 METHODS

=over

=item eager_fetch_filter

Returns list of objects that have EAGER fetch method.
Takes hash ref of objects.

=cut

sub eager_fetch_filter {
    my ($class, $hash_of_objects) = @_;
    $class->fetch_objects_filter($hash_of_objects, EAGER);
}


=item lazy_fetch_filter

Returns list of objects that have LAZY fetch method.
Takes hash ref of objects.

=cut

sub lazy_fetch_filter {
    my ($class, $hash_of_objects) = @_;
    $class->fetch_objects_filter($hash_of_objects, LAZY);
}


=item fetch_objects_filter

Returns list of objects that have specyfied fetch method.
Takes hash ref of objects, fetch method.

=cut

sub fetch_objects_filter {
    my ($class, $hash_of_objects, $fetch_method) = @_;
    my @result;
    foreach my $k (keys %$hash_of_objects) {
        my $object = $hash_of_objects->{$k};
        next if $object->fetch_method ne $fetch_method;
        push @result, $object;
    }
    @result;
}


=item lazy_fetch_handler

=cut

sub lazy_fetch_handler {
    my ($self, $attribute) = @_;
    my %pending_fetch;
    my $class_name = $attribute->class_name;
    my $attr_name = $attribute->name;
    sub {
           my ($this, $values) = @_;
           my $entity_manager = $self->orm->entity_manager;
           if ($entity_manager && ! $attribute->has_value($this)) {
                unless ($entity_manager->has_lazy_fetch_flag($this, $attr_name)) {
                     unless ($pending_fetch{$this}) {
                          $pending_fetch{$self} = 1;
                          my $orm = $entity_manager->find_entity_mappings($class_name);
                          $self->deserialise_attribute($this, $entity_manager, $orm);
                          delete $pending_fetch{$self};
                          $values = $attribute->get_value($this);
                    }
                    $entity_manager->add_lazy_fetch_flag($this, $attr_name);
                }
           }
           $entity_manager->add_lazy_fetch_flag($this, $attr_name);
           $values;
    };
}

1;



__END__

=back

=head1 SEE ALSO

L<Persistence::Entity>
L<Persistence::Relationship::OneToMany>
L<Persistence::Relationship::ManyToMany>

=head1 COPYRIGHT AND LICENSE

The Persistence::Relationship module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;


