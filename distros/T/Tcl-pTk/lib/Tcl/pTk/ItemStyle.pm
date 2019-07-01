package Tcl::pTk::ItemStyle;

our ($VERSION) = ('1.02');

require Tcl::pTk;
use base  qw(Tcl::pTk::Widget);

Construct Tcl::pTk::Widget 'ItemStyle';


sub new
{
 my $package = shift;
 my $widget  = shift;
 my $type    = shift;
 my %args    = @_;
 my $int     = $widget->interp;
 $args{'-refwindow'} = $widget unless exists $args{'-refwindow'};
 $package->InitClass($widget);
 $int->pkg_require("Tix");
 my $name = $int->icall('tixDisplayStyle', $type, %args);
 
 # Create an object structure: itemStyle with the name of the style item, winID so 
 #  we can find our interp for (semi-) compatibility with other widget objects
 return bless {itemStyle => $name, winID => $widget->{winID} },$package;
}

sub delete{
 my $self = shift;
 $self->interp->icall($self->path, 'delete');
}

sub Install
{
 # Dynamically loaded image types can install standard images here
 my ($class,$mw) = @_;
}

sub ClassInit
{
 # Carry out class bindings (or whatever)
 my ($package,$mw) = @_;
 return $package;
}

sub path{
   my $self = shift;
   return $self->{itemStyle};
}


1;
