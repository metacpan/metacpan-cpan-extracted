package Games::Roguelike::Console::Dump;

=head1 NAME

Games::Roguelike::Console::Dump - fake console that dumps to file, for testing

=head1 SYNOPSIS

use Games::Roguelike::Console::Dump;

$con = Games::Roguelike::Console::Dump->new(keys=>'qY', file=>'/dev/null');

=head1 DESCRIPTION

Fake console that dumps screens to file, used for testing game scripts without needing "curses" support.

Notably, the new function takes a keystroke string and a file as arguments.

Inherits from Games::Roguelike::Console.  See Games::Roguelike::Console for list of methods.

=head1 SEE ALSO

L<Games::Roguelike::Console>

=cut

use strict;
use IO::File;
use Carp qw(cluck croak);
use Games::Roguelike::Utils qw(:DEFAULT);
use base 'Games::Roguelike::Console';

our $VERSION = '0.4.' . [qw$Revision: 233 $]->[1];

sub new {
        my $pkg = shift;
        croak "usage: Games::Roguelike::Console::Dump->new()" unless $pkg;

        my $self = bless {}, $pkg;
        $self->init(@_);
        return $self;
}

my $STD;
sub init {
	my $self = shift;

	my %opt = @_;

	if ($opt{file}) {
		$self->{file} = $opt{file};
		$opt{out} = new IO::File;
		open($opt{out}, ">" . $opt{file});
	}

	$self->{out} = *STDOUT{IO} 
		unless $self->{out} = $opt{out};

	$self->{out}->autoflush(1);

	$self->{buf} = [];
	$self->{cbuf} = $opt{keys};
}

sub DESTROY {
	my $self = shift;
	if ($self->{out}) { 
		close $self->{out};
	}
}


sub clear {
	my $self = shift;
	my $out = $self->{out};
	print $out ("******************\n"); 	#clear the screen 
}

sub redraw {
}

sub attron {
}

sub attroff {
}

sub addstr {
	my $self = shift;
	my $str =  pop @_;
	if (@_== 0) {
		for (my $i = 0; $i < length($str); ++$i) {
			$self->{buf}->[$self->{cy}][$self->{cx}+$i] = substr($str,$i,1);
		}
		$self->{cx} += length($str);
	} elsif (@_==2) {
		my ($y, $x) = @_;
		for (my $i = 0; $i < length($str); ++$i) {
			$self->{buf}->[$y][$x+$i] = substr($str,$i,1);
		}
		$self->{cy}=$y;
		$self->{cx}=$x+length($str);
	}
}

sub tagstr {
	my $self = shift;
	my $str = pop @_;
	$str =~ s/<[^>]+>//g;
	$self->addstr(@_, $str);
}


sub refresh {
	my $self = shift;
	my $out = $self->{out};

	my $cc = 0;

        for (my $y = 0; $y <= @{$self->{buf}}; ++$y) {
                next if !$self->{buf}->[$y];
                next if $self->{cur}->[$y] && (join('',@{$self->{buf}->[$y]}) eq join('',@{$self->{cur}->[$y]}));
		print $out sprintf("%03d|", $y), @{$self->{buf}->[$y]}, "\n";
		@{$self->{cur}->[$y]} = @{$self->{buf}->[$y]};
		++$cc;
        }

	++$self->{refrc};

	return unless $cc > 0;

	print $out "\n<*" . $self->{refrc} . ">\n";
}

sub move {
	my $self = shift;
	my ($y, $x) = @_;
	$self->{cy}=$y;
	$self->{cx}=$x;
}

sub cursor {
}

sub addch {
	my $self = shift;
	$self->addstr(@_);
}

sub getch {
	my $self = shift;

	my $c;	
	if ($self->{cbuf}) {
		$c = substr($self->{cbuf},0,1);
		$self->{cbuf} = substr($self->{cbuf},1);
	}

	return $c;
}

sub nbgetch {
        my $self = shift;
	return $self->getch();
}

1;
