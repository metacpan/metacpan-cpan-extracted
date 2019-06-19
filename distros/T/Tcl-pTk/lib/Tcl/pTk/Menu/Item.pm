###### Menu::Item widgets #################
## Converted from perl/tk version #########

package Tcl::pTk::Menu::Item;

our ($VERSION) = ('1.00');

require Tcl::pTk::Menu;

use Carp;
use strict;


sub PreInit
{
 # Dummy (virtual) method
 my ($class,$menu,$minfo) = @_;
}

sub new
{
 my ($class,$menu,%minfo) = @_;
 my $kind = $class->kind;
 my $name = $minfo{'-label'};
 if (defined $kind)
  {
   my $invoke = delete $minfo{'-invoke'};
   if (defined $name)
    {
     # Use ~ in name/label to set -underline
     if (defined($minfo{-label}) && !defined($minfo{-underline}))
      {
       my $cleanlabel = $minfo{-label};
       my $underline = ($cleanlabel =~ s/^(.*)~/$1/) ? length($1): undef;
       if (defined($underline) && ($underline >= 0))
        {
         $minfo{-underline} = $underline;
         $name = $cleanlabel if ($minfo{-label} eq $name);
         $minfo{-label} = $cleanlabel;
        }
      }
    }
   else
    {
     $name = $minfo{'-bitmap'} || $minfo{'-image'};
     confess("No -label option supplied to $kind") unless defined($name);
     $minfo{'-label'} = $name;
    }
   $class->PreInit($menu,\%minfo);
   $menu->add($kind,%minfo);
   $menu->invoke('last') if ($invoke);
  }
 else
  {
   $menu->add('separator');
  }
 return bless [$menu,$name],$class;
}

sub configure
{
 my $obj = shift;
 my ($menu,$name) = @$obj;
 my %args = @_;
 $obj->[1] = $args{'-label'} if exists $args{'-label'};
 $menu->entryconfigure($name,@_);
}

sub cget
{
 my $obj = shift;
 my ($menu,$name) = @$obj;
 $menu->entrycget($name,@_);
}

sub parentMenu
{
 my $obj = shift;
 return $obj->[0];
}

# Default "kind" is a command
sub kind { return 'command' }

# Now the derived packages

package Tcl::pTk::Menu::Separator;
use base qw(Tcl::pTk::Menu::Item);
Tcl::pTk::Menu->Construct( 'Separator' );
sub kind { return undef }

package Tcl::pTk::Menu::Button;
use base qw(Tcl::pTk::Menu::Item);
Tcl::pTk::Menu->Construct( 'Button' );
Tcl::pTk::Menu->Construct( 'Command' );

#package Tk::Menu::Command;
#use base qw(Tk::Menu::Button);
#Construct Tk::Menu 'Command';

package Tcl::pTk::Menu::Cascade;
use base qw(Tcl::pTk::Menu::Item);
Tcl::pTk::Menu->Construct( 'Cascade' );
sub kind { return 'cascade' }
use Carp;

sub PreInit
{
 my ($class,$menu,$minfo) = @_;
 my $tearoff   = delete $minfo->{-tearoff};
 my $items     = delete $minfo->{-menuitems};
 my $widgetvar = delete $minfo->{-menuvar};
 my $command   = delete $minfo->{-postcommand};
 my $name = delete $minfo->{'Name'};
 $name = $minfo->{'-label'} unless defined $name;
 my @args = ();
 push(@args, '-tearoff' => $tearoff) if (defined $tearoff);
 push(@args, '-menuitems' => $items) if (defined $items);
 push(@args, '-postcommand' => $command) if (defined $command);
 my $submenu = $minfo->{'-menu'};
 unless (defined $submenu)
  {
   $minfo->{'-menu'} = $submenu = $menu->Menu(Name => $name, @args);
  }
 $$widgetvar = $submenu if (defined($widgetvar) && ref($widgetvar));
}

sub menu
{
 my ($self,%args) = @_;
 my $w = $self->parentMenu;
 my $menu = $self->cget('-menu');
 if (!defined $menu)
  {
   require Tcl::pTk::Menu;
   $w->ColorOptions(\%args);
   my $name = $self->cget('-label');
   warn "Had to (re-)create menu for $name";
   $menu = $w->Menu(Name => $name, %args);
   $self->configure('-menu'=>$menu);
  }
 else
  {
   $menu->configure(%args) if %args;
  }
 return $menu;
}

# Some convenience methods

sub separator   {  shift->menu->Separator(@_);   }
sub command     {  shift->menu->Command(@_);     }
sub cascade     {  shift->menu->Cascade(@_);     }
sub checkbutton {  shift->menu->Checkbutton(@_); }
sub radiobutton {  shift->menu->Radiobutton(@_); }

sub pack
{
 my $w = shift;
 if ($^W)
  {
   require Carp;
   Carp::carp("Cannot 'pack' $w - done automatically")
  }
}

package Tcl::pTk::Menu::Checkbutton;
use base qw(Tcl::pTk::Menu::Item);
Tcl::pTk::Menu->Construct( 'Checkbutton' );
sub kind { return 'checkbutton' }

package Tcl::pTk::Menu::Radiobutton;
use base qw(Tcl::pTk::Menu::Item);
Tcl::pTk::Menu->Construct( 'Radiobutton' );
sub kind { return 'radiobutton' }

package Tcl::pTk::Menu::Item;

1;
__END__

