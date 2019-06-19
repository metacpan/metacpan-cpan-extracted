# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Converted to Tcl:Tk 4/8/09  John Cerney
#

package Tcl::pTk::Optionmenu;

our ($VERSION) = ('1.00');

use Tcl::pTk;
require Tcl::pTk::Menubutton;
require Tcl::pTk::Menu;
use Carp;


use base  qw(Tcl::pTk::Derived Tcl::pTk::Menubutton);

use strict;

Construct Tcl::pTk::Widget 'Optionmenu';

sub Populate
{
 my ($w,$args) = @_;
 $w->SUPER::Populate($args);
 $args->{-indicatoron} = 1;
 my $menu = $w->menu;
 $menu->configure(-tearoff => 0);

 # Should we allow -menubackground etc. as in -label* of Frame ?

 $w->ConfigSpecs(-command => ['CALLBACK',undef,undef,undef],
                 -options => ['METHOD', undef, undef, undef],
		 -variable=> ['PASSIVE', undef, undef, undef],
		 -font    => [['SELF',$menu], undef, undef, undef],
		 -foreground => [['SELF', 'CHILDREN'], undef, undef, undef],

   -takefocus          => [ qw/SELF takefocus          Takefocus          1/ ],
   -highlightthickness => [ qw/SELF highlightThickness HighlightThickness 1/ ],
   -relief             => [ qw/SELF relief             Relief        raised/ ],

                );

 # configure -variable and -command now so that when -options
 # is set by main-line configure they are there to be set/called.

 my $tvar = delete $args->{-textvariable};
 my $vvar = delete $args->{-variable};
 if (!defined($vvar))
  {
   if (defined $tvar)
    {
     $vvar = $tvar;
    }
   else
    {
     my $new;
     $vvar = \$new;
    }
  }
 $tvar = $vvar if (!defined($tvar));
 $w->configure(-textvariable => $tvar, -variable => $vvar);
 $w->configure(-command  => $vvar) if ($vvar = delete $args->{-command});
}

sub setOption
{
 my ($w, $label, $val) = @_;
 my $tvar = $w->cget(-textvariable);
 my $vvar = $w->cget(-variable);
 if (@_ == 2)
  {
   $val = $label;
  }
 $$tvar = $label if $tvar;
 $$vvar = $val   if $vvar;
 $w->Callback(-command => $val);
}

sub addOptions
{
 my $w     = shift;
 my $menu  = $w->menu;
 my $tvar  = $w->cget(-textvariable);
 my $vvar  = $w->cget(-variable);
 my $oldt  = $$tvar;
 my $width = $w->cget('-width');
 my %hash;
 my $first;
 while (@_)
  {
   my $val = shift;
   my $label = $val;
   if (ref $val)
    {
     if ($vvar == $tvar)
      {
       my $new = $label;
       $w->configure(-textvariable => ($tvar = \$new));
      }
     ($label, $val) = @$val;
    }
   my $len = length($label);
   $width = $len if (!defined($width) || $len > $width);
   $menu->command(-label => $label, -command => [ $w , 'setOption', $label, $val ]);
   $hash{$label} = $val;
   $first = $label unless defined $first;
  }
 if (!defined($oldt) || !exists($hash{$oldt}))
  {
   $w->setOption($first, $hash{$first}) if defined $first;
  }
 $w->configure('-width' => $width);
}

sub options
{
 my ($w,$opts) = @_;
 if (@_ > 1)
  {
   my $mnu = $w->menu;
   $w->menu->delete(0,'end');
   $w->addOptions(@$opts);
  }
 else
  {
   return $w->_cget('-options');
  }
}


# Overridden cget to return a real widget for the -menu option
sub cget {
    my $wid = shift;
    my $int = $wid->interp;
    if ($_[0] eq "-menu") {
        return $int->widget($int->invoke("$wid",'cget','-menu'));
    } else {
        $wid->SUPER::cget(@_);
    }
}

1;

__END__
