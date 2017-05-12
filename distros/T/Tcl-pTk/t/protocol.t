# Test Case for bind and commands
#

use Tcl::pTk;
#use Tk;
use Test;

plan tests => 4;

$| = 1;

my $TOP = MainWindow->new;

my $button1Pressed = 0;
my $button2Pressed = 0;

my $b = $TOP->Button( -text    => 'Button1',
                      -width   => 10,
                      -command => sub { $button1Pressed = 1; },
);
$b->pack(qw/-side top -expand yes -pady 2/);

my $b2 = $TOP->Button( -text    => 'Button2',
                      -width   => 10,
                      -command => sub { $button2Pressed = 1; },
);
$b2->pack(qw/-side top -expand yes -pady 2/);

# Set Protocol
$TOP->protocol('WM_DELETE_WINDOW' =>  sub{ print "I'm melting!\n"; $TOP->destroy});

my @protos = $TOP->protocol();
ok( join(", ", @protos), 'WM_DELETE_WINDOW', "protocol return with no args");
#print "protos = ".join(", ", @protos)."\n";

my $protoCallback = $TOP->protocol('WM_DELETE_WINDOW');
ok( ref($protoCallback), 'Tcl::pTk::Callback', "Protocol WM_DELETE_WINDOW Returns Callback Object");

# Un-set a protocol
$TOP->protocol('WM_DELETE_WINDOW' =>  undef);
$protoCallback = $TOP->protocol('WM_DELETE_WINDOW');
ok( defined($protoCallback), "", "Undefined Protocol WM_DELETE_WINDOW Returns undef");

# Test Wm Delete Window
my $deleteVar = 0;

$TOP->protocol(WM_DELETE_WINDOW => sub{ $deleteVar = 1; $TOP->destroy});

$TOP->after(2000, sub{ $TOP->WmDeleteWindow });

MainLoop;

ok( $deleteVar, 1, "WmDeleteWindow method");


exit;


