use strict;
use TVision qw(:keys :commands tnew);

use constant {
  hcCancelBtn            => 35,
  hcFCChDirDBox          => 37,
  hcFChangeDir           => 15,
  hcFDosShell            => 16,
  hcFExit                => 17,
  hcFOFileOpenDBox       => 31,
  hcFOFiles              => 33,
  hcFOName               => 32,
  hcFOOpenBtn            => 34,
  hcFOpen                => 14,
  hcFile                 => 13,
  hcNoContext            => 0,
  hcOCColorsDBox         => 39,
  hcOColors              => 28,
  hcOMMouseDBox          => 38,
  hcOMouse               => 27,
  hcORestoreDesktop      => 30,
  hcOSaveDesktop         => 29,
  hcOpenBtn              => 36,
  hcOptions              => 26,
  hcPuzzle               => 3,
  hcSAbout               => 8,
  hcSAsciiTable          => 11,
  hcSystem               => 7,
  hcViewer               => 2,
  hcWCascade             => 22,
  hcWClose               => 25,
  hcWNext                => 23,
  hcWPrevious            => 24,
  hcWSizeMove            => 19,
  hcWTile                => 21,
  hcWZoom                => 20,
  hcWindows              => 18,
};

my $submenu0 = tnew(TSubMenu=>"~s~ubmenu", 0, 0 );
my @mi = map {tnew(TMenuItem=> 'aaa', 201, kbNoKey)} 0 .. 3;
my $mnam = 'aaa';

my $sub1 =
    TVision::TSubMenu::new( "~\xf0~тут системно", 0, hcSystem )
      -> plus ( TVision::TMenuItem::new( "~A~bout...", cmAboutCmd, kbNoKey, hcSAbout ) )
    -> plus (
	TVision::TSubMenu::new( "~т~ут ещё", 0, 0 )
	  -> plus ( TVision::TMenuItem::new( "~A~bout 2...", cmAboutCmd, kbNoKey, hcSAbout ) )
    )
    #-> plus ( [map {$submenu0->plus($mi[0])} 0 .. 0]->[0])
    #-> plus ( $submenu0)
    -> plus (
	$submenu0
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TSubMenu::new("~x~ubmenu", 0, 0 )
		->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
		->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
		->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    )
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
	    ->plus(TVision::TMenuItem::new( $mnam++, 201, kbNoKey))
    )
    -> plus (
    TVision::TSubMenu::new( "~W~indows", 0, hcWindows )
        -> plus ( TVision::TMenuItem::new( "~R~esize/move", cmResize, kbCtrlF5, hcWSizeMove, "Ctrl-F5" ) )
        -> plus ( TVision::TMenuItem::new( "~Z~oom", cmZoom, kbF5, hcWZoom, "F5" ) )
        -> plus ( TVision::TMenuItem::new( "~N~ext", cmNext, kbF6, hcWNext, "F6" ) )
        -> plus ( TVision::TMenuItem::new( "~C~lose", cmClose, kbAltF3, hcWClose, "Alt-F3" ) )
        -> plus ( TVision::TMenuItem::new( "~T~ile", cmTile, kbNoKey, hcWTile ) )
        -> plus ( TVision::TMenuItem::new( "C~a~scade", cmCascade, kbNoKey, hcWCascade ) )
     )
;
print "last mnam is $mnam\n";

my $menubar = tnew TMenuBar=>([0,0,179,1],$sub1);
my $tapp = tnew TVApp => $menubar;

my $desktop = $tapp->deskTop;
$tapp->onCommand(sub {
    my ($cmd, $arg) = @_;
    print "command[@_]\n";
    if ($cmd == 123) {
	#button pressed
	#$b->locate(15,15,30,17);
    }
    elsif ($cmd == 125) {
    }
});
$tapp->run;

