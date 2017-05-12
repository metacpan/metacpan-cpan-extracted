package MySQL::Partition::Handle;
use strict;
use warnings;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/mysql_partition statement/],
    rw  => [qw/_executed/],
);

sub execute {
    my $self = shift;
    die 'statement is already executed' if $self->_executed;

    my $mysql_partition = $self->mysql_partition;
    my $sql             = $self->statement;
    if ($mysql_partition->verbose || $mysql_partition->dry_run) {
        printf "Following SQL statement to be executed%s.\n", ($mysql_partition->dry_run ? ' (dry-run)' : '');
        print "$sql\n";
    }
    if (!$mysql_partition->dry_run) {
        $mysql_partition->dbh->do($sql);
        print "done.\n" if $mysql_partition->verbose;
        delete $mysql_partition->{partitions};
    }
    $self->_executed(1);
}

1;
__END__

=encoding utf-8

=head1 NAME

MySQL::Partition::Handle - handler for MySQL::Partition

=head1 SYNOPSIS

    use MySQL::Partition;
    my $dbh = DBI->connect(@connect_info);
    my $list_partition = MySQL::Partition->new(...);

    # prepare_* method returns MySQL::Partition::Handle object
    my $handle = $list_partition->prepare_add_partitions('p4' => 4);
    print $handle->statement;
    $handle->execute;

=head1 DESCRIPTION

MySQL::Partition::Handle is module of handler for MySQL::Partition.

=head1 INTERFACE

=head2 Methods

=head3 C<< my $sql = $handle->statement >>

Returns a SQL statement to be executed.

=head3 C<< $handle->execute >>

Execute the SQL.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
