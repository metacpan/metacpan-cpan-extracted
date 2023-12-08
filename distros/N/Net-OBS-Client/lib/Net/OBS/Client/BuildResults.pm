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
package Net::OBS::Client::BuildResults;

use Moose;
use Net::OBS::Client;
use Net::OBS::Client::DTD;
use XML::Structured;
use Data::Dumper;

with 'Net::OBS::Client::Roles::Client';

=head1 NAME

Net::OBS::Client::BuildResults - fetch binarylist and fileinfo

=head1 SYNOPSIS

  use Net::OBS::Client::BuildResults;

  my $obj = Net::OBS::Client::BuildResults->new(
    apiurl     => $apiurl,
    project    => $project,
    package    => $package,
    repository => $repo,
    arch       => $arch,
  );

  my $bin = $obj->binarylist;

  my $inf = $obj->fileinfo($filename);


=head1 ATTRIBUTES


=head2 project


=head2 package


=head2 repository


=head2 arch


=cut

has project => (
  is  => 'rw',
  isa => 'Str',
);

has repository => (
  is  => 'rw',
  isa => 'Str',
);

has arch => (
  is  => 'rw',
  isa => 'Str',
);

has package => (
  is  => 'rw',
  isa => 'Str',
);

has api_path => (
  is  => 'rw',
  isa => 'Str',
);

=head1 SUBROUTINES/METHODS

=head2 binarylist - fetch list of binary buildresults

 my $bin = $obj->binarylist();

=cut

sub binarylist {
  my ($self) = @_;

  $self->api_path('/build/'
    . join
        q{/},
        $self->project,
        $self->repository,
        $self->arch,
        $self->package,
  );

  my $binarylist = $self->request(GET=>$self->api_path);

  my $dtd = Net::OBS::Client::DTD->new()->binarylist();

  return XMLin($dtd, $binarylist)->{binary};
}

=head2 fileinfo - get detailed information about a specific package

 my $bin = $obj->fileinfo($filename);

=cut

sub fileinfo {
  my ($self, $binary) = @_;

  # /build/OBS:Server:Unstable/images/x86_64/OBS-Appliance-qcow2/obs-server.x86_64-2.5.51-Build6.4.qcow2?view=fileinfo
  #
  $self->api_path('/build/'
    . join
        q{/},
          $self->project,
          $self->repository,
          $self->arch,
          $self->package,
          $binary,
    . '?view=fileinfo'
  );

  my $binarylist = $self->request(GET=>$self->api_path);

  my $dtd = Net::OBS::Client::DTD->new()->fileinfo();

  return XMLin($dtd, $binarylist);
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
