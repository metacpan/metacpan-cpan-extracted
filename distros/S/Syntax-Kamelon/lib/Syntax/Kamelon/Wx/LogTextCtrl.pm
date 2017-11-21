package Syntax::Kamelon::Wx::LogTextCtrl;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use Wx qw( :textctrl :font :colour );
use base qw( Wx::TextCtrl );

my $defaultfont = [10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0];

my $blue                = [0x00, 0x00, 0xff];
my $darkgreen           = [0x00, 0x80, 0x00];
my $brown               = [0xa5, 0x2a, 0x2a];
my $red                 = [0xff, 0x00, 0x00];
my $foreground 			= [0x10, 0x10, 0x10];
my $background				= [0xf0, 0xf0, 0xf0];

my $defaultstyle = [
	['title', $foreground, undef, [12, undef, undef, wxFONTWEIGHT_BOLD]],
	['key', $blue],
	['value', $brown],
	['error', $red],
	['header', $foreground, undef, [undef, undef, undef,  wxFONTWEIGHT_BOLD]],
	['header1', $blue, undef, [undef, undef, undef,  wxFONTWEIGHT_BOLD]],
	['message', $darkgreen],
	['normal', $foreground],
];
my $keylength = 20;
my $formatdirection = 0;


sub new {
   my $class = shift;
   my $self = $class->SUPER::new(@_, wxHSCROLL|wxTE_MULTILINE|wxTE_READONLY|wxTE_RICH);


   $self->SetFont( Wx::Font->new(@$defaultfont) );
   $self->{INDENT} = 0;
   $self->{INDENTSTRING} = "   ";

   my $attr = Wx::TextAttr->new;
	$attr->SetTextColour(Wx::Colour->new(@$foreground));
	$attr->SetBackgroundColour(Wx::Colour->new(@$background));
	$self->SetDefaultStyle($attr);

	$self->{STYLES} = {};
	$self->SetStyles;

   return $self;
}

sub FormatStringLength {
	my ($self, $str, $length, $direction) = @_;
	unless (defined $direction) { $direction = $formatdirection }
	unless (defined $length) { $length = $keylength }
	if ($direction) {
		while (length($str) < $length) {
			$str = "$str ";
		}
	} else {
		while (length($str) < $length) {
			$str = " $str";
		}
	}
	return $str;
}

sub IndentDown {
	my $self = shift;
	my $i = $self->{INDENT};
	unless ($i eq 0) {
		$self->{INDENT} = $i - 1;
	}
}

sub IndentUp {
	my $self = shift;
	$self->{INDENT} = $self->{INDENT} + 1;
}

sub IndentString {
	my $self = shift;
	if (@_) { $self->{INDENTSTRING} = shift; }
	my $i = $self->{INDENT};
	my $s = $self->{INDENTSTRING};
	my $o = "";
	if ($i) {
		for (1 .. $i) { $o = $o . $s }
	}
	return $o;
}


sub SetStyles {
   my ($self, $styles) = @_;
   unless (defined($styles)) { $styles = $defaultstyle }
   foreach (@$styles) {
      my @s = @$_;
      my ($name, $fgcolour, $bgcolour, $fontinfo) = @$_;
      my ($fg, $bg, $font);
      my $attr = Wx::TextAttr->new;
      if (defined($fgcolour)) {
         $attr->SetTextColour(Wx::Colour->new(@$fgcolour));
      } else {
         $attr->SetTextColour($self->GetForegroundColour);
      }
      if (defined($bgcolour)) {
         $attr->SetBackgroundColour(Wx::Colour->new(@$bgcolour));
      } else {
         $attr->SetBackgroundColour($self->GetBackgroundColour);
      }
      if (defined($fontinfo)) {
			my @fi = @$fontinfo;
         my $curfont = $self->GetFont;

         my $size = shift @fi;
         unless (defined($size)) { $size = $curfont->GetPointSize }

         my $family = shift @fi;
         unless (defined($family)) { $family = $curfont->GetFamily }

         my $style = shift @fi;
         unless (defined($style)) { $style = $curfont->GetStyle }

         my $weight = shift @fi;
         unless (defined($weight)) { $weight = $curfont->GetWeight }

         my $underline = shift @fi;
         unless (defined($underline)) { $underline = $curfont->GetUnderlined }

         my $face = shift @fi;
         unless (defined($face)) { $face = $curfont->GetFaceName }

         $font = Wx::Font->new($size, $family, $style, $weight, $underline, $face);
         $attr->SetFont($font);
      }  else {
         $attr->SetFont($self->GetFont);
      }

      $self->Styles->{$name} = $attr;
   }
}

sub Styles {
   my $self = shift;
   if (@_) { $self->{STYLES} = shift; }
   return $self->{STYLES};
}

sub WriteHash {
	my $self = shift;
	my $h = shift;
	my %exclude = ();
	for (@_) {
		$exclude{$_} = 1;
	
	}
	my $length = $keylength;
	foreach my $k (sort keys %$h) {
		unless (exists $exclude{$k}) {
			my $l = length $k;
			if ($l > $length) { $length = $l }
		}
	}
	foreach my $k (sort keys %$h) {
		unless (exists $exclude{$k}) {
			my $l = $k;
			$l = $self->FormatStringLength($l, $length);
			$self->WriteStyle("$l: ", 'key');
			my $i = $self->{INDENT};
			$self->{INDENT} = 0;
			$self->WriteStyle($h->{$k} . "\n", 'value');
			$self->{INDENT} = $i;
		}
	}
}

sub WriteTable {
	my $self = shift;
	my $table = shift;
	my $tabs = shift;
	my @columns = @_;
	my $cw;
	my $num = 0;
	for (@columns) {
		my $w =  $tabs->[$num];
		if (defined $w) { $cw = $w }
		my $title = $self->FormatStringLength($_, $cw, 1);
		$self->WriteStyle($title, 'header');
		$num ++
	}
	$self->WriteStyle("\n", 'header');
	foreach my $record (@$table) {
		$num = 0;
		foreach my $column (@$record) {
			my $w =  $tabs->[$num];
			if (defined $w) { $cw = $w }
			my $value = $self->FormatStringLength($column, $cw, 1);
			$self->WriteStyle($value, 'value');
			$num++
		}
		$self->WriteStyle("\n", 'value');
	}
}

sub WriteStyle {
	my $self = shift;
	while (@_) {
		my $txt = shift;
		my $style = shift;
		unless (defined($style)) { $style = 'normal' }
		
		my $begin = $self->GetInsertionPoint;
		$self->WriteText($self->IndentString . $txt);
		my $end = $self->GetInsertionPoint;
		if (defined($style)) {
			$self->SetStyle($begin, $end, $self->Styles->{$style});
		} else {
			warn "Style $style not found\n";
		}
	}
}

1;
__END__
