package Test::DBChanges::Role::DBIC;
use Moo::Role;
use Types::Standard qw(HasMethods);
use namespace::autoclean;

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: adapt DBChanges to DBIC


has schema => ( is => 'ro', required => 1, isa => HasMethods[qw(storage resultset)] );
sub _storage { shift->schema->storage }
sub _db_do {
    my ($self,$sql,@args) = @_;
    $self->_storage->dbh_do(
        sub {
            my (undef,$dbh) = @_;
            # silence "NOTICE: the relation already exists"
            local $dbh->{PrintWarn} = 0;
            $dbh->do($sql,{},@args);
        }
    );
}

sub _db_fetch {
    my ($self,$sql,@args) = @_;
    return $self->_storage->dbh_do(
        sub {
            my (undef,$dbh) = @_;
            return $dbh->selectall_arrayref($sql, { Slice => {} }, @args);
        }
    );
}

sub _table_and_factory_for_source {
    my ($self, $source_name) = @_;

    # source names are resultset names, and we inflate the result of
    # _db_fetch into row objects

    my $rs = $self->schema->resultset($source_name);
    my $table_name = $rs->result_source->name;

    return ($table_name, sub { $rs->new_result(shift) } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Role::DBIC - adapt DBChanges to DBIC

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

This role provides a C<schema> attribute, whose value should be a L<<
C<DBIx::Class::Schema> >> instance. Using this role you can refer to
resultset names instead of table names.

=head1 ATTRIBUTES

=head2 C<schema>

Required, the DBIC schema to track changes on.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
