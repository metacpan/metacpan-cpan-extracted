package Net::Amazon::EC2::Volume;
$Net::Amazon::EC2::Volume::VERSION = '0.36';
use Moose;

=head1 NAME

Net::Amazon::EC2::Volume

=head1 DESCRIPTION

A class representing a volume

=head1 ATTRIBUTES

=over

=item volume_id (required)

The ID of the volume.

=item size (required)

The size, in GiB (1GiB = 2^30 octects)

=item snapshot_id (optional)

The ID of the snapshot which this volume was created from (if any).

=item zone (required)

The availability zone the volume was creared in.

=item status (required)

The volume's status.

=item create_time (required)

The time the volume was created.

=item volume_type (optional)

The volume type.

=item iops (optional)

The number of I/O operations per second (IOPS) that the volume
supports (only applies to volumes with a volume_type of io1).

=item attachments (optional)

An array ref of Net:Amazon::EC2::Attachment objects.

=item tag_set (optional)

The associated tags (key:value) of the specified volume.

=back

=cut

has 'volume_id'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'size'			=> ( is => 'ro', isa => 'Str', required => 1 );
has 'snapshot_id'	=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'zone'			=> ( is => 'ro', isa => 'Str', required => 1 );
has 'status'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'create_time'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'volume_type'       => ( is => 'ro', isa => 'Str', default => 'standard');
has 'iops'              => ( is => 'ro', isa => 'Maybe[Int]');
has 'encrypted'         => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'attachments'	=> ( is => 'ro', isa => 'Maybe[ArrayRef[Net::Amazon::EC2::Attachment]]', required => 0 );
has 'tag_set'              => ( is => 'ro', isa => 'Maybe[ArrayRef[Net::Amazon::EC2::TagSet]]', required => 0 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <cpan@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2010 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;
