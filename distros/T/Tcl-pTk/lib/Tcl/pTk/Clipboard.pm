# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Tcl::pTk::Clipboard;
use strict;

our ($VERSION) = ('1.02');

use Tcl::pTk;

sub clipEvents
{
 return qw[Copy Cut Paste];
}

sub ClassInit
{
 my ($class,$mw, $tag) = @_;  # optional tag for binding
 $tag ||= $class; # If not supplied $tag = $class
 foreach my $op ($class->clipEvents)
  {
   $mw->bind($tag,"<<$op>>","clipboard$op");
  }
 return $class;
}

sub clipboardSet
{
 my $w = shift;
 $w->call('clipboard', 'clear');
 $w->call('clipboard', 'append', @_);
}

sub clipboardCopy
{
 my $w = shift;
 my $val = $w->getSelected;
 if (defined $val)
  {
   $w->clipboardSet('--',$val);
  }
 return $val;
}

sub clipboardCut
{
 my $w = shift;
 my $val = $w->clipboardCopy;
 if (defined $val)
  {
   $w->deleteSelected;
  }
 return $val;
}

sub clipboardGet
{
 my $w = shift;
 $w->SelectionGet('-selection','CLIPBOARD',@_);
}

sub clipboardPaste
{
 my $w = shift;
 local $@;
# Tcl::pTk::catch
  {
     eval
     {
       $w->deleteSelected;
     };
   my $value = $w->clipboardGet;
   # print "Clipboard paste = $value\n";
   $w->insert("insert", $value);
   $w->SeeInsert if $w->can('SeeInsert');
  };
}

sub clipboardOperations
{
 my @class = ();
 my $mw    = shift;
 if (ref $mw)
  {
   $mw = $mw->DelegateFor('bind');
  }
 else
  {
   push(@class,$mw);
   $mw = shift;
  }
 while (@_)
  {
   my $op = shift;
   $mw->bind(@class,"<<$op>>","clipboard$op");
  }
}

# These methods work for Entry and Text
# and can be overridden where they don't work

sub deleteSelected
{
 my $w = shift;
 Tcl::pTk::catch { $w->delete('sel.first','sel.last') };
}



sub getSelected
{
 my $w   = shift;
 my $val = Tcl::pTk::catch { $w->get('sel.first','sel.last') };
 return $val;
}

1;
