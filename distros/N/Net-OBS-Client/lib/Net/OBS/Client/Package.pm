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
package Net::OBS::Client::Package;

=head1 NAME

Net::OBS::Client::Package - fetch package information

=head1 SYONPSIS

 use Net::OBS::Client::Package;

  my $obj = Net::OBS::Client::Package->new(
    project    => 'OBS:Server:Unstable',
    name       => 'obs-server',
    repository => 'openSUSE_Factory',
    arch       => 'x86_64',
    use_oscrc  => 0,
    apiurl     => 'https://api.opensuse.org/public'
  );

  my $s = $obj->fetch_status();

  print "code: ".$p->code($repo, $arch)."\n";


=cut

use Moose;
use XML::Structured;

# define roles
with "Net::OBS::Client::Roles::BuildStatus";
with "Net::OBS::Client::Roles::Client";

=head1 ATTRIBUTES

=head2 project

=head2 repository

=head2 arch

=head2 details

=cut

has details => (
  is => 'rw',
  isa => 'Str'
);

has _status => (
  is => 'rw',
  isa => 'HashRef',
  lazy => 1,
  default => \&fetch_status
);

=head1 METHODS

=head2 fetch_status -

  my $s = $ojb->fetch_status();

=cut

sub fetch_status {
  my $self = shift;

  my $api_path = join('/',"/build",$self->project,$self->repository,$self->arch,$self->name,"_status");

  my $list = $self->request(GET=>$api_path);

  my $data = XMLin($self->dtd->buildstatus,$list);

  return $data;
}

=head2 code - get package build code

  my $c = $obj->code;

=cut

sub code {
  return $_[0]->_status->{code};
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

