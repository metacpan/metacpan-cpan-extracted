use Sx;

$X_SIZE = 300;
$Y_SIZE = 300;
$FALSE = 0;
$TRUE = 1;
$GXcopy = 3;


@string_table = (
  "Metallica", "Black Sabbath", "Diamond Head", "Budgie", "Dio",
  "Ozzy Osbourne", "Flotsam and Jetsam", "George Micheal", "Slayer",
  "Candlemass", "Van Halen", "W.A.S.P.", "Anthrax", "Soundgarden",
  "Iron Maiden", "The Cult", "Danzig", "Queensryche", "Motorhead",
  "AC/DC", "Led Zepplin", "Misfits", "Jimi Hendrix", "Nudeswirl",
  "Nirvana", "Vivaldi", "Holst", "Ravel", "B-52's", "Ice Cube", "Yes",
  "The Police", "The Cure", "Minor Threat", "Cro-Mags", "Agnostic Front",
  "Ministry", "Ice-T", "N.W.A", "Run-DMC", "Deep Purple", "Agent Orange"
);


sub do_redisplay {
  local($who,$width,$height) = @_;
  local($i, $str);
  $str = "My Cool Program";

  if ($me_in_color_mode) {
    &do_colorstuff;
    return;
  }

  SetBgColor($who, WHITE);
  ClearDrawArea;

  SetColor(BLACK);
  SetBgColor($who, GREEN);
  DrawText($str, ($width-TextWidth($me_draw_font, $str))/2, $height/2); 

  SetBgColor($who, WHITE);
  SetColor($me_col1);
  for($i=0; $i < $width; $i+=5) {
    DrawLine(0,$i, $i,$height);
  }
  SetColor($me_col2);
  for($i=0; $i < $width; $i+=5) {
    DrawLine($width,$i, $width-$i,$height);
  }
}



sub do_colorstuff {
  local($i);

  for($i=0; $i < 256; $i++) {
    SetColor($i);
    DrawLine($i,0, $i,255);
  }
}


sub quit {
  local($w) = @_;
  local($index,$str);

  $str = GetStringEntry($me_str_entry);
  print "Final value for string entry is: $str\n";

  $index = GetCurrentListItem($me_list);
  print "Current list index is: $index\n";
  exit;
}



sub Mload {
  local($w) = @_;

  local($fname);

  $fname = GetString("Enter name of file to load:", "Foobar.c");
  if ($fname) {
    print "You entered: $fname\n";
  } else {
    print "You clicked cancel.\n";
  }
}


sub Msave {
  local($w) = @_;

  local($ans);

  $ans = GetYesNo("\nAre you a weenie ?\n\n");

  if ($ans == $TRUE) {
    print "You're a weenie.\n";
  } else {
    print "You are not a weenie.\n";
  }
}


sub scroll_func {
local($w,$val) = @_;
  print "new value is: $val\n";
}


sub string_func {
local($w, $txt) = @_;

  print "Got text: $txt\n";
  
  if (-f $txt) {
    SetTextWidgetText($me_text_widget, $txt, $TRUE);
  } else {
    SetTextWidgetText($me_text_widget, $txt, $FALSE);
  }
}



sub list_callback {
local($w, $str, $index) = @_;

  print "In list callback, got item: $str  index==$index\n";
}


$counter = 2; $asked = 0;

sub do_stuff {
  local($w) = @_;
  local($i, $str);

  $str="This takes over the colormap of the display.\n\n Are you Sure?";

  return if ($asked == $FALSE && GetYesNo($str) == $FALSE);
  $asked=1;

  GetAllColors;
  SetColorMap($counter);
  $counter = ($counter + 1) % 4;

  SetFgColor($me_quit,     248);
  SetBorderColor($me_quit, 248);

  SetFgColor($me_color_widget,     248);
  SetBorderColor($me_color_widget, 248);

  $me_in_color_mode = 1;
  for($i=0; $i < 256; $i++) {
    SetColor($i);
    DrawLine($i,0, $i,255);
  }
}

$toggle = 0;

sub check_me {
local($w) = @_;

  $toggle ^= 1;
  SetMenuItemChecked($w, $toggle);
}


sub more_stuff {
  local($w) = @_;
  local($width,$height);
  
  $width=100,$height=100;
  
  print "More stuff...\n";

  ScrollDrawArea(0, FontHeight($me_draw_font), 0,0, 300,300);
}


sub toggle1 {
local($w) = @_;

  $me_toggle1 ^= 1;

  print "toggle 1 changing state: $me_toggle1\n";
}

sub toggle2 {
local($w) = @_;

  $me_toggle2 ^= 1;

  print "toggle 2 changing state: $me_toggle2\n";
}

sub toggle3 {
local($w) = @_;

  $me_toggle3 ^= 1;

  print "toggle 3 changing state: $me_toggle3\n";
}

sub toggle4 {
local($w) = @_;

  $me_toggle4 ^= 1;

  print "toggle 4 changing state: $me_toggle4\n";
}

sub other_toggle {
local($w) = @_;

  $me_other_toggle ^= 1;

  print "other toggle changing state: $me_other_toggle\n";
}


sub menu_item1 {
  local($w) = @_;
  print "menu item 1 chosen\n";
}

sub menu_item2 {
  local($w) = @_;
  print "menu item 2 chosen\n";
}

sub menu_item3 {
  local($w) = @_;
  print "menu item 3 chosen\n";
}

sub menu_item4 {
  local($w) = @_;
  print "menu item 4 chosen\n";
}



sub redisplay {
  local($w, $new_width, $new_height) = @_;
  &do_redisplay($w, $new_width, $new_height);
}



sub button_down {
  local($w, $which_button, $x, $y) = @_;
  
  print "You pressed mouse button $which_button at ($x,$y)\n";

  $me_down = $which_button;
  $me_oldx = $me_startx = $x;
  $me_oldy = $me_starty = $y;

  SetMouseMotionCB($w, 'motion');
  SetDrawMode(SANE_XOR);
  SetColor($me_col1);
  SetBgColor($me_draw_widget, WHITE);
}


sub button_up {
  local($w, $which_button, $x, $y) = @_;
  
  print "You released mouse button $which_button at ($x,$y)\n";

  $me_down = 0;
  SetDrawMode($GXcopy);
  SetMouseMotionCB($w, '');
}


sub keypress {
  local($w, $input, $up_or_down) = @_;
  local($str);

  return unless ($input);

  if ($up_or_down == 0) {
    $str = "Down";
  } else {
    $str = "up";
  }
  
  print "Key: <<$input>> $str\n";
}



sub motion {
  local($w, $x, $y) = @_;
  local($owidth, $oheight);
  
  $owidth  = $me_oldx - $me_startx;
  $oheight = $me_oldy - $me_starty;
  
  if ($me_down == 1) {
    DrawBox($me_startx, $me_starty, $owidth, $oheight);
    DrawBox($me_startx, $me_starty, ($x - $me_startx), ($y - $me_starty));
  } elsif ($me_down == 2) {
    DrawArc($me_startx, $me_starty, $owidth, $oheight, 0, 360);
    DrawArc($me_startx, $me_starty, ($x-$me_startx),($y-$me_starty), 360,360);
  } elsif ($me_down == 3) {
    DrawFilledBox($me_startx, $me_starty, $owidth, $oheight);
    DrawFilledBox($me_startx, $me_starty, ($x - $me_startx), ($y - $me_starty));
  }
  $me_oldx = $x;
  $me_oldy = $y;
}




OpenDisplay('Foo Bar');

$w[0]  = MakeMenu("File");
$w[1]  = MakeMenuItem($w[0], "Load...",  'Mload', undef);
$w[2]  = MakeMenuItem($w[0], "Save...",  'Msave', undef);
$w[3]  = MakeMenuItem($w[0], "Quit",     'quit', undef);
 
$w[4]  = MakeMenu("Edit");
$w[5]  = MakeMenuItem($w[4], "Check me", 'check_me', undef);
$w[6]  = MakeMenuItem($w[4], "Copy",  '', undef);
$w[7]  = MakeMenuItem($w[4], "Paste", '', undef);
  
$w[8]  = MakeButton("Color Stuff", 'do_stuff', undef); 
$w[9]  = MakeButton("More Stuff",  'more_stuff', undef);
$w[10] = MakeButton("Quit!",       'quit', undef);

$w[11] = MakeDrawArea($X_SIZE, $Y_SIZE, 'redisplay', undef);
$w[12] = MakeScrollList(125, 275, 'list_callback', '', @string_table);
  
$w[13] = MakeHorizScrollbar($X_SIZE, 'scroll_func', undef);
$w[14] = MakeHorizScrollbar($X_SIZE, 'scroll_func', undef);
$w[15] = MakeVertScrollbar($Y_SIZE, 'scroll_func', undef);

$w[16] = MakeToggle("Slow",    $TRUE, undef,  'toggle1', undef);
$w[17] = MakeToggle("Fast",    $FALSE, $w[16], 'toggle2', undef);
$w[18] = MakeToggle("Faster",  $FALSE, $w[16], 'toggle3', undef);
$w[19] = MakeToggle("Fastest", $FALSE, $w[16], 'toggle4', undef);

$w[20] = MakeToggle("Toggle me", $FALSE, undef, 'other_toggle', undef);

$w[21] = MakeStringEntry("button.c", 435, 'string_func', undef);
$w[22] = MakeTextWidget("button.c", $TRUE, $TRUE, 435, 200);
$w[23] = MakeLabel("   A Sample LibSx Demo Program (cool huh?)");

SetWidgetPos($w[4],  PLACE_RIGHT, $w[0], NO_CARE, undef);

SetWidgetPos($w[8],  PLACE_UNDER, $w[0], NO_CARE, undef);
SetWidgetPos($w[9],  PLACE_UNDER, $w[0], PLACE_RIGHT, $w[8]);
SetWidgetPos($w[10], PLACE_UNDER, $w[0], PLACE_RIGHT, $w[9]);

SetWidgetPos($w[11], PLACE_UNDER, $w[8], NO_CARE, undef); 

SetWidgetPos($w[13], PLACE_UNDER, $w[11], NO_CARE, undef);
SetWidgetPos($w[14], PLACE_UNDER, $w[13], NO_CARE, undef);
SetWidgetPos($w[15], PLACE_RIGHT, $w[11], PLACE_UNDER, $w[8]);

SetWidgetPos($w[12], PLACE_RIGHT, $w[15], PLACE_UNDER, $w[8]);

SetWidgetPos($w[16], PLACE_RIGHT, $w[13], PLACE_UNDER, $w[15]);
SetWidgetPos($w[17], PLACE_RIGHT, $w[16], PLACE_UNDER, $w[15]);
SetWidgetPos($w[18], PLACE_RIGHT, $w[13], PLACE_UNDER, $w[16]);
SetWidgetPos($w[19], PLACE_RIGHT, $w[18], PLACE_UNDER, $w[16]);

SetWidgetPos($w[20], PLACE_RIGHT, $w[10], PLACE_UNDER, $w[0]);
SetWidgetPos($w[21], PLACE_UNDER, $w[18], NO_CARE, undef);
SetWidgetPos($w[22], PLACE_UNDER, $w[21], NO_CARE, undef);
SetWidgetPos($w[23], PLACE_RIGHT, $w[4], NO_CARE, undef);


$me_toggle1 = $TRUE;
$me_toggle2 = $me_toggle3 = $me_toggle4 = $me_other_toggle = $FALSE;

$me_list         = $w[12];  
$me_str_entry    = $w[21];
$me_text_widget  = $w[22];
$me_draw_widget  = $w[11];
$me_quit         = $w[10];
$me_color_widget = $w[8];

$me_draw_font = GetFont("10x20");

SetWidgetFont($me_draw_widget, $me_draw_font);

SetButtonDownCB($w[11], 'button_down');
SetButtonUpCB($w[11],   'button_up');
SetKeypressCB($w[11],   \&keypress);

SetScrollbar($w[13],   3.0,  14.0, 14.0);
SetScrollbar($w[14], 250.0, 255.0,  1.0);
SetScrollbar($w[15],  30.0, 100.0, 25.0);

ShowDisplay;


GetStandardColors;

$me_col1 = GetNamedColor("peachpuff2");
warn  "Error getting color peachpuff" if ($me_col1 == -1);

$me_col2 = GetRGBColor(255, 0, 255);
warn "Error getting RGB color 0 255 255" if ($me_col2 == -1);

MainLoop;


