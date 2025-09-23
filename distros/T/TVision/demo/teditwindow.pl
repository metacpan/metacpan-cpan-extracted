use strict;
use TVision('tnew');

# TRect r = deskTop->getExtent();
# TView *p = validView( new TEditWindow( r, fileName, wnNoNumber ) );
# if( !visible )
#     p->hide();
# deskTop->insert( p );

my $tapp = tnew('TVApp');
my $desktop = $tapp->deskTop;
my $teditw = tnew(TEditWindow=>$desktop->getExtent, '', 0);

my $editor = $teditw->get_editor; 
my $s = join("\n",'a'..'zzz');
$editor->insertMultilineText($s,length($s));

$desktop->insert($teditw);

$tapp->onCommand(sub {
    my ($cmd, $arg) = @_;
    print "command[@_]\n";
    if ($cmd == 123) {
    }
    elsif ($cmd == 125) {
    }
    elsif ($cmd == 1) {
	print("cmd=1, exit");
	exit;
    }
});

$tapp->run;

