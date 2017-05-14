# $Id: Table.pm,v 1.2 1995/07/15 12:39:06 rik Exp $

require Net::NIS;

package Net::NIS::Table;

sub new
{
  my($pkg, $map, $domain) = @_;
  $domain = Net::NIS::yp_get_default_domain() if ! $domain;

  $self->{'map'} = $map;
  $self->{'domain'} = $domain;
  
  bless $self;
}


sub list
{
  my ($me) = shift;
  my ($value);

  ($me->{'status'}, $value) = Net::NIS::yp_all($me->{'domain'}, $me->{'map'});

  return $value;
}


sub match
{
  my ($me, $key) = @_;
  my ($value);

  ($me->{'status'}, $value) =
    Net::NIS::yp_match($me->{'domain'}, $me->{'map'}, $key);

  return $value;
}


sub search
{
  my ($me, $srch) = @_;
  my ($value, %ret);

  ($me->{'status'}, $value) = Net::NIS::yp_all($me->{'domain'}, $me->{'map'});

  foreach (grep(/$srch/, keys %{$value})) { $ret{$_} = $value->{$_}; };
  return \%ret;
}


sub status
{
  my ($me) = shift;

  $me->{'status'};
}

1;
__END__
