package SQL::Executor::Iterator;
use strict;
use warnings;

use Class::Accessor::Lite (
    ro => ['sth',  'executor', 'table_name', 'select_id'],
);

=head1 NAME

SQL::Executor::Iterator - iterator for SQL::Executor

=head1 SYNOPSIS

  use DBI;
  use SQL::Executor;
  my $dbh = DBI->connect($dsn, $id, $pass);
  my $ex = SQL::Executor->new($dbh);
  #
  my $itr= $ex->select_named('SELECT id, value1 FROM SOME_TABLE WHERE value2 = :arg1', { arg1 => 'aaa' });


=head1 METHODS

=cut

=head2 new($sth, $table_name, $executor, $select_id)

$sth: L<DBI>'s statement handler
$table_name: table name
$executor: SQL::Executor object
$select_id: select_id(UUID) this is used for to make Row object uniquely

=cut

sub new {
    my ($class, $sth, $table_name, $executor, $select_id) = @_;

    my $self = {
        sth        => $sth,
        table_name => $table_name,
        executor   => $executor,
        select_id  => $select_id,
    };
    bless $self, $class;
}


=head2 next

return row hashref by default. if specified callback or table_callback option is specified in SQL::Executor::new(),
callback will be called.

=cut

sub next {
    my ($self) = @_;
    my $sth = $self->sth;
    my $row = $sth->fetchrow_hashref;
    if( !defined $row ) {
        $sth->finish;
        return;
    }
    my $callback = $self->executor->callback;
    if( defined $callback ) {
        return $callback->($self->executor, $row, $self->table_name, $self->select_id);
    }
    return $row;
}



1;
__END__



=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi {at} cpan.orgE<gt>

=head1 SEE ALSO

L<SQL::Executor>, L<DBI>, L<SQL::Maker>, L<DBIx::Simple>

Codes for named placeholder is taken from L<Teng>'s search_named.

=head1 LICENSE

Copyright (C) Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
