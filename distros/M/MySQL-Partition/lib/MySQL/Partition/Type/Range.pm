package MySQL::Partition::Type::Range;
use strict;
use warnings;

use parent 'MySQL::Partition';
use Class::Accessor::Lite (
    ro => [qw/catch_all_partition_name/],
);

__PACKAGE__->_grow_methods(qw/add_catch_all_partition reorganize_catch_all_partition/);

sub _build_add_catch_all_partition_sql {
    my $self = shift;
    die "catch_all_partition_name isn't specified" unless $self->catch_all_partition_name;

    sprintf 'ALTER TABLE %s ADD PARTITION (%s)',
        $self->table, $self->_build_partition_part($self->catch_all_partition_name, 'MAXVALUE');
}

sub _build_reorganize_catch_all_partition_sql {
    my ($self, @args) = @_;
    die "catch_all_partition_name isn't specified" unless $self->catch_all_partition_name;

    sprintf 'ALTER TABLE %s REORGANIZE PARTITION %s INTO (%s, PARTITION %s VALUES LESS THAN (MAXVALUE))',
        $self->table, $self->catch_all_partition_name, $self->_build_partition_parts(@args), $self->catch_all_partition_name;
}

sub _build_partition_part {
    my ($self, $partition_name, $partition_description) = @_;

    my $comment;
    if (ref $partition_description && ref $partition_description eq 'HASH') {
        $comment = $partition_description->{comment};
        $comment =~ s/'//g if defined $comment;
        $partition_description = $partition_description->{description};
        die 'no partition_description is specified' unless $partition_description;
    }

    if ($partition_description !~ /^[0-9]+$/ && $partition_description ne 'MAXVALUE' && $partition_description !~ /\(/) {
        $partition_description = "'$partition_description'";
    }
    my $part = sprintf 'PARTITION %s VALUES LESS THAN (%s)', $partition_name, $partition_description;
    $part .= " COMMENT = '$comment'" if $comment;
    $part;
}

1;
__END__

=encoding utf-8

=head1 NAME

MySQL::Partition::Type::Range - subclass of MySQL::Partition for range partition

=head1 DESCRIPTION

Subclass of MySQL::Partition for manipulating range partitions.

=head1 INTERFACE

This class has extra constructor options and methods in other than base class.

=head2 Constructor Options

=over

=item C<catch_all_partition_name>

Catch-all partition name for the statement like C<< PARTITION pmax VALUES LESS THAN MAXVALUE >>.
C<pmax> is catch-all partition name in the above case.

=back

=head2 Methods

=head3 C<< $range_partition->add_catch_all_partition >>

Add catch all partition.

C<prepare_add_catch_all_partition> method is also available.

=head3 C<< $range_partition->reorganize_catch_all_partition >>

The MySQL table which have catch-all partition can't be added new partition.
In this case, we can use C<< ALTER TABLE REORGANIZE PARTITION ... >> and this method
issuance and execute the SQL statements.

C<prepare_reorganize_catch_all_partition> method is also available.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
