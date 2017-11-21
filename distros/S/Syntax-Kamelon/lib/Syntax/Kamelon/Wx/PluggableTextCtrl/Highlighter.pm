package Syntax::Kamelon::Wx::PluggableTextCtrl::Highlighter;

use strict;
use warnings;
use Carp;

use Wx qw( :textctrl :font :colour :timer );
use base qw( Syntax::Kamelon::Wx::PluggableTextCtrl::BasePlugin );
use Wx::Event qw( EVT_TIMER );

my $debug = 0;

if ($debug) {
   use Data::Dumper;
}

my $defaultfont = [10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0];

my $blue                = [0x00, 0x00, 0xff];
my $lightblue           = [0xad, 0xd8, 0xe6];
my $darkblue            = [0x00, 0x00, 0x80];
my $green               = [0x00, 0xff, 0x00];
my $lightgreen          = [0x90, 0xee, 0x90];
my $darkgreen           = [0x00, 0x80, 0x00];
my $lightbrown          = [0xe5, 0x6a, 0x6a];
my $brown               = [0xa5, 0x2a, 0x2a];
my $darkbrown           = [0x85, 0x1a, 0x1a];
my $lightred            = [0xff, 0x6f, 0x6f];
my $red                 = [0xff, 0x00, 0x00];
my $darkred             = [0xaf, 0x00, 0x00];
my $orange              = [0xff, 0xa5, 0x00];
my $lightpurple         = [0xb0, 0x00, 0xb0];
my $purple              = [0x80, 0x00, 0x80];
my $cyan                = [0x00, 0xaa, 0xaa];
my $magenta             = [0xaf, 0x55, 0xaf];
my $lightyellow         = [0xff, 0xff, 0x56];
my $yellow              = [0xff, 0xff, 0x00];
my $darkyellow          = [0xcf, 0xcf, 0x00];
my $lightbeige          = [0xf5, 0xf5, 0xef];
my $beige               = [0xf5, 0xf5, 0xdc];
my $darkbeige           = [0xf5, 0xf5, 0xa9];
my $lightgray           = [0xcf, 0xcf, 0xcf];
my $gray                = [0x80, 0x80, 0x80];
my $darkgray            = [0x4f, 0x4f, 0x4f];
my $black               = [0x10, 0x10, 0x10];
my $white               = [0xef, 0xef, 0xef];


my $defaultstyles = [
   ['Alert', $orange, $blue],
   ['Annotation', $orange, $lightgray],
   ['Attribute', $darkbrown],
   ['BaseN', $darkgreen],
   ['BString', $purple],
   ['BuiltIn', $lightbrown],
   ['Char', $magenta],
   ['Comment', $gray, undef, [undef, undef, wxFONTSTYLE_ITALIC]],
   ['CommentVar', $blue, undef, [undef, undef, wxFONTSTYLE_ITALIC]],
   ['Constant', $darkblue],
   ['DataType', $blue],
   ['DecVal', $darkblue, undef, [undef, undef, undef, wxFONTWEIGHT_BOLD]],
   ['Documentation', $darkgray, $lightbeige],
   ['Error',  $red, $yellow],
   ['Extension',  $darkgray, $lightyellow],
   ['Float', $darkblue, undef, [undef, undef, undef, wxFONTWEIGHT_BOLD]],
   ['Function', $brown],
   ['Import', $darkbrown],
   ['IString', $lightred],
   ['Information', $darkgray, $lightgreen],
   ['Keyword', $darkgreen, undef, [undef, undef, undef, wxFONTWEIGHT_BOLD]],
   ['Normal', $black],
   ['Operator', $orange],
   ['Others', $cyan],
   ['Preprocessor', $darkgray, $lightgreen],
   ['RegionMarker', $lightblue],
   ['Reserved', $purple, $beige],
   ['SpecialChar', $purple],
   ['SpecialString', $lightpurple],
   ['String', $red],
   ['Variable', $lightblue, undef, [undef, undef, undef, wxFONTWEIGHT_BOLD]],
   ['VerbatimString', $lightred],
   ['Warning', $blue, $yellow],
];

sub new {
   my $class = shift;
   my $txtctrl = shift;
   my $engine = shift;
   my $self = $class->SUPER::new($txtctrl);
   my ($mode, $noindex, $verbose, $xmldir) = @_;

   $self->{ACTIVE} = 0;
   $self->{BASICSTATE} = undef;
   $self->{BLOCKSIZE} = 128;
   $self->{ENABLED} = 0;
   $self->{ENGINE} = $engine;
   $self->{HLEND} = 0;
   $self->{INTERVAL} = 1;
   $self->{LINEINFO} = [];
   $self->{STYLES} = {};
	my $tid = Wx::NewId;
   $self->{TIMER} = Wx::Timer->new($self->TxtCtrl, $tid);
   
   $self->SetStyles($defaultstyles);
   $self->Commands(
      'clear' => \&Clear,
      'load' => \&Load,
      'syntax' => \&Syntax,

      'doremove' => \&Purge,
      'doreplace' => \&Purge,
      'dowrite' => \&Purge,
      'remove' => \&Purge,
      'replace' => \&Purge,
      'write' => \&Purge,
   );
   $self->EngineInit;
   $self->Require('KeyEchoes');

   EVT_TIMER($self->TxtCtrl, $tid, sub { $self->Loop });

   return $self;
}

sub BasicState {
   my $self = shift;
   if (@_) { $self->{BASICSTATE} = shift; }
   return $self->{BASICSTATE};
}

sub BlockSize {
   my $self = shift;
   if (@_) { $self->{BLOCKSIZE} = shift; }
   return $self->{BLOCKSIZE};
}

sub Active {
   my $self = shift;
   return $self->{ACTIVE};
}

sub Clear {
   my $self = shift;
   my $tc = $self->TxtCtrl;
   $tc->SetStyle(0, $tc->GetLastPosition, $self->Styles->{'Normal'});
   $self->Engine->Reset;
   $self->{LINEINFO} = [];
   $self->HlEnd(0);
   return 0
}

sub Enabled {
   my $self = shift;
   if (@_) {
      my $state = shift;
      $self->{ENABLED} = $state;
      unless ($state) { $self->Clear; }
   }
   return $self->{ENABLED};
}

sub Engine {
   my $self = shift;
   if (@_) { $self->{ENGINE} = shift; }
   return $self->{ENGINE};
}

#1st world problem: I definitely need a faster higlighter;
#problem solved, got one.
sub EngineInit {
   my $self = shift;
   my $eng  = $self->Engine;
   unless (defined $eng) {
      use Syntax::Kamelon;
      my $k = Syntax::Kamelon->new(
			formatter => ['Base',
				format_table => $self->Styles
			],
      );
      $self->Engine($k);
   } else {
		$eng->Formatter->{FORMATTABLE} = $self->Styles
   }
}

sub HlEnd {
   my $self = shift;
   if (@_) { $self->{HLEND} = shift; }
   return $self->{HLEND};
}

sub Interval {
   my $self = shift;
   if (@_) { $self->{INTERVAL} = shift; }
   return $self->{INTERVAL};
}

sub HighlightLine {
   my ($self, $num) = @_;
   my $tc = $self->{TXTCTRL};
   my $hlt = $self->{ENGINE};
   my $begin = $tc->XYToPosition(0, $num); 
   my $end = $tc->XYToPosition(0, $num + 1);
   my $li = $self->{LINEINFO};
   my $k;
   if ($num eq 0) {
      $k = $self->{BASICSTATE};
   } else {
      $k = $li->[$num - 1];
   }
   $hlt->StateSet(@$k);
   $tc->SetStyle($begin, $end, $self->{STYLES}->{'Normal'});
   my $txt = $tc->GetRange($begin, $end); #get the text to be highlighted
	my $pos = 0;
	my $start = 0;
	my @h = $hlt->ParseRaw($txt);
	while (@h ne 0) {
		use bytes;
		$start = $pos;
		$pos = $pos + length(shift @h);
		my $tag = shift @h;
		$tc->SetStyle($begin + $start, $begin + $pos, $tag);
	};
   $li->[$num] = [ $hlt->StateGet ];
}

sub InitLoop {
   my $self = shift;
   unless ($self->{ACTIVE}) {
		$self->{ACTIVE} = 1;
      $self->{TIMER}->Start($self->Interval, 5);
   };
}

sub Load { # TODO
   my ($self, $file) = @_;
   if ($self->Enabled) {
		$self->Clear;
		$self->Syntax($self->Engine->SuggestSyntax($file));
	}
   return 0
}

sub Loop {
   my $self = shift;
   if ($self->{ENABLED}) {
      my $hlend = $self->{HLEND};
      my $numoflines = $self->{TXTCTRL}->GetNumberOfLines;
      if ($hlend < $numoflines) {
         $self->{ACTIVE} = 0;
         my $n = 0;
         while (($hlend < $numoflines) and ($n < 1)) {
				$self->HighlightLine($hlend);
				$hlend ++;
				$n ++;
			}
         $self->{HLEND} = $hlend;
         $self->InitLoop;
      } else {
         $self->{ACTIVE} = 0;
         if ($debug) {
            my $i = $self->{LINEINFO};
            my $size = @$i;
#             print "hilight stack size $size\n";
         }
      }
   }
}

sub Purge {
   my ($self, $index) = @_;
   my $line = $self->TxtCtrl->GetLineNumber($index);
   if ($line <= $self->HlEnd) {
      $self->HlEnd($line);
      my $cli = $self->{LINEINFO};
      if (@$cli) { splice(@$cli, $line) };
      $self->InitLoop;
   }
   return 0;
}

sub SetStyles {
   my ($self, $styles) = @_;
   my $tc = $self->TxtCtrl;
   $self->Styles({});
   foreach (@$styles) {
      my @s = @$_;
      my $name = shift @s;
      my $fgcolour = shift @s;
      my $bgcolour = shift @s;
      my $fontinfo = shift @s;
      my ($fg, $bg, $font) = (undef, undef, undef);
      my $attr = Wx::TextAttr->new;
      if (defined($fgcolour)) {
         $attr->SetTextColour(Wx::Colour->new(@$fgcolour));
      } else {
         $attr->SetTextColour($tc->GetForegroundColour);
      }
      if (defined($bgcolour)) {
         $attr->SetBackgroundColour(Wx::Colour->new(@$bgcolour));
      } else {
         $attr->SetBackgroundColour($tc->GetBackgroundColour);
      }
      if (defined($fontinfo)) {
         my $curfont = $tc->GetFont;

         my $size = shift @$fontinfo;
         unless (defined($size)) { $size = $curfont->GetPointSize }

         my $family = shift @$fontinfo;
         unless (defined($family)) { $family = $curfont->GetFamily }

         my $style = shift @$fontinfo;
         unless (defined($style)) { $style = $curfont->GetStyle }

         my $weight = shift @$fontinfo;
         unless (defined($weight)) { $weight = $curfont->GetWeight }

         my $underline = shift @$fontinfo;
         unless (defined($underline)) { $underline = $curfont->GetUnderlined }

         my $face = shift @$fontinfo;
         unless (defined($face)) { $face = $curfont->GetFaceName }

         $font = Wx::Font->new($size, $family, $style, $weight, $underline, $face);
         $attr->SetFont($font);
      }  else {
         $attr->SetFont($tc->GetFont);
      }

      $self->Styles->{$name} = $attr;
   }
}

sub Styles {
   my $self = shift;
   if (@_) { $self->{STYLES} = shift; }
   return $self->{STYLES};
}

sub Syntax {
   my ($self, $syntax) = @_;
#    print "setting syntax '$syntax'\n";
   if ($syntax eq 'Off') {
      $self->Clear;
      $self->Enabled(0);
   } else {
      $self->Enabled(1);
      my $e = $self->Engine;
      $e->Syntax($syntax);
      $self->HlEnd(0);
      $self->{LINEINFO} = [];
      $self->BasicState([ $e->StateGet]);
      $self->InitLoop;
   }
   return 1
}


1;
__END__
