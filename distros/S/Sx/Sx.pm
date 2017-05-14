package Sx;

require Exporter;
require DynaLoader;

@ISA = (Exporter, DynaLoader);
@EXPORT = qw(
    OpenDisplay ShowDisplay MainLoop SyncDisplay
    MakeWindow SetCurrentWindow CloseWindow
    MakeForm SetForm
    MakeButton Make3Button
    MakeLabel
    MakeToggle SetToggleState GetToggleState
    MakeDrawArea SetButtonDownCB SetButtonUpCB SetKeypressCB SetMouseMotionCB
    SetColor SetDrawMode SetLineWidth SetDrawArea GetDrawAreaSize ClearDrawArea
    DrawPixel GetPixel DrawLine DrawPolyline DrawFilledPolygon DrawFilledBox
    DrawBox DrawText DrawArc DrawFilledArc DrawImage GetImage ScrollDrawArea
    MakeStringEntry SetStringEntry GetStringEntry
    MakeTextWidget SetTextWidgetText GetTextWidgetText
    MakeHorizScrollbar MakeVertScrollbar SetScrollbar
    MakeScrollList Make3List SetCurrentListItem GetCurrentListItem
    ChangeScrollList
    MakeMenu MakeMenuItem SetMenuItemChecked GetMenuItemChecked
    SetWidgetPos AttachEdge
    SetFgColor SetBgColor SetBorderColor GetFgColor GetBgColor
    SetLabel SetWidgetState GetWidgetState SetWidgetBitmap
    Beep
    GetFont SetWidgetFont GetWidgetFont FreeFont FontHeight TextWidth
    AddTimeOut RemoveTimeOut
    AddReadCallback AddWriteCallback RemoveReadWriteCallback
    GetString GetYesNo
    GetStandardColors GetNamedColor GetRGBColor FreeStandardColors
    GetPrivateColor SetPrivateColor FreePrivateColor GetAllColors
    SetColorMap SetMyColorMap FreeAllColors
    DestroyWidget SetWidgetInt SetWidgetDat GetWidgetInt GetWidgetDat
    AppendText InsertText ReplaceText GetSelection GetTextSelectionPos
    UnsetTextSelection SetTextSelection WarpPointer
    AddTranslation
    SAME_DISPLAY ORIGINAL_WINDOW NullSx TOP_LEVEL_FORM
    WHITE BLACK RED GREEN BLUE YELLOW NONEXCLUSIVE_WINDOW EXCLUSIVE_WINDOW 
    SANE_XOR NO_CARE PLACE_RIGHT PLACE_UNDER LEFT_EDGE RIGHT_EDGE TOP_EDGE
    BOTTOM_EDGE ATTACH_LEFT ATTACH_RIGHT ATTACH_TOP ATTACH_BOTTOM
    GREY_SCALE_1 GREY_SCALE_2 RAINBOW_1 RAINBOW_2
);

$SxVersion = "2.3";
$VERSION = $SxVersion;		# for use by Exporter.pm

bootstrap Sx;

sub SAME_DISPLAY() { undef }
sub ORIGINAL_WINDOW() { undef }
sub NullSx() { undef }
sub TOP_LEVEL_FORM() { undef }


sub AddTranslation ($%) {
  my($widget,%trans_list) = @_;
  my($event,$callb,$trtable);

  while (($event,$callb) = each(%trans_list)) {
    unless ($callb =~ /[()]/) {
      $callb = "trback_to_perl($callb)";
    } elsif ($callb =~ /\(\s*\)/) {
      $callb =~ s/[()]//g;
      $callb = "trback_to_perl($callb)";
    } else {
      $callb =~ s/\(/,/;
      $callb = "trback_to_perl($callb";
    }
    $trtable .= ":$event:\t$callb\n";
  }
  Sx::AddTrans($widget,$trtable);
}

$NONEXCLUSIVE_WINDOW = 0;
$EXCLUSIVE_WINDOW = 1;
$SANE_XOR = 127;
$NO_CARE = 0;
$PLACE_RIGHT = 1;
$PLACE_UNDER = 2;
$LEFT_EDGE = 0;
$RIGHT_EDGE = 1;
$TOP_EDGE = 2;
$BOTTOM_EDGE = 3;
$ATTACH_LEFT = 0;
$ATTACH_RIGHT = 1;
$ATTACH_TOP = 2;
$ATTACH_BOTTOM = 3;
$GREY_SCALE_1 = 0;
$GREY_SCALE_2 = 1;
$RAINBOW_1 = 2;
$RAINBOW_2 = 3;

sub NONEXCLUSIVE_WINDOW() { 0 }
sub EXCLUSIVE_WINDOW() { 1 }
sub SANE_XOR() { 127 }
sub NO_CARE() { 0 }
sub PLACE_RIGHT() { 1 }
sub PLACE_UNDER() { 2 }
sub LEFT_EDGE() { 0 }
sub RIGHT_EDGE() { 1 }
sub TOP_EDGE() { 2 }
sub BOTTOM_EDGE() { 3 }
sub ATTACH_LEFT() { 0 }
sub ATTACH_RIGHT() { 1 }
sub ATTACH_TOP() { 2 }
sub ATTACH_BOTTOM() { 3 }
sub GREY_SCALE_1() { 0 }
sub GREY_SCALE_2() { 1 }
sub RAINBOW_1() { 2 }
sub RAINBOW_2() { 3 }

1;

__END__
