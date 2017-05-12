# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .
package Pg::Pcurse::Widget;
use v5.8;
use Curses;
use Curses::Widgets;
use Carp::Assert;
use Curses::Widgets::Menu;
use Curses::Widgets::Label;
use Curses::Widgets::ButtonSet;
use strict;
use warnings;
use Pg::Pcurse;
our $VERSION = '0.14';


use base 'Exporter';

our @EXPORT = qw( 
	          init_screen       init_mini_root
	          create_root       create_button
		  create_commentbox
	          create_menu
	          create_botton 
	          main_listbox  secondary_listbox  big_listbox
		  form_dbmenu
);

sub miniscan_sec {
	noecho();
        my $mwh = shift;
        my $key = -1;
        while ($key eq -1) {
                $key = $mwh->getch;
                if($key eq "j")  { return KEY_DOWN    };
                if($key eq "k")  { return KEY_UP      };
                if($key eq "h")  { return "\n"        };
                if($key eq ' ')  { return "\n"        };
                if($key eq 'm')  { return KEY_RIGHT   };
                if($key eq 'd')  { got_d($mwh)        };
                if($key eq 'n')  { return KEY_LEFT    };
                if($key eq 'q')  { exit 0             };
        }
        return $key;
}
sub miniscan {
	noecho();
        my $mwh = shift;
        my $key = -1;
        while ($key eq -1) {
                $key = $mwh->getch;
                if($key eq "j")  { return KEY_DOWN    };
                if($key eq "k")  { return KEY_UP      };
                if($key eq "h")  { return "\n"        };
                if($key eq ' ')  { return "\e"        };
                if($key eq 'm')  { return KEY_RIGHT   };
                if($key eq 'n')  { return KEY_LEFT    };
                if($key eq 'q')  { exit 0             };
        }
        return $key;
}
sub miniscan_5c {
	noecho();
        my $mwh = shift;
        my $key = -1;
        while ($key eq -1) {
                $key = $mwh->getch;
                if($key eq "j")  { return KEY_DOWN    };
                if($key eq "k")  { return KEY_UP      };
                if($key eq "h")  { return "\n"        };
                if($key eq ' ')  { return KEY_DOWN    };
                if($key eq 'm')  { return KEY_RIGHT   };
                if($key eq 'n')  { return KEY_LEFT    };
                if($key eq 'q')  { exit 0             };
        }
        return $key;
}


sub _Database_Menu_Choice {
        my $dbs = shift;
        { ITEMORDER => $dbs ,
          map  { my $i=$_; ($_ => sub{ $::db=$i}) } @$dbs,
        }
}


my @MODES = sort qw( Vacuum Stats Procedures Tables Views Users Rules
                     Databases Buffers Indexes Settings Triggers Bucardo
		     Dict
             );
sub form_dbmenu {
        my $dbs = shift;
	assert( ref $dbs, 'ARRAY') if DEBUG;
        my $menus = { MENUORDER => [qw( Databases Mode About ) ],
                      Databases => _Database_Menu_Choice ($dbs),
                      Hide      =>{ ITEMORDER => [ 'System' ],
                                System    => sub { $::hid{system}++} },
                      Mode      =>{ ITEMORDER => [ @MODES ],
                                Vacuum     => sub { $::mode = 'vacuum'    },
                                Stats      => sub { $::mode = 'stats'     },
                                Procedures => sub { $::mode = 'procedures'},
                                Tables     => sub { $::mode = 'tables'    },
                                Views      => sub { $::mode = 'views'     },
                                Users      => sub { $::mode = 'users'     },
                                Databases  => sub { $::mode = 'databases' },
                                Buffers    => sub { $::mode = 'buffers'   },
                                Indexes    => sub { $::mode = 'indexes'   },
                                Dict       => sub { $::mode = 'dict'      },
                                Settings   => sub { $::mode = 'settings'  },
                                Triggers   => sub { $::mode = 'triggers'  },
                                Bucardo    => sub { $::mode = 'bucardo'   },
                                Rules      => sub { $::mode = 'rules'     },
				   },	
                      About      =>{ ITEMORDER => [  
                                            "Version $Pg::Pcurse::VERSION",
                                            'Ioannis Tambouras (C)' 
                                                  ],
                                     },
                    };
        new Curses::Widgets::Menu {
                FOREGROUND  => 'black',
                BACKGROUND  => 'red',
                BORDER      => 1,
                FOCUSSWITCH => "\tl",
	        INPUTFUNC   => \&miniscan  ,
                CURSORPOS   => [qw(Databases)],
                MENUS       => $menus,
         }
}


sub init_screen {
	halfdelay(5);
	curs_set(0);
	leaveok(1);
}

sub create_root {
	my $mwh = new Curses;
	$mwh->erase();
	$mwh->keypad(1);
	$mwh->syncok(1);
	$mwh->attrset(COLOR_PAIR(select_colour(qw(red black))));
	$mwh->box(0,0);
	$mwh->attrset(0);
	$mwh->standout();
	$mwh->standend();
	$mwh;
}


sub create_menu {
	new Curses::Widgets::Menu {
		FOREGROUND  => 'yellow',
		BACKGROUND  => 'green',
		BORDER      => 1,
		CURSORPOS   => [qw(File)],
		MENUS       => { MENUORDER  => [qw(File Help)],
		                 File       => {ITEMORDER=>[qw(Open Save Exit)],
	                                        Open      => sub { 1 },
	                                        Save      => sub { 1 },
	                                        Exit      => sub { exit 0 },
	                       },
		Help    => { ITEMORDER => [qw(Help About)],
		             Help      => sub { 1 },
		             About     => sub { 1 },
		           },
	    },

	  };
}
sub create_botton {
	  new Curses::Widgets::ButtonSet {
		  Y           => 2,
		  X           => 2,
		  FOREGROUND  => 'white',
		  BACKGROUND  => 'black',
		  BORDER      => 0,
		  LABELS      => [ qw( OK CANCEL HELP ) ],
		  LENGTH      => 8,
		  HORIZONTAL  => 1,
	  };
}

sub jscan {
	noecho();
        my $mwh = shift;
        my $key = -1;
        while ($key eq -1) {
                $key = $mwh->getch;
                #if($key eq "\e") {
                        #my $k = $mwh->getch;
                        #if ($k eq 's') { $::mode = 'stats'; return '\t' };
                        #$key = $k; }
                if($key eq 'd' )  { got_h( $mwh )       }
                if($key eq '')  { got_L( $mwh )       }
                if($key eq '')  { got_T( $mwh )       }
                if($key eq '')  { got_H( $mwh )       }
                if($key eq "")  { save2file( $mwh )   }
                if($key eq '')  { analyze             }
                if($key eq '')  { vacuum              }
                if($key eq 'j' )  { return KEY_DOWN     }
                if($key eq 'k' )  { return KEY_UP       }
                if($key eq 'h' )  { return "\n"         }
                if($key eq ' ' )  { return "\n"         }
                if($key eq 'q' )  { exit 0              }
        }
        return $key;
}


sub main_listbox {
	my ($title, $list, $y, $x, $lines) = @_;
	$lines or $lines = @$list;
	assert( ref($list), 'ARRAY') if DEBUG;
	new Curses::Widgets::ListBox {
		  Y           => $y,
		  X           => $x,
		  COLUMNS     => 10,
		  LINES       => $lines,
		  LISTITEMS   => $list,
		  MULTISEL    => 0,
		  VALUE       => 0,
		  INPUTFUNC   => \&miniscan,
		  SELECTEDCOL => 'green',
		  CAPTION     => $title,
		  CAPTIONCOL  => 'yellow',
		  FOCUSSWITCH => "\tl",
		  INPUTFUNC   => \&jscan,
	  };
}
sub secondary_listbox {
	my ($title, $list, $y, $x, $val) = @_;
	#$lines or $lines = @$list;
	assert( ref($list), 'ARRAY') if DEBUG;
	new Curses::Widgets::ListBox {
		  Y           => $y,
		  X           => $x,
		  COLUMNS     => 65,
		  COLUMNS     => 40,
		  LINES       => 7,
		  LISTITEMS   => $list,
		  MULTISEL    => 0,
		  INPUTFUNC   => \&miniscan_sec,
		  FOCUSSWITCH => "\tl",
		  SELECTEDCOL => 'green',
		  CAPTION     => $title,
		  CAPTIONCOL  => 'yellow',
		  CURSORPOS   => $val||0,
		  VALUE       => $val||0,
	  };
}
sub big_listbox {
	my ($title, $list, $y, $x, $val) = @_;
	#$lines or $lines = @$list;
	assert( ref($list), 'ARRAY') if DEBUG;
	new Curses::Widgets::ListBox {
		  Y           => $y,
		  X           => $x,
		  COLUMNS     => 77,
		  LINES       => 12,
		  LISTITEMS   => $list,
		  MULTISEL    => 0,
 		  VALUE       => $val||0,
		  INPUTFUNC   => \&jscan,
		  FOCUSSWITCH => "\tl",
		  CURSORPOS   => $val||0,
		  SELECTEDCOL => 'green',
		  CAPTION     => $title,
		  CAPTIONCOL  => 'yellow',
	  };
}
#####################################################################
sub create_mini_root {
        my $mwh = new Curses @_;
        $mwh->erase();
        $mwh->keypad(1);
        $mwh->syncok(1);
        $mwh->attrset(COLOR_PAIR(select_colour(qw(red black))));
        #$mwh->box(0,0);
        $mwh->attrset(0);
        $mwh->standout();
        $mwh->standend();
        $mwh;
}
our ($sroot, $win_secret);
sub init_mini_root {
	$sroot      = create_mini_root ( 5,40,3,40);
	$win_secret = create_mini_root ( 20,81,4,0);
}

sub got_h {
        my $mwh = shift;
        my $lb_secret  = listbox5 (18,78,0,0, \&retrieve_context)  or return;
        $lb_secret->draw($win_secret,0);
        $lb_secret->execute($win_secret);
}

sub got_d {
        my $mwh = shift;
        my $ll_secret = label_sec( 4,29,0,0) or return;
        $sroot->box(0,0);
        $ll_secret->draw($sroot);
        $ll_secret->execute($sroot);
        sleep 1;
}
sub got_H {
        my $mwh = shift;
        my $ll_secret = label_help( 5,40,0,0) or return;
        $sroot->box(0,0);
        $ll_secret->draw($sroot);
        $ll_secret->execute($sroot);
        sleep 4;
}
sub got_L {
        my $mwh = shift;
        my $lb_secret  = listbox5_white(18,78,0,0,\&capital_context) or return;
        $lb_secret->draw($win_secret,0);
        $lb_secret->execute($win_secret);
}
sub got_T {
        my $mwh = shift;
	eval{
        my $fun = {  tables     => \& table2of   ,
                     stats      => \& stat_of    ,
                     indexes    => \& idx3b      ,
                     vacuum     => \& table3of   ,
                     rules      => \& rewrite_of ,
                     databases  => \& over3      ,
                     buffers    => \& bufcalc    ,
                  }->{$::mode||return};
        my $lb_secret  = listbox5_c2 (18,78,0,0, $fun )  or return;
        $lb_secret->draw($win_secret,0);
        $lb_secret->execute($win_secret);
	} or return;
}
sub display_keyword {
	my $keyword = shift||return;
	my ($y,$x)  = (9,1) ;
	$::mwh->addstr( $y,$x, $keyword);
	$::mwh->refresh;
	sleep 1;
	$::mwh->addstr( $y,$x, ' ' x length$keyword);
	$::mwh->refresh;
}

sub got_A { analyze }
sub got_V { vacuum  }
sub got_R { reindex };

sub listbox5 {
        my ( $lines, $cols, $y,$x, $fun) = @_;
	my $content = $fun->() or return;
        new Curses::Widgets::ListBox {
                  Y           => $x||1,
                  X           => $y||3,
                  COLUMNS     => $cols||25,
                  LISTITEMS   => $content,
                  MULTISEL    => 0,
                  LINES       => $lines||5,
                  INPUTFUNC   => \&miniscan,
                  SELECTEDCOL => 'white',
                  CAPTIONCOL  => 'yellow',
                  FOCUSSWITCH =>  "\tdDl\n",
                  BORDER      => 0,
                  FOREGROUND  => 'white',
                  BACKGROUND  => 'blue',
                  VALUE       =>  0,
          };
}

sub listbox5_c2 {
        my ( $lines, $cols, $y,$x, $fun) = @_;
	my $content = $fun->() or return;
        new Curses::Widgets::ListBox {
                  Y           => $x||1,
                  X           => $y||3,
                  COLUMNS     => $cols||25,
                  LISTITEMS   => $content,
                  MULTISEL    => 0,
                  LINES       => $lines||5,
                  INPUTFUNC   => \&miniscan_5c,
                  SELECTEDCOL => 'black',
                  CAPTIONCOL  => 'yellow',
                  FOCUSSWITCH =>  "\tdDl\n",
                  BORDER      => 0,
                  FOREGROUND  => 'black',
                  BACKGROUND  => 'magenta',
                  VALUE       =>  0,
          };
}
sub listbox5_white {
        my ( $lines, $cols, $y,$x, $fun) = @_;
	my $content = $fun->() or return;
        new Curses::Widgets::ListBox {
                  Y           => $x||1,
                  X           => $y||3,
                  COLUMNS     => $cols||25,
                  LISTITEMS   => $content,
                  MULTISEL    => 0,
                  LINES       => $lines||5,
                  INPUTFUNC   => \&miniscan_5c,
                  SELECTEDCOL => 'black',
                  CAPTIONCOL  => 'yellow',
                  FOCUSSWITCH =>  "\tdDl\n",
                  BORDER      => 0,
                  FOREGROUND  => 'blue',
                  BACKGROUND  => 'white',
                  VALUE       =>  0,
          };
}

sub label_sec {
        my ( $lines, $cols, $y,$x) = @_;
	my $content = retrieve_permit() or return;
        new  Curses::Widgets::Label {
		   COLUMNS     =>  $cols,
		   LINES       =>  $lines,
		   VALUE       =>  "@$content",
		   FOREGROUND  =>  'white',
		   BACKGROUND  =>  'blue',
		   X           =>  $x,
		   Y           =>  $y,
		   ALIGNMENT   => 'C',
        };
}
sub bscan {
        my $mwh = shift;
        my $key = -1;
        while ($key eq -1) {
                $key = $mwh->getch;
                #if($key eq "k")  { return 259};  #ver
                #if($key eq "j")  { return 258};  #ver
                if($key eq "h")  { return 260};  #horz
                if($key eq "k")  { return 261};  #horz
                if($key eq "n")  { return 260};  #horz
                if($key eq "m")  { return 261};  #horz
                if($key eq "l")  { return "\t"};
                if($key eq " ")  { return "\n"};
        }
        return $key;
}

sub create_button {
        my ( $choices, $cols, $x,$y) = @_;
        new Curses::Widgets::ButtonSet   {
           LABELS      => $choices,
           LENGTH      => $cols,
           INPUTFUNC   => \&bscan,
           FOREGROUND  => 'white',
           BACKGROUND  => 'blue',
           BORDER      => 1,
           BORDERCOL   => 'red',
           FOCUSSWITCH => "\t\n",
           HORIZONTAL  => 1,
           PADDING     => 0,
           X           => $x,
           Y           => $y,
        }
}

sub label_help {
        my ( $lines, $cols, $y,$x) = @_;
	my $content = q(
Ctrl-L   Display 20 lastest tuples
Ctrl-T   Statistics
Ctrl-A   Analyze
Ctrl-F   data to File /tmp/pcurse.out 
        );
        new  Curses::Widgets::Label {
		   COLUMNS     =>  $cols,
		   LINES       =>  $lines,
		   VALUE       =>  $content,
		   FOREGROUND  =>  'black',
		   BACKGROUND  =>  'green',
		   X           =>  $x,
		   Y           =>  $y,
		   ALIGNMENT   => 'L',
        };
}
1;
__END__
=head1 NAME

Pg::Pcurse::Widget  - Support widgets for Pg::Pcurse

=head1 SYNOPSIS

  use Pg::Pcurse::Query0;

=head1 DESCRIPTION

Support widgets for Pg::Pcurse


=head1 SEE ALSO

Pg::Pcurse, pcurse(1)

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms of GPLv3


=cut

