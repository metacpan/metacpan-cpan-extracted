package Tcl::pTk::Tile;

our ($VERSION) = ('1.11');

use strict;
use warnings;
use Carp;

=head1 NAME

Tcl::pTk::Tile -  Tile/ttk Widget Support for Tcl::pTk


=head1 SYNOPSIS

        # Get a list of defined Tile Themes
        my @themes = $widget->ttkThemes;
        
        # Set a Tile Theme
        $widget->ttkSetTheme($themeName);
        
        # Create a Tile/ttk widget
        my $check->ttkCheckbutton(-text => 'Enabled', -variable => \$enabled);
        
        # Check some of the ttk style settings
        my $font = $widget->ttkStyleLookup($style, -font);

=head1 DESCRIPTION

I<Tcl::pTk::Tile> provides some helper methods and mappings for Tile/ttk support
in the L<Tcl::pTk> package. Tile/ttk are the new themed widget set that is
present in Tcl/Tk 8.5 and above, and available for Tcl/Tk 8.4 in the Tile package.

This package is auto-loaded and the tile widgets declared if Tk 8.5 is being
used by Tcl::pTk, or if the Tile package for Tk 8.4 is installed.

=head2 Style method mapping

The Tcl/Tk I<ttk::style> command has be mapped to I<ttkStyle> widget methods in L<Tcl::pTk>. 
The following table defines this mapping:

 Tcl Usage                                  Equivalent Tcl::pTk Usage                               
 ------------------------------------------ --------------------------------------------------------
 ttk::style configure $style -option $value $widget->ttkStyleConfigure($style, -option, $value)     
 ttk::style map $style -option ...          $widget->ttkStyleMap( $style, -option, ...)               
 ttk::style lookup $style -font             $widget->ttkStyleLookup( $style, -font)                 
 ttk::style layout $style ...               $widget->ttkStyleLayout( $style, ...)                   
 ttk::style element create $elementname ..  $widget->ttkStyleElementCreate($elementname, $type, ..)
 ttk::style element names                   $widget->ttkStyleElementNames()                         
 ttk::style element options $element        $widget->ttkStyleElementOptions($element)               
 ttk::style theme create ...                $widget->ttkThemeCreate( ... )                             
 ttk::style theme settings ...              $widget->ttkThemeSettings(...)                            
 ttk::style theme names                     $widget->ttkThemeNames                                  
 ttk::style theme use $themename            $widget->ttkThemeUse($themename)  
 

=head1 METHODS

=cut

Tcl::pTk::Tile->_setupMapping( 'Tcl::pTk::Widget',
			       'ttkStyle' => ['ttk::style'],
			       [qw/ configure map lookup layout element theme /],
			       'ttkStyleElement' => [ 'ttk::style', 'element' ],
			       [qw/ create names options  /],
			       'ttkStyleTheme' => [ 'ttk::style', 'theme' ],
			       [qw/ create names use  /]
);


##################################################

=head2 ttkSetTheme

Set a Tile Theme
        
B<Usage:>

        $widget->ttkSetTheme($name);

=cut

sub Tcl::pTk::Widget::ttkSetTheme {
	my $self = shift;

	my $theme = shift;

	$self->interp->call( 'ttk::setTheme', $theme );

}

##################################################

=head2 ttkThemes

Get a list of Tile/ttk theme names
        
B<Usage:>

        my @themes $widget->ttkThemes;

=cut

sub Tcl::pTk::Widget::ttkThemes {
	my $self = shift;

	$self->interp->call('ttk::themes');

}

##################################################

=head2 _declareTileWidgets

Internal sub to declare the tile widgets. This is called when a mainwindow
is created, if we are using Tcl/Tk 8.5 or higher, or the Tile package for
Tcl/Tk 8.4 is present.

B<Usage:>

        _declareTileWidgets($interp);
        
        where $interp is the Tcl interp object

=cut

sub _declareTileWidgets {
	my $interp = shift;

	my @ttkwidgets = (
		qw/
		  button checkbutton combobox entry frame image label
		  label labelframe menubutton notebook panedwindow
		  progressbar radiobutton scale scrollbar separator
		  sizegrip treeview /
	);

	foreach my $ttkwidget (@ttkwidgets) {

		#print STDERR "delcareing "."ttk".ucfirst($ttkwidget).
		#                 "  ttk::$ttkwidget\n";
		$interp->Declare(
			'ttk' . ucfirst($ttkwidget),
			"ttk::$ttkwidget",
			-require => 'tile',
		);
	}

}

#
##################################################

=head2 _setupMapping

Internal method called at startup to provide mapping to the Tile methods. See the docs above on how
mapping is done.
        
B<Usage:>

        Tcl::pTk::Tile->_setupMapping($package, @mappingSpecs);

=cut

sub _setupMapping {
	my $class = shift;
	no strict 'refs';
	my $package = shift;
	while (@_) {
		my $commandBase = shift;
		my $mappedcommandBase = shift;
		my $submethods = shift;
		foreach my $submethod ( @{$submethods} ) {
			my $pfn = $package . '::' . $commandBase;
			my $methodName = $pfn . "\u$submethod";
			#print "Creating method $methodName for call ".join(" ", @$mappedcommandBase, $submethod)."\n";
			*{ $methodName } = sub {
				my $self = shift;
				$self->call( @$mappedcommandBase, $submethod, @_ );
			};
		}
	}
}

###### Special cases to get ttkTreeview methods to work ###

# Avoid using Tcl::pTk::Widget::children
sub Tcl::pTk::ttkTreeview::children {
    my $self = shift;
    $self->call($self->path, 'children', @_);
}

# Ensure Perl list (not Tcl list) is returned
# https://github.com/chrstphrchvz/perl-tcl-ptk/issues/7
sub Tcl::pTk::ttkTreeview::selection {
    my $self = shift;
    $self->call($self->path, 'selection', @_);
}
sub Tcl::pTk::ttkTreeview::item {
    my $self = shift;
    $self->call($self->path, 'item', @_);
}
sub Tcl::pTk::ttkTreeview::tag {
    my $self = shift;
    $self->call($self->path, 'tag', @_);
}
sub Tcl::pTk::ttkTreeview::cellselection {
    my $self = shift;
    $self->call($self->path, 'cellselection', @_);
}

1;

