#!/usr/bin/perl -I../lib -w
use Remote::Use config => 'rsyncconfig';
# Warning! the first time takes a long time to load from a remote source

# tempcon version 0.1      for Perl/Tk
# by Alan Ford <alan@whirlnet.demon.co.uk> 27/03/1999
# Allows conversion of temperatures between different scales

require 5.002;
use English;
use Tk;
use Tk::DialogBox;
# use strict;
sub convert ;

my $MW = MainWindow->new;

$MW->title("Temperature Converter");
$MW->Label(-text => "Version 0.1 - Written by Alan Ford\n<alan\@whirlnet.demon.co.uk>")->pack(-side => 'bottom');

my $ans;

my $exit = $MW->Button(-text => 'Exit',
                        -command => sub 
                        {
                         #print STDOUT "Goodbye.\n";
                         exit;
                        });
$exit->pack(-side => 'bottom', -expand => '1', -fill => 'both');

my $convert = $MW->Button(-text => 'Convert',
                        -command => sub 
                        {
                         convert;
                        });
$convert->pack(-side => 'bottom', -expand => '1', -fill => 'both');

my $answer_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side
=> 'bottom');

$answer_frame->Label(-text => "Converted value:")->pack(-side => 'left');
my $answer_value = $answer_frame->Entry(-width => '15', -relief => 'sunken')->pack(-side => 'right');

my $value_frame = $MW->Frame()->pack(-expand => '1', -fill => 'both', -side =>
'bottom');

$value_frame->Label(-text => "Enter value to convert:")->pack(-side => 'left');
my $convert_value = $value_frame->Entry(-width => '10', -relief => 'sunken')->pack(-side => 'right');
#$convert_value->bind('<Enter>' => convert);

my $from_frame = $MW->Frame(-relief => 'raised', -width => '100', -height => '200');
$from_frame->pack(-side => 'left', -expand => '1', -fill => 'both');

my $to_frame = $MW->Frame(-relief => 'raised', -width => '100', -height => '200');
$to_frame->pack(-side => 'right', -expand => '1', -fill => 'both');

$from_frame->Label(-text => "Convert From")->pack();
my $from_celsius = $from_frame->Radiobutton(-variable => \$from,
                                            -value    => '1',
                                            -text     => 'Celsius')->pack(-side => 'top', -anchor => 'w');

my $from_fahrenheit = $from_frame->Radiobutton(-variable => \$from,
                                               -value    => '2',
                                               -text     => 'Fahrenheit')->pack(-side => 'top', -anchor => 'w');

my $from_kelvin = $from_frame->Radiobutton(-variable => \$from,
                                           -value    => '3',
                                           -text     => 'Kelvin')->pack(-side => 'top', -anchor => 'w');

my $from_rankine = $from_frame->Radiobutton(-variable => \$from,
                                            -value    => '4',
                                            -text     => 'Rankine')->pack(-side => 'top', -anchor => 'w');

my $from_reaumur = $from_frame->Radiobutton(-variable => \$from,
                                            -value    => '5',
                                            -text     => 'Reaumur')->pack(-side => 'top', -anchor => 'w');

$to_frame->Label(-text => "Convert To")->pack();
my $to_celsius = $to_frame->Radiobutton(-variable => \$to,
                                        -value    => '1',
                                        -text     => 'Celsius')->pack(-side => 'top', -anchor => 'w');

my $to_fahrenheit = $to_frame->Radiobutton(-variable => \$to,
                                           -value    => '2',
                                           -text     => 'Fahrenheit')->pack(-side => 'top', -anchor => 'w');

my $to_kelvin = $to_frame->Radiobutton(-variable => \$to,
                                       -value    => '3',
                                       -text     => 'Kelvin')->pack(-side => 'top', -anchor => 'w');

my $to_rankine = $to_frame->Radiobutton(-variable => \$to,
                                        -value    => '4',
                                        -text     => 'Rankine')->pack(-side => 'top', -anchor => 'w');

my $to_reaumur = $to_frame->Radiobutton(-variable => \$to,
                                        -value    => '5',
                                        -text     => 'Reaumur')->pack(-side => 'top', -anchor => 'w');

#set defaults: Centigrade to Fahrenheit

$from_celsius->select;
$to_fahrenheit->select;

MainLoop;

#subs here
sub convert {
    my $question = $convert_value->get;
    #my $ans; #now set earlier
    if ($from == '1') {
        if ($to == '1') {
            $ans = $question;
        }
        if ($to == '2') {
            $ans = ($question * 1.8) + 32;
        }
        if ($to == '3') {
            $ans = $question + 273.16;
        }
        if ($to == '4') {
            $ans = ($question + 273.16) * 1.8;
        }
        if ($to == '5') {
            $ans = $question / 1.25;
        }
    }
    if ($from == '2') {
        if ($to == '1') {
            $ans = ($question - 32) / 1.8;
        }
        if ($to == '2') {
            $ans = $question;
        }
        if ($to == '3') {
            $ans = ($question + 459.67) / 1.8;
        }
        if ($to == '4') {
            $ans = $question + 459.67;
        }
        if ($to == '5') {
            $ans = ($question - 273.16) / 1.25;
        }
    }
    if ($from == '3') {
        if ($to == '1') {
            $ans = $question - 273.16;
        }
        if ($to == '2') {
            $ans = ($question * 1.8) - 459.67;
        }
        if ($to == '3') {
            $ans = $question;
        }
        if ($to == '4') {
            $ans = $question * 1.8;
        }
        if ($to == '5') {
            $ans = ($question - 273.16) / 1.25;
        }
    }
    if ($from == '4') {
        if ($to == '1') {
            $ans = ($question / 1.8) - 273.16;
        }
        if ($to == '2') {
            $ans = $question - 459.67;
        }
        if ($to == '3') {
            $ans = $question / 1.8;
        }
        if ($to == '4') {
            $ans = $question;
        }
        if ($to == '5') {
            $ans = (($question / 1.8) - 273.16) / 1.25;
        }
    }
    if ($from == '5') {
        # easy way out: first convert to kelvin
        my $kelvin = ($question * 1.25) + 273.16;
        if ($to == '1') {
            $ans = $kelvin - 273.16;
        }
        if ($to == '2') {
            $ans = ($kelvin * 1.8) - 459.67;
        }
        if ($to == '3') {
            $ans = $kelvin;
        }
        if ($to == '4') {
            $ans = $kelvin * 1.8;
        }
        if ($to == '5') {
            $ans = ($kelvin - 273.16) / 1.25;
        }
    }
    
    $answer_value->delete('0', 'end');
    $answer_value->insert('0', $ans);
    
    my $dialog = $MW->DialogBox( -title   => "Temperature Converter",
                                 -buttons => [ "OK" ],
                                );
    @scales = ("degrees Celsius", "degrees Fahrenheit", "Kelvin", "degrees Rankine", "degrees Reaumur");
    $dialog->add("Label", -text => "$question $scales[$from-1] is $ans $scales[$to-1]")->pack;
    $dialog->Show;
}
