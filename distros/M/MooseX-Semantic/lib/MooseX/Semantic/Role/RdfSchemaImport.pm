package MooseX::Semantic::Role::RdfSchemaImport;
use MooseX::Role::Parameterized;

parameter import_opts => (
    isa =>  'HashRef',
    required => 1,
);

role {
    my $p = shift;

    my %import_opts = %{$p->import_opts};

    around BUILDARGS => sub {
        my $orig  = shift;
        my $class = shift;
        MooseX::Semantic::Util::SchemaImport->initialize_one_class_from_model( %import_opts );
        $class->$orig(@_);
    };
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

