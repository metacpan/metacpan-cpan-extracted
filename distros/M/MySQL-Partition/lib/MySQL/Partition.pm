package MySQL::Partition;
use 5.008001;
use strict;
use warnings;

our $VERSION = "1.0001";

use MySQL::Partition::Handle;

use Module::Load ();
use Class::Accessor::Lite (
    rw      => [qw/dry_run verbose/],
    ro      => [qw/type dbh table expression/],
);

sub dbname {
    my $self = shift;
    exists $self->{dbname} ? $self->{dbname} : $self->{dbname} ||= _get_dbname($self->dbh->{Name});
}

sub new {
    my $class = shift;
    die q[can't call new method directory in sub class] if $class ne __PACKAGE__;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    $args{type} = uc $args{type};

    my ($type) = split /\s+/, $args{type};
    my $sub_class = __PACKAGE__ . '::Type::' . ucfirst( lc $type );
    Module::Load::load($sub_class);
    bless \%args, $sub_class;
}

__PACKAGE__->_grow_methods(qw/create_partitions add_partitions drop_partitions truncate_partitions/);

sub retrieve_partitions {
    my ($self, $table) = @_;

    my $parts = $self->{partitions} ||= do {
        my @parts;
        my $sth = $self->dbh->prepare('
            SELECT
              partition_name
            FROM
              information_schema.PARTITIONS
            WHERE
              table_name       = ? AND
              table_schema     = ? AND
              partition_method = ?
            ORDER BY
              partition_name
        ');
        $sth->execute($self->table, $self->dbname, $self->type);
        while (my $row = $sth->fetchrow_arrayref) {
            push @parts, $row->[0] if defined $row->[0];
        }
        \@parts;
    };
    @$parts;
}

sub is_partitioned {
    my $self = shift;
    $self->retrieve_partitions ? 1 : ();
}

sub has_partition {
    my ($self, $partition_name) = @_;
    grep {$_ eq $partition_name} $self->retrieve_partitions;
}

sub _build_create_partitions_sql {
    my ($self, @args) = @_;

    if ($self->isa('MySQL::Partition::Type::Range') && $self->catch_all_partition_name) {
        push @args, $self->catch_all_partition_name, 'MAXVALUE';
    }
    sprintf 'ALTER TABLE %s PARTITION BY %s (%s) (%s)',
        $self->table, $self->type, $self->expression, $self->_build_partition_parts(@args);
}

sub _build_add_partitions_sql {
    my ($self, @args) = @_;

    sprintf 'ALTER TABLE %s ADD PARTITION (%s)', $self->table, $self->_build_partition_parts(@args);
}

sub _build_partition_parts {
    my ($self, @args) = @_;

    my @parts;
    while (my ($partition_name, $partition_description) = splice @args, 0, 2) {
        push @parts, $self->_build_partition_part($partition_name, $partition_description);
    }
    join ', ', @parts;
}

sub _build_partition_part {
    die 'this is abstruct method';
}

sub _build_drop_partitions_sql {
    my ($self, @partition_names) = @_;

    sprintf 'ALTER TABLE %s DROP PARTITION %s', $self->table, join(', ', @partition_names);
}

sub _build_truncate_partitions_sql {
    my ($self, @partition_names) = @_;

    sprintf 'ALTER TABLE %s TRUNCATE PARTITION %s', $self->table, join(', ', @partition_names);
}

sub _grow_methods {
    my ($class, @methods) = @_;

    for my $method (@methods) {
        my $prepare_method = "prepare_$method";
        my $sql_builder_method   = "_build_${method}_sql";

        no strict 'refs';
        *{$class . '::' . $prepare_method} = sub {
            use strict 'refs';
            my ($self, @args) = @_;
            my $sql = $self->$sql_builder_method(@args);

            return MySQL::Partition::Handle->new(
                statement       => $sql,
                mysql_partition => $self,
            );
        };
        *{$class . '::' . $method} = sub {
            use strict 'refs';
            my ($self, @args) = @_;
            $self->$prepare_method(@args)->execute;
        };
    }
}

sub _get_dbname {
    my $connected_db = shift;

    # XXX can't parse 'host=hoge;database=fuga'
    my ($dbname) = $connected_db =~ m!^(?:(?:database|dbname)=)?([^;]*)!i;
    $dbname;
}

1;
__END__

=encoding utf-8

=head1 NAME

MySQL::Partition - Utility for MySQL partitioning

=head1 SYNOPSIS

    use MySQL::Partition;
    my $dbh = DBI->connect(@connect_info);
    my $list_partition = MySQL::Partition->new(
        dbh        => $dbh,
        type       => 'list',
        table      => 'test',
        expression => 'event_id',
    );
    $list_partition->is_partitioned;
    $list_partition->create_partitions('p1' => 1); # ALTER TABLE test PARTITION BY LIST ...
    $list_partition->has_partition('p1'); # true
    
    $list_partition->add_partitions('p2_3' => '2, 3');
    
    # handle interface
    my $handle = $list_partition->prepare_add_partitions('p4' => 4);
    print $handle->statement;
    $handle->execute;
    
    $list_partition->truncate_partitions('p1');
    $handle = $list_partition->prepare_truncate_partitions('p2_3');
    $handle->execute;
    
    $list_partition->drop_partitions('p1');
    $handle = $list_partition->prepare_drop_partitions('p2_3');
    $handle->execute;

=head1 DESCRIPTION

MySQL::Partition is utility module for MySQL partitions.

This module creates a object for manipulating MySQL partitions.
This is very useful that we no longer write complicated and MySQL specific SQL syntax any more.

=head1 INTERFACE

=head2 Constructor

=head3 C<< my $mysql_partition:MySQL::Partition = MySQL::Partition->new(%args) >>

Create a new object which is subclass of L<MySQL::Partition>.
(L<MySQL::Partition::Type::Range> or L<MySQL::Partition::Type::List>.

Following keys are required in C<%args>.

=over

=item C<< dbh => DBI::db >>

=item C<< table => Str >>

=item C<< type => Str >>

partitioning method. C<< list(?: columns)? >> or C<< range(?: columns)? >>.

If C<list> is specified, C<new> method returns C<MySQL::Partition::Type::List> object.

=item C<< expression => Str >>

partitioning expression. e.g. C<event_id>, C<created_at>, C<TO_DAYS(created_at)>, etc.

=back

=head2 Methods

=head3 C<< my @partition_names = $mysql_partition->retrieve_partitions >>

Returns partition names in the table.

=head3 C<< my $bool = $mysql_partition->is_partitioned >>

Returns the table is partitioned or not.

=head3 C<< my $bool = $mysql_partition->has_partitione($partition_name) >>

Returns the table has a specified partition name or not.

=head2 Methods for manipulating partition

=head3 C<< $mysql_partition->create_partitions($partition_name => $partition_description, [$name => $description, ...]) >>

=head3 C<< $mysql_partition->add_partitions($partition_name => $partition_description, [$name => $description], ...) >>

=head3 C<< $mysql_partition->drop_partitions(@partition_names) >>

=head3 C<< $mysql_partition->truncate_partitions(@partition_names) >>

=head2 Methods for MySQL::Partition::Handle

Each method for manipulating partition has C<prepare_*> method which returns L<MySQL::Partition::Handle> object.

=over

=item C<prepare_create_partitions>

=item C<prepare_add_partitions>

=item C<prepare_drop_partitions>

=item C<prepare_truncate_partitions>

=back

Actually, C<< $mysql_partition->create_partitions(...); >> is a shortcut of following.

    my $handle = $mysql_partition->prepare_create_partitions(...);
    $handle->execute;

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
