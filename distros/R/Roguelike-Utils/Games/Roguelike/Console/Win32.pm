use strict;
package Games::Roguelike::Console::Win32;

#### refer to Games::Roguelike::Console for docs ###

use Win32::Console;
use Carp;

use base 'Games::Roguelike::Console';

our $VERSION = '0.4.' . [qw$Revision: 247 $]->[1];

sub new {
        my $pkg = shift;
        croak "usage: Games::Roguelike::Console::Win32->new()" unless $pkg;

        my $self = bless {}, $pkg;
        $self->init(@_);
        return $self;
}

my $CON;

#todo: figure out how to free/alloc/resize
sub init {
	my $self = shift;
	my %opts = @_;

	$self->SUPER::init(%opts);	

	$self->{conin} = Win32::Console->new(STD_INPUT_HANDLE);

	# turns off echo
	$self->{conin}->Mode(ENABLE_PROCESSED_INPUT);
		
	$self->{buf} = Win32::Console->new(GENERIC_READ|GENERIC_WRITE);
	$self->{buf}->Cls();
	$self->{buf}->Cursor(-1,-1,-1,0);
	
	$self->{con} = Win32::Console->new(STD_OUTPUT_HANDLE);
	$self->{cur} = 0;

	($self->{winx},$self->{winy}) = $self->{con}->MaxWindow();
	$self->{con}->Size($self->{winx}, $self->{winy});
	$self->{buf}->Size($self->{winx}, $self->{winy});

	$self->{rx} = 0 if !defined $self->{rx};
	
	if (!$opts{noinit}) {
		$self->{con}->Cursor(-1,-1,-1,0);
		$self->{con}->Display();
		$self->{con}->Cls();
	}
	
	$CON = $self->{con} unless $CON;
	
	$SIG{INT} = \&sig_int_handler;
	$SIG{__DIE__} = \&sig_die_handler;
}

sub DESTROY {
	$_[0]->{con}->Cls() if $_[0]->{con};
}

sub sig_int_handler {
	$CON->Cls();
	exit;
}

sub sig_die_handler {
	die @_ if $^S;
        $CON->Cls();
	die @_;
}

sub nativecolor {
        my ($self, $fg, $bg, $fgb, $bgb) = @_;

#	$fg = 'white' if $fg eq '';
#	$bg = 'black' if $bg eq '';

	$fg = 'light' . $fg if $fgb;

	$fg = 'gray' if $fg eq 'lightblack';
	$bg = 'gray' if $bg eq 'lightblack';
	$fg = 'brown' if $fg eq 'yellow';
	$bg = 'brown' if $bg eq 'yellow';
	$fg = 'yellow' if $fg eq 'lightyellow';
	$bg = 'yellow' if $bg eq 'lightyellow';
	$fg = 'lightgray' if $fg eq 'white';
	$fg = 'white' if $fg eq 'lightwhite';
	$bg = 'white' if $bg eq 'lightwhite';

	no strict 'refs';
	my $color = ${"FG_" . uc($fg)} | ${"BG_" . uc($bg)} ;
		
	use strict 'refs';

	$color = $self->defcolor if !$color;
	return $color;
}

sub attron {
        my $self = shift;
        my ($attr) = @_;
        $self->{cattr} = $self->parsecolor($attr);
}

sub attroff {
	my $self = shift;
	$self->{cattr} = $self->defcolor;
}

sub addstr {
	my $self = shift;
	my $str =  pop @_;

	if (@_== 0) {
		if ($self->{cx}+length($str) > ($self->{winx}+1)) {
			$str = substr(0, ($self->{cx}+length($str)) - ($self->{winx}));
		}
		return if length($str) == 0;
		$self->{buf}->WriteChar($str, $self->{cx}, $self->{cy});
		$self->{buf}->WriteAttr(chr($self->{cattr}) x length($str), $self->{cx}, $self->{cy});
		#$self->invalidate($self->{cx}, $self->{cy}, $self->{cx} + length($str), $self->{cy});
		$self->{cx} += length($str);
	} elsif (@_==2) {
		my ($y, $x) = @_;
		if ($x+length($str) > ($self->{winx}+1)) {
			$str = substr(0, ($x+length($str)) - ($self->{winx}));
		}
		return if length($str) == 0;
		$self->{buf}->WriteChar($str, $x, $y);
		$self->{buf}->WriteAttr(chr($self->{cattr}) x length($str), $x, $y);
		#$self->invalidate($x, $y, $x+length($str), $y);
		$self->{cx} = $x + length($str);
		$self->{cy} = $y;
	}
	if ($self->{cursor}) {
		$self->{con}->Cursor($self->{cx},$self->{cy},-1,1);		
	}
}

sub tagstr {
        my $self = shift;
        my ($y, $x, $str);
        if (@_ == 1) {
                ($y, $x, $str) = ($self->{cy}, $self->{cx}, @_);
        } else {
                ($y, $x, $str) = @_;
        }
        my $attr = chr($self->defcolor);
        my $r = $x;
        my $c;
        for (my $i = 0; $i < length($str); ++$i) {
                $c = substr($str,$i,1);
                if ($c eq '<') {
                        substr($str,$i) =~ s/<([^>]*)>//;
			if ($1 eq 'gt') {
				$c = '>';
				--$i;
			} elsif ($1 eq 'lt') {
				$c = '<';
				--$i;
                        } else {
				$attr = chr($self->parsecolor($1));
                        	$c = substr($str,$i,1);
			}
                }
		if ($c eq "\r") {
			next;
		}
		if ($c eq "\n") {
			$r = $self->{rx};
			$y++;
			next;
		}

                $self->{buf}->WriteChar($c, $r, $y);
                $self->{buf}->WriteAttr($attr, $r, $y);
                ++$r;
        }
        #$self->invalidate($x, $y, $x+$r, $y);
        $self->{cy}=$y;
        $self->{cx}=$x+$r;
}

sub refresh {
	my $self = shift;
	#my $rect = $self->{buf}->ReadRect($self->{invl}, $self->{invt}, $self->{invr}, $self->{invb});
	#$self->{con}->WriteRect($rect, $self->{invl}, $self->{invt}, $self->{invr}, $self->{invb});
	my $rect = $self->{buf}->ReadRect(0, 0, $self->{winx}, $self->{winy});
	$self->{con}->WriteRect($rect, 0, 0, $self->{winx}, $self->{winy});
#	$self->{invl} = $self->{winx}+1;
#	$self->{invt} = $self->{winy}+1;
#	$self->{invr} = $self->{invb} = -1;
}

sub move {
	my $self = shift;
	my ($y, $x) = @_;
	$self->{cx}=$x;
	$self->{cy}=$y;
	if ($self->{cursor}) {
		$self->{con}->Cursor($x,$y,-1,1);		
	}
}

sub cursor {
	my $self = shift;
	if ($self->{cursor} != shift) {
		$self->{cursor} = !$self->{cursor};
		$self->{con}->Cursor($self->{cx},$self->{cy},-1,$self->{cursor});
	}
}

sub printw   { 
	my $self = shift;
	$self->addstr(sprintf shift, @_)
} 

sub addch {
	my $self = shift;
	$self->addstr(@_);
}

sub invalidate {
	my $self = shift;
	my ($l, $t, $r, $b) = @_;
	$r = 0 if ($r < 0);
	$t = 0 if ($t < 0);
	$b = $self->{winy} if ($b > $self->{winy});
	$r = $self->{winx} if ($r > $self->{winx});

	if ($r < $l) {
		my $m = $r;
		$r = $l;
		$l = $m;
	}
	if ($b < $t) {
		my $m = $t;
		$b = $t;
		$t = $m;
	}
	$self->{invl} = $l if $l < $self->{invl};
	$self->{invr} = $r if $r > $self->{invr};
	$self->{invt} = $t if $t < $self->{invt};
	$self->{invb} = $b if $b > $self->{invb};
}

# read 1 event, translate and return translated value
sub getev {
        my $self = shift;
	my ($type, @e)= $self->{conin}->Input();
	if ($type == 1) {
		my ($kd, $rep, $vk, $vs, $c, $ctrl) = @e;
		next if $kd;
		return 'DOWN' if $vk == 0x28;
		return 'RIGHT' if $vk == 0x27;
		return 'LEFT' if $vk == 0x25;
		return 'UP' if $vk == 0x26;
		return 'ESC' if $c == 27;
		return chr($c) if $c > 0;
	}
	return undef;
}

# todo, support win32 arrow/function/control keys - ReadKey ignores them
sub getch {
        my $self = shift;
	# readkey breaks on carraige returns
	while (1) {
		my $c = $self->getev();
		return $c if defined $c;
	};
}

sub nbgetch {
        my $self = shift;
	# readkey breaks on carraige returns
	while ($self->{conin}->GetEvents() > 0) {
		my $c = $self->getev();
		return $c if defined $c;
	};
	return undef;
}

1;
