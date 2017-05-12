package OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB;


use Moose::Role;

requires 'load_namespaces';

sub merge_authdb
{
    my $class = shift;
    $class->load_namespaces(
        result_namespace => '+OpusVL::AppKit::Schema::AppKitAuthDB::Result',
        resultset_namespace => '+OpusVL::AppKit::Schema::AppKitAuthDB::ResultSet',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB

=head1 VERSION

version 6

=head1 SYNOPSIS

    with 'OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB';

    __PACKAGE__->merge_authdb;

=head1 DESCRIPTION

The role allows the simple importing of the AppKitAuthDB into your own schema so that you can join
to the objects.  Simply use the role and call merge_authdb (via __PACKAGE__).

=head1 NAME

OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB

=head1 METHODS

=head2 merge_authdb

This loads the results and resultsets from the AppKitAuthDB into your schema.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
