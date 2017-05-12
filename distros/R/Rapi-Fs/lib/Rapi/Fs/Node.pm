package Rapi::Fs::Node;

use strict;
use warnings;

# ABSTRACT: Base class for File/Dir/Symlink objects

use Moo;
use Types::Standard qw(:all);

use DateTime;

has 'driver', is => 'ro', isa => ConsumerOf['Rapi::Fs::Role::Driver'], required => 1;
has 'path',   is => 'ro', isa => Str, required => 1;
has 'name',   is => 'ro', isa => Str, required => 1;

sub is_dir   { 0 }
sub is_link  { 0 }
sub is_file  { 0 }
sub subnodes { [] }

# Arbitrary container reserved for the driver to persist/cache data associated
# with this node object. What this will hold, if anything, is up to the driver
# and is intended for internal use by the driver only
has 'driver_stash', is => 'ro', isa => HashRef, default => sub {{}};

sub _has_attr {
  my $attr = shift;
  has $attr, is => 'rw', isa => Maybe[Str], lazy => 1,
  default => sub {
    my $self = shift;
    $self->driver->call_node_get( $attr => $self )
  }, @_
}

_has_attr 'mtime',       is => 'ro', isa => Int;
_has_attr 'parent_path', is => 'ro', isa => Maybe[Str];
_has_attr 'parent',      is => 'ro', isa => Maybe[InstanceOf['Rapi::Fs::Dir']];

has 'mtime_dt', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $epoch = $self->mtime or return undef;
  DateTime->from_epoch( epoch => $epoch, time_zone => 'local' )
}, isa => Maybe[InstanceOf['DateTime']];

has 'ctime_dt', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $epoch = $self->ctime or return undef;
  DateTime->from_epoch( epoch => $epoch, time_zone => 'local' )
}, isa => Maybe[InstanceOf['DateTime']];

has 'atime_dt', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $epoch = $self->atime or return undef;
  DateTime->from_epoch( epoch => $epoch, time_zone => 'local' )
}, isa => Maybe[InstanceOf['DateTime']];


# These are extra, *optional* attrs which might be available in driver and/or set by user:
_has_attr $_ for qw(
  iconCls
  cls
  view_url
  ctime
  atime
  hidden
  readable_file
);


1;

__END__

=head1 NAME

Rapi::Fs::Node - Base class for File/Dir/Symlink objects

=head1 DESCRIPTION

This is the base class for all node objects used by <Rapi::Fs>. This class is used internally and 
should not need to be instantiated directly.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Fs>

=item * 

L<RapidApp>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

