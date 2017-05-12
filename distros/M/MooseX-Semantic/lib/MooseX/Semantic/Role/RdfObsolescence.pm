package MooseX::Semantic::Role::RdfObsolescence;
use Moose::Role;
use RDF::Trine qw(iri);
use RDF::Trine::Namespace qw(rdf);
use MooseX::Semantic::Types qw( TrineModel );

with (
    'MooseX::Semantic::Role::RdfExport',
);

has obsolescence_model => (
    is => 'rw',
    isa => TrineModel,
    default => sub { RDF::Trine::Model->temporary_model },
);

around 'export_to_model' => sub {
    my $orig = shift;
    my $self = shift;
    my $model = shift;
    my %opts = @_;
    if ( ! $opts{do_not_recurse_further}) {
        # warn "storing old statements in the obsolescence model";
        $opts{do_not_recurse_further} = 1;
        $self->export_to_model( $self->obsolescence_model, %opts);
        # warn "done storing old statements in the obsolescence model";
        return $self->$orig( $model, %opts );
    }
    return $self->$orig( $model, %opts );
};

around '_get_serializer' => sub {
    my $orig = shift;
    my $self = shift;
    my %opts = @_;
    if ($opts{format} && $opts{format} eq 'sparqlu') {
        my $serializer_opts = $opts{serializer_opts} || {};
        $serializer_opts->{delete_model} = $self->obsolescence_model;
        $opts{serializer_opts} = $serializer_opts;
    }
    return $self->$orig( %opts );
};

1;
=head1 AUTHOR

Konstantin Baierer (<kba@cpan.org>)

=head1 SEE ALSO

=over 4

=item L<MooseX::Semantic|MooseX::Semantic>

=back

=cut

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

