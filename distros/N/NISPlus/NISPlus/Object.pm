# $Id: Object.pm,v 1.5 1997/02/07 11:32:41 rik Exp $

BEGIN { require Net::NISPlus; };

package Net::NISPlus::Object;

sub print
{
  my($me) = shift;

  Net::NISPlus::nis_print_object($me->object);
}

sub object
{
  my($me) = shift;

  if (! $me->{'object'})
  {
    if ( !($me->{'object'} = Net::NISPlus::nis_lookup($me->{'full_path'})))
    {
      Net::NISPlus::prwarning("can't look up object $me->{'full_path'}: ",
        Net::NISPlus::nis_sperrno(Net::NISPlus::last_error));
    }
  }
  $me->{'object'};
}

sub type
{
  my ($me) = shift;

  Net::NISPlus::obj_type($me->object);
}

1;
