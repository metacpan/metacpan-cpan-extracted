# Test to check error reporting for a background error (with TkHijack Active)
#   that occurs due to a undefined sub in a megawidget

use Test;
BEGIN {plan tests=>4};

use Tcl::pTk::TkHijack;


package Tk::SlideSwitch;
use Tk;
use Tk::TextUndo;
use base qw/Tk::Frame/;


use strict;

Construct Tk::Widget 'SlideSwitch';
#Construct Tk::Widget 'SlideSwitch';

sub Populate {

    my($self, $args) = @_;

    $self->SUPER::Populate($args);

    
    my $mw = $self->MainWindow();
    
    
    my $ll = $self->Label->pack(-side => 'left');
    my $sl = $self->Scale->pack(-side => 'left');
    my $rl = $self->Label->pack(-side => 'left');
    
    
    $self->ConfigSpecs(
        -command      => [$sl,        qw/command      Command            /],  
        -from         => [$sl,        qw/from         From              0/],
        -highlightthickness => [$sl,
            qw/highlightThickness HighlightThickness                    0/],
        -length       => [$sl,        qw/length       Length           30/],
        -llabel       => [qw/METHOD      llabel       Llabel             /],
        -orient       => [$sl,        qw/orient       Orient   horizontal/],
        -rlabel       => [qw/METHOD      rlabel       Rlabel             /],  
        -showvalue    => [$sl,        qw/showValue    ShowValue         0/],
        -sliderlength => [$sl,        qw/sliderLength SliderLength     15/],
        -sliderrelief => [$sl,        qw/sliderRelief SliderRelief raised/],
        -to           => [$sl,        qw/to           To                1/],
        -troughcolor  => [$sl,        qw/troughColor  TroughColor        /],
        -width        => [$sl,        qw/width        Width             8/],
        -variable     => [$sl,        qw/variable     Variable           /],
        'DEFAULT'     => [$ll, $rl],
    );

    $self->{ll} = $ll;
    $self->{sl} = $sl;
    $self->{rl} = $rl;
    
    $self->Advertise($sl => 'Scale');

    $self->bind('<Configure>' => sub {
	my ($self) = @_;
	my $orient = $self->cget(-orient);
	return if $orient eq 'horizontal';
	my ($ll, $sl, $rl) = ($self->{ll}, $self->{sl}, $self->{rl});
	$ll->packForget;
	$sl->packForget;
	$rl->packForget;
	$ll->pack;
	$sl->pack;
	$rl->pack;
    });

} # end Populate

# Private methods and subroutines.

sub llabel {
    my ($self, $args) = @_;
    $self->{ll}->configure(@$args);
} # end llabel

sub rlabel {
    my ($self, $args) = @_;
    $self->{rl}->configure(@$args);
} # end rlabel

1;

##############################################################################

package main;

use Tk;

# Setup to redirect stderr to file, so we can check it.
# Save existing StdErr
*OLD_STDERR = *STDERR;
open(my $stderr, '>', 'serr.out');
*STDERR = $stderr;

my $TOP = MainWindow->new();



    my $mw = $TOP;

    my $sl = $mw->SlideSwitch(
        -bg          => 'gray',
        -orient      => 'horizontal',
        -command     => sub {
                                print "Switch value is '".join("', '", @_)."'\n";
                                 main::bogus(); # Call undefined routine to trigger error

                            },
        -llabel      => [-text => 'OFF', -foreground => 'blue'],
        -rlabel      => [-text => 'ON',  -foreground => 'blue'],
        -troughcolor => 'tan',
    )->pack(qw/-side left -expand 1/);


$mw->after(2000, [$mw, 'destroy']);

MainLoop;
    
# Redirect stderr back
*STDERR = *OLD_STDERR;

# Close error messages file and read it
close $stderr;

open(INFILE, 'serr.out');
my $errMessages = '';
while( <INFILE> ){
        $errMessages .= $_;
};
close INFILE;

# Check error messages for key components
ok( $errMessages =~ /Undefined subroutine\s+\&main\:\:bogus/);
ok( $errMessages =~ /command executed by scale/);
ok( $errMessages =~ /Error Started at t\/tkHijack_bgerror2.t line 124/);
ok( $errMessages =~ / Undefined subroutine \&main::bogus called at t\/tkHijack_bgerror2.t line 113/);

unlink 'serr.out';

