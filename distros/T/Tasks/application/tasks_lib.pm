#
# Library of functions for tasks.pl
#
# Copyright (c) 2000 Sergey Gribov <sergey@sergey.com>
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute and modify it freely, but please leave
# this message attached to this file.
#
# Subject to terms of GNU General Public License (www.gnu.org)
#
# Last update: $Date: 2001/06/05 22:58:10 $ by $Author: sergey $
# Revision: $Revision: 1.1 $

# Show text popup
sub popup_text {
  my ($fname, $title) = @_;

  error("No main window") unless Exists($win->{main});
  my $popup = $win->{main}->Toplevel(-title => $title);

  my ($frame, $text_win);
  ($frame, $text_win) = create_text_frame($popup, '', $title);
  error("Can't create a window") unless $frame;

  $frame = $popup->Frame();
  $frame->Button(-text => 'Close', -command => [$popup => 'destroy'])->pack();
  $frame->pack(-fill=>'x', -side=>'bottom');
  
  $text_win->configure(-state => "normal");
  $text_win->delete("0.0", "end");
  open(F, $fname) or error("Can't open file $fname: $!");
  while(<F>) {
    $text_win->insert("end", $_);
  }
  $text_win->configure(-state => "disabled");
}

# Create a frame with text
# Parameters:
#   $wgt   - parent widget
#   $text  - text to show
#   $title - optional title to show
# Returns list of ($frame, $text_win) there:
#   $frame    - pointer to frame widget.
#   $text_win - pointer to text window
sub create_text_frame {
  my ($wgt, $text, $title) = @_;

  my $frame = $wgt->Frame();
  $frame->Label(-text => $title, -anchor => 'c')->pack(-fill=>'x') if $title;
  
  my $text_win = $frame->Text(-height => 20, -width => 80, -wrap => "word");
  my $text_sb = $frame->Scrollbar(-command => ['yview', $text_win])
      ->pack(-side => "right", -fill => "y");
  $text_sb->configure(-takefocus => 0);
  $text_win->configure(-yscrollcommand => ['set', $text_sb]);
  $text_win->pack(-expand => "true", -fill => "both");
  $frame->pack(-fill => "both", -expand => "true");

  $text_win->configure(-state => "normal");
  $text_win->delete("0.0", "end");
  $text_win->insert("end", $text);
  $text_win->configure(-state => "disabled");
  
  return ($frame, $text_win);
}

# Insert text into text frame
# Parameters:
#   $text_win - text frame widget
#   $text     - text to insert into the frame
sub insert_text2frame {
  my ($text_win, $text) = @_;
  $text_win->configure(-state => "normal");
  $text_win->delete("0.0", 'end');
  $text_win->insert('end', $text);
  $text_win->configure(-state => "disabled");
}

sub error {
  my $err = shift;
  popup_str($err, {'title' => 'Error', 'bg' => 'red', 'fg' => 'white'});
}

sub popup_str {
  my ($str, $options) = @_;
  
  $options->{title} = 'Popup' unless $options->{title};
  if (Exists($win->{main})) {
    my $top = $win->{main}->Toplevel;
    push(@{$win->{popups}}, $top);
    $top->title($options->{title});
    my $l = $top->Label(-text => $str, -justify=>'left')->pack;
    $top->Button(-text => 'close',
		  -command => [$top => 'destroy']
		  )->pack();
    if ($options->{bg} && $options->{fg}) {
      $l->configure(-bg => $options->{bg}, -fg => $options->{fg});
      $top->configure(-bg => $options->{bg}, -fg => $options->{fg});
    }
    dprint("$str\n", 1);
  }
  else {
    print STDERR "$str\n";
  }
}

# Debug print
# print $msg if $level >= $debug
sub dprint {
  my ($msg, $level) = @_;
  print STDERR $msg if $level <= $debug;
}

sub Usage {
  print STDERR <<"USAGE";
Usage: $0 [-i <tasklist-fname>] [-v] [-d] [-h]
  <tasklist-fname> - file name of the Task list,
      default <addressbook-fname> is $tasks_fname.
  -v - verbose mode
  -d - debug mode (even more prints)
USAGE
  exit 1;
}

sub close_popups {
  dprint("close_popups()\n", 2);
  foreach (@{$win->{popups}}) {
    $_->destroy() if Exists($_);
  }
  $win->{popups} = undef;
}

# convert time from seconds to string "IdXhYmZs"
sub convert_time {
  my $sec = shift;
  my $ret = '';
  my ($d, $h, $m);

  $d = int($sec / (60*60*24));
  $sec = $sec - $d*60*60*24 if $d;
  
  $h = int($sec / (60*60));
  $sec = $sec - $h*60*60 if $h;
  
  $m = int($sec / 60);
  $sec = $sec - $m*60 if $m;

  $ret = $d.'d' if $d;
  $ret .= $h ? $h.'h' : ($ret ? '0h' : '');
  $ret .= $m ? $m.'m' : ($ret ? '0m' : '');
  $ret .= $sec ? $sec.'s' : '0s';

  return $ret;
}

sub print_text {
  my $text = shift;
  dprint("print_text()\n", 2);
  return undef unless $text;

  my $fname = "/tmp/.tasks$$.lpr";
  unless(open(F, ">$fname")) {
    error("Error opening temp file $fname: $!");
    return undef;
  }
  $text =~ s/\n/\n\r/gs if $c_lpr_dos;
  print F "$text\n";
  close(F);
  system($c_lpr_prg, $fname);
  if ($? >> 8) {
    error("Error printing the text");
  }
  else {
    popup_str("Text printed");
  }
  unlink($fname);
}

sub save_text {
  my ($fname, $text) = @_;
  dprint("save_text($fname, ...)\n", 2);
  return undef unless $fname;
  unless(open(F, ">$fname")) {
    error("Error opening file $fname for writing: $!");
    return undef;
  }
  print F $text;
  close(F);
  popup_str("Saved as file $fname");
}

sub fit_str {
  my ($str, $w) = @_;
  $_ = $str;
  s/^(.{$w}).*$/$1/gs;
  $_ .= ' 'x($w - length($_)) if (length($_) < $w);
  return $_;
}

1;

