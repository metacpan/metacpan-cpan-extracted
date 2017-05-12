package Pangloss::Shell::Command;

use strict;
use warnings;

use Term::ReadKey qw( ReadKey GetControlChars );

our $HAS_ANSI;
BEGIN {
    eval 'use Term::ANSIColor qw( :constants ); $HAS_ANSI=1;';
}

use base qw( Pangloss::Object );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

our $PROMPT  = 'pangloss> ';
our %CONTROL = (
		# key    => 'handler_sub'
		chr(127) => 'backspace',
		chr(27)  => 'arrow',
		chr(11)  => 'kill_line',
		"\t"     => 'tab',
	       );
our %ARROW   = (
		'[A' => 'arrow_up',
		'[B' => 'arrow_dn',
		'[C' => 'arrow_rt',
		'[D' => 'arrow_lt',
	       );
our $CHARS_RE = qr/[\w \=\+\-\_\;\:\<\>\,\.\~\`\[\]\{\}\\\/\?\!\@\#\$\%\^\&\*\(\)\'\"]/;

sub init {
    my $self = shift;
    $self->{history} = [];
}

sub get_command {
    my $self   = shift;
    my $prompt = shift || $PROMPT;

    $self->{cmd}     = '';
    delete $self->{old_cmd};
    delete $self->{hist_idx};

    pretty_print( $prompt );

    while (my $key = ReadKey( 0 )) {
	if (my $method = $CONTROL{$key}) {
	    $self->$method( $key );
	} elsif ($key =~ $CHARS_RE) {
	    $self->{cmd} .= $key;
	    pretty_print( $key );
	} elsif ($key =~ /\n/) {
	    print "\n";
	    push @{ $self->{history} }, $self->{cmd} if $self->{cmd};
	    return $self->{cmd};
	} else {
	    print "\nI don't recognize '$key' ord(".ord($key).")\n";
	}
    }
}

sub backspace {
    my $self = shift;
    print "\b \b" if $self->{cmd} =~ s/.\z//;
}

sub arrow {
    my $self = shift;
    my $cmd  = '';
    while (my $key = ReadKey( -1 )) { $cmd .= $key };
    if (my $method = $ARROW{$cmd}) {
	$self->$method if $self->can( $method );
    }
}

sub arrow_up {
    my $self = shift;

    return unless @{ $self->{history} };

    if (exists $self->{hist_idx}) {
	$self->{hist_idx}-- if $self->{hist_idx};
    } else {
	$self->{hist_idx} = $#{ $self->{history} };
	$self->{old_cmd}  = $self->{cmd};
    }

    $self->erase_command;
    $self->{cmd} = $self->{history}->[$self->{hist_idx}];

    pretty_print( $self->{cmd} );
}

sub arrow_dn {
    my $self = shift;

    return unless exists $self->{hist_idx};

    $self->{hist_idx}++ if $self->{hist_idx} < @{ $self->{history} };

    $self->erase_command;

    if ($self->{hist_idx} > $#{ $self->{history} }) {
	$self->{cmd} = delete $self->{old_cmd} if exists $self->{old_cmd};
	delete $self->{hist_idx};
    } else {
	$self->{cmd} = $self->{history}->[$self->{hist_idx}];
    }

    pretty_print( $self->{cmd} );
}

sub arrow_lt {
    my $self = shift;
}
sub arrow_rt {
    my $self = shift;
}

sub kill_line {
    my $self = shift;
    my $key  = shift;
    $self->erase_command
         ->{cmd} = '';
}

sub erase_command {
    my $self = shift;
    print "\b \b" x length($self->{cmd});
    return $self;
}

sub tab {
    my $self = shift;
    my $key  = shift;
    # completions ?
    return;
}

sub pretty_print {
    if ($HAS_ANSI) {
	local $Term::ANSIColor::AUTORESET = 1;
	print BLUE @_;
    } else {
	print @_;
    }
}

1;
