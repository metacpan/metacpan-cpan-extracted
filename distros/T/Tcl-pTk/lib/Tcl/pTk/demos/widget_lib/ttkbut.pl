# ttkbut.pl
# Demo of tile widget

use vars qw/$TOP/;

sub ttkbut {

    # Create a top-level window that displays a bunch of entries.

    my($demo) = @_;
    $TOP = $MW->WidgetDemo(
        -name     => $demo,
        -title    => 'Tile Widget Button Demo',
	-text	  => '',
        -iconname => 'ttkbut',
    );

	my $msg = $TOP->ttkLabel( -text => 
		"Ttk is the new Tk themed widget set. This is a Ttk themed label, and below are three groups of Ttk widgets in Ttk labelframes. The first group are all buttons that set the current application theme when pressed. The second group contains three sets of checkbuttons, with a separator widget between the sets. Note that the Enabled button controls whether all the other themed widgets in this toplevel are in the disabled state. The third group has a collection of linked radiobuttons.",
		qw/ -wraplength 4i -justify left/)->pack(-side => 'top', -fill => 'x');
	 
	 
	# Make the button frame
	my $bigFrame = $TOP->ttkFrame()->pack(-expand => 'y', -fill => 'both');

	# Make the button frame
	my $buttonFrame = $bigFrame->ttkLabelframe(-text => 'Buttons');

	my @themes = $buttonFrame->ttkThemes;

	foreach my $theme ( @themes ){
		my $button = $buttonFrame->ttkButton(-text => $theme,
		        -command => sub{ $buttonFrame->ttkSetTheme($theme)}
		)->pack( -pady =>  2);
	}
		

	# Make the check-button frame
	my $checkFrame = $bigFrame->ttkLabelframe(-text => 'Checkbuttons');

	my $enabled = 1;
	my ($cheese, $tomato, $basil, $oregano);
	$cheese = -1;
	$checkFrame->ttkCheckbutton(-text => 'Enabled', -variable => \$enabled)->pack( -fill => 'x', -pady => 2);
	$checkFrame->ttkSeparator()->pack( -fill => 'x', -pady => 2);
	$checkFrame->ttkCheckbutton(-text => 'Cheese', -variable => \$cheese)->pack( -fill => 'x', -pady => 2);
	$checkFrame->ttkCheckbutton(-text => 'Tomato', -variable => \$tomato)->pack( -fill => 'x', -pady => 2);
	$checkFrame->ttkSeparator()->pack( -fill => 'x', -pady => 2);
	$checkFrame->ttkCheckbutton(-text => 'Basil', -variable => \$basil)->pack( -fill => 'x', -pady => 2);
	$checkFrame->ttkCheckbutton(-text => 'Oregano', -variable => \$oregano)->pack( -fill => 'x', -pady => 2);


	## Set up the radiobutton group
	my $radioFrame = $bigFrame->ttkLabelframe(-text => 'RadioButtons');
	my $happiness = 'great';
	$radioFrame->ttkRadiobutton(-text => "Great", -variable =>  \$happiness,  -value => 'great')->pack( -fill => 'x', -pady => 2);
	$radioFrame->ttkRadiobutton(-text => "Good" , -variable =>  \$happiness,  -value => 'good')->pack( -fill => 'x', -pady => 2);
	$radioFrame->ttkRadiobutton(-text => "OK"   , -variable =>  \$happiness,  -value => 'ok')->pack( -fill => 'x', -pady => 2);
	$radioFrame->ttkRadiobutton(-text => "Poor" , -variable =>  \$happiness,  -value => 'poor')->pack( -fill => 'x', -pady => 2);
	$radioFrame->ttkRadiobutton(-text => "Awful", -variable =>  \$happiness,  -value => 'awful')->pack( -fill => 'x', -pady => 2);


	$buttonFrame->grid($checkFrame, $radioFrame, qw/-sticky nwe  -pady 2 -padx 3/);
	$bigFrame->gridColumnconfigure([0,1,2],  -weight => 1,  -uniform =>  'yes');

} # end entry1

1;
