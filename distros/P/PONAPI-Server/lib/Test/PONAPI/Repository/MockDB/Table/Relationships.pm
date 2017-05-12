# ABSTRACT: mock repository - table - Relationships
package Test::PONAPI::Repository::MockDB::Table::Relationships;

use Moose;

extends 'Test::PONAPI::Repository::MockDB::Table';

has REL_ID_COLUMN => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has ONE_TO_ONE => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose; 1

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PONAPI::Repository::MockDB::Table::Relationships - mock repository - table - Relationships

=head1 VERSION

version 0.003001

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
