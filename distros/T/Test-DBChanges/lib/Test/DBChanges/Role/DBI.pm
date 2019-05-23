package Test::DBChanges::Role::DBI;
use Moo::Role;
use Types::Standard qw(HasMethods);
use namespace::autoclean;

our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: adapt DBChanges to DBI


has dbh => ( is => 'ro', required => 1, isa => HasMethods[qw(do selectall_arrayref)] );

sub _db_do {
    my ($self,$sql,@args) = @_;
    my $dbh = $self->dbh;
    # silence "NOTICE: the relation already exists"
    local $dbh->{PrintWarn} = 0;
    $dbh->do($sql,{},@args);
}

sub _db_fetch {
    my ($self,$sql,@args) = @_;
    return $self->dbh->selectall_arrayref($sql, { Slice => {} }, @args);
}

sub _table_and_factory_for_source {
    my ($self,$source_name) = @_;

    # source names are table names, and we don't transform the result
    # of _db_fetch
    return ( $source_name, sub { return @_ } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Role::DBI - adapt DBChanges to DBI

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

Classes that talk directly to DBI should consume this role. It
provides a C<dbh> attribute, whose value should be a database handle
as returned by C<< DBI->connect >>.

=head1 ATTRIBUTES

=head2 C<dbh>

Required, the database handle to track changes on.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
