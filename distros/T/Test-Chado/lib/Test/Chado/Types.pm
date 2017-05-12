package Test::Chado::Types;
{
  $Test::Chado::Types::VERSION = 'v4.1.1';
}

use Type::Library
    -base,
    -declare => qw(DBH DbManager BCS Twig Graph GraphT
    HashiFied FixtureManager FixtureLoader DBIC
    MaybeFixtureLoader MaybeDbManager TB TD1 TD2);
use Type::Utils;
use Types::Standard qw/Maybe/;

class_type DBH,
    { class => "DBI::db" };
class_type DBIC,   { class => "DBIx::Class::Schema" };
class_type Twig,   { class => "XML::Twig" };
class_type Graph,  { class => "Graph" };
class_type GraphT, { class => "Graph::Traversal" };
class_type BCS,    { class => "Bio::Chado::Schema" };
class_type FixtureManager,
    { class => "Test::Chado::FixtureManager::Flatfile" };
class_type HashiFied, { class => "Data::Perl::Collection::Hash" };
class_type TD1,       { class => "Test::Builder" };
class_type TD2,       { class => "Test::Tester::Delegate" };
union( TB => [ TD1, TD2 ] );
role_type DbManager,     { role => 'Test::Chado::Role::HasDBManager' };
role_type FixtureLoader, { role => 'Test::Chado::Role::Helper::WithBcs' };
declare MaybeFixtureLoader, as Maybe [FixtureLoader];
declare MaybeDbManager,     as Maybe [DbManager];

1;

__END__

=pod

=head1 NAME

Test::Chado::Types

=head1 VERSION

version v4.1.1

=head1 SYNOPSIS

=over

=item In the consuming class

use Test::Chado::Types qw/BCS FixtureLoader/;
use Moo;
use Test::Chado::FixtureLoader::Preset;

has 'schema' => ( is => 'rw', isa => BCS);

has 'loader' => (
    is => 'rw', 
    isa => FixtureLoader,
    lazy => 1,
    default => sub { return Test::Chado::FixtureLoader::Preset->new }
);

=back

=head1 Types defined

=over

=item DBH

The L<DBI> connect object

=item DbManager

A consuming class that consumes L<Test::Chado::Role::HasDBManager>

=item BCS

L<Bio::Chado::Schema> object

=item Twig

L<XML::Twig> object

=item Graph

L<Graph> object

=item GraphT

L<Graph::Traversal> object

=item HashiFied

L<Data::Perl::Collection::Hash> object

=item FixtureLoader

Class that consumes L<Test::Chado::Role::Helper::WithBcs> role

=item FixtureManager

Class that consumes L<Test::Chado::FixtureManager::Flatfile>

=item DBIC

L<DBIx::Class::Schema> object

=item TB

L<Test::Builder> object

=item MaybeDbManager

To define a type which might or might not hold a L<DbManager> type

=item MaybeFixtureLoader

To define a type which might or might not hold a L<FixtureManager> type

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
