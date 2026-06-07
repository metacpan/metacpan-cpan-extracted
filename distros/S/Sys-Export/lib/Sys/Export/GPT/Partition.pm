package Sys::Export::GPT::Partition;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Describes a partition entry for a GPT partition table

use v5.26;
use warnings;
use experimental qw( signatures );
use parent 'Sys::Export::Extent';


sub type($self, @v) { @v? ($self->{type}= $v[0]) : $self->{type} }
sub guid($self, @v) { @v? ($self->{guid}= $v[0]) : $self->{guid} }
sub flags($self, @v) { @v? ($self->{flags}= $v[0]) : $self->{flags} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::GPT::Partition - Describes a partition entry for a GPT partition table

=head1 DESCRIPTION

GPT entries are composed of Type GUID, Unique GUID, Starting LBA, Ending LBA, Flags, and
partition Name.  This object inherits C<start_lba> and C<end_lba> from L<Sys::Export::Extent>
which are actually setting C<device_offset> and C<size>.  As a result, it is not possible to
set C<end_lba> before C<start_lba>.

=head1 CONSTRUCTORS

=head2 new

  $partition= Sys::Export::GPT::Partition->new(%attrs);

=head2 coerce

  $partition= Sys::Export::GPT::Partition->new($x);

If C<$x> is a hashref, construct a new Partition object.  If C<$x> is already a partition
object, return it.

=head1 ATTRIBUTES

=head2 name

Unicode string label for the partition.

=head2 type

The GUID of the type of the partition.

=head2 guid

A GUID unique to this partition.

=head2 start_lba

See L<Sys::Export::Extent/start_lba>.

=head2 end_lba

See L<Sys::Export::Extent/end_lba>.  Note that you must set start_lba before end_lba.

=head2 flags

Bitwise-or of flags.

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
