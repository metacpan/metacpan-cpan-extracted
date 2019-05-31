package Test::DBChanges::Role::Triggers;
use Moo::Role;
use 5.024;
use namespace::autoclean;

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: fetches data recorded by triggers


sub db_item_prefix { 'test_dbchanges' }
sub _table_name { shift->db_item_prefix . '_table' }

requires qw(_db_fetch maybe_prepare_db decode_recorded_data _make_changeset);

sub changeset_for_code {
    my ($self,$coderef) = @_;

    $self->maybe_prepare_db;
    my $table_name = $self->_table_name;

    my $last_id = $self->_db_fetch("SELECT MAX(id) AS id FROM ${table_name}")
        ->[0]{id} // 0;

    $coderef->();

    my $rows = $self->_db_fetch(<<"SQL",$last_id);
SELECT *
FROM ${table_name}
WHERE id > ?
ORDER BY id ASC
SQL

    $_->{data} = $self->decode_recorded_data($_->{data})
        for $rows->@*;

    return $self->_make_changeset($rows);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Role::Triggers - fetches data recorded by triggers

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

Classes that implement change tracking by means of triggers that store
data into a dedicated table should consume this role.

=head1 METHODS

=head2 C<db_item_prefix>

Returns a string to be used to prefix the names of all tables and
triggers.

=for Pod::Coverage changeset_for_code

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
