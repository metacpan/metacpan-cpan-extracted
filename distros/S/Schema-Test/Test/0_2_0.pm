package Schema::Test::0_2_0;

use base qw(DBIx::Class::Schema);
use strict;
use warnings;

our $VERSION = 0.02;

__PACKAGE__->load_namespaces;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Schema::Test::0_2_0 - Test schema version 0.2.0.

=head1 SYNOPSIS

 use Schema::Test::0_2_0;

 my $obj = Schema::Test::0_2_0->connect(@connect_info);

 $obj->source('Person');

=head1 DESCRIPTION

Versioned DBIx::Class schema for the C<0.2.0> test layout.

=head1 METHODS

=head2 C<connect>

 my $schema = Schema::Test::0_2_0->connect(@connect_info);

Returns L<DBIx::Class::Schema> instance.

=head2 C<source>

 my $source = $schema->source($source_name);

Returns L<DBIx::Class::ResultSource> instance.

=head1 DEPENDENCIES

L<DBIx::Class::Schema>,
L<Schema::Test>.

=head1 SEE ALSO

=over

=item L<Schema::Test>

Wrapper for selecting schema versions.

=item L<DBIx::Class::Schema>

Base class for the versioned schema package.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Schema-Test>

=head1 AUTHOR

Michal Josef Špaček E<lt>skim@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022-2026 Michal Josef Špaček.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 VERSION

0.02

=cut
