package MySQL::Workbench::DBIC::FakeDBIC;

package
  DBIx::Class::Schema;

# ABSTRACT: provide some DBIx::Class method stubs when DBIx::Class is not installed 

sub DBIx::Class::Schema::load_namespaces {}

package
   DBIx::Class;

sub DBIx::Class::load_components {}
sub DBIx::Class::table {}
sub DBIx::Class::add_columns {}
sub DBIx::Class::set_primary_key {}
sub DBIx::Class::belongs_to {}
sub DBIx::Class::has_many {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MySQL::Workbench::DBIC::FakeDBIC - provide some DBIx::Class method stubs when DBIx::Class is not installed 

=head1 VERSION

version 0.08

=head1 DESCRIPTION

C<MySQL::Workbench::DBIC> tries to load the schema class to determine what version number
should be used. This fails when L<DBIx::Class> is not installed. So we fake it.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
