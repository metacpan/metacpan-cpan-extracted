package Tcl::pTk::Menu;

our ($VERSION) = ('1.00');

# Simple Menu package.
#  This file is needed to provide the proper inheritance of Menu to 
#   the Wm, Derived and widget packages
#

use base qw(Tcl::pTk::Wm Tcl::pTk::Derived Tcl::pTk::Widget);

use Tcl::pTk::Widget();
use Tcl::pTk::Wm();
use Tcl::pTk::Derived();
use Tcl::pTk::Menubutton;
use Tcl::pTk::Menu::Item;


Tcl::pTk::Widget->Construct('Menu');

sub CreateArgs{
        my $package = shift;
        my $parent  = shift;
        my $args    = shift;
        
        # Turn -tearoff => '' to -tearoff => 0. (Tcl needs a boolean value for this,
        #   not a empty string
        
        if( exists($args->{-tearoff}) && !($args->{-tearoff}) ){
                $args->{-tearoff} = 0;
        }
        return $package->SUPER::CreateArgs($parent, $args);
}


sub InitObject
{
 my ($menu,$args) = @_;
 my $menuitems = delete $args->{-menuitems};
 $menu->SUPER::InitObject($args);
 if (defined $menuitems)
  {
   # If any other args do configure now
   if (%$args)
    {
     $menu->configure(%$args);
     %$args = ();
    }
    # Process menu items using the internal widget method
    my $int = $menu->interp;
    $menu->_process_menuitems($int,$menu,$menuitems);

  }
}

# Create widget packages and methods for Menu
Tcl::pTk::Widget::create_widget_package('Menu');
Tcl::pTk::Widget::create_method_in_widget_package('Menu',
        command => sub {
            my $wid = shift;
            my %args = @_;
            
            # Convert -bg and -fg abbreviations to -background and -foreground
            #   These abbreviations are valid in perl/tk, but not in Tcl/tk, so we have to
            #  translate
            $args{-foreground} = delete($args{-fg}) if( defined($args{-fg}));
            $args{-background} = delete($args{-bg}) if( defined($args{-bg}));
            
            $wid->_process_underline(\%args);
            $wid->menu->Command(%args);
        },
        checkbutton => sub {
            shift->Checkbutton(@_);
        },
        radiobutton => sub {
            shift->Radiobutton(@_);
        },
        cascade => sub {
            my $wid = shift;
            $wid->_addcascade(@_);
        },
        separator => sub {
            shift->Separator(@_);
        },
        menu => sub {
            my $wid = shift;
            return $wid->interp->widget("$wid");
        },
        
        entryconfigure => sub {
            my $wid = shift;
            my $label = shift;
            $label =~ s/~//;
            $wid->call("$wid", 'entryconfigure', $label, @_);
        },
);


sub Populate
{
 my ($cw,$arg) = @_;
 $cw->SUPER::Populate($arg);
}

# Method to return the containerName of the widget
#   Any subclasses of this widget can call containerName to get the correct
#   container widget for the subwidget
sub containerName{
        return 'Menu';
}

# Overloaded cget that takes care of -menu option, for compatibility with perl/tk
sub cget {
    my $self = shift;
    my $opt = shift;
    if ($opt eq '-menu') {
        return $self->interp->widget($self);
    }
    return $self->SUPER::cget($opt);
}

# Wrapper for the Menu Widget's entrycget method. 
#  For most cases, this just calls the tcl with the args supplied, but when called with
#  the -menu option, it takes the pathname returned by tcl and turns it into a widget.
#  This is for compatibility with perl/tk
#
sub Tcl::pTk::Menu::entrycget{
        
        my $self = shift;
        
        my $index = shift;
        
        my $option = shift;
        
        my $result = $self->call($self->path, 'entrycget', $index, $option);
        
        # If option -menu, a widget path will be returned,
        #   we need to translate to a actual widget
        if( $option eq '-menu' && $result){
            my $widgets = Tcl::pTk::widgets();
            my $widgetObj = $widgets->{RPATH}{$result};
            $result = $widgetObj;
        }
        
        return $result;
}

# Wrapper method for Tcl::pTk::Menu path method
#  This gets the cloned menu path (like the menubar menu), rather than non-cloned menu path.
#   The cloned menu path is needed for bindings to work correctly on cloned menus
#


sub path{
        my $self = shift;
        
        my $path = $self->Tcl::pTk::Widget::path(@_); # get normal path
        
        # If this is a menubar, then it will be a cloned menu, which the
        #  tk source prepends a '#' to the name (e.g. .menu02 becomes '.#menu02'
        #  (See TkNewMenuName in tkMenu.c for details)
        #
        # Prepend '#' to the name to make bindings work correctly
        #   we use a direct icall here, rather then a cget call to avoid recursively calling ourselves
        my $exists = $self->interp->icall('winfo','exists',$path); # only do this if the widget exists
        if( $exists && $self->interp->icall($path, 'cget', '-type') eq 'menubar'){
                
                # Build cloned menu path #
                my $toplevelPath = $self->interp->icall('winfo','toplevel',$path);
                my $nonToplevelPath = $path;
                my $toplevelPathMatch = quotemeta($toplevelPath); # make toplevelPath work for a regexp matching
                $nonToplevelPath =~ s/$toplevelPathMatch//;
                
                my @pieces = split('\.', $path);
                shift @pieces if ($pieces[0] eq ''); # get rid of empty first piece, which happens when non-toplevel starts with '.'
                
                #print "pieces = '".join("', '", @pieces)."'\n";
                my $newPathPiece = "#".join("#", @pieces);
                        
                $toplevelPath = '' if( $toplevelPath eq '.'); # Allow for simple '.' toplevel pathname
                my $newpath = join('.', $toplevelPath, $newPathPiece); # Prepend '#' to the names
               
                #print "newpath = '$newpath'\n";
                # Use the new path only if it exists
                if( $self->interp->icall('winfo','exists',$newpath)){
                        #print "New path = '$newpath'\n";
                        $path = $newpath;
                }
                #print "path = $path\n";
        }
        
        return $path;
}


# Post for Menu (Using the native tk_post tcl function)
sub Post{
        my $self = shift;
        $self->call('tk_popup', $self->path, @_);
}

# Calling Menubutton on a menu will directly call the menubutton creation sub
#   instead of going thru the Tcl::pTk::new delegation code
sub Menubutton{
        my $self = shift;
        $self->Tcl::pTk::Menubutton(@_);
}

################# Raw Widget Creation Method #####
## Created in Tcl::pTk space
##  For other auto-wrapped widgets (like Label, Entry) this would be auto-created
##  by the declareAutoWidget method in Tcl::pTk::Widget
sub Tcl::pTk::Menu {
    my $self = shift; # this will be a parent widget for newer menu
    my $int  = $self->interp;

   # Take care of any Name => $wpref syntax during the creation
   #  (For compatibility with perltk)
   my $wpref = 'menu';
   if( $_[0] and $_[0] eq 'Name'){
           shift;
           $wpref = shift;
           $wpref = lcfirst $wpref; # window name must start with a lower case letter in tcl 
           $wpref =~ s/\s+/_/g; # no spaces allowed in window names in tcl
   }

    my $w    = $self->w_uniq($wpref); # return unique widget id
    my %args = @_;

    my $mis         = delete $args{'-menuitems'};
    $args{'-state'} = delete $args{state} if exists $args{state};

    my $mnu = $int->widget($self->call('menu', $w, %args), "Tcl::pTk::Menu");
    $mnu->_process_menuitems($int,$mnu,$mis);
    
    # Cal normal widget initialization methods
    $mnu->InitObject(\%args);
    $mnu->configure(%args) if (%args);

    return $mnu;
}

1;

