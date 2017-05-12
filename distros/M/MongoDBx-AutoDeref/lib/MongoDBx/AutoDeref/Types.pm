package MongoDBx::AutoDeref::Types;
BEGIN {
  $MongoDBx::AutoDeref::Types::VERSION = '1.110560';
}

#ABSTRACT: Types specific for MongoDBx::AutoDeref

use warnings;
use strict;

use MooseX::Types -declare => [qw/ DBRef /];
use MooseX::Types::Structured(':all');
use MooseX::Types::Moose(':all');



subtype DBRef,
    as Dict
    [
        '$db' => Str,
        '$ref' => Str,
        '$id' => class_type('MongoDB::OID')
    ];

1;


=pod

=head1 NAME

MongoDBx::AutoDeref::Types - Types specific for MongoDBx::AutoDeref

=head1 VERSION

version 1.110560

=head1 TYPES

=head2 DBRef

    Dict
    [
        '$db' => Str,
        '$ref' => Str,
        '$id' => class_type('MongoDB::OID')
    ]

For MongoDBx::AutoDeref to function, it has to operate with the codified
database reference. This type constraint checks that the hash has the necessary
fields.  One slight variation from the mongodb docs is that the $db field is
required.  This might change in the future, but it certainly doesn't hurt to be
explicit.

http://www.mongodb.org/display/DOCS/Database+References

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
