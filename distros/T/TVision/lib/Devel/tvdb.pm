use strict;
package Devel::tvdb;
use DB;
our @ISA = qw(DB);

__PACKAGE__->register;

sub init {
    # WHY not called??
    print "init\n";
}

# optional tcl/tk
my $int;

sub idle {
    TVision::spin_loop();
    $int->update if $int;
}
sub loadfile {
    print "loadfile[@_]\n";
}


use blib '/home/vad/tv/perl-tvision/blib';
use TVision qw(:keys :commands :msgbox tnew);

=head1 NAME

Devel::tvdb - Perl debugger using Turbo Vision interface.

=head1 SYNOPSIS

    perl -d:tvdb myscript.pl

=head1 DESCRIPTION

tvdb is a debugger for perl that uses Turbo Vision for a user interface.

=head1 See also

https://github.com/vadrerko/... XXX TODO

=head1 AUTHORS

 Vadim Konovalov

=cut


BEGIN {
    $Devel::tvdb::linenumber_length = 5;
}

my $tapp;
my $desktop;
my $log_window;
my $log_window_e;
my $cur_editor;
my $evil_window;
my $extent;

sub ::_log($) {
    if ($log_window_e) {
        $log_window_e->insertMultilineText($_[0]."\n",length($_[0])+1);
        $log_window_e->scrollTo(0, 100000);
    } else {
        print "@_;;\n";
    }
}

my %files;
my %files2cnt;
my %pos;
my $prevline;
sub stop {
    # why not called?
    my ($self, $filename, $line) = @_;
    ::_log "STOP - $filename $line \$#dbline=$#DB::dbline";
}
sub cleanup {
    # why not called?
    ...;
    TVision::messageBox("program ended.",mfOKButton);
}
my $wnd_cnt=-1;
sub showfile {
    my ($self, $filename, $line) = @_;
    init1() unless $tapp;
    #DEBUG ::_log "$filename $line \$#dbline=$#DB::dbline";
    unless ($files{$filename}) {
        $wnd_cnt++;
        $files{$filename} = TVision::tnew('TEditWindow', 
                0 ? $desktop->getExtent : [$wnd_cnt,$wnd_cnt,80+$wnd_cnt,50+$wnd_cnt],
                "$filename.debug", 0
            );
        $desktop->insert($files{$filename});
        $cur_editor = $files{$filename}->get_editor;
        $cur_editor->store_user_value($filename);
        my $i0 = "0" x $Devel::tvdb::linenumber_length;
        if ($#DB::dbline > -1) {
            for (@DB::dbline[1 .. $#DB::dbline]) {
                my $str = s/\n$//r;
                my $i1 = ++$i0;
                my $s = "$i0 " . ($i1==$line? '[*]' : '[ ]') . ($_==0? ' ':'.') . " $str";
                $pos{$filename}->[$i1] = $cur_editor->get_curPtr;
                $cur_editor->insertBuffer($s, 0, length($s),0,0);
                $cur_editor->insertEOL(0);
            }
        }
        $files2cnt{$filename} = $#DB::dbline;
    } else {
	# switch to it
        $files{$filename}->focus;
        if ($files2cnt{$filename} != $#DB::dbline) {
            ::_log "??? BUG $filename $line - $files2cnt{$filename} != $#DB::dbline";
        }
    }

    if ($prevline) {
        # remove mark on previous line
        $cur_editor->setSelect($pos{$filename}->[$prevline]+7, $pos{$filename}->[$prevline]+8, 0);
        $cur_editor->insertText(" ", 1,0);
    }
    # set new mark (wish it could be color selectionn
    $cur_editor->setSelect($pos{$filename}->[$line]+7, $pos{$filename}->[$line]+8, 0);
    $cur_editor->insertText("*", 1,0);
    $cur_editor->setSelect($pos{$filename}->[$line], $pos{$filename}->[$line]+4, 0);
    $cur_editor->trackCursor(0);

    $prevline = $line;

}

my $received_message = '';
sub output {
    TVision::messageBoxRect([5,5,60,12],$_[1],mfOKButton);
    $received_message = $_[1];
}

sub init1 {
    print "init1\n";

    my $submenu = TVision::TSubMenu::new( "~\xf0~system", 0, 0 )
        -> plus ( TVision::TMenuItem::new( "~A~bout...", cmAboutCmd, kbNoKey, 0 ) )
        -> plus ( TVision::TMenuItem::new( "E~x~it", cmQuit, kbAltX, 0 ) )
        -> plus (
            tnew(TSubMenu=>"~D~ebug", 0, 0 )
                ->plus(tnew 'TMenuItem', 'Step-in', 201, kbF7, 0, 'F7')
                ->plus(tnew 'TMenuItem', 'Step-over', 202, kbF8, 0, 'F8')
                ->plus(tnew 'TMenuItem', 'Run', 203, kbAltR, 0, 'Alt-R')
                ->plus(tnew 'TMenuItem', 'Eval', 204, kbAltE, 0, 'Alt-E')
                ->plus(TVision::TMenuItem::newLine)
                ->plus(tnew 'TMenuItem', 'set breakpoint', 205, kbAltB, 0, 'Alt-B')
                ->plus(tnew 'TMenuItem', 'clear breakpoint', 206, 0, 0)
                ->plus(TVision::TMenuItem::newLine)
                ->plus(tnew 'TMenuItem', 'files', 207, 0, 0)
                ->plus(tnew 'TMenuItem', 'subs', 208, 0, 0)
        )
        ->plus(
            tnew(TSubMenu=>"~T~cl/tk", 0, 0 )
                ->plus(tnew('TMenuItem','tcl/tk', 306, kbAltL, 0, 'Alt-L'))
                ->plus(TVision::TMenuItem::newLine)
                ->plus(tnew('TMenuItem','try1', 307))
                ->plus(tnew('TMenuItem','try2', 308))
        )
        -> plus (
            TVision::TSubMenu::new( "~W~indows", 0, 0 )
            -> plus ( TVision::TMenuItem::new( "~R~esize/move", cmResize, kbCtrlF5, 0, "Ctrl-F5" ) )
            -> plus ( TVision::TMenuItem::new( "~Z~oom", cmZoom, kbF5, 0, "F5" ) )
            -> plus ( TVision::TMenuItem::new( "~N~ext", cmNext, kbF6, 0, "F6" ) )
            -> plus ( TVision::TMenuItem::new( "~C~lose", cmClose, kbAltF3, 0, "Alt-F3" ) )
            -> plus ( TVision::TMenuItem::new( "~T~ile", cmTile, kbNoKey, 0 ) )
            -> plus ( TVision::TMenuItem::new( "C~a~scade", cmCascade, kbNoKey, 0 ) )
        );
    my $menubar = tnew TMenuBar=>([0,0,179,1],$submenu);

    $tapp = tnew TVApp => $menubar;
    $desktop = $tapp->deskTop;
    $extent = $desktop->getExtent;

    $log_window = tnew(TEditWindow=> [82,1,162,20], 'log.txt', 0);
    $desktop->insert($log_window);
    $log_window_e = $log_window->get_editor;
    $evil_window = tnew(TEditWindow=> [82,21,162,40], 'evil.txt', 0);
    $desktop->insert($evil_window);

    $tapp->onCommand(sub {
	my ($cmd, $arg) = @_;
	if ($cmd == 201) { # step-in
            __PACKAGE__->step;
            __PACKAGE__->ready;
	} elsif ($cmd == 202) { # step-over
            __PACKAGE__->next;
            __PACKAGE__->ready;
	} elsif ($cmd == 203) { # run
            __PACKAGE__->cont;
            __PACKAGE__->ready;
	} elsif ($cmd == 204) { # eval
            my $str = "2+3";
            if ($cur_editor->hasSelection) {
                my ($ss,$se) = ($cur_editor->get_selStart, $cur_editor->get_selEnd);
                $str = substr $cur_editor->get_buffer,$ss, $se-$ss;
            }
            $str = TVision::inputBox("eval", "input string to be evaluated", $str);
            ::ins($evil_window->get_editor, "eval $str = " . eval("$str") . ($@ ? $@ : "") . "\n");
            # ?? __PACKAGE__->evalcode($str)
	} elsif ($cmd == 205) { # set break
            if ($cur_editor) {
                my $p = $cur_editor->get_curPos;
                ::_log "(@$p)";
                $received_message = '';
                __PACKAGE__->set_break($p->[1]);
                if ($received_message eq '') {
                    my $_filename = $cur_editor->retrieve_user_value();
                    $cur_editor->setSelect($pos{$_filename}->[$p->[1]]+5, $pos{$_filename}->[$p->[1]]+6, 0);
                    $cur_editor->insertText('@', 1,0);
                    #$cur_editor->my_draw([1,1,100,1], "proba1 proba2 проба3 ~проба4~ ds", 0x4E);
                } else {
                    # was not able to set breakpoint, so nothig to be done here
                }
            }
	} elsif ($cmd == 207) {
            ::_log  join "\n", __PACKAGE__->files(), '';
	} elsif ($cmd == 208) {
            ::_log join "\n", __PACKAGE__->subs(), '';
	} elsif ($cmd == 307) { # try1
            ::_log "drawLine=" . $cur_editor->get_drawLine;
	} elsif ($cmd == 308) { # try2
            ::_log "set_drawLine(5)";
            $cur_editor->set_drawLine(5);
	} elsif ($cmd == 306) { # tcl/tk
            unless ($int) {
                require Tcl::Tk;
                $int = new Tcl::Tk;
                $int->Eval('
                    pack [frame .f]
                    pack [button .f.bstep -text step] -side left
                    pack [button .f.bnext -text next] -side left
                    pack [label .f.l -text {      }] -side left
                    pack [entry .f.e -textvariable txte] -side left
                    pack [button .f.beval -text eval] -side left
                ');
                $int->call('.f.bstep', 'configure', -command => sub {
                    __PACKAGE__->step;
                    __PACKAGE__->ready;
                });
                $int->call('.f.bnext', 'configure', -command => sub {
                    __PACKAGE__->next;
                    __PACKAGE__->ready;
                });
                $int->call('.f.beval', 'configure', -command => sub {
                    my $str = $int->GetVar('txte');
                    ::ins($evil_window->get_editor, "eval $str = " . eval("$str") . ($@ ? $@ : "") . "\n");
                });
            }
            if ($cur_editor->hasSelection) {
                my ($ss,$se) = ($cur_editor->get_selStart, $cur_editor->get_selEnd);
                my $str = substr $cur_editor->get_buffer,$ss, $se-$ss;
                $int->SetVar('txte', $str);
            }
	}
	elsif ($cmd == cmQuit) {
	    exit;
	}
    });
}

sub ::ins {
    $_[0]->insertMultilineText($_[1], length($_[1]));
}

__PACKAGE__->ready;

1;

