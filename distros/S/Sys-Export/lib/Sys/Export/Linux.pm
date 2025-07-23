package Sys::Export::Linux;

# ABSTRACT: Export subsets of a Linux system
our $VERSION = '0.001'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use parent 'Sys::Export::Unix';


sub add_passwd($self, %options) {
   # If the dst_userdb hasn't been created, create it by filtering the src_userdb by which
   # group and user ids have been seen during the export.
   my $db= $self->dst_userdb;
   unless ($db) {
      $db= Sys::Export::Unix::UserDB->new(
         auto_import => ($self->{src_userdb} //= $self->_build_src_userdb),
      );
      $db->group($_) for keys $self->dst_gid_used->%*;
      $db->user($_) for keys $self->dst_uid_used->%*;
   };
   $db->save($self);
   $self;
}


sub add_localtime($self, $tz_name) {
   ...
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Linux - Export subsets of a Linux system

=head1 SYNOPSIS

  use Sys::Export::Linux;
  my $exporter= Sys::Export::Linux->new(
    src => '/', dst => '/initrd'
  );
  $exporter->add('bin/busybox');
  $exporter->add_passwd;
  $exporter->add_localtime("UTC");

=head1 DESCRIPTION

This object extends L<Sys::Export::Unix> with Linux-specific helpers and special cases.

See C<Sys::Export::Unix> for the list of core attributes and methods.

=head1 METHODS

=head2 add_passwd

  $exporter->add_passwd; # no options yet

This method writes the Linux password files ( C<< /etc/passwd >>, C<< /etc/group >>,
C<< /etc/shadow >> ) either according to the contents of L<Sys::Export::Unix/dst_userdb>
(if you used name-based exports) or according to L<Sys::Export::Unix/src_userdb> filtered by
L<Sys::Export::Unix/dst_uid_used> if C<dst_userdb> is not defined.

In the first pattern, you've either pre-specified the C<dst_userdb> users, or built it lazily
as you exported files.  The C<dst_userdb> contains the complete contents of C<passwd>, C<group>,
and C<shadow> and this method simply generates and adds those files.

In the second pattern, you want the destination userdb to be a subset of the source userdb
according to which UIDs and GIDs were actually used.

If you actually just want to copy the entire source user database files, you could just call

  $exporter->add(qw( /etc/passwd /etc/group /etc/shadow ));

so that pattern doesn't need a special helper method.

=head2 add_localtime

  $exporter->add_localtime($tz_name);

Generate the symlink in C</etc/localtime>, *or* export the timezone file directly to that path
if the system image lacks C</usr/local/zoneinfo>.

Linux uses a symlink at C</etc/localtime> to point to a compiled zoneinfo file describing the
current time zone.  You can simply export this symlink, but if you are building a minimal
system image (like initrd) you might not be exporting the timezone database at
C</usr/local/zoneinfo>.  In that case, you want the single timezone file copied to
C</etc/localtime>.

This method looks for the zone file in your destination filesystem, and if not found there, it
looks in the source filesystem, and if not there either, it checks the host filesystem.  If it
can't find this timezone in any of those locations, it dies.

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
