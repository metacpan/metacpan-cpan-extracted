#!/usr/local/bin/perl
# -d:ptkdb

# This is hierarchical task list management system with time
# management.
#
# Copyright (c) 2000 Sergey Gribov <sergey@sergey.com>
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute and modify it freely, but please leave
# this message attached to this file.
#
# Subject to terms of GNU General Public License (www.gnu.org)
#
# Last update: $Date: 2001/07/30 15:09:32 $ by $Author: sergey $
# Revision: $Revision: 1.2 $

# This stuff is to find our actual location...
BEGIN {
  use File::Basename;
  use Cwd;

  my $full = $0;
  my $cwd = Cwd::cwd();
  while (-l $full) {
    $BASEDIR = dirname($full);
    $full = readlink $full;
    ($full !~ m|^/|) and $full = $BASEDIR . "/" . $full;
  }
  $BASEDIR = dirname($full);
  $BASEDIR = "$cwd" if (!$BASEDIR || $BASEDIR eq "./" || $BASEDIR eq ".");
  $BASEDIR = "$cwd/$BASEDIR" unless ($BASEDIR =~ m|^/|);

# Uncomment and edit this line if you want to put tasks.pl in some
# other place than the rest of the files
#  $BASEDIR = '/usr/local/share/tasks';
  
  unshift(@INC, $BASEDIR);
  unshift(@INC, $ENV{'HOME'}.'/lib') if $ENV{'HOME'};
}

use Getopt::Std;
use Tk;

use Tasks;
use tasks_lib;

use strict;
no strict 'refs';

$| = 1;

my $revision = '$Revision: 1.2 $';
$revision =~ s/[^0-9\.]//g;
my $VERSION = $revision;

#my $tasks_fname = 'tasks.xml';
my $tasks_fname = $ENV{'HOME'}.'/.tasks.xml';

use vars qw($debug $VERSION $win);

# constants
use vars qw($c_lpr_prg $c_lpr_dos);
$c_lpr_prg = '/usr/bin/lpr';
$c_lpr_dos = 1; # convert to DOS file before printing

use constant FIXED_FONT => 'fixed';
use constant ACTIVE_TASK_COLOR => 'LightBlue';
use constant PASSIVE_TASK_COLOR => 'gray';

use constant SEC_IN_DAY => 86400;

$debug = 0;
my $win_h = 69;			# main window hight
my $win_w = 124;		# main window width
my $g_listview_width = 45;	# listview or notes area width
my $g_report_width   = 75;	# report area width
my $g_idle_task_name = '< IDLE >';
my $g_expand         = 0;	# Expand to subtasks by default if 1
my $g_autosave_on    = 1;	# On / Off autosave feature 
my $g_autosave_tm    = 300;	# autosave timeout
my $g_show_private   = 1;	# Show private tasks in the reports

my %bt_timer_attr = (
                    'start' => {'text' => 'Start', 'color' => 'green'},
                    'stop'  => {'text' => 'Stop ', 'color' => 'tomato'},
                    );


my %opt;
my $ret = getopts('i:dvh', \%opt);
$debug = 1 if ($opt{v});
$debug = 2 if ($opt{d});
Usage() if ($opt{h});
$tasks_fname = $opt{i} if $opt{i};

my $tasks = new Tasks;
dprint("Reading task list...  ", 1);
my $ret = $tasks->read($tasks_fname);
error($ret) if $ret;
dprint("Done.\n", 1);

my $g_tasklist = $tasks->tasklist();
$g_tasklist = $g_tasklist->[0] if $g_tasklist;	# use only the first tasklist
my $tasks_hash = $tasks->create_task_hash(undef, $g_tasklist);

# Initialization
my $timer = undef;
my $current_task = undef;

dprint("Initiating window...\n", 1);
$win = {};
$win->{main} = MainWindow->new;
#$win->{main}->geometry($win_w.'x'.$win_h);
$win->{main}->geometry($win_w.'x'.$win_h.'+0-0');

$win->{basic}{fr_menu} =
  $win->{main}->Frame()->pack(-fill=>'x', -side=>'top');
$win->{basic}{fr_main} =
  $win->{main}->Frame()->pack(-fill=>'x');
$win->{basic}{fr_bottom} =
  $win->{main}->Frame()->pack(-fill=>'x', -side=>'bottom');

# Menu setup
$win->{basic}{menu} =
  $win->{basic}{fr_menu}->Menubutton(-text=>"Menu ",
				  -borderwidth=>1, -padx => 3, -pady => 3,
                                  -relief=>'groove',
				  -anchor =>'w'
				  )->pack(-side=>'left');

# File menu
$win->{basic}{mn_file} = $win->{basic}{menu}->Menu();
$win->{basic}{menu}->cascade(-label => 'File',
                             -menu => $win->{basic}{mn_file});

$win->{basic}{menu_reload} =
  $win->{basic}{mn_file}->command(-label => 'Reload',
                                  -command => sub{
                                     $ret = $tasks->read($tasks_fname);
                                     error($ret) if $ret;
                                     create_tasks_menu();
                                  });
$win->{basic}{menu_save} =
  $win->{basic}{mn_file}->command(-label => 'Save',
                                  -command => sub{
                                     $ret = $tasks->save();
                                     error($ret) if $ret;
                                  });
$win->{basic}{menu_saveas} =
  $win->{basic}{mn_file}->command(-label => 'Save As...',
                                  -command => \&save_as);

# Reports menu
$win->{basic}{mn_rep} = $win->{basic}{menu}->Menu();
$win->{basic}{menu}->cascade(-label => 'Reports',
                             -menu => $win->{basic}{mn_rep});

$win->{basic}{menu_rep_time} =
  $win->{basic}{mn_rep}->command(-label => 'Times reports',
                                  -command => sub{ report({'mode'=>'time'});});
$win->{basic}{menu_rep_time} =
  $win->{basic}{mn_rep}->command(-label => 'List of tasks',
                                  -command => sub{ report({'mode'=>'list'});});
$win->{basic}{menu_rep_time} =
  $win->{basic}{mn_rep}->command(-label => 'List by Priority',
                                  -command => sub{ report({'mode'=>'priority'});});

# Misc submenu
$win->{basic}{mn_misc} = $win->{basic}{menu}->Menu();
$win->{basic}{menu}->cascade(-label => 'Misc',
                             -menu => $win->{basic}{mn_misc});
$win->{basic}{menu_pref} =
  $win->{basic}{mn_misc}->command(-label => 'Preferences',
                                  -command => \&edit_pref);
$win->{basic}{menu_closepop} =
  $win->{basic}{mn_misc}->command(-label => 'Close all popups',
                                  -command => \&close_popups);
$win->{basic}{menu_closepop} =
  $win->{basic}{mn_misc}->command(-label => 'Reset the times',
                                  -command => sub {
                                    zero_times();
#                                    $tasks->zero_time();
                                  });
$win->{basic}{menu_exitnosave} =
  $win->{basic}{mn_misc}->command(-label => 'Exit without Save',
                                  -command => sub{exit;});

# Help submenu
$win->{basic}{mn_help} = $win->{basic}{menu}->Menu();
$win->{basic}{menu}->cascade(-label => 'Help',
                             -menu => $win->{basic}{mn_help});
$win->{basic}{menu_about} =
  $win->{basic}{mn_help}->command(-label => 'About',
     -command => sub{
	popup_text("$main::BASEDIR/about.txt",
		   "About tasks.pl (v".$VERSION.")");
     });
$win->{basic}{menu_help} =
  $win->{basic}{mn_help}->command(-label => 'Help',
     -command => sub{ popup_text("$main::BASEDIR/help.txt", 'Help'); });

$win->{basic}{menu_list} =
  $win->{basic}{menu}->command(-label => 'List View',
                               -command => \&listview);
$win->{basic}{menu_new} =
  $win->{basic}{menu}->command(-label => 'New task',
                               -command => \&new_task);
$win->{basic}{menu_exit} =
  $win->{basic}{menu}->command(-label => 'Exit',
                               -command => sub{
                                             $ret = $tasks->save();
                                             error($ret) if $ret;
                                             exit;
                                           });

$win->{basic}{bt_timer} =
  $win->{basic}{fr_menu}->Button(-text => $bt_timer_attr{start}{text},
                                 -background => $bt_timer_attr{start}{color},
			         -padx=>2, -pady=>2, -relief=>'groove',
				 -command=> \&switch_timer,
			        )->pack(-side=>'left');
$win->{basic}{bt_edit} =
  $win->{basic}{fr_menu}->Button(-text=>"Edit ",
				  -borderwidth=>1, -highlightthickness=>1,
			          -padx=>2, -pady=>2, -relief=>'groove',
				  -command=> sub { edit_task($current_task); },
				  )->pack(-side=>'left');
create_tasks_menu();

my $task_comment = '';
$win->{basic}{et_desc} =
  $win->{basic}{fr_bottom}->Entry(-textvariable=>\$task_comment)->pack();

set_autosave();

MainLoop;

print "Should never end up here... :)\n";

exit;

###################################################################

# 'Zero times' popup
sub zero_times {
  dprint("zero_times()\n", 2);
  
  error("No main window") unless Exists($win->{main});
  my $popup = $win->{main}->Toplevel(-title => 'Reset times');
  push(@{$win->{popups}}, $popup);

  my $frame = $popup->Frame();
  my $days = 0;
  $frame->Label(-text => 'Number of days to leave the times untouched (0 resets all the times):')->pack(-side => 'left');
  $frame->Entry(-textvariable => \$days, -width => 3)->pack(-side => 'left');
  $frame->pack(-fill=>'x', -side=>'top');
  
  $frame = $popup->Frame();
  $frame->Button(-text => 'Reset the times',
		 -command => sub {
		   my $d = $days;
		   $d = time() - $days * SEC_IN_DAY if $days;
		   $tasks->zero_time(undef, 0, $d);
		 })->pack(-side => 'left');
  $frame->Button(-text => 'Close',
		 -command => [$popup => 'destroy'])->pack(-side => 'left');
  $frame->pack(-side=>'bottom');
}

# Show times report
# Parameter: $options - pointer to hash with options
sub report {
  my $options = shift;
  dprint("report()\n", 2);
  my $title = 'Report';
#  my $options = {'start' => 0, 'finish' => 0};
  $options->{'expand'} = $g_expand;
  $win->{time_rep}{options} = $options;
  my $mode = $win->{time_rep}{options}{mode} ?
      $win->{time_rep}{options}{mode} : 'time';
  
  error("No main window") unless Exists($win->{main});
  if (Exists($win->{time_rep}{win})) {
    $win->{time_rep}{win}->destroy();
  }
  $win->{time_rep}{win} = $win->{main}->Toplevel(-title => $title);
  push(@{$win->{popups}}, $win->{time_rep}{win});

  my ($frame, $text_win, $bt_expand, $rep);

  my $days = 0;
  $win->{time_rep}{days} = \$days;
  $frame = $win->{time_rep}{win}->Frame();
#  $frame->Label(-text => 'Number of days to limit the report to (0 for no limit):')->pack(-side => 'left');
#  $frame->Entry(-textvariable => \$days, -width => 3)->pack(-side => 'left');
  $frame->Button(-text => 'Regenerate Report',
		 -command => sub {
		   $options->{start} = int($days) ?
		       (time() - int($days) * SEC_IN_DAY) : 0;
		   $rep = generate_report(undef, $options);
		   insert_text2frame($text_win, $rep);
		 })->pack(-side => 'right');
  $frame->Button(-text => 'Report Options',
		 -command => \&report_options)->pack(-side => 'right');
  $frame->pack(-fill=>'x', -side=>'top');

  $rep = generate_report(undef, $options);
  ($frame, $text_win) = create_text_frame($win->{time_rep}{win}, $rep, $title);

  $frame = $win->{time_rep}{win}->Frame();
  $frame->Button(-text => 'Close', -command => [$win->{time_rep}{win} => 'destroy'])
      ->pack(-side => 'right');
  
  my $label = $g_expand ? ' Collapse ' : '  Expand  ';
  $bt_expand = $frame->Button(-text => $label,
	  -command => sub {
  	  $g_expand = $g_expand ? 0 : 1;
  	  $label    = $g_expand ? ' Collapse ' : '  Expand  ';
	  $options->{'expand'} = $g_expand;
	  $options->{start} = int($days) ?
	      (time() - int($days) * SEC_IN_DAY) : 0;
  	  $rep = generate_report(undef, $options);
	  insert_text2frame($text_win, $rep);
  	  $bt_expand->configure(-text => $label);
  	})->pack(-side => 'right');

  $frame->Button(-text => 'Print', -command => sub { print_text($rep); })
      ->pack(-side => 'right');
  
  my $fname = '/tmp/report.txt';
  $frame->Label(-text => 'FileName to save to:')->pack(-side => 'left');
  $frame->Entry(-textvariable => \$fname)->pack(-side => 'left');
  $frame->Button(-text => 'Save', -command => sub { save_text($fname, $rep); })
      ->pack(-side => 'left');
  
  $frame->pack(-fill=>'x', -side=>'bottom');
}

sub report_options {
  error("No main window") unless Exists($win->{main});
  if (Exists($win->{rep_opt}{win})) {
    $win->{rep_opt}{win}->destroy();
  }
  $win->{rep_opt}{win} = $win->{main}->Toplevel(-title => 'Report Options');
  push(@{$win->{popups}}, $win->{rep_opt}{win});

  my $frame = $win->{rep_opt}{win}->Frame();
  $frame->Label(-text => 'Number of days to limit the report to (0 for no limit):')->pack(-side => 'left');
  $frame->Entry(-textvariable => $win->{time_rep}{days}, -width => 3)->pack(-side => 'left');
  $frame->pack(-fill=>'x', -side=>'top');
  
  $frame = $win->{rep_opt}{win}->Frame();
  $frame->Label(-text => 'Show the private tasks')->pack(-side => 'left');
  $frame->Checkbutton(-variable=>\$g_show_private)->pack(-side => 'left');
  $frame->pack(-fill=>'x', -side=>'top');

  $frame = $win->{rep_opt}{win}->Frame();
  $frame->Button(-text => 'Close',
		 -command => [$win->{rep_opt}{win} => 'destroy'])
      ->pack(-side => 'right');
  $frame->pack(-fill=>'x', -side=>'bottom');
}

# Parameters:
#   $task - pointer to task.
#   $options - pointer to options hash
sub generate_report {
  my ($task, $options) = @_;

  my $mode = $options->{mode} ? $options->{mode} : 'time';
  dprint("generate_report($mode)\n", 2);
  my $report = {};

  if ($mode eq 'time') {
    $report->{rep}   =<<"EOM";
Task Name                                                Time        Percent
+-------------------------------------------------------+-----------+---------+
EOM
  }
  elsif ($mode eq 'list') {
    $report->{rep}   =<<"EOM";
Task Name / [Description]                       Priority Time        Percent
+----------------------------------------------+--------+-----------+---------+
EOM
  }
  elsif ($mode eq 'priority') {
    $report->{rep}   =<<"EOM";
Task Name                                       Priority Time        Percent
+----------------------------------------------+--------+-----------+---------+
EOM
  }
  else {
    error("Unknown report mode: $mode");
    return undef;
  }
    
  $report->{time_options} = $options;
  $report->{time_options}{private} = $g_show_private;
  $report->{total} = $tasks->get_total_time($task, $report->{time_options});

  unless ($options->{expand} || $mode eq 'priority') {
    if ($task) {
      map { $report = gen_rep($_, $report, 0); } @{$g_tasklist->{_tasks}}
    }
    else {
      foreach $task (@{$g_tasklist->{_tasks}}) {
	$report = gen_rep($task, $report, 0);
      }
    }
  }
  else {
    if ($task) {
      $report = $tasks->traverse_task_tree($task, \&gen_rep, $report, 0);
    }
    else {
      foreach $task (@{$g_tasklist->{_tasks}}) {
	$report = $tasks->traverse_task_tree($task, \&gen_rep, $report, 0);
      }
    }
  }
  
  if ($mode eq 'priority') {
    map { $report->{rep} .= $report->{pr}{$_}; }
      (sort {$b <=> $a} keys %{$report->{pr}});
  }

  my $total = convert_time($report->{total});
  my $buf = '';
  $buf = "Report take in account only last ${$win->{time_rep}{days}} days"
      if ${$win->{time_rep}{days}};
  $report->{rep} .=<<"EOM";
+-----------------------------------------------------------------------------+
Total registred time spend on all tasks: $total
$buf
EOM

  return $report->{rep};

  sub gen_rep {
    my ($task, $ret, $level) = @_;
    my $prefix = ' 'x$level;

    my $mode = $ret->{time_options}->{mode} ?
	$ret->{time_options}->{mode} : 'time';
    return $ret unless $task;
    return $ret if ($task->{inactive});
    return $ret if (!$g_show_private && $task->{private});
    my $time = $tasks->get_total_time($task, $ret->{time_options});
    my $pcnt = $ret->{total} ? $time * 100 / $ret->{total} : 0;
    dprint("gen_rep: $task->{name} --- $time\n", 2);
    
    $pcnt =~ s/\.(..).*$/\.$1/g;
    $pcnt = $pcnt ? "$prefix ($pcnt\%)" : '';
    $time = fit_str(convert_time($time), 10);

    my ($w, $str, $t);
    if ($mode eq 'time') {
      $w = $g_report_width - 19;
      $str = $prefix.$task->{name};
      $str = fit_str($str, $w);
      $ret->{rep} .= "$str $time $pcnt\n";
    }
    elsif ($mode eq 'list') {
      $w = $g_report_width - 26;
      $str = $prefix.$task->{name};
      $str = fit_str($str, $w);
      
      $str .= "  $task->{priority}";
      $w = $g_report_width - 19;
      $str = fit_str($str, $w);
      $ret->{rep} .= "$str $time $pcnt\n";

      $str = $task->{_text};
      $str =~ s/^(\s*\n*)+//gs;
      $str =~ s/\n(\s*\n*)+$//gs;
      chomp($str);
      unless ($str =~ /^\s*$/s) {
	$str = $prefix.'['.$str.']';
	$str =~ s/\n/\n$prefix/gs;
	$ret->{rep} .= "$str\n\n";
      }
    }
    elsif ($mode eq 'priority') {
      $w = $g_report_width - 26;
      $str = $task->{name};
      if ($task->{_parent}) {
	$t = $tasks->get_task($task->{_parent});
	$str .= ' ( '.$t->{name}.' )' if ($t && $t->{name});
      }
      $str = fit_str($str, $w);
      
      $str .= "  $task->{priority}";
      $w = $g_report_width - 19;
      $str = fit_str($str, $w);
      $ret->{pr}{$task->{priority}} .= "$str $time $pcnt\n";
    }
    
    return $ret;
  }
}

# Create / recreate tasks menu
sub create_tasks_menu {
  dprint("create_tasks_menu()\n", 2);
  if (Exists($win->{basic}{mn_tasks})) {
    dprint("create_tasks_menu(): recreate menu\n", 2);
    $win->{basic}{mn_tasks}->destroy();
    $tasks_hash = $tasks->create_task_hash(undef, $g_tasklist);
  }
  $win->{basic}{mn_tasks} =
      $win->{basic}{fr_main}->Menubutton(-text => $g_idle_task_name,
					 -relief => "raised",
					 -background => PASSIVE_TASK_COLOR
					 )->pack(-fill=>'x', -expand=>1);

  foreach (@{$g_tasklist->{_tasks}}) {
    cascade_tasks_menu($win->{basic}{mn_tasks}, $_, \&set_task);
  }
  $win->{basic}{mn_tasks}->command(-label => $g_idle_task_name,
				   -command => sub { set_task(undef); });
}
# Create recursively tasks menu
# Parameters:
#   $pmenu - parent menu object
#   $task  - pointer to the task
#   $handler - pointer to function to call with this task selected
sub cascade_tasks_menu {
  my ($pmenu, $task, $handler) = @_;
  return undef unless (Exists($pmenu) && $task);
  return undef if ($task->{inactive});
  my $name = $task->{name} ? $task->{name} : '';
  if (scalar(@{$task->{_tasks}})) {
    $tasks_hash->{$task->{id}}{menu} = $pmenu->Menu();
    $pmenu->cascade(-label => $name,
		    -menu => $tasks_hash->{$task->{id}}{menu});
    $tasks_hash->{$task->{id}}{menu}->command(-label => $name,
					      -command => sub {
						&$handler($task);
					      });
    foreach (@{$task->{_tasks}}) {
      cascade_tasks_menu($tasks_hash->{$task->{id}}{menu}, $_, $handler);
    }
  }
  else {
    $tasks_hash->{$task->{id}}{menu} =
	$pmenu->command(-label => $name,
			-command => sub { &$handler($task); });
  }
}

sub set_task {
  my $task = shift;
  my $name  = $task ? $task->{name} : $g_idle_task_name;
  my $color = $task && $task->{name} ? ACTIVE_TASK_COLOR : PASSIVE_TASK_COLOR;
  dprint("set_task($name)\n", 2);
  stop_timer();
  $current_task = $task;
  $task_comment = '';
  start_timer() if ($task && $task->{name});
  $win->{basic}{mn_tasks}->configure(-text => $name,
				     -background => $color);
}

# Edit task
# Parameters:
#   $task - (optional) pointer to task, if not defined $current_task used
sub edit_task {
  my $task = shift;
  $task = $current_task unless $task;
  dprint("edit_task()\n", 2);
  unless ($task) {
    error("No task to edit");
    return;
  }
  my $popup = $win->{main}->Toplevel(-title => "Edit task \"$task->{name}\"");
  push(@{$win->{popups}}, $popup);

  my %t = ();
  map { $t{$_} = $task->{$_}; } ('name', 'id', '_text', 'priority',
				 'private', 'inactive');

  my %edit_win = ();

  # Create frames
  $edit_win{fr_buttons}  = $popup->Frame()->pack(-side=>'bottom');
  $edit_win{fr_note}     = $popup->Frame()->pack(-side=>'bottom');
  $edit_win{fr_subtasks} = $popup->Frame()->pack(-side=>'bottom');
  $edit_win{fr_main}     = $popup->Frame()->pack(-side=>'top', -fill=>'both',
						 -expand => "true");
  
  # Main entries
  my ($c1, $c2);
  $c1 = $edit_win{fr_main}->Label(-text => 'Task Name');
  $c2 = $edit_win{fr_main}->Entry(-textvariable => \$t{name});
  $c1->grid($c2, -sticky => 'w');
  
  $c1 = $edit_win{fr_main}->Label(-text => 'Priority');
  $c2 = $edit_win{fr_main}->Scale(-orient=>'horizontal', -length=>'30m',
				  -sliderlength=>'5m', -width=>'3m',
				  -from=>'0', -to=>'5',
				  -variable=>\$t{priority});
  $c1->grid($c2, -sticky => 'w');

  $c1 = $edit_win{fr_main}->Label(-text => 'Task is Private');
  $c2 = $edit_win{fr_main}->Checkbutton(-variable=>\$t{private});
  $c1->grid($c2, -sticky => 'w');

  $c1 = $edit_win{fr_main}->Label(-text => 'Inactivate task');
  $c2 = $edit_win{fr_main}->Checkbutton(-variable=>\$t{inactive},
					-text => '(almost the same as delete)');
  $c1->grid($c2, -sticky => 'w');

  # Statistics
  $c1 = $edit_win{fr_main}->Label(-text => 'Time statistics:');
  $c1->grid(-columnspan => 2, -sticky => 'ew');

  my ($l1, $l2, $time);
  $time = $tasks->get_total_time($task);
  $c1 = $edit_win{fr_main}->Label(-text => 'Time with subtasks');
  $c2 = $edit_win{fr_main}->Frame()->pack(-expand => 1, -fill => 'x');
  $l1 = $c2->Label(-text => convert_time($time))->pack(-side => 'left');
  $c2->Button(-text => 'Zero time',
	      -command => sub {
		$tasks->zero_time($task);
		$l1->configure(-text => convert_time(0));
		$l2->configure(-text => convert_time(0));
		})->pack(-side => 'right', -anchor => 'w');
  $c1->grid($c2, -sticky => 'w');
  $c2->gridConfigure(-sticky => 'we');

  $time = $tasks->get_total_time($task, {'this_only' => 1});
  $c1 = $edit_win{fr_main}->Label(-text => 'Time without subtasks');
  $c2 = $edit_win{fr_main}->Frame()->pack(-expand => 1, -fill => 'x');
  $l2 = $c2->Label(-text => convert_time($time))->pack(-side => 'left');
  $c2->Button(-text => 'Zero time',
	      -command => sub {
		$tasks->zero_time($task, 1);
		$l2->configure(-text => convert_time(0));
		$time = $tasks->get_total_time($task);
		$l1->configure(-text => convert_time($time));
	      })->pack(-side => 'right', -anchor => 'w');
  $c1->grid($c2, -sticky => 'w');
  $c2->gridConfigure(-sticky => 'we');

  my $total = $tasks->get_total_time(undef);
  $time     = $tasks->get_total_time($task);
  my $pcnt = $total ? $time * 100 / $total : 0;
  $pcnt =~ s/\.(..).*$/\.$1/g;
  $pcnt .= '%';
  $c1 = $edit_win{fr_main}->Label(-text => 'Percent of total time');
  $c2 = $edit_win{fr_main}->Label(-text => $pcnt);
  $c1->grid($c2, -sticky => 'w');

  my ($c, $r) = $edit_win{fr_main}->gridSize();
  for (my $i = 0; $i < $c; $i++) {
    $edit_win{fr_main}->gridColumnconfigure($i, -weight => 1);
  }
  
  # Subtasks
  my ($sel, $par);
  if (scalar(@{$task->{_tasks}})) {
    my $lv_height = scalar(@{$task->{_tasks}});
    map { $lv_height += scalar(@{$_->{_tasks}});} @{$task->{_tasks}};
    $lv_height = 5 if ($lv_height > 5);
    $edit_win{fr_subtasks}->Label(-text => 'SubTasks:')->pack(-side => 'top');
    $edit_win{lv_sub} = $edit_win{fr_subtasks}->Listbox(-selectmode=>'browse',
							-font => FIXED_FONT);
    $edit_win{sb_sub} = $edit_win{fr_subtasks}->
	Scrollbar(-command => [$edit_win{lv_sub} => 'yview'])
	    ->pack(-side => 'right', -fill => 'y');
    $edit_win{lv_sub}->configure(-yscrollcommand=>[$edit_win{sb_sub}=>'set']);
    $edit_win{lv_sub}->configure(-height => $lv_height,
				 -width => $g_listview_width);
    $edit_win{lv_sub}->pack(-side => 'top', -expand => 'true', -fill =>'both');
    $edit_win{lv_sub}->bind('<Double-ButtonPress-1>', sub {
      $sel = $edit_win{lv_sub}->get($edit_win{lv_sub}->curselection);
    if ($sel =~ /^.{$g_listview_width}\s*(\d+)/) {
      ($par, $_) = $tasks->get_task($1);
      edit_task($_) if $_;
    }
    });

    my @buf = create_list4listview($task, $g_expand);
    $edit_win{lv_sub}->delete(0, 'end');
    $edit_win{lv_sub}->insert('end', @buf);
  }
  else {
    $edit_win{fr_subtasks}->Label(-text => 'No SubTasks')
	->pack(-side => 'top');
  }
      

  # Description part
  $edit_win{fr_note}->Label(-text => 'Task description:')
      ->pack(-side => 'top');
  $edit_win{note_text} =
      $edit_win{fr_note}->Text(-width => $g_listview_width,
			       -wrap => "word", -height => 10);
  $edit_win{note_text_sb} =
      $edit_win{fr_note}->Scrollbar(-command => ['yview',
						 $edit_win{note_text}],
				    -takefocus => 0)->pack(-side => "right",
							   -fill => "y");
  $edit_win{note_text}->configure(-yscrollcommand =>
				  ['set', $edit_win{note_text_sb}]);
  $edit_win{note_text}->delete("0.0", 'end');
  $edit_win{note_text}->pack(-fill => "both", -expand => "true");

  $edit_win{note_text}->delete("0.0", 'end');
  $edit_win{note_text}->insert('end', $t{_text});


  # Buttons
  $edit_win{fr_buttons}->Button(-text => ' Ok ',
     -command => sub {
       dprint("edit_task(): edited $task->{name}\n", 2);
       if ($t{name}) {
	 my $fl = ($t{name} eq $task->{name}) ? 0 : 1;
	 $t{_text} = $edit_win{note_text}->get("0.0", 'end');
	 map { $task->{$_} = $t{$_};
	     } ('name', '_text', 'priority', 'private', 'inactive');
	 create_tasks_menu() if $fl;
	 $popup->destroy();
       }
       else {
	 error("Empty task name!");
       }
     })->pack(-side => 'left');
  $edit_win{fr_buttons}->Button(-text => ' New Subtask ',
     -command => sub {
       dprint("edit_task(): subtask $task->{name}\n", 2);
       new_task($task);
     })->pack(-side => 'left');
  $edit_win{fr_buttons}->Button(-text => ' Delete ',
     -command => sub {
       dprint("edit_task(): delete $task->{name}\n", 2);
       delete_task($task);
       $popup->destroy();
     })->pack(-side => 'left');
  $edit_win{fr_buttons}->Button(-text => ' Cancel ',
     -command => sub { $popup->destroy();})->pack(-side => 'left');
}

# Prepare the list of tasks for the listview widgets
# Parameters:
#   $task - pointer to task
#   $expand - expand subtasks
sub create_list4listview {
  my ($task, $expand) = @_;
  my @buf = ();
  my ($i);
  my $total = $tasks->get_total_time($task);
  for ($i=0; $i < scalar(@{$task->{_tasks}}); $i++) {
    $_ = line_list4listview($task->{_tasks}[$i], '', $total);
    push(@buf, $_) if $_;
    cascade_list4listview($task->{_tasks}[$i], \@buf, ' ', $total) if $expand;
  }
  return @buf;
}

sub cascade_list4listview {
  my ($task, $buf, $prefix, $total) = @_;
  return undef unless ($task && $buf);
  return undef if ($task->{inactive});
  my ($i);
  for ($i=0; $i < scalar(@{$task->{_tasks}}); $i++) {
    $_ = line_list4listview($task->{_tasks}[$i], $prefix, $total);
    push(@{$buf}, $_) if $_;
    cascade_list4listview($task->{_tasks}[$i], $buf, $prefix.' ', $total);
  }
}

# Form line for list4listview functions
sub line_list4listview {
  my ($task, $prefix, $total) = @_;

  return '' if ($task->{inactive});
  my $time = $tasks->get_total_time($task);
  my $pcnt = $total ? $time * 100 / $total : 0;
  $pcnt =~ s/\.(..).*$/\.$1/g;
  $pcnt = $pcnt ? "  ($pcnt\%)" : '';
  
  my $w = $g_listview_width - 11;
  $_ = $prefix.$task->{name};
  $_ = fit_str($_, $w);
  $_ .= " $pcnt";
  $_ .= ' 'x50;		# just to make sure
  $_ .= $task->{id};
  return $_;
}

# Create a new task
# Parameter: $parent - parent task (undef in case of top level task)
sub new_task {
  my $parent = shift;
  dprint("new_task()\n", 2);
  my $task = $tasks->add_task($parent);
  if ($task) {
    edit_task($task);
  }
  else {
    error("Can't create the new task");
  }
}

sub delete_task {
  my $task = shift;
  dprint("delete_task()\n", 2);
  return unless $task;
  if ($current_task == $task) {
    set_task(undef);
  }
  my ($par);
  ($par, $_) = $tasks->get_task($task->{id});
  my ($i);
  for ($i = 0; $i < scalar(@{$par->{_tasks}}); $i++) {
    if ($par->{_tasks}[$i]{id} eq $task->{id}) {
      splice(@{$par->{_tasks}}, $i, 1);
      last;
    }
  }
  create_tasks_menu();
  $task->{id} = undef;
}

# 'Save As' popup
sub save_as {
  dprint("save_as()\n", 2);
  my $popup = $win->{main}->Toplevel(-title => 'Save As...');
  push(@{$win->{popups}}, $popup);
  my $fname = $tasks_fname;
  my $ret = "";

  my $l = $popup->Label(-text => 'Enter the file name to save to:')
      ->pack(-side => 'left');
  $popup->Entry(-textvariable => \$fname)->pack(-side => 'left');

  my $frame = $popup->Frame()->pack(-side=>'bottom');
  $frame->Button(-text => 'Save',
		 -command => sub{
		   if ($fname) {
		     $ret = $tasks->save($fname);
		     error($ret) if $ret;
		   }
		 })->pack(-side => 'left');
  $frame->Button(-text => 'Close',
		 -command => sub{ $popup->destroy(); })->pack(-side => 'left');
}

sub listview {
  dprint("listview()\n", 2);

  if (Exists($win->{lv}{win})) {
    $win->{lv}{win}->destroy();
  }
  $win->{lv}{win} =
      $win->{main}->Toplevel(-title => 'Task list at the glance');
  push(@{$win->{popups}}, $win->{lv}{win});

  my %lv_win = ();
  my ($sel, $par);
  
  $win->{lv}{fr_main}     = $win->{lv}{win}->Frame()->pack(-side=>'top');
  $win->{lv}{fr_buttons}  = $win->{lv}{win}->Frame()->pack(-side=>'bottom');

  $win->{lv}{fr_main}->Label(-text => 'DoubleClick on task to edit')
      ->pack(-side => 'top');
  $win->{lv}{lv_tasks} = $win->{lv}{fr_main}->Listbox(-selectmode=>'browse',
						      -font => FIXED_FONT);
  $win->{lv}{sb_tasks} = $win->{lv}{fr_main}->
      Scrollbar(-command => [$win->{lv}{lv_tasks} => 'yview'])
	  ->pack(-side => 'right', -fill => 'y');
  $win->{lv}{lv_tasks}->
      configure(-yscrollcommand=>[$win->{lv}{sb_tasks} => 'set']);
  $win->{lv}{lv_tasks}->configure(-height => 15, -width => $g_listview_width);
  $win->{lv}{lv_tasks}->pack(-side => 'top', -expand => 'true', -fill=>'both');
  $win->{lv}{lv_tasks}->bind('<Double-ButtonPress-1>', sub {
    $sel = $win->{lv}{lv_tasks}->get($win->{lv}{lv_tasks}->curselection);
    if ($sel =~ /^.{$g_listview_width}\s*(\d+)/) {
      ($par, $_) = $tasks->get_task($1);
      edit_task($_) if $_;
    }
  });

  my @buf = create_list4listview($g_tasklist, $g_expand);
  $win->{lv}{lv_tasks}->delete(0, 'end');
  $win->{lv}{lv_tasks}->insert('end', @buf);

  # Buttons
  my $label = $g_expand ? ' Collapse ' : '  Expand  ';
  dprint("listview: g_expand=$g_expand, label=$label\n", 2);
  $win->{lv}{bt_expand} =
      $win->{lv}{fr_buttons}->Button(-text => $label,
	-command => sub {
	  $g_expand = $g_expand ? 0 : 1;
	  $label    = $g_expand ? ' Collapse ' : '  Expand  ';
	  @buf = create_list4listview($g_tasklist, $g_expand);
	  $win->{lv}{lv_tasks}->delete(0, 'end');
	  $win->{lv}{lv_tasks}->insert('end', @buf);
	  $win->{lv}{bt_expand}->configure(-text => $label);
	})->pack(-side => 'left');
  $win->{lv}{fr_buttons}->Button(-text => ' Close ',
     -command => sub {
       $win->{lv}{win}->destroy();
       $win->{lv} = undef;
     })->pack(-side => 'left');

}

# Edit preferences popup
sub edit_pref {
  dprint("edit_pref()\n", 2);
  my $popup = $win->{main}->Toplevel(-title => "Preferences");
  push(@{$win->{popups}}, $popup);

  my $frame = $popup->Frame();
  $frame->Label(-text=>"Verbose level:\n(silent - verbose - debug)"
		)->pack(-side=>'left');
  $frame->Scale(-orient=>'horizontal', -length=>'15m',
		-sliderlength=>'5m', -width=>'3m',
		-from=>'0', -to=>'2', -variable=>\$debug
		)->pack(-side=>'right');
  $frame->pack(-fill => "x");
  
  $frame = $popup->Frame();
  $frame->Label(-text=>"Expand subtasks:\n(No - Yes)"
		)->pack(-side=>'left');
  $frame->Scale(-orient=>'horizontal', -length=>'10m',
		-sliderlength=>'5m', -width=>'3m',
		-from=>'0', -to=>'1', -variable=>\$g_expand
		)->pack(-side=>'right');
  $frame->pack(-fill => "x");
  
  $frame = $popup->Frame();
  $frame->Label(-text=>"Tasks File:")->pack(-side=>'left');
  $frame->Entry(-width=>16, -textvariable=>\$tasks_fname
		)->pack(-side=>'right');
  $frame->pack(-fill => "x");

  $frame = $popup->Frame();
  $frame->Checkbutton(-text => 'Autosave', -variable=>\$g_autosave_on,
		      -command => \&set_autosave)
      ->pack(-side=>'left');
  $frame->Label(-text => " every ")->pack(-side=>'left');
  $frame->Entry(-width=>4, -textvariable => \$g_autosave_tm)
      ->pack(-side=>'left');
  $frame->Label(-text => " seconds")->pack(-side=>'left');
  $frame->pack();

  $popup->Button(-text => 'Close',
		 -command => sub{ $popup->destroy(); })->pack(-fill=>'x');
}

#
# Timer functions
#

sub switch_timer {
  dprint("switch_timer()\n", 2);
  unless ($current_task) {
    error("There is no task selected");
    return;
  }
  if ($timer) {
    stop_timer();
  }
  else {
    start_timer();
  }
}

sub start_timer {
  dprint("start_timer()\n", 2);
  unless ($current_task) {
    error("There is no task selected");
    return;
  }
  $timer->{start} = time();
  $win->{basic}{bt_timer}->configure(-text => $bt_timer_attr{stop}{text},
				   -background => $bt_timer_attr{stop}{color});
  $win->{basic}{mn_tasks}->configure(-background => ACTIVE_TASK_COLOR)
      if Exists($win->{basic}{mn_tasks});
}

sub stop_timer {
  dprint("stop_timer()\n", 2);
  return unless ($current_task);
  my $time = {};
  if ($timer) {
#      $timer->{finish} = time();
#      map { $time->{$_} = $timer->{$_} } ('start', 'finish');
#      $time->{_text} = $task_comment;
#      push (@{$current_task->{_times}}, $time);
    $tasks->add_time($current_task, $timer->{'start'}, time(), $task_comment);
    $timer = undef;
  }
  $win->{basic}{bt_timer}->configure(-text => $bt_timer_attr{start}{text},
				  -background => $bt_timer_attr{start}{color});
  $win->{basic}{mn_tasks}->configure(-background => PASSIVE_TASK_COLOR)
      if Exists($win->{basic}{mn_tasks});
}

sub set_autosave {
  dprint("set_autosave($g_autosave_on)\n", 2);
  $SIG{ALRM} = 'alarm_handler';
  if ($g_autosave_on) {
    alarm($g_autosave_tm);
  }
  else {
    alarm(0);
  }
}

sub alarm_handler {
  dprint("alarm... autosave...\n", 2);
  return unless $g_autosave_on;
  my $ret = $tasks->save();
  error($ret) if $ret;
  alarm($g_autosave_tm);
}
