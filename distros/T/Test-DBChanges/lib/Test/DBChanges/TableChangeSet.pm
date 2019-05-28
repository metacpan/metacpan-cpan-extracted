package Test::DBChanges::TableChangeSet;
use Moo;
use 5.024;
use Types::Standard qw(Str CodeRef ArrayRef HashRef);
use namespace::autoclean;

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: set of changes to one DB table


has table_name => ( is => 'ro', required => 1, isa => Str );
has source_name => ( is => 'ro', required => 1, isa => Str );
# how to turn the raw changes into the proper objects that the caller expects
has factory_sub => ( is => 'ro', required => 1, isa => CodeRef );
has _raw_changes => ( is => 'ro', required => 1, isa => ArrayRef[HashRef],
                      init_arg => 'raw_changes' );

has _raw_changes_by_operation => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;

        my %changes_by_operation;
        for my $change ($self->_raw_changes->@*) {
            push $changes_by_operation{$change->{operation}}->@*,
                $change;
        }

        return \%changes_by_operation;
    },
);

sub _make_row_objects {
    my ($self,$operation) = @_;

    return [ map {
        $self->factory_sub->($_->{data})
    } $self->_raw_changes_by_operation->{$operation}->@* ];
}


has inserted_rows => (
    is => 'lazy',
    builder => sub { shift->_make_row_objects('INSERT') },
);


has updated_rows => (
    is => 'lazy',
    builder => sub { shift->_make_row_objects('UPDATE') },
);


has deleted_rows => (
    is => 'lazy',
    builder => sub { shift->_make_row_objects('DELETE') },
);

sub _raw_combined_changes_data {
    my ($self,$key_column) = @_;
    $key_column //= 'id';

    my %data_by_key;
    for my $change ($self->_raw_changes->@*) {
        my $key = $change->{data}{$key_column};
        if ($change->{operation} eq 'INSERT') {
            $data_by_key{$key} = $change->{data};
        }
        elsif ($change->{operation} eq 'UPDATE') {
            my %data = $change->{data}->%*;
            $data_by_key{$key}
                ->@{ keys %data } = values %data;
        }
        elsif ($change->{operation} eq 'DELETE') {
            delete $data_by_key{$key};
        }
    }
    return [ values %data_by_key ];
}


sub combined_rows {
    my ($self,$key_column) = @_;

    return [ map {
        $self->factory_sub->($_)
    } $self->_raw_combined_changes_data($key_column)->@* ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::TableChangeSet - set of changes to one DB table

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

Instances of this class are instantiated by L<<
C<Test::DBChanges::ChangeSet> >>. They contain all the data needed to
construct hashrefs or objects for each inserted / updated / deleted
row in one table.

=head1 ATTRIBUTES

=head2 C<table_name>

Name of the table this set of changes refer to.

=head2 C<source_name>

Name of the I<source> this set of changes refer to. For some DBChanges
classes (e.g. L<< C<Test::DBChanges::Pg::DBIC> >>) the source name is
different from the table name.

=head2 C<inserted_rows>

Arrayref of row objects, one for each newly-inserted row. The
corresponding rows might not be in the database at all: they may have
been deleted, for example.

=head2 C<updated_rows>

Arrayref of row objects, one for each updated row. You may get
multiple objects for the "same" row, one for each "UPDATE" operation.

=head2 C<deleted_rows>

Arrayref of row objects, one for each deleted row. The corresponding
rows are obviously not in the db.

=head2 C<combined_rows>

    my @rows = $table_changeset->combined_rows->@*;

    # same thing
    my @rows = $table_changeset->combined_rows('id')->@*;

    # different primary key column
    my @other_rows = $other_table_changeset->combined_rows('primary')->@*;

If you don't need to know each separate insert / update / delete, but
only care about the resulting rows, you can use this method. It needs
a primary key column (defaults to C<id>) to match different operations
to the "same" row.

=for Pod::Coverage factory_sub

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
