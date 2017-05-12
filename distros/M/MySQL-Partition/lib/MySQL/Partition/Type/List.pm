package MySQL::Partition::Type::List;
use strict;
use warnings;

use parent 'MySQL::Partition';

sub _build_partition_part {
    my ($self, $partition_name, $partition_description) = @_;

    my $comment;
    if (ref $partition_description && ref $partition_description eq 'HASH') {
        $comment = $partition_description->{comment};
        $comment =~ s/'//g if defined $comment;
        $partition_description = $partition_description->{description};
        die 'no partition_description is specified' unless $partition_description;
    }
    my $part = sprintf 'PARTITION %s VALUES IN (%s)', $partition_name, $partition_description;
    $part .= " COMMENT = '$comment'" if $comment;
    $part;
}

1;
__END__

=encoding utf-8

=head1 NAME

MySQL::Partition::Type::List - subclass of MySQL::Partition for list partition

=head1 DESCRIPTION

Subclass of MySQL::Partition for manipulating list partitions.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
