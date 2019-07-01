package Tcl::pTk::DragDrop::LocalDrop;

our ($VERSION) = ('1.02');

use strict;

use base qw(Tcl::pTk::DragDrop::Rect);
require Tcl::pTk::DragDrop;

my @toplevels;

#Tcl::pTk::DragDrop->Type('Local');
Tcl::pTk::DragDrop::Common::Type('Tcl::pTk::DragDrop', 'Local');

sub XY
{
 my ($site,$event) = @_;
 return ($event->X - $site->X,$event->Y - $site->Y);
}

sub Apply
{
 my $site = shift;
 my $name = shift;
 my $cb   = $site->{$name};
 if ($cb)
  {
   my $event = shift;
   $cb->Call(@_,$site->XY($event));
  }
}

sub Drop
{
 my ($site,$token,$seln,$event) = @_;
 $site->Apply(-dropcommand => $event, $seln);
 $site->Apply(-entercommand => $event, 0);
 $token->Done;
}

sub Enter
{
 my ($site,$token,$event) = @_;
 $token->AcceptDrop;
 $site->Apply(-entercommand => $event, 1);
}

sub Leave
{
 my ($site,$token,$event) = @_;
 $token->RejectDrop;
 $site->Apply(-entercommand => $event, 0);
}

sub Motion
{
 my ($site,$token,$event) = @_;
 $site->Apply(-motioncommand => $event);
}


1;

__END__
