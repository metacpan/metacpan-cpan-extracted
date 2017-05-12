# Demo of tile combo box widgets

use vars qw/$TOP/;

sub combo {

        # Create a top-level window that displays a bunch of entries.

       my($demo) = @_;
       $TOP = $MW->WidgetDemo(
                -name     => $demo,
                -title    => 'Combobox Demonstration',
                -text	  => '',
                -iconname => 'ttkbut',
        );

        my $msg = $TOP->ttkLabel( -text => 
                "Three different combo-boxes are displayed below. You can add characters to the first one by pointing, clicking and typing, just as with an entry; pressing Return will cause the current value to be added to the list that is selectable from the drop-down list, and you can choose other values by pressing the Down key, using the arrow keys to pick another one, and pressing Return again. The second combo-box is fixed to a particular value, and cannot be modified at all. The third one only allows you to select values from its drop-down list of Australian cities.",
        qw/ -wraplength 4i -justify left/)->pack(-side => 'top', -fill => 'x');
         
        my @australianCities = ( qw/ 
            Canberra Sydney Melbourne Perth Adelaide Brisbane
            Hobart Darwin "Alice Springs"
         /);
        
        my $firstvalue = '';
        my $secondvalue = 'unchangeable';
        my $ozCity = 'Sidney';
        
        my $labelFrame1 = $TOP->ttkLabelframe(-text => 'Fully Editable');
        my $cb1 = $labelFrame1->ttkCombobox(-textvariable => \$firstvalue);
        
        my $labelFrame2 = $TOP->ttkLabelframe(-text => 'Disabled');
        my $cb2 = $labelFrame2->ttkCombobox(-textvariable => \$secondvalue, -state => 'disabled');
        
        my $labelFrame3 = $TOP->ttkLabelframe(-text => 'Defined List Only');
        my $cb3 = $labelFrame3->ttkCombobox(-textvariable => \$ozCity, -state => 'readonly', 
                -values => \@australianCities);
        
        # Any new value get added to the list for combobox 1
        $cb1->bind('<Return>', sub{ 
                       my $W = shift;
                       my $val = $W->get();
                       unless( grep $_ eq $val, $W->cget('-values') ){
                               my @values = $W->cget('-values');
                               $W->configure('-values' => [@values, $val]);
                       }
        });
                       
        # Pack all the labframes
        foreach my $lb ($labelFrame1, $labelFrame2, $labelFrame3){
                $lb->pack( -side => 'top', -pady => 5, -padx => 10);
        }
        
        # Pack all the comboboxes
        foreach my $cb ($cb1, $cb2, $cb3){
                $cb->pack( -pady => 5, -padx => 10);
        }
        
        
}
 

