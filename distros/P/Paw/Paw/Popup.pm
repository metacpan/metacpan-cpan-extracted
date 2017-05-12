#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
package Paw::Popup;
use strict;
use Paw::Button;
use Paw::Textbox;
use Paw::Window;

@Paw::Popup::ISA = qw(Paw);

=head1 Popup Window

B<$popup=Paw::Popup->new([$height], [$width], [$shade], \@buttons, \$text, [$name]);>

B<Parameter>

     $height   => number of rows [optionally]

     $width    => number of columns [optionally]

     $shade    => popup box has a shadow (shade=>1)

     $name     => name of the widget [optionally]

     \@buttons => an array of strings for the labels on the buttons
                  in the box.

     \$text    => reference to a scalar with the Text.
  
B<Example>

     @butt=('Okay', 'Cancel');
     $text=('Do you really want to continue ?');
     $pu=Popup::new(height=>20, width=>20,
                        buttons=>\@butt, text=>\$text);

If a button is pressed, the box closes and the number of the button is returned (beginning by 0). 

=head2 draw();

raises the popup-window, returns the number of the pushed button.

B<Example>

     $button=$pu->draw();

=head2 set_border(["shade"])

activates the border of the widget (optionally also with shadows). 

B<Example>

     $widget->set_border("shade"); or $widget->set_border();

=cut

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;
    my $window = 0;
    my $textbox= 0;
    my @buttons= ();
    my $cb     = \&_callback;

    bless ($this, $class);
    $this->{name}    = (defined $params{name})?($params{name}):('_auto_popup');
    $this->{cols}    = (defined $params{width})?($params{width}):($this->{screen_cols}/2);
    $this->{rows}    = (defined $params{height})?($params{height}):($this->{screen_rows}/2);
    $this->{x_pos}   = (defined $params{abs_x})?($params{abs_x}):(($this->{screen_cols}-$this->{cols})/2);
    $this->{y_pos}   = (defined $params{abs_y})?($params{abs_y}):(($this->{screen_rows}-$this->{rows})/2);

    $this->{buttons} = $params{buttons};
    $this->{text}    = $params{text};

    # backwards compatibility
    if ( ref $params{text} eq 'ARRAY' ) {
	my $dummy;
	foreach ( @{$this->{text}} ) {
	    $dummy .= $_;
	}
	$this->{text} = \$dummy;
    }

    $window = Paw::Window->new( abs_x   => $this->{x_pos}, 
				abs_y   => $this->{y_pos}, 
				callback=> $cb,
				height  => $this->{rows}, width=>$this->{cols} );
    $window->set_border();
    $window->set_border('shade') if defined $params{shade};
    $textbox = Paw::Textbox->new( text     => $this->{text}, 
				  width    => $this->{cols}-2, 
				  height   => $this->{rows}-5, 
				  wordwrap => 1 );
    $textbox->{act_able}=0;
    $textbox->set_border();
    $window->abs_move_curs(new_y=>1); #hmm...
    $window->put($textbox);
    $window->{parent}=$this;
    my $button_cols=0;
    for ( my $i=0; $i < @{$params{buttons}}; $i++ ) {
        my $temp = Paw::Button->new( text=>$params{buttons}->[$i] );
        push(@buttons, $temp);
        $temp->set_border();
        $window->put($temp);
        $window->put_dir('h');
	$button_cols += $temp->{cols}+2;
    }
    $this->{window}  = $window;
    $this->{buttons} = \@buttons;
    return $this;
}

sub draw {
    my $this = shift;

    return $this->{window}->raise();
}

sub _callback {
    my $this = shift;

    for ( my $i=0; $i < @{$this->{parent}->{buttons}}; $i++ ) {
        $this->{parent}->{buttons}->[$i]->release_button();
    }
    while ( 1 ) {
        my $key = getch();
        if ( $key ne -1 ) {
            $this->key_press($key);
            for ( my $i=0; $i < @{$this->{parent}->{buttons}}; $i++ ) {
                return $i if ( $this->{parent}->{buttons}->[$i]->is_pressed() );
            }
        }
    }
}
return 1;
