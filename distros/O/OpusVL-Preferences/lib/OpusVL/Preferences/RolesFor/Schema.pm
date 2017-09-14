package OpusVL::Preferences::RolesFor::Schema;


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

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences::RolesFor::Schema

=head1 VERSION

version 0.27

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

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
