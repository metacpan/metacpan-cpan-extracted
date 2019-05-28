package Test::DBChanges::ChangeSet;
use Moo;
use 5.024;
use Types::Standard qw(HashRef ArrayRef);
use Test::DBChanges::TableChangeSet;
use namespace::autoclean;
our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: set of changes to DB tables


has table_source_map => ( is => 'ro', required => 1, isa => HashRef );
has _raw_changes => ( is => 'ro', required => 1, isa => ArrayRef[HashRef],
                      init_arg => 'raw_changes' );

has _raw_changes_for_table => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;

        my %changes_for_table;
        for my $change ($self->_raw_changes->@*) {
            push $changes_for_table{$change->{table_name}}->@*,
                $change;
        }

        return \%changes_for_table;
    },
);

has changed_tables => (
    is => 'lazy',
    builder => sub { return [ sort keys shift->_raw_changes_for_table->%* ] },
);

has _changes_for_source => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;
        my %changes_for_source;

        for my $table_name (keys $self->table_source_map->%*) {
            my $factory = $self->table_source_map->{$table_name}{factory};
            my $source_name = $self->table_source_map->{$table_name}{name};
            $changes_for_source{$source_name} = Test::DBChanges::TableChangeSet->new({
                table_name => $table_name,
                source_name => $source_name,
                factory_sub => $factory,
                raw_changes => $self->_raw_changes_for_table->{$table_name} // [],
            });
        }

        return \%changes_for_source;
    },
);



sub changes_for_source {
    my ($self,$source_name) = @_;
    return $self->_changes_for_source->{$source_name};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::ChangeSet - set of changes to DB tables

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    my $dbchanges = Test::DBChanges::Pg->new({
        dbh => $dbh,
        source_names => [qw(things ledger)],
    });

    # later:
    my $changeset = $dbchanges->changeset_for_code(sub { do_something($dbh) });

    for my $row ($changeset->changes_for_source('things')->inserted_rows->@*) {
       # $row is a hashref with the inserted data
    }

=head1 DESCRIPTION

Instances of this class are instantiated by a L<<
C<Test::DBChanges::*> >> class. They contain all the data needed to
construct hashrefs or objects for each inserted / updated / deleted
row in all tracked tables.

=head1 ATTRIBUTES

=head2 C<changed_tables>

List of strings, the names of the tables that saw changes.

=head1 METHODS

=head2 C<changes_for_source>

    my $changes = $changeset->changes_for_source('things');

Given a source name (that was in the C<source_names> attribute
of the C<DBChanges> instance that build this object), returns a L<<
C<Test::DBChanges::TableChangeSet> >> instance containing the changes
for the corresponding table.

If you pass in a wrong (or just not tracked) name, you get C<undef>.

=for Pod::Coverage table_source_map

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
