# -*- perl -*-

# Copyright (c) 2004 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2004-Jun-03 10:24 (EDT)
# Function: pager like more/less
#
# $Id: Pager.pm,v 1.4 2012/12/02 18:06:46 jaw Exp $

=head1 NAME

Term::Pager - Page through text, a screenful at a time, like more or less

=head1 SYNOPSIS

    use Term::Pager;

    my $t = Term::Pager->new( rows => 25, cols => 80 );
    $t->add_text( $text );
    $t->more();

=head1 DESCRIPTION

This is a module for paging through text one screenful at a time.
It supports the features you expect, including backwards
movement and searching. It uses the keys you expect.

=head1 USAGE

=head2 Create the Pager

    $t = Term::Pager->new( option => value, ... );

If no options are specified, sensible default values will be used.
The following options are recognized:

=over 4

=item C<rows>

The number of rows on your terminal.
This defaults to 25.

=item C<cols>

The number of columns on your terminal.
This defaults to 80.

=item C<speed>

The speed (baud rate) of your terminal. Will default
to a sensible value.

=back

=head2 Adding Text

You will need some text to page through. You can specify text as
as a parameter to the constructor:

    text => $text

Or add text later:

    $t->add_text( $text );

=cut
    ;

package Term::Pager;
$VERSION = '1.02';

use Term::Cap;
use strict;

sub new {
    my $class = shift;
    my %param = @_;

    my $t = Term::Cap->Tgetent({ OSPEED => ($param{speed} || 38400) });
    my $dumbp;

    eval{
	$t->Trequire(qw/cm ce cl sf sr/);
    };
    $dumbp = 1 if $@;

    my $me = bless {
	# default values
	term  => $t,
	cols  => 80,
	rows  => 25,
	dumbp => $dumbp,

	# if the termcap entries don't exist, nothing bad will happen
	HI    => $t->Tputs('md') . $t->Tputs('us'),	# search hilight
	SE    => $t->Tputs('md') . $t->Tputs('us'),	# search entry
	MN    => $t->Tputs('md') . $t->Tputs('mr'),	# popup menus
	ML    => $t->Tputs('mr'),			# mode line
	NO    => $t->Tputs('me'),			# normal

	# user supplied values override
	%param,
    }, $class;

    $me->{fnc} = {
	"\n"=> \&downline,
	' ' => \&downpage,
	'd' => \&downhalf,
	'q' => \&done,
	'b' => \&uppage,
	'y' => \&upline,
	'u' => \&uphalf,
	'r' => \&refresh,
	'h' => \&help,
	'?' => \&help,
	'0' => \&to_top,
	'g' => \&to_bott,
	'$' => \&to_bott, # '
	'/' => \&search,
	'<' => \&move_left,
	'>' => \&move_right,
    };

    $me;
}

sub add_text {
    my $me = shift;
    my $tx = shift;

    $me->{text} .= $tx;
}

sub add_func {
    my $me = shift;
    my $fn = shift;
    my $fc = shift;

    $me->{fnc}{$fn} = $fc;
}

sub more {
    my $me = shift;
    my $sp = $|;
    my $t = $me->{term};

    $me->{L} = $me->{rows} - 1;
    $me->{l} = [ split /\n/, $me->{text} ];
    $me->{nl}= @{ $me->{l} };

    $me->{start} = 0;
    $me->{end}   = $me->{L} - 1;

    $SIG{INT} = $SIG{QUIT} = \&done;
    system('stty -icanon -echo min 1');
    $| = 1;

    eval {
	if( $me->{dumbp} ){
	    $me->dumb_mode();
	}else{
	    print $me->{NO};
	    $me->refresh();

	    while(1){
		print $t->Tgoto('cm', 0, $me->{L});	# bottom left
		print $t->Tputs('ce');			# clear line

		print $me->{ML};			# reverse video
		$me->prompt();
		print $me->{NO};			# normal video

		my $q = getc();

		print $t->Tgoto('cm', 0, $me->{L});	# bottom left
		print $t->Tputs('ce');			# clear line

		$me->{msg} = '';
		my $f = $me->{fnc}->{lc($q)} || \&beep;
		$f->($me);
	    }
	}
    };

    system('stty icanon echo');
    $| = $sp;

    if( $@ && !ref $@ ){
	die $@;
    }
    return;
}

*less = \&more;
*page = \&more;

sub beep { print "\a" }

# display a prompt, etc
sub prompt {
    my $me = shift;

    my $pct = ($me->{nl} > 1) ? 100*$me->{end}/($me->{nl}-1) : 100;
    my $p = sprintf "[more] %d%% %s %s", $pct,
    ($me->{start} ? ($me->{end}==$me->{nl}-1) ? 'Bottom' : '' : 'Top'), $me->{msg};

    my $p2 = "  <space>=down <b>=back <h>=help <q>=quit";

    $p .= ' ' x ($me->{cols} - 2 - length($p) - length($p2));

    print $p,$p2;
}

sub done {
    die \ 'foo';
}

# put a box around some text
sub box_text {
    my $me  = shift;
    my $txt = shift;
    my $l;

    my @l = split /\n/, $txt;
    foreach (@l){ $l = length($_) if length($_) > $l };
    my $b = '+' . '=' x ($l + 2) . '+';
    my $o = join('', map { "| $_" . (' 'x($l-length($_))) ." |\n" } @l);

    "$b\n$o$b\n";
}

# provide help to user
sub help {
    my $me = shift;

    my $help = $me->box_text(<<EOH);
 q      quit                    h      help
 /      search
 space  page down               b      page up
 enter  line down               y      line up
 d      half page down          u      half page up
 0      goto top                g      goto bottom
 <      scroll left             >      scroll right

           press any key to continue
EOH
    ;

    $me->disp_menu( $help );
    getc();
    $me->remove_menu();

}

# display a popup menu (or other text)
sub disp_menu {
    my $me = shift;
    my $menu = shift;
    my $t = $me->{term};

    my $nl = @{[split /\n/, $menu]};
    $me->{menu_nl} = $nl;

    print $t->Tgoto('cm', 0, $me->{L} - $nl);		# move
    print $me->{MN};					# set color

    my $x = $t->Tgoto('RI', 0,4);			# 4 transparent spaces
    $menu =~ s/^\s*/$x/gm;
    print $menu;
    print $me->{NO};					# normal color

}

# remove popup and repaint
sub remove_menu {
    my $me = shift;
    my $t  = $me->{term};

    my $s = $me->{end} - $me->{menu_nl} + 1;
    foreach my $n ($s .. $me->{end}){
	print $t->Tgoto('cm', 0, $n - $me->{start});		# move
	print $t->Tputs('ce');					# clear
	$me->line($n);
    }
}

# refresh screen
sub refresh {
    my $me = shift;
    my $t  = $me->{term};

    print $t->Tputs('cl');					# home, clear
    for my $n ($me->{start} .. $me->{end}){
	print $t->Tgoto('cm', 0, $n - $me->{start});		# move
	print $t->Tputs('ce');					# clear line
	$me->line($n);
    }
}

sub prline {
    my $me = shift;
    my $line = shift;

    my $len = length($line);
    $line = substr($line, $me->{left}, $me->{cols});
    if( $len - $me->{left} > $me->{cols} ){
	substr($line, -1, 1, "\$");
    }

    if( $me->{search} ne '' ){
	my $s = $me->{HI};
	my $e = $me->{NO};
	$line =~ s/($me->{search})/$s$1$e/g;
    }
    print $line;

}

sub line {
    my $me = shift;
    my $n  = shift;

    $me->prline( $me->{l}[$n] );
}

sub down_lines {
    my $me = shift;
    my $n  = shift;
    my $t  = $me->{term};

    for (1 .. $n){
	if( $me->{end} >= $me->{nl}-1 ){
	    print "\a";
	    last;
	}else{
            # why? because some terminals have bugs...
            print $t->Tgoto('cm', 0, $me->{L} );        # move
            print $t->Tputs('sf');                      # scroll
            print $t->Tgoto('cm', 0, $me->{L} - 1);     # move
            print $t->Tputs('ce');                      # clear line

	    $me->line( ++$me->{end} );
	    $me->{start} ++;
	}
    }
}

sub downhalf {
    my $me = shift;
    $me->down_lines( $me->{L} / 2 );
}

sub downpage {
    my $me = shift;
    $me->down_lines( $me->{L} );
}

sub downline {
    my $me = shift;
    $me->down_lines( 1 );
}

sub up_lines {
    my $me = shift;
    my $n  = shift;
    my $t  = $me->{term};

    for (1 .. $n){
	if( $me->{start} <= 0 ){
	    print "\a";
	    last;
	}else{
	    print $t->Tgoto('cm',0,0);		# move
	    print $t->Tputs('sr');		# scroll back
	    $me->line( --$me->{start} );
	    $me->{end} --;
	}
    }

    print $t->Tgoto('cm',0,$me->{L});		# goto bottom
}

sub uppage {
    my $me = shift;
    $me->up_lines( $me->{L} );
}

sub upline {
    my $me = shift;
    $me->up_lines( 1 );
}

sub uphalf {
    my $me = shift;
    $me->up_lines( $me->{L} / 2 );
}

sub to_top {
    my $me = shift;

    $me->{start} = 0;
    $me->{end}   = $me->{L} - 1;
    $me->refresh();
}

sub to_bott {
    my $me = shift;

    $me->{start} = $me->{nl} - $me->{L};
    $me->{start} = 0 if $me->{start} < 0;
    $me->{end}   = $me->{start} + $me->{L} - 1;
    $me->refresh();
}

sub move_right {
    my $me = shift;

    $me->{left} += 8;
    $me->refresh();
}

sub move_left {
    my $me = shift;

    $me->{left} -= 8;
    $me->{left} = 0 if $me->{left} < 0;
    $me->refresh();
}

sub search {
    my $me = shift;
    my $t  = $me->{term};

    # get pattern
    my $prev = $me->{search};
    $me->{search}  = '';

    print $t->Tgoto('cm', 0, $me->{L});			# move bottom
    print $t->Tputs('ce');				# clear line
    print $me->{SE};					# set color
    print "/";

    while(1){
	my $l = getc();
	last if $l eq "\n" || $l eq "\r";
	if( $l eq "\e" || !defined($l) ){
	    $me->{search} = '';
	    last;
	}
	if( $l eq "\b" || $l eq "\177" || $l eq '#' ){
	    print "\b \b" if $me->{search} ne '';
	    substr($me->{search}, -1, 1, '');
	    next;
	}
	print $l;
	$me->{search} .= $l;
    }
    print $me->{NO};					# normal color
    print $t->Tgoto('cm', 0, $me->{L});			# move bottom
    print $t->Tputs('ce');				# clear line
    return if $me->{search} eq '';

    $me->{search} = $prev if $me->{search} eq '/' && $prev;

    for my $n ( $me->{start} .. $me->{nl}-1 ){
	next unless $me->{l}[$n] =~ /$me->{search}/;

	$me->{start} = $n;
	$me->{start} = 0 if $me->{nl} < $me->{L} - 1;
	$me->{end}   = $me->{start} + $me->{L} - 1;

	if( $me->{end} > $me->{nl} - 1 && $me->{start} ){
	    my $x = $me->{end} - $me->{nl} + 1;
	    $x = $me->{start} if $x > $me->{start};
	    $me->{start} -= $x;
	    $me->{end}   -= $x;
	}

	$me->refresh();
	return;
    }
    # not found
    print "\a";
    my $m = $me->box_text( 'Not Found' );
    $me->disp_menu($m);
    sleep 1;
    $me->remove_menu();
    return;

}


sub dumb_mode {
    my $me = shift;
    my $end = 0;

    while(1){
	for my $i (1 .. $me->{rows} - 1){
	    last if $end >= $me->{nl};
	    print $me->{l}[$end++], "\n";
	}

	print "--more [dumb]--";
	my $a = getc();
	print "\b \b"x15;

	return if $a eq 'q';
	return if $end >= $me->{nl};
    }
}



=head1 FEATURES

This code uses termcap. If the termcap entry for your ancient esoteric
terminal is wrong or incomplete, this module may either fill your screen
with unintelligible gibberish, or drop back to a feature-free mode.

=head1 SEE ALSO

    Term::Cap, termcap(5), more(1), less(1)
    Yellowstone National Park

=head1 AUTHOR

    Jeff Weisberg - http://www.tcp4me.com

=cut
    ;
