package Tcl::pTk::DragDrop::Rect;

our ($VERSION) = ('1.02');

use strict;
use Carp;

# Proxy class which represents sites to the dropping side


# Some default methods when called site side
# XIDs and viewable-ness from widget

# XID of ancestor
sub ancestor { ${shift->widget->toplevel->id} }

# XID of site window
sub win      { ${shift->widget->id} }

# Is site window mapped
sub viewable { shift->widget->viewable }

sub Over
{
 my ($site,$X,$Y) = @_;
 
 #print "In Over, $site = ".ref($site)."\n";

 my $x = $site->X;
 my $y = $site->Y;
 my $w = $site->width;
 my $h = $site->height;
 my $val = ($X >= $x && $X < ($x + $w) && $Y >= $y && $Y < ($y + $h));

 return 0 unless $val;

 my $widget = $site->widget;

 my $containing = $widget->containing($X,$Y);
 #print "Containing = '$containing', widget = '$widget'\n";
 unless( defined($containing) && $containing eq $widget){
       #print "Over site, but not containing\n";
       $val = 0;
 }

 return 0 unless $val;

 ### This original code from perl/tk commented out, because
 ###   the PointToWindow sub is not defined yet (i.e. only local drag/drops supported
 
 # Now XTranslateCoords from root window to site window's
 # ancestor. Ancestors final descendant should be the site window.
 # Like $win->containing but avoids a problem that dropper's "token"
 # window may be the toplevel (child of root) that contains X,Y
 # so if that is in another application ->containing does not
 # give us a window.
 #my $id = $site->ancestor;
 #while (1)
 # {
 #  my $cid = $widget->PointToWindow($X,$Y,$id);
 #  last unless $cid;
 #  $id = $cid;
 # }
 return 1;
}

sub FindSite
{
 my ($class,$widget,$X,$Y) = @_;
 foreach my $site ($class->SiteList($widget))
  {
   return $site if ($site->viewable && $site->Over($X,$Y));
  }
 return undef;
}

sub NewDrag
{
 my ($class,$widget) = @_;
}

sub Match
{
 my ($site,$other) = @_;
 return 0 unless (defined $other);
 return 1 if ($site == $other);
 return 0 unless (ref($site) eq ref($other));
 for ("$site")
  {
   if (/ARRAY/)
    {
     my $i;
     return 0 unless (@$site == @$other);
     for ($i = 0; $i < @$site; $i++)
      {
       return 0 unless ($site->[$i] == $other->[$i]);
      }
     return 1;
    }
   elsif (/SCALAR/)
    {
     return $site == $other;
    }
   elsif (/HASH/)
    {
     my $key;
     foreach $key (keys %$site)
      {
       return 0 unless exists $other->{$key};
       return 0 unless ($other->{$key} eq $site->{$key});
      }
     foreach $key (keys %$other)
      {
       return 0 unless exists $site->{$key};
       return 0 unless ($other->{$key} eq $site->{$key});
      }
     return 1;
    }
   return 0;
  }
 return 0;
}


1;
