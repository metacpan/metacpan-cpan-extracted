# button.pl

#use Tk;
#use Tk::Balloon;

use Tcl::pTk;

use Test;

plan test => 1;

my $TOP0 = MainWindow->new(-title=> 'First Mainwindow');

my $button0 = $TOP0->Button(-text => 'Simple Button')->pack;

my $TOP = MainWindow->new;


my $bln = $TOP->Balloon();

	my $b = $TOP->Button( Name => 'btn',
            -text    => "Balloon Test",
            -width   => 10,
        )->pack;
 
$bln->attach($b, -msg => "Popup help");

$TOP->after(1000, sub{
                
                print STDERR "Balloon should appear over 'Balloon Text' button\n";
                
                $TOP0->lower;
                
                $button0->Busy;
                $b->eventGenerate('<Motion>', -x => 10, -y => 10);
                $button0->Unbusy;

}
);
$TOP->after(5000, sub{
                $button0->Unbusy;
                $TOP0->destroy;
                $TOP->destroy;
}
);

MainLoop;

ok(1);
