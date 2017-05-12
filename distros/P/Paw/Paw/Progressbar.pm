#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information

package Paw::Progressbar;
use strict;

@Paw::Progressbar::ISA=qw(Paw);
use Curses;

=head1 Button Widget

B<$pb=Paw::Progressbar->new( \$variable, [$from], [$to], [$blocks], [$color], [$name] );>

B<Parameter>

  variable => a reference to a scalar variable which
              should be represented by the progressbar

  from     => the minimum value (defaults to 0)

  to       => the maximum value (defaults to 100)

  blocks   => the number ob blocks between 'from' and 'to'
              defaults to 10

  name     => name of the progressbar [optionally]

  color    => the colorpair must be generated with
              Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
              [optionally]

B<Example>

  $pb=Paw::Progressbar->new( from=>-10, to=>10, blocks=>25, color=>3 );

=cut

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base;
    my %params = @_;
    
    $this->{name}       = (defined $params{name})?($params{name}):('_auto_pb');
    $this->{rows}       = 1;
    $this->{direction}  = 'h';
    $this->{type}       = 'progressbar';
    $this->{color_pair} = (defined $params{color})?($params{color}):(0);
    $this->{blocks}     = (defined $params{blocks})?($params{blocks}):(10);
    $this->{variable}   = $params{variable};
    $this->{from}       = (defined $params{from})?($params{from}):(0);
    $this->{to}         = (defined $params{to})?($params{to}):(100);
    $this->{color}      = (defined $params{color})?(1):(0);

    bless ($this, $class);
    $this->{cols} = length $this->{blocks};
    return $this;
};

sub draw {
    my $this = shift;
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );
    attron( COLOR_PAIR($this->{color_pair}) );
    my $value = ${$this->{variable}};
    $value -= $this->{from};
    my $to = $this->{to}-$this->{from};
    $value = $to if ($value+$this->{from}) > $this->{to};
    my $step = $to/$this->{blocks};
    my $done = int($value/$step+.5);

    if ( not $this->{color} ) {
	my $filled = '#' x $done;
	my $empty = $this->{blocks}-$done;
	$filled .= '-' x $empty;
	addstr($filled);
    }
    else {
	attron(A_REVERSE);
	my $filled = ' ' x $done;
	addstr($filled);
	attroff(A_REVERSE);
	$filled = ' ' x ($this->{blocks}-$done);
	addstr($filled);
    }
}

return 1;
