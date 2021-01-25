# Copyright (c) 2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
package Net::OBS::Client::Project;

use Moose;
use XML::Structured;
use Carp;

with 'Net::OBS::Client::Roles::BuildStatus';
with 'Net::OBS::Client::Roles::Client';

=head1 NAME

Net::OBS::Client::Project

=head1 SYNOPSIS

  use Net::OBS::Client::Project;

  my $obj = Net::OBS::Client::Project->new(
    apiurl     => $apiurl,
    name       => $project,
    use_oscrc  => 0,
  );

  my $res = $obj->fetch_resultlist(package => $package);


=head1 ATTRIBUTES

=head2 resultlist

=cut

has resultlist => (
  is      => 'rw',
  isa     => 'HashRef',
  lazy    => 1,
  default => \&fetch_resultlist,
);

=head1 SUBROUTINES/METHODS

=head2 fetch_resultlist - fetch build result code and other information for a project

=cut

# /build/OBS:Server:Unstable/_result
sub fetch_resultlist {
  my ($self, %opts) = @_;

  my $api_path = '/build/'.$self->name.'/_result';
  my @ext;

  while (my ($k,$v) = each %opts) { push @ext, "$k=$v"; }

  $api_path .= q{?} . join q{&}, @ext if @ext;
  my $list = $self->request(GET=>$api_path);
  my $data = XMLin($self->dtd->resultlist, $list);

  $self->resultlist($data);

  return $data;
}

=head2 code - get current build result code

  my $code = $obj->code($repo, $arch);

  print "build succeeded\n" if ($code eq 'succeeded');

=cut

sub code {
  my ($self, @args) = @_;
  my $ra   = $self->_get_repo_arch(@args);
  return $ra->{code};
}

=head2 dirty -

  my $dirty = $obj->dirty($repo, $arch);

  print "Project is in a clean state - no outstanding actions\n" if !$dirty;

=cut

sub dirty {
  my ($self, @args) = @_;

  my $ra = $self->_get_repo_arch(@args);

  return ( exists $ra->{dirty} && $ra->{dirty} eq 'true' ) ? 1 : 0;
}

sub _get_repo_arch {
  my ($self, $repo, $arch) = @_;

  $self->repository($repo) if $repo;
  $self->arch($arch)       if $arch;

  croak("repository and arch needed to get code\n")
    if ( !$self->repository || !$self->arch );

  foreach my $result ( @{$self->resultlist->{result}} ) {
    return $result
      if ( $result->{repository} eq $self->repository
      && $result->{arch} eq $self->arch );
  }

  croak("combination of repository and arch not found\n");
}

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Frank Schreiner, C<< <frank at samaxi.de> >>

=head1 SEE ALSO

You can find some examples in the L<contrib/> directory


=head1 COPYRIGHT

Copyright 2016 Frank Schreiner <frank@samaxi.de>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
