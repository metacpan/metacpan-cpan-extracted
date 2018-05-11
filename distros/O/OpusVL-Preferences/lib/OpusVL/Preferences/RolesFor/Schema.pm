package OpusVL::Preferences::RolesFor::Schema;

=head1 SYNOPSIS

This allows for our preferences to be inserted into an existing schema and make use of the existing
connection details.  

    # in your schema class.
    with 'OpusVL::Preferences::RolesFor::Schema';
    __PACKAGE__->setup_preferences_schema;


=head1 METHODS

=head2 setup_preferences_schema


=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

use Moose::Role;

sub setup_preferences_schema
{
    my $package = shift;
    $package->load_namespaces(
        result_namespace => '+OpusVL::Preferences::Schema::Result',
        resultset_namespace => '+OpusVL::Preferences::Schema::ResultSet',
    );
}



1;
