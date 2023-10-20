package Mojo::IOLoop::ReadWriteProcess::CGroup;

use Mojo::Base -base;
use Mojo::File 'path';

use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;
use Mojo::IOLoop::ReadWriteProcess::CGroup::v2;
use File::Spec::Functions 'splitdir';

our @EXPORT_OK = qw(cgroupv2 cgroupv1);
use Exporter 'import';

use constant CGROUP_FS => $ENV{MOJO_CGROUP_FS} // '/sys/fs/cgroup';
use constant DEBUG     => $ENV{MOJO_PROCESS_DEBUG};

has '_vfs' => sub { CGROUP_FS() };

has [qw(name parent)];

sub cgroupv2 { Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new(@_)->create }
sub cgroupv1 { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new(@_)->create }

sub from {
  my ($self, $string) = @_;
  my $g = $self->_vfs;
  $string =~ s/$g//;
  my @p   = splitdir($string);
  my $pre = substr $string, 0, 1;
  shift @p if $pre eq '/';
  my $name = shift @p;
  return $_[0]->new(name => $name, parent => path(@p));
}

sub _cgroup {
  path($_[0]->parent
    ? path($_[0]->_vfs, $_[0]->name // '', $_[0]->parent)
    : path($_[0]->_vfs, $_[0]->name // ''));
}

sub create { $_[0]->_cgroup->make_path unless -d $_[0]->_cgroup; $_[0] }

# TODO: Make sure there aren't pid belonging to cgroup before removing
# This is done in Container class, but we might want to warn in case this is hit
sub remove { rmdir $_[0]->_cgroup->to_string }    #->remove_tree() }

sub child {
  return $_[0]->new(
    name   => $_[0]->name,
    parent => $_[0]->parent ? path($_[0]->parent, $_[1]) : $_[1])->create;
}

sub exists { -d $_[0]->_cgroup }

sub _append { my $h = $_[0]->_cgroup->child($_[1])->open('>>'); print $h pop() }
sub _write  { my $h = $_[0]->_cgroup->child($_[1])->open('>');  print $h pop() }

sub _flag {
  my $f = pop;
  my $h = $_[0]->_cgroup->child($_[1])->open('>');
  print $h ($f == 0 ? 0 : 1);
}

sub _appendln  { shift->_append(shift() => pop() . "\n") }
sub _list      { my $c = shift->_cgroup->child(pop); $c->slurp if -e $c }
sub _listarray { split(/\n/, shift->_list(@_)) }

sub _contains {
  my $p = pop;
  my $i = pop;
  grep { $p eq $_ } shift->_listarray($i);
}

sub _setget {
  $_[2]
    ? shift->_cgroup->child($_[0])->spew($_[1])
    : shift->_cgroup->child($_[0])->slurp;
}

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup - Base object for CGroups implementations.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup->new( name => "test" );

    $cgroup->create;
    $cgroup->exists;
    my $child = $cgroup->child('bar');

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
