#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# completely rewritten Code it's shorter now and it works :-)
# thanx to Arthur Corliss (Author of Curses::Widgets Module for Perl)
# for some ideas.
# 

=head1 Textbox

B<$popup=Paw::Textbox->new($height, $width, \$text, [$color], [$cursor_color], [$name], [$edit]);>

B<Parameter>

     $height       => number of rows

     $width        => number of columns

     \$text        => reference to a scalar that contains the text.

     $edit         => text edit able (0/1) default is 0

     $color        => the colorpair must be generated with
                      Curses::init_pair(pair_nr, COLOR_fg, COLOR_bg)
                      [optionally]

     $cursor_color => same like color but only for the cursor

     $name         => Name of the widget [optionally]


B<Example>

  $data=("This is free software with ABSOLUTELY NO WARRANTY.\n");
  $pu=Paw::Textbox->new(height=>20, width=>20, text=>\$text);

=head2 set_border(["shade"])

activates the border of the widget (optionally also with shadows). 

B<Example>

     $widget->set_border("shade"); or $widget->set_border();

=cut

package Paw::Textbox;
use strict;
use Curses;
@Paw::Textbox::ISA = qw(Paw);

sub new {
    my $class  = shift;
    my $this   = Paw->new_widget_base();
    my %params = @_;
    
    $this->{name} = (defined $params{name})?($params{name}):('_auto_textbox');
    $this->{rows} = $params{height};
    $this->{cols} = $params{width};
    $this->{edit_able} = (defined $params{edit})?(1):(0);
    $this->{act_able}    = 1;
    $this->{direction}   = 'v';
    $this->{array_is_dirty} = 1;
    $this->{color_pair} = (defined $params{color})?($params{color}):(undef);
    $this->{cursor_color}= (defined $params{cursor_color})?($params{cursor_color}):(undef);

    bless ($this, $class);
    $this->{text}     = $params{text};
    $this->{cursor}   = 0;
    $this->{top_line} = 0;

    return $this;
}

sub draw {
    my $this       = shift;
    my $print_line = shift;
    my $tl = $this->{top_line};
    $this->{color_pair} = $this->{parent}->{color_pair} if ( not defined $this->{color_pair} );
    attron(COLOR_PAIR($this->{color_pair}));

    my @text;
    if ( $this->{array_is_dirty} == 1 ) {
	@text = line_split( $ {$this->{text}}, $this->{cols}-1 );
	$this->{text_array} = \@text;
	$this->{array_is_dirty} = 0;
    }
    @text = @{$this->{text_array}};
    
    my $string = "";
    my $len = 0;
    my $i = 0;
    my $cursor_line = 0;
    my $cursor_char = $this->{cursor};
    while ( 1 ) {
	last if not defined $text[$i];
	$len += length $text[$i++];
	last if $len > $this->{cursor};
	$cursor_line++;
	$cursor_char = $this->{cursor}-$len;
    }
    if ( $this->{cursor} == length $ {$this->{text}} ) {
	$cursor_line--;
	$cursor_char = length $text[--$i];
    }
    $this->{cursor_line} = $cursor_line;
    $this->{cursor_char} = $cursor_char;
    
    # Line with Cursor ?
    if ( $print_line+$tl == $cursor_line ) {
	my $str = $text[$print_line+$tl];
	if ( chomp $str or $cursor_char == length $str) {
	    $str .= ' ';	# "\n" -> ' '
	}
	$str =~ s/\t/        /g;
	addstr( substr $str,0,$cursor_char );
	attron( A_REVERSE );
	attron(COLOR_PAIR($this->{cursor_color})) if ( defined $this->{cursor_color} );
	addstr( substr $str,$cursor_char, 1);
	attroff( A_REVERSE );
	attron(COLOR_PAIR($this->{color_pair}));
	addstr( substr $str,$cursor_char+1 ) if ( length($str) >= $cursor_char+1);
	addstr( ' 'x( $this->{cols}-(length $str) ) );
    }
    # other lines
    elsif ( $print_line+$tl < @text ) {
	my $str = $text[$print_line+$tl];
	chomp $str;
	$str =~ s/\t/        /g;	
	$string = 
	  $str.' 'x( $this->{cols}-(length $str) );
	addstr($string);
    }
    # empty line
    else {
	$string = (' 'x$this->{cols});
	addstr($string);
    }
}

sub key_press {
    my $this = shift;
    my $key  = shift;
    my $cl = $this->{cursor_line};
    my $cc = $this->{cursor_char};
    
    if ( $key eq "\t" ) {
        $this->{parent}->next_active();
    }
    elsif ( $key eq KEY_DOWN ) {
	return '' if $cl+1 == @{$this->{text_array}};
	$this->{top_line}++ if ($cl-$this->{top_line}) == $this->{rows}-1;      # scroll
	$this->{cursor} += length(@{$this->{text_array}}[$cl])-$cc;
	if ( length(@{$this->{text_array}}[$cl+1])-1 >= $cc ) {
	    $this->{cursor} += $cc;
	}
	else {
	    $this->{cursor} += length(@{$this->{text_array}}[$cl+1])-1;
	}
    }
    elsif ( $key eq KEY_UP ) {
	return '' if $cl == 0;
	$this->{top_line}-- if ( $cl == $this->{top_line} );
	$this->{cursor} -= $cc+1;
	$this->{cursor} -= length(@{$this->{text_array}}[$cl-1])-$cc-1 
	  if $cc < length(@{$this->{text_array}}[$cl-1]);
    }
    elsif ( $key eq KEY_RIGHT ) {
	return '' if $this->{cursor} == length $ {$this->{text}};
	$this->{top_line}++ if ($cl-$this->{top_line}) == $this->{rows}-1 and 
	  $cc+1 == length scalar(@{$this->{text_array}}[$cl]);
	$this->{cursor}++;
    }
    elsif ( $key eq KEY_LEFT ) {
	return '' if not $this->{cursor};
	$this->{top_line}-- if ( $cl == $this->{top_line} and $cc == 0);
	$this->{cursor}--;
    }
    elsif ( $key eq KEY_DC ) {
	return '' if $this->{cursor} == length ($ {$this->{text}});
	$ {$this->{text}} = 
	  (substr $ {$this->{text}}, 0, $this->{cursor}).(substr $ {$this->{text}}, $this->{cursor}+1);
	$this->{array_is_dirty} = 1;
    }
    elsif ( $key eq KEY_BACKSPACE ) {
	return '' if ( $this->{cursor} == 0 );
	$ {$this->{text}} = 
	  (substr $ {$this->{text}}, 0, $this->{cursor}-1).(substr $ {$this->{text}}, $this->{cursor});
	$this->{top_line}-- if ( $cl == $this->{top_line} and $cc == 0);
	$this->{cursor}--;
	$this->{array_is_dirty} = 1;
    }
    else {
	if ( $this->{edit_able} ) {
	    $this->{array_is_dirty} = 1;
	    $ {$this->{text}} = 
	      (substr $ {$this->{text}}, 0, $this->{cursor}).($key).(substr $ {$this->{text}}, $this->{cursor});
	    $this->{top_line}++ if ( (($cl-$this->{top_line}) == $this->{rows}-1 and 
				      $cc+1 == length scalar(@{$this->{text_array}}[$cl])) or $cl-$this->{top_line} > $this->{rows}-1);
	    $this->{cursor}++;
	}
    }
    return '';
}


#
# stolen Code (I was to lazy, maybe I'll write my own line_split in the future :-))
# thanx Arthur Corliss (Author of Curses::Widgets Module for Perl)
# BTW, little fix implemented (endless loop fixed - ug@suse.de)
#
sub line_split {
    # Internal and external use, but not exported by default.  Returns
    # an array, which is the string broken according to column limits 
    # and whitespace.
    #
    # Usage:  @lines = line_split($string, 80);
    
    my ($content, $col_lim) = @_;
    my ($m, @line);
    
    if (length($content) == 0) {
	push (@line, '');
    } else {
	foreach (split(/(\n)/, $content)) {
	    if (length($_) <= $col_lim) {
		if ($_ eq "\n") {
		    if (scalar @line > 0) {
			$line[scalar @line - 1] .= $_;
		    } else {
			push (@line, $_);
		    }
		} else {
		    push (@line, $_);
		}
	    } else {
		if (/\b/) {
		    while (length($_) > $col_lim) {
			undef $m;
			while (/\b/g) {
			    if ((pos) <= $col_lim) {
				$m = pos;
			    } else {
				last;
			    }
			}
#			unless (defined $m) { $m = $col_lim };
			unless ($m) { $m = $col_lim };        # little Bugfix (ug@suse.de)
			++$m if (substr($_, $m, 1) =~ /\s/);
			push (@line, substr($_, 0, $m));
			$_ = substr($_, $m);
		    }
		    push (@line, $_);
		} else {
		    while (length($_) > $col_lim) {
			push (@line, substr($_, 0, $col_lim));
			$_ = substr($_, $col_lim);
		    }
		    push (@line, $_);
		}
	    }
	}
    }
    return @line;
}
1;
