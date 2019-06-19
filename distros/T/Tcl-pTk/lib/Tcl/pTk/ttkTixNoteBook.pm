package Tcl::pTk::ttkTixNoteBook;

our ($VERSION) = ('1.00');

=head1 NAME 

Tcl::pTk::ttkTixNoteBook - Tix NoteBook compatible wrapper for ttkNotebook

=head1 SYNOPSIS

 use Tcl::pTk;
 use Tcl::pTk::ttkTixNoteBook;

 # Create widget implemented by ttkNotebook that is compatible with the
 # Tcl::pTk::NoteBook widget (i.e. the tix-implemented NoteBook widget)
 $n = $top->ttkTixNoteBook(-ipadx => 6, -ipady => 6);
 
 # Add Address tab and return the frame for the tab
 my $address_p = $n->add("address", -label => "Address", -underline => 0);
  ...
 $n->pack;

=head1 DESCRIPTION

L<Tcl::pTk::ttkTixNoteBook> is a wrapper around the Tile widget I<ttkNotebood> that is compatible with L<Tcl::pTk::Notebook>.
It is provided for a quick upgrade of existing code to use the newer Notebook widget with a upgraded look/feel.

=head1 OPTIONS

The following lists the options from the original L<Tk::Notebook> and how they are implemented with this widget. See the 
original L<Tk::Notebook> docs for the detailed description of these options.

=over 1

=item B<-dynamicgeometry>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-ipadx>

This option is supported using the I<padding> option of the I<ttkNotebook> widget.

=item B<-ipady>

This option is supported using the I<padding> option of the I<ttkNotebook> widget.

=item B<-backpagecolor>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-disabledforeground>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-focuscolor>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-font>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-inactivebackground>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-tabpadx>

This option is not implemented. It can be set and queried, but is ignored.

=item B<-tabpady>

This option is not implemented. It can be set and queried, but is ignored.

=back

=head1 METHODS

The following lists the methods from the original L<Tk::Notebook> widget and how they are implemented with this widget. See the 
original L<Tk::Notebook> docs for the detailed description of these methods.

=over 4

=item B<add>

Implemented with the ttkNotebook I<add> method, with wrapper code to return the tab frame to be compatible with the tix notebook widget.

Options implemented for the I<add> method are:

=over 4


=item B<-anchor>

Not implemented. Ignored if supplied.

=item B<-bitmap>

Not implemented. Ignored if supplied.

=item B<-label>

Implemented with the ttkNotebood I<-text> option.

=item B<-justify>

Not implemented. Ignored if supplied.

=item B<-createdcmd>

Not implemented. Ignored if supplied.

=item B<-raisecmd>

Not implemented. Ignored if supplied.

=item B<-state>

Implemented with the ttkNotebood I<-state> option.

=item B<-underline>

Implemented with the ttkNotebood I<-underline> option.

=item B<-wraplength>

Not implemented. Ignored if supplied.

=back

=item B<delete>

Implemented with the ttkNotebook I<forget> method.

=item B<pagecget>

Implemented with the ttkNotebook I<tab> method.

=item B<pageconfigure>

Implemented with the ttkNotebook I<tab> method.

=item B<pages>

Implemented with the ttkNotebook I<tab> method with a internal name-to-widget lookup hash.

=item B<page_widget>

Implemented with the internal name-to-widget lookup hash.

=item B<raise>

Implemented with the ttkNotebook I<select> method.

=item B<raised>

Implemented with the ttkNotebook I<select> method.

=item B<geometryinfo>

Not implemented

=item B<identify>

Implemented with the ttkNotebook I<identify> tab method.

=item B<info("pages")>

Implemented with the ttkNotebook I<tab> method with a internal name-to-widget lookup hash.

=item B<info("focus")>

Implemented with the ttkNotebook I<select> method.

=item B<info("focusnext")>

Implemented with the ttkNotebook I<select> method and returns the next tab in the order.

=item B<info("focusnext")>

Implemented with the ttkNotebook I<select> method and returns the previous tab in the order.

=item B<info("active")>

Implemented with the ttkNotebook I<select> method.

        
=back


=cut



use Tcl::pTk qw(Ev);
use Carp;
use strict;


use base qw(Tcl::pTk::Frame);
Construct Tcl::pTk::Widget 'ttkTixNoteBook';

sub Populate {
    my ($cw, $args) = @_;
     
    # Set foreground and background options to undef, unless defined during widget creation
    #   This keeps Tcl::pTk::Derived from setting these options from the options database, which is
    #    not needed for ttk widgets, and also makes -state => 'disabled' not look right
    foreach my $option( qw/ -foreground -background /){
            $args->{$option} = undef unless( defined($args->{$option} ));
    }
    
    $cw->SUPER::Populate($args);
    
    # Setup label options that will be ignored  (setup to just be passive), because they don't
    #  exists in the substituted tile widget
    my @ignoreOptions = ( qw/ 
    -dynamicgeometry -backpagecolor -disabledforeground -focuscolor -font -inactivebackground -tabpadx -tabpady
    /);
    my %ignoreConfigSpecs = map( ($_ => [ "PASSIVE", $_, $_, undef ]), @ignoreOptions);

    my $nb = $cw->ttkNotebook();
    $nb->pack( -side => 'right', -fill => 'both', -expand => 1); 
    $cw->Advertise('ttkNotebook' => $nb);

    # Create lookup of widget to tab name
    $cw->{widgetLookup} = {};
    
    $cw->Delegates(DEFAULT => $nb); # methods are handled by the combobox
    $cw->ConfigSpecs( 
		      DEFAULT => [ 'ttkNotebook' ],  # Default options go to ttkCombobox
		      -ipadx      => [ qw/METHOD ipadx     ipadx/,            undef ],
		      -ipady      => [ qw/METHOD ipady     ipady/,            undef ],
		      %ignoreConfigSpecs, 
    );
    
  
      
}

#----------------------------------------------
# Sub called when -ipadx option changed
#
sub ipadx{
	my ($cw, $ipadx) = @_;

        
	if(! defined($ipadx)){ # Handle case where $widget->cget(-ipadx) is called

		return $cw->{Configure}{-ipadx}
		
	}
	
        my $nb = $cw->Subwidget('ttkNotebook');
        
        # Get current padding parms
        my $padding = $nb->cget(-padding);
        my ($left, $top) = (0,0);
        ($left, $top) = @$padding if( ref($padding) );
        
        $nb->configure(-padding => [$ipadx, $top]);
}

#----------------------------------------------
# Sub called when -ipady option changed
#
sub ipady{
	my ($cw, $ipady) = @_;

        
	if(! defined($ipady)){ # Handle case where $widget->cget(-ipady) is called

		return $cw->{Configure}{-ipady}
		
	}
	
        my $nb = $cw->Subwidget('ttkNotebook');
        
        # Get current padding parms
        my $padding = $nb->cget(-padding);
        my ($left, $top) = (0,0);
        ($left, $top) = @$padding if( ref($padding) );
        
        $nb->configure(-padding => [$left, $ipady]);
}

#----------------------------------------------
# Add method
#   This uses the ttkNotebook add command, but creates a frame to populate, similar to the Tcl::pTk::NoteBook widget
sub add{
	my ($cw, $name, @options) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
	
        # Create a frame for the tab
        my $tabFrame = $nb->ttkFrame();
        
        # Translate Options
        my %options = @options;
        if( defined($options{-label})){
                $options{-text} = delete $options{-label};
        }
        
        # Ignore Options
        my @ignoreOptions = 
                qw/ -backpagecolor -disabledforeground focuscolor
                    -font -inactivebackground -tabpadx -tabpady
                  /;
        foreach my $option( @ignoreOptions ){
                delete $options{$option} if(defined($options{$option}));
        }
                
        
        # Delegate the add to the ttkNotebook widget
        $nb->add($tabFrame, %options);
        
        # Update widget Lookup for the tab we just added
        $cw->{widgetLookup}{"$tabFrame"} = $name;
        
        return $tabFrame;
}

#----------------------------------------------
# pages method
#   This uses the ttkNotebook add command, but creates a frame to populate, similar to the Tcl::pTk::NoteBook widget
sub pages{
	my ($cw ) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
	
        my $widgetLookup = $cw->{widgetLookup};

        my $tabWidgets = $nb->tabs();

        # Tanslate Widgets to Tab Names
        my @tabNames = map $widgetLookup->{"$_"}, @$tabWidgets;

        return @tabNames;
}

#----------------------------------------------
# info method
#   This delegates or executes an action based on the first arg to the method
sub info{
	my ($cw, $what ) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
	
        if( $what eq 'pages'){
                return $cw->pages;
        }
        elsif( $what eq 'focus' or $what eq 'active'){
                return $cw->raised;
        }
        elsif( $what eq 'focusnext'){
                my $current = $cw->raised;
                my @pages = $cw->pages;
                my $next;
                my $i = 0;
                foreach my $page(@pages){
                        if( $page eq $current){
                                my $nextI = $i+1;
                                $nextI = 0 if( $nextI > $#pages); # wraparound case
                                $next = $pages[$nextI];
                        }
                        $i++;
                }
                return $next;
        }
        elsif( $what eq 'focusprev'){
                my $current = $cw->raised;
                my @pages = $cw->pages;
                my $prev;
                my $i = 0;
                foreach my $page(@pages){
                        if( $page eq $current){
                                my $prevI = $i-1;
                                $prevI = -1 if( $prevI < 0); # wraparound case
                                $prev = $pages[$prevI];
                        }
                        $i++;
                }
                return $prev;
        }
        
}

#----------------------------------------------
# raised method
#   This returns the current tab name that has the focus
sub raised{
	my ($cw ) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
        
        my $raisedWidget = $nb->select();
        
        my $widgetLookup = $cw->{widgetLookup};
        
        return $widgetLookup->{"$raisedWidget"};
}

#----------------------------------------------
# identify method
#   This uses the identify tab method of the ttkNotebook widget
sub identify{
	my ($cw, $x, $y ) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
        
        my $widgetN = $nb->identify('tab', $x, $y);
        
        if( defined($widgetN)){
                        
                my @pages = $cw->pages;
                my $tabName = $pages[$widgetN];
                return $tabName;
        }
        return undef;
 
}

#----------------------------------------------
# raise method
#   This uses the select method of the ttkNotebook widget
sub raise{
	my ($cw, $name ) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
        
        # Make reverse lookup of name to widget
        my $widgetLookup = $cw->{widgetLookup};
        my %reverseLookup = reverse %$widgetLookup;
        my $widget = $reverseLookup{$name};
        
        $nb->select($widget);
 
}

#----------------------------------------------
# pageconfigure method
#   This uses the tab method of the ttkNotebook widget
sub pageconfigure{
        my ($cw, $name, @options ) = @_;
        
        # Translate Options
        my %options = @options;
        if( defined($options{-label})){
                $options{-text} = delete $options{-label};
        }
        
        # Ignore Options
        my @ignoreOptions = 
                qw/ -backpagecolor -disabledforeground focuscolor
                    -font -inactivebackground -tabpadx -tabpady
                  /;
        foreach my $option( @ignoreOptions ){
                delete $options{$option} if(defined($options{$option}));
        }
 
        my $nb = $cw->Subwidget('ttkNotebook');
        
       # Make reverse lookup of name to widget
        my $widgetLookup = $cw->{widgetLookup};
        my %reverseLookup = reverse %$widgetLookup;
        my $widget = $reverseLookup{$name};
        
        $nb->tab($widget, %options);
}

#----------------------------------------------
# pagecget method
#   This uses the tab method of the ttkNotebook widget
sub pagecget{
        my ($cw, $name, $option) = @_;
        
        # Translation for options
        if( $option eq '-label'){
                $option = '-text';
        }
       
        # Ignore Options
        my @ignoreOptions = 
                qw/ -backpagecolor -disabledforeground focuscolor
                    -font -inactivebackground -tabpadx -tabpady
                  /;
                  
        my %ignoreOptions;
        @ignoreOptions{@ignoreOptions} = @ignoreOptions; # Hash for quick lookup
        
        # Return undef for ignored options
        if( defined( $ignoreOptions{$option} )){
                return undef;
        }

      # Make reverse lookup of name to widget
        my $widgetLookup = $cw->{widgetLookup};
        my %reverseLookup = reverse %$widgetLookup;
        my $widget = $reverseLookup{$name};
        
        my $nb = $cw->Subwidget('ttkNotebook');
        
        my $value = $nb->tab($widget, $option);
        
        return $value;
        
}

#----------------------------------------------
# page_widget method
#   This uses the widget lookup hash to return the widget for a given tab name
sub page_widget{
        my ($cw, $name) = @_;
        

      # Make reverse lookup of name to widget
        my $widgetLookup = $cw->{widgetLookup};
        my %reverseLookup = reverse %$widgetLookup;
        my $widgetID = $reverseLookup{$name};
        
        my $widget = $Tcl::pTk::W{RPATH}{$widgetID}; # Use reverse lookup hash built-into Tcl::pTk to get actual widget from pathname
        
        return $widget;
        
}

#----------------------------------------------
# delete method
#   This uses the forget method of the ttkNotebook widget
sub delete{
	my ($cw, $name ) = @_;
	
	# Get ttkNotebook subwidget that is implementing the widget
        my $nb = $cw->Subwidget('ttkNotebook');
        
        # Make reverse lookup of name to widget
        my $widgetLookup = $cw->{widgetLookup};
        my %reverseLookup = reverse %$widgetLookup;
        my $widget = $reverseLookup{$name};
        
        $nb->forget($widget);
 
}
1;
