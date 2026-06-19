package Schema::Test;

use base qw(Schema::Abstract);
use strict;
use warnings;

use File::Share ':all';

our $VERSION = 0.02;

sub _versions_file {
	my $self = shift;

	my $versions_file = dist_file('Schema-Test', 'versions.txt');

	return $versions_file;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Schema::Test - Test schema versions for DBIx::Class.

=head1 SYNOPSIS

 use Schema::Test;

 my $obj = Schema::Test->new(%params);

 $obj->list_versions;
 $obj->schema;
 $obj->version;

=head1 METHODS

=head2 C<new>

 my $schema = Schema::Test->new(%args);

Constructor inherited from L<Schema::Abstract>.
The optional C<version> parameter selects a schema version from
F<share/versions.txt>.

Returns L<Schema::Test> instance.

=head2 C<list_versions>

 my @versions = $schema->list_versions;

Return sorted list of available schema versions.

Returns list of strings.

=head2 C<schema>

 my $schema_class = $schema->schema;

Return DBIx::Class schema class name for the selected version.

Returns string.

=head2 C<version>

 my $version = $schema->version;

Return selected schema version.

Returns string.

=head1 ERRORS

 new():
         Schema version has bad format.
         Cannot load Schema module.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLES

=head2 EXAMPLE1

=for comment filename=schema_test_versions.pl

 use strict;
 use warnings;

 use Schema::Test;

 my $schema = Schema::Test->new(version => '0.3.0');

 print $schema->schema, "\n";
 print $schema->version, "\n";

 # Output:
 # Schema::Test::0_3_0
 # 0.3.0

=head1 DEPENDENCIES

L<File::Share>,
L<Schema::Abstract>.

=head1 SEE ALSO

=over

=item L<Schema::Abstract>

Base class for versioned schema wrappers.

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
