package Persistence::ValueGenerator::SequenceGenerator;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use base qw (Exporter  Persistence::ValueGenerator);

use Abstract::Meta::Class ':all';

@EXPORT_OK = qw(sequence_generator);
%EXPORT_TAGS = (all => \@EXPORT_OK);

$VERSION = 0.02;

=head1 NAME

Persistence::ValueGenerator::SequenceGenerator - Unique value generator based on database sequence

=head1 CLASS HIERARCHY

 Persistence::ValueGenerator
    |
    +----Persistence::ValueGenerator::SequenceGenerator

=head1 SYNOPSIS

    use Persistence::ValueGenerator::SequenceGenerator;

    my $generator = Persistence::ValueGenerator::SequenceGenerator->new(
        entity_manager_name  => $entity_manager_name,
        name                 => 'pk_generator',
        sequence_name        => 'cust_seq',
        allocation_size      =>  1,
    );

    $generator->nextval;

    or
    use Persistence::ValueGenerator::SequenceGenerator ':all';

    my $generator = sequence_generator 'pk_generator' => (
        entity_manager_name  => $entity_manager_name,
        sequence_name        => 'cust_seq',
        allocation_size      =>  1,        
    )

=head1 DESCRIPTION

Represents sequence generator that uses database sequcnce.

=head1 EXPORT

sequence_generator by ':all' tag.

=head2 ATTRIBUTES

=over

=item sequence_name

=cut

has '$.sequence_name' => (required => 1);

=back

=head2 METHODS

=over

=item retrieve_next_value

Returns next value for the instance generator

=cut

sub retrieve_next_value {
    my ($self) = @_;
    my $entity_manager = $self->entity_manager;
    my $connection = $entity_manager->connection;
    $connection->sequence_value($self->sequence_name);
}


=item sequence_generator

Creates a new instance of Persistence::ValueGenerator::TableGenerator

=cut

sub sequence_generator {
    my $name = shift;
    __PACKAGE__->new(@_, name => $name);
}



1;    

__END__

=back

=head1 SEE ALSO

L<Persistence::ValueGenerator>

=head1 COPYRIGHT AND LICENSE

The Persistence::ValueGenerator::SequenceGenerator module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
