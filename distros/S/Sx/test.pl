use Sx;

sub MyQuit {
  print "[@_]\n";
}


sub MB {
  MakeButton('Test 2',sub { MyQuit('foo','bar') },'Anon sub',"MyBut2");
}


sub Init {
$rquit = \&MyQuit;

@args = OpenDisplay('SxTest',@_);
shift(@args);

$b1 = MakeButton('Test',$rquit,"Ref","MyBut");
$b2 = MB;
SetWidgetPos($b2,1,$b1,0,undef);

ShowDisplay;

MainLoop;

}

Init(@ARGV);
