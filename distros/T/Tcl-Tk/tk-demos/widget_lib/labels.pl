# labels.pl

use vars qw/$TOP/;

sub labels {

    # Create a top-level window that displays a bunch of labels.  @pl is the
    # "packing list" variable which specifies the list of packer attributes.

    my($demo) = @_;
    $TOP = $MW->WidgetDemo(
        -name     => $demo,
        -text     => 'Five labels are displayed below: three textual ones on the left, and an image label and a text label on the right.  Labels are pretty boring because you can\'t do anything with them.',
        -title    => 'Label Demonstration',
        -iconname => 'label',
    );

    my(@pl) = qw/-side left -expand yes -padx 10 -pady 10 -fill both/;
    my $left = $TOP->Frame->pack(@pl);
    my $right = $TOP->Frame->pack(@pl);

    @pl = qw/-side top -expand yes -pady 2 -anchor w/;
    my $left_l1 = $left->Label(-text => 'First label')->pack(@pl);
    my $left_l2 = $left->Label(
        -text   => 'Second label, raised just for fun',
        -relief => 'raised',
    )->pack(@pl);
    my $left_l3 = $left->Label(
        -text   => 'Third label, sunken',
        -relief => 'sunken',
    )->pack(@pl);

    my $left_l4 = $left->Label(
        -font	=> 20,
        -justify => 'left',
        -anchor	=> 'n',
        -text   => <<"EOS",

Unicode strings

Arabic		\x{FE94}\x{FEF4}\x{FE91}\x{FEAE}\x{FECC}\x{FEDF}\x{FE8D}\x{FE94}\x{FEE4}\x{FEE0}\x{FEDC}\x{FEDF}\x{FE8D}
Trad. Chinese	\x{4E2D}\x{570B}\x{7684}\x{6F22}\x{5B57}
Simpl. Chinese	\x{6C49}\x{8BED}
Greek		\x{0395}\x{03BB}\x{03BB}\x{03B7}\x{03BD}\x{03B9}\x{03BA}\x{03AE} \x{03B3}\x{03BB}\x{03CE}\x{03C3}\x{03C3}\x{03B1}
Hebrew		\x{05DD}\x{05D9}\x{05DC}\x{05E9}\x{05D5}\x{05E8}\x{05D9} \x{05DC}\x{05D9}\x{05D0}\x{05E8}\x{05E9}\x{05D9}
Japanese		\x{65E5}\x{672C}\x{8A9E}\x{306E}\x{3072}\x{3089}\x{304C}\x{306A}, \x{6F22}\x{5B57}\x{3068}\x{30AB}\x{30BF}\x{30AB}\x{30CA}
Korean		\x{B300}\x{D55C}\x{BBFC}\x{AD6D}\x{C758} \x{D55C}\x{AE00}
Russian		\x{0420}\x{0443}\x{0441}\x{0441}\x{043A}\x{0438}\x{0439} \x{044F}\x{0437}\x{044B}\x{043A}
EOS
    )->pack(@pl);

    @pl = qw/-side top/;
    my $right_bitmap = $right->Label(
        -image       => $TOP->Photo(-file => Tk->findINC('Xcamel.gif')),
        -borderwidth => 2,
	-relief      => 'sunken',
    )->pack(@pl);
    my $right_caption = $right->Label(-text => 'Perl/Tk')->pack(@pl);

} # end labels

1;
