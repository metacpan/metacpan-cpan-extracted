# demotbac.pl
# program demo TBackground

use
  TUI::Objects; use TUI::App; use TUI::Views;

{
  package TSampleProgram;
  use TUI::toolkit;
  extends ::TApplication;
  sub initDeskTop;
}

{
  package TNewDeskTop; 
  use TUI::toolkit;
  extends ::TDeskTop;
  sub initBackground;
}

sub TNewDeskTop::initBackground { shift;
my (
  $bounds, 
  $temp,
);
  $bounds = shift;
  $temp = TBackground->new(
    bounds => $bounds, pattern => chr( 0xff ) );
  return $temp;
}

sub TSampleProgram::initDeskTop { shift;
my (
  $bounds,
) = @_;
  $bounds->{a}{y}++; $bounds->{b}{y}--;
  return TNewDeskTop->new( bounds => $bounds );
}

package main;
  with: for ( $sampleProgram )
  {
    $_ = TSampleProgram->new;
    $_->run;
    $_ = undef;
  }
exit;
