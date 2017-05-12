package Tasks;

#
# Tasks - module & application for the tasks / projects and time tracking
#
# See POD documentation in this file for more info
#
# Copyright (c) 2001 Sergey Gribov <sergey@sergey.com>
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute and modify it freely, but please leave
# this message attached to this file.
#
# Subject to terms of GNU General Public License (www.gnu.org)
#
# Last update: $Date: 2001/07/30 15:11:54 $ by $Author: sergey $
# Revision: $Revision: 1.3 $

use strict;
no strict "refs";

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use XML::Parser;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
$VERSION = '1.2';

#bootstrap Tasks $VERSION;

# Preloaded methods go here.

my $ident_prefix = '  ';

# Create object
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless($self, $class);

  $self->init();
  return $self;
}


# initialize everything
sub init {
  my $self = shift;
  $self->{FNAME}     = $ENV{'HOME'} ? $ENV{'HOME'}.'/' : '';
  $self->{FNAME}     .= '.tasks.xml';
  $self->{max_id}    = 0;
  ($self->{pkgname}) = caller;
  $self->{tree}      = undef;
  $self->{tasklist}  = ();
  $self->{tasks_hash} = undef;
}

# Read task list
sub read {
  my ($self, $fname) = @_;
  my $buf = '';

  $self->{FNAME} = $fname if $fname;
  open(F, $self->{FNAME}) or return "Can't open task list $self->{FNAME}: $!";
  while (<F>) { $buf .= $_; }
  close(F);

  my $parser = XML::Parser->new(Style => 'Objects', Pkg => $self->{pkgname});
  $self->{tree} = $parser->parse($buf);

  $self->tree2tasklist();
  $self->{tree} = undef;
  
  return '';
}

# Convert objects tree to tasklist
sub tree2tasklist {
  my $self = shift;

  my ($task, $i, $tl, $el);
  for ($i = 0; $i < scalar(@{ $self->{tree} }); $i++) {
    $tl = $self->{tree}[$i];
    next unless (lc(ref($tl)) eq lc($self->{pkgname}.'::tasklist'));
    map {
      $self->{tasklist}[$i]{$_} = $tl->{$_} unless (ref($tl->{$_}));
    } keys %{ $tl };
#    if (lc(ref($_)) eq lc($self->{pkgname}.'::Characters')) {

    foreach $task (@{$self->{tree}[$i]{Kids}}) {
      $el = $self->convert_task($task);
      push(@{ $self->{tasklist}[$i]{_tasks} }, $el) if $el;
    }
  }
}

# Convert task $task from tree to the tasklist format
sub convert_task {
  my ($self, $task) = @_;
  
  return undef unless (lc(ref($task)) eq lc($self->{pkgname}.'::task'));

  my %ret = ();
  map {$ret{$_} = $task->{$_} unless ref($task->{$_});} keys %{$task};
  
  my ($tmp, $el);
  $ret{_text} = '';
  foreach (@{$task->{Kids}}) {
    if (lc(ref($_)) eq lc($self->{pkgname}.'::task')) {
      $el = $self->convert_task($_);
      $el->{_parent} = $ret{id} if $ret{id};
      push(@{$ret{_tasks}}, $el) if $el;
    }
    elsif (lc(ref($_)) eq lc($self->{pkgname}.'::time')) {
      $el = $self->convert_time($_);
      push(@{$ret{_times}}, $el) if $el;
    }
    elsif (lc(ref($_)) eq lc($self->{pkgname}.'::Characters')) {
      $tmp = clean_empty_spaces($_->{Text});
      $ret{_text} .= "$tmp" unless ($tmp =~ /^\s*$/);
    }
  }
  return \%ret;
}

# Convert time tree element to the simple hash
sub convert_time {
  my ($self, $time) = @_;
  return undef unless (lc(ref($time)) eq lc($self->{pkgname}.'::time'));

  my ($tmp);
  my %ret = ();
  map {$ret{$_} = $time->{$_} unless ref($time->{$_});} keys %{$time};
  $ret{_text} = '';
  foreach (@{$time->{Kids}}) {
    if (lc(ref($_)) eq lc($self->{pkgname}.'::Characters')) {
      $tmp = clean_empty_spaces($_->{Text});
      $ret{_text} .= "$tmp" unless ($tmp =~ /^\s*$/);
    }
  }

  return \%ret;
}


sub print_tasks {
  my $self = shift;

  my ($task, $tasklist);
  foreach $tasklist (@{ $self->{tasklist} }) {
    print "==== Task list $tasklist->{name} v$tasklist->{version}\n";
    foreach $task (@{$tasklist->{_tasks}}) {
      print_task($task, $ident_prefix);
    }
  }
}

# Add new tasklist
# Parameter:
#   $attr   - pointer to the hash with task attributes
# Returns pointer to the new tasklist or undef in case of error
sub add_tasklist {
  my ($self, $attr) = @_;
  my %tl = ();
  map { $tl{$_} = $attr->{$_}; } keys %{$attr};
  push(@{$self->{tasklist}}, \%tl);
  return \%tl;
}

# Add new task
# Parameter:
#   $parent - pointer to parent task
#   $attr   - pointer to the hash with task attributes
# Returns pointer to the new task or undef in case of error
sub add_task {
  my ($self, $parent, $attr) = @_;
  
  unless ($parent) {
    $self->add_tasklist({'name' => 'tasklist'})
	unless scalar(@{$self->{tasklist}});
    $parent = $self->{tasklist}[0];
  }
  return undef unless $parent;
  
  my %task = ();
  $task{id} = $self->new_id();
  $task{_parent} = $parent->{id} if $parent->{id};
  map { $task{$_} = $attr->{$_}; } keys %{$attr};
  push(@{ $parent->{_tasks} }, \%task);
  return \%task;
}

# Generate the new task ID
# Parameter: $prefix - optional ID prefix
sub new_id {
  my ($self, $prefix) = @_;
  my $id = undef;
  
  my ($task, $tasklist);
  foreach $tasklist (@{ $self->{tasklist} }) {
    foreach $task (@{$tasklist->{_tasks}}) {
      $id = find_max_id($task, $id);
    }
  }
  $id = 1 unless $id;
  $id++;
  return $prefix.$id;
}

# Save tasks to the file
# Parameter:
#   $fname - (optional) file name to save to. If not supplied, the same
#      file is used as in read()
# Returns: '' if Ok, error in case of error
sub save {
  my ($self, $fname) = @_;

  my ($buf, $tasklist);
  $self->{FNAME} = $fname if $fname;
  open(F, ">$self->{FNAME}") or
      return "Can't open file $self->{FNAME} for writing: $!";
  foreach $tasklist (@{ $self->{tasklist} }) {
    $buf = form_attr_line('tasklist', $tasklist);
    print F "$buf\n";
    print F &StrToXML("\n$tasklist->{_text}\n") if $tasklist->{_text};
    foreach (@{$tasklist->{_tasks}}) {
      save_task(\*F, $_, $ident_prefix);
    }
    print F "\n</tasklist>\n";
  }

  close(F);
  return '';
}

# Add times to task.
# Parameters:
#   $task   - pointer to task
#   $start  - start time (in sec. since 1/1/70
#   $finish - finish time (if undef the current time will be used)
#   $desc   - description (optional)
sub add_time {
  my ($self, $task, $start, $finish, $desc) = @_;
  return undef unless ($task && $start);
  my $time = {};
  $time->{start}  = $start;
  $time->{finish} = $finish ? $finish : time();
  $time->{_text} = $desc;
  push(@{$task->{_times}}, $time);
}

# Create hash with back pointers to parents
# Parameters:
#   $parent - pointer to parent, if undef, initialize the list
#   $task   - pointer to task
sub create_task_hash {
  my ($self, $parent, $task) = @_;

  if ($parent) {
    if ($task) {
      $self->{tasks_hash}{$task->{id}}{name}   = $task->{name};
      $self->{tasks_hash}{$task->{id}}{parent} = $parent;
    }
  }
  else {
    $self->{tasks_hash} = {};
  }
  $task = $self->{tasklist}[0] unless $task;
  map { $self->create_task_hash($task, $_) if $_; } @{$task->{_tasks}};
  return $self->{tasks_hash};
}

# Get task pointer by task ID
# Parameters:
#   $id   - task ID
# Returns: list ($parent, $task) if task found, undef otherwise
sub get_task {
  my ($self, $id) = @_;
  my ($task, $tasklist, $ret, $par);
  foreach $tasklist (@{ $self->{tasklist} }) {
    foreach $task (@{$tasklist->{_tasks}}) {
      return ($tasklist, $task) if ($id eq $task->{id});
      ($par, $ret) = $self->get_task_by_id($id, $task);
      return ($par, $ret) if $ret;
    }
  }
  return undef;
}

# Get task pointer by task ID (internal function)
# Parameters:
#   $id   - task ID
#   $task - task to start from
# Returns: list ($parent, $task) if task found, undef otherwise
sub get_task_by_id {
  my ($self, $id, $task) = @_;
  return undef unless ($id && $task);
  my ($par, $ret);
  foreach (@{$task->{_tasks}}) {
    return ($task, $_) if ($id eq $_->{id});
    ($par, $ret) = $self->get_task_by_id($id, $_);
    return ($par, $ret) if $ret;
  }
  return undef;
}

# Reset / Zero all the times for the task.
# Parameters:
#   $task - pointer to task, if undef, resets all the times
#   $this_only - flag. If to zero this task only without subtasks
#   $sec  - time (in sec.) till which to times should be reset
#          (all times entries with 'start' time less than this will be zeroed)
# Returns: void 
sub zero_time {
  my ($self, $task, $this_only, $till) = @_;
  
  if ($task) {
    unless ($this_only) {
      $self->traverse_task_tree($task, \&zero_task_time, $till);
    }
    zero_task_time($task);
    return;
  }
  
  # else
  my ($tasklist);
  foreach $tasklist (@{ $self->{tasklist} }) {
    $self->traverse_task_tree($tasklist, \&zero_task_time, $till);
  }
  return;

  sub zero_task_time {
    my ($task, $till) = @_;
    my ($tmp, $t);
    if ($till) {
      $tmp = $task->{_times};
      $task->{_times} = undef;
      foreach $t (@$tmp) {
	push(@{$task->{_times}}, $t) if ($t->{start} > $till);
      }
    }
    else {
      $task->{_times} = undef;
    }
    return $till;
  }
}

# Get total time spend on this task
# Parameters:
#   $task - pointer to task, if undef, calculates total
#   $options - pointer to options, possible options:
#     this_only - flag. If set when calculate this task only without subtasks
#     start     - start time to take in account (in sec. from 1970)
#     private   - take into account private tasks
# Returns: time in seconds
sub get_total_time {
  my ($self, $task, $options) = @_;
  
  $options->{ret} = 0;
  $options->{private} = 1 unless (defined($options->{private}));
  if ($task) {
    if ($options->{this_only}) {
      $options = calc_time($task, $options);
    }
    else {
      $options = $self->traverse_task_tree($task, \&calc_time, $options);
    }
    return $options->{ret};
  }
  
  # else 
  my $ret = 0;
  my ($tasklist);
  foreach $tasklist (@{ $self->{tasklist} }) {
    $options = $self->traverse_task_tree($tasklist, \&calc_time, $options);
    $ret += $options->{ret};
  }
  return $ret;

  sub calc_time {
    my ($task, $ret) = @_;
    return $ret unless $task;
    return $ret if (!$ret->{private} && $task->{private});
    foreach (@{$task->{_times}}) {
      next if ($ret->{start} && ($ret->{start} > $_->{start}));
      next if ($ret->{finish} && ($ret->{finish} > $_->{finish}));
      $ret->{ret} += ($_->{finish} - $_->{start});
    }
    return $ret;
  }
}

# Traverse task tree and use supplied function on any task
# Parameters:
#   $task - task to start from
#   $func - pointer to function to apply for every task
#      function should get two arguments: $task, $ret, where $ret is
#      result of this function for previous tasks
#   $ret  - result of this function for previous tasks
#   $level - level in the tree
sub traverse_task_tree {
  my ($self, $task, $func, $ret, $level) = @_;
  $level = 0 unless $level;
  return undef unless ($task && $func);
  $ret = &$func($task, $ret, $level);
  foreach my $t (@{$task->{_tasks}}) {
    $ret = $self->traverse_task_tree($t, $func, $ret, ($level+1));
  }
#  return &$func($task, $ret);
  return $ret;
}

##########################################################################
# functions

# Returns maximal task ID found in the tasks.
sub find_max_id {
  my ($task, $id) = @_;
  return $id unless $task;
  $_ = $task->{id};
  s/[^0-9]//g;
  $id = $_ if ($_ > $id);
  foreach my $t (@{$task->{_tasks}}) {
    $id = find_max_id($t, $id);
  }
  return $id;
}

# Form XML line of type "<$label attr1="value1"... >"
# Parameters:
#   $label - XML label
#   $hash  - pointer to hash with values
sub form_attr_line {
  my ($label, $hash) = @_;
  
  my $buf = "<$label";
  map {
    $buf .= &StrToXML(qq( $_="$hash->{$_}"))
	unless (ref($hash->{$_}) || $_ =~ /^_/); } keys %{$hash};
  return "$buf>";
}

# Save the task and call itself recursively for the 'Kids' tasks
# Parameters:
#   $fh     - file handle
#   $task   - pointer to the task
#   $prefix - prefix to print before any line (typically some number of spaces
sub save_task {
  my ($fh, $task, $prefix) = @_;

  return undef unless ($task && $task->{id});

  my ($time, $buf);
  $buf = $prefix.form_attr_line('task', $task);;
  print $fh "\n$buf\n";
  print $fh &StrToXML(qq($prefix$ident_prefix$task->{_text}\n))
      if $task->{_text};
  foreach $time (@{$task->{_times}}) {
    $buf = $prefix.$ident_prefix.form_attr_line('time', $time);
    print $fh "$buf";
    print $fh &StrToXML(qq($time->{_text})) if $time->{_text};
    print $fh "</time>\n";
  }
  foreach (@{$task->{_tasks}}) {
    save_task($fh, $_, $prefix.$ident_prefix);
  }
  print $fh "$prefix</task>\n";
  return '';
}

# Print the task and call itself recursively for the 'Kids' tasks
# Parameters:
#   $task   - pointer to the task
#   $prefix - prefix to print before any line (typically some number of spaces
sub print_task {
  my ($task, $prefix) = @_;

  return undef unless $task;
  
  print "\n".$prefix."Task name: $task->{name}, id: $task->{id}\n";
  print $prefix.$task->{_text}."\n" if $task->{_text};

  foreach (@{$task->{_times}}) {
    print $prefix."time start=$_->{start} finish=$_->{finish} $_->{_text}\n";
  }
  if (scalar(@{$task->{_tasks}})) {
    print $prefix."Sub-tasks:\n";
    foreach (@{$task->{_tasks}}) {
      print_task($_, $prefix.$ident_prefix);
    }
  }
}

# Clean leading and tailing empty lines
sub cleanr_empty_spaces(\$) {
  my $s = shift;
  $$s =~ s/^(\s*\n*)+//gs;
  $$s =~ s/\n(\s*\n*)+$//gs;
  return $$s;
}
sub clean_empty_spaces {
  my $str = shift;
  return cleanr_empty_spaces($str);
}

sub StrToXML {
  my $str = shift;
  my(@chars) = split(//, $str);
  local $_;

  $_ = "";
  foreach my $char (@chars) {
    if ($char eq '&') {
      $_ .= "&amp;";
    }
    elsif ($char eq '<') {
      $_ .= "&lt;";
    }
    elsif ((ord($char) < 32 || ord($char) > 127)
	   && (ord($char) != 9 && ord($char) != 10 && ord($char) != 13)) {
      $_ .= "&#" . ord($char) . ";";
    } else {
      $_ .= $char;
    }
  }

  return $_;
}

##########################################################################
# Create properties access methods
my ($prop, $sub);

foreach $prop ('FNAME', 'max_id', 'pkgname', 'tasklist') {
  *$prop = sub {
    my ($self, $val) = @_;
    $self->{$prop} = $val if $val;
    return $self->{$prop};
  }
}


1;
__END__

=head1 NAME

Tasks - Perl module for the tasks / projects and time tracking 

=head1 SYNOPSIS

  use Tasks;

  my $tasks = new Tasks;
  my $ret = $tasks->read('tasks.xml');
  die("Error in reading tasks file: $ret") if $ret;

  # Create the new tasklist 'tasklist'
  $tasks->add_tasklist({'name' => 'tasklist'});

  # Create the new task 'task1'
  my $task = $tasks->add_task(undef, {'name' => 'task1',
				      '_text' => 'task1 description'});

  # Set time for the work on task1 10 minutes starting now
  my $time = time();
  $tasks->add_time($task, $time, $time + 600, 'hanging around');

  # Print all the tasks in the task file
  $ret = undef; # no need to return anything in this case
  my $tasklist = $tasks->tasklist();
  $tasklist = $tasklist->[0]; # Use the first tasklist (our)
  $tasks->traverse_task_tree($tasklist, \&print_task, $ret);

  # Save the tasks
  $tasks->save();

  exit 0;

  sub print_task {
    my ($task, $ret, $level) = @_;
    my $prefix = ' 'x$level;

    print $prefix."$task->{name}\n";
    return $ret;
  }


  NOTE: Before trying this example you need to create an
    empty tasks.xml file which will looks like the following:
  <tasklist name="example" version="1.0">
  </tasklist>


=head1 DESCRIPTION

Module to track the tasks / projects and time spend on each task.
This module allows to keep the hierarchical list of the tasks,
including the time logs for every task.

All information is saved in XML file.

=head1 METHODS

new() - This is a class method, the constructor for Tasks.

read($fname) - Read tasks file.
  Parameter:
    $fname - file name to read tasks from. (optional,
	     if not defined ~/.tasks.xml will be used.
  Returns '' if Ok, error string otherwise.


add_tasklist($attr) - Add new tasklist.
  Parameter:
    $attr   - pointer to the hash with task attributes
	      (e.g. 'name', '_text')
  Returns pointer to the new tasklist or undef if error.
    See STRUCTURES for more info on how tasklist looks like.

add_task($parent, $attr) - Add new task
  Parameter:
    $parent - pointer to parent task (if undef,
            the first tasklist is used)
    $attr   - pointer to the hash with task attributes
            (e.g. 'name', 'priority', '_text')
  Returns pointer to the new task or undef if error

save($fname) - Save tasks to the file
  Parameter:
    $fname - (optional) file name to save to. If
       not supplied, the same file is used as in read()
  Returns: '' if Ok, error in case of error

add_time($task, $start, $finish, $desc) - Add times to task.
  Parameters:
    $task   - pointer to task
    $start  - start time (in sec. since 1/1/70
    $finish - finish time (if undef the current
       time will be used)
    $desc   - description (optional)

get_task($id) - Get task pointer by task ID
  Parameters:
    $id   - task ID
  Returns: list ($parent, $task) if task found,
           undef otherwise.
           where: $parent - pointer to parent task
                  $task - pointer to task (see STRUCTURES)

zero_time($task, $this_only, $till) - Reset / Zero all
 the times for the task.
  Parameters:
    $task - pointer to task, if undef, resets all
            the times
    $this_only - flag. If to zero this task only
            without subtasks
    $sec  - time (in sec.) till which to times should
            be reset (all times entries with 'start'
            time less than this will be zeroed)

get_total_time($task, $options) - Get total time spend
 on this task
  Parameters:
    $task - pointer to task, if undef, calculates total
    $options - pointer to options, possible options:
      this_only - flag. If set when calculate this task
                  only without subtasks
      start     - start time to take in account
                  (in sec. from 1970)
      private   - take into account private tasks
  Returns: time in seconds

traverse_task_tree($task, $func, $ret, $level) -
 Traverse task tree and use supplied function on any task.
  Parameters:
    $task - task to start from
    $func - pointer to function to apply for every task
       function should get 3 arguments:
       $task, $ret, $level
       where $ret is result of this function for previous
       tasks and $level is level in within the tree
    $ret  - result of this function for previous tasks
    $level - level in the tree
  Returns: $ret from last call in recursion

print_tasks() - Print the tasklist to STDERR,
  usefull for debugging.

=head1 STRUCTURES

B<task> - Single task structure. Includes the following fields:
  'id' - unique ID of the task (generated automatically)
  'name' - name of task
  '_text' - some text (e.g. description)
  '_tasks' - pointer to the array with subtasks hashes
  '_times' - pointer to the array with 'time' hashes
   Any other attributes can be added (e.g. 'priority')

B<tasklist> - Tasklist (Single file can contain more than one tasklist)
  'name' - name of the tasklist
  '_text' - some text (e.g. description)
  '_tasks' - pointer to the array with subtasks hashes

B<time> - Time structure (contained in '_times' arrays)
  'start'  - start time in seconds since jan 1 1970
  'finish' - finish time in seconds since jan 1 1970
  '_text' - some text (e.g. description)

=head1 AUTHOR

Sergey Gribov, sergey@sergey.com

Copyright (c) 2001 Sergey Gribov. All rights
reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1).

=cut
