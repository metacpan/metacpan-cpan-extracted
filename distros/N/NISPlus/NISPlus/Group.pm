# $Id: Group.pm,v 1.5 1996/11/25 22:04:43 rik Exp $

require Net::NISPlus::Object;

package Net::NISPlus::Group;

@ISA = qw(Net::NISPlus::Object);

sub new
{
  my($name, $path) = @_;
  my($self) = {};

  $path = Net::NISPlus::nis_local_group() if (! $path);

  bless $self;
}

sub DESTROY
{
}
