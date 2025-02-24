package MySQL::Workbench::DBIC::FakeDBIC;

# ABSTRACT: provide some DBIx::Class method stubs when DBIx::Class is not installed 

use strict;
use warnings;


package
  DBIx::Class::Schema;

use strict;
use warnings;

no warnings 'redefine';

*DBIx::Class::Schema::load_namespaces = sub {};


package
   DBIx::Class;

use strict;
use warnings;

*DBIx::Class::load_components = sub{};
*DBIx::Class::table = sub {};
*DBIx::Class::add_columns = sub{};
*DBIx::Class::set_primary_key = sub{};
*DBIx::Class::belongs_to = sub{};
*DBIx::Class::has_many = sub{};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::DBIC::FakeDBIC - provide some DBIx::Class method stubs when DBIx::Class is not installed 

=head1 VERSION

version 1.21

=head1 DESCRIPTION

C<MySQL::Workbench::DBIC> tries to load the schema class to determine what version number
should be used. This fails when L<DBIx::Class> is not installed. So we fake it.

=head1 METHODS OVERLOADED

=head2 DBIx::Class::Schema

=head3 load_namespaces

=head2 DBIx::Class

=over 4

=item * DBIx::Class::load_components

=item * DBIx::Class::table

=item * add_columns

=item * set_primary_key

=item * belongs_to

=item * has_many

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
