package Term::TUI;
# Copyright (c) 1999-2008 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
# TODO
########################################################################

# improve completion:
#    /math
#    ad<TAB>
# completes correctly to add but
#    /math/ad<TAB>
# doesn't autocomplete.

# add abbreviation

# case insensitivity

# add .. and . to valid mode strings

# "Hr. Jochen Stenzel" <Jochen.Stenzel.gp@icn.siemens.de>
#    alias command
#    history file (stored last commands)

# config file (store commands to execute)

########################################################################

use warnings;
use vars qw($VERSION);
$VERSION="1.23";

require 5.000;
require Exporter;

use Term::ReadLine;
use Text::ParseWords;
#use Text::Abbrev;

@ISA = qw(Exporter);
@EXPORT = qw(TUI_Run);
@EXPORT_OK = qw(TUI_Script TUI_Out TUI_Version);
%EXPORT_TAGS = (all => [ @EXPORT, @EXPORT_OK ]);

use strict "vars";

sub TUI_Version {
  return $VERSION;
}

BEGIN {
  my($term,$out);

  #
  # Takes a program name (to be used in the prompt) and an interface
  # description, and runs with it.
  #

  #
  # Interactive version.
  #
  sub TUI_Run {
    my($program,$hashref)=@_;
    my(@mode,$line,$err);
    my($prompt)="$program> ";
    $term=new Term::ReadLine $program;
    $term->ornaments(0);

    # Command line completion
    $term->Attribs->{'do_expand'}=1;
    $term->Attribs->{'completion_entry_function'} =
        $term->Attribs->{'list_completion_function'};

    $out=$term->OUT || STDOUT;

    my($ret)=0;

    # Command line completion
    # The strings for completion
    my(@completions) = _GetStrings(\@mode,$hashref);
    $term->Attribs->{'completion_word'} = \@completions;

    while (defined ($line=$term->readline($prompt)) ) {
      $err=_Line(\@mode,$hashref,$line);

      # Command line completion
      @completions = _GetStrings(\@mode,$hashref);
      $term->Attribs->{'completion_word'} = \@completions;

      if ($err =~ /^exit\[(\d+)\]$/) {
        $ret=$1;
        last;
      }
      print $out $err  if ($err && $err !~ /^\d+$/);

      if (@mode) {
        $prompt=$program . ":" . join("/",@mode) . "> ";
      } else {
        $prompt="$program> ";
      }
    }
    return $ret;
  }

  #
  # Non-interactive version.
  #
  sub TUI_Script {
    my($hashref,$script,$sep)=@_;
    $out=STDOUT;

    $sep=";"  if (! $sep);
    my(@cmd)=split(/$sep/,$script);

    my($err,$cmd,@mode);
    my($ret)=0;
    foreach $cmd (@cmd) {
      $err=_Line(\@mode,$hashref,$cmd);
      if ($err =~ /^exit\[(\d+)\]$/) {
        $ret=$1;
        last;
      }
      print $out $err  if ($err);
    }
    return $ret;
  }

  #
  # Prints a message.
  #
  sub TUI_Out {
    my($mess)=@_;
    print $out $mess;
  }
}


########################################################################
# NOT FOR EXPORT
########################################################################

{
  # Stuff for doing completion.

  my $i;
  my @matches;

  sub _TUI_completion_function {
    my($text,$state)=@_;
    $i = ($state ? $i : 0);

    if (! $i) {
      if ($text =~ /^\s*(\S+)\s+(\S+)$/) {
        # MODE CMD^
        #    completes CMD
        # MODE/CMD OPTION^
        #    no matches

      } elsif ($text =~ /^\s*(\S+)\s+$/) {
        # MODE ^
        #    completes CMD
        # MODE/CMD ^
        #    no matches

      } elsif ($text =~ /^\s*(\S+)$/) {
        # MODE^
        # MODE/CMD^

      } else {
        @matches=();
      }
    }
  }
}

#
# Takes the current mode (as a list), the interface description, and
# the current line and acts on the line.
#
sub _Line {
  my($moderef,$cmdref,$line)=@_;

  $line =~ s/\s+$//;
  $line =~ s/^\s+//;
  return  if (! $line);

  my(@cmd)=shellwords($line);
  return _Cmd($moderef,$cmdref,@cmd);
}

BEGIN {
  my(%Cmds) =
    (
     ".."     => [ "Go up one level",     "_Mode",0 ],
     "/"      => [ "Go to top level",     "_Mode",1 ],
     "help"   => [ "Online help",         "_Help"   ],
     "exit"   => [ "Exit",                "_Exit",0 ],
     "quit"   => [ "An alias for exit",   "_Exit",0 ],
     "abort"  => [ "Exit without saving", "_Exit",1 ]
    );
  my($Moderef,$Cmdref);

  #
  # Returns an array of strings (commands or modes) that can be
  # entered given a mode
  #
  sub _GetStrings {
    my ($moderef,$cmdref) = @_;
    my @strings;

    if (!defined $Cmdref || ref $Cmdref ne "HASH") {
      $Cmdref = $cmdref;
    }
    my $desc = _GetMode(@{$moderef});
    if ( ref $desc eq "HASH" ) {
      @strings = grep !/^\./, sort keys %$desc;
    }
    push @strings,keys %Cmds;
    return @strings;
  }

  #
  # Takes the current mode (as a list), the interface description, and the
  # current command (as a list) and executes the command.
  #
  sub _Cmd {
    my($moderef,$cmdref,@args)=@_;
    my($cmd)=shift(@args);
    $Moderef=$moderef;
    $Cmdref=$cmdref;
    my(@mode,$desc,$mode,$help);

    if (exists $Cmds{lc $cmd}) {
      $desc=$Cmds{lc $cmd};

    } else {
      ($mode,@mode)=_CheckMode(\$cmd);

      if ($mode && $cmd) {
        #
        # MODE/CMD [ARGS]
        # CMD [ARGS]
        #
        $desc=_CheckCmd($mode,$cmd);

      } elsif ($mode && @args) {
        #
        # MODE CMD [ARGS]
        #
        $cmd=shift(@args);
        $desc=_CheckCmd($mode,$cmd);

      } elsif ($mode) {
        #
        # MODE
        #
        $desc=[ "","_Mode",2,@mode ]
      }
    }

    my(@args0);
    if (ref $desc eq "ARRAY") {
      ($help,$cmd,@args0)=@$desc;
      if (! defined &$cmd) {
        $cmd="::$cmd";
        if (! defined &$cmd) {
          return "ERROR: invalid subroutine\n";
        }
      }
      return &$cmd(@args0,@args);
    } else {
      return "ERROR: unknown command\n";
    }
  }

  #
  # Takes a mode and/or command (as a list) and determines the mode
  # to use.  Returns a description of that mode.
  #
  sub _CheckMode {
    my($cmdref)=@_;
    my($cmd)=$$cmdref;
    my(@mode,$tmp2);

    if ($cmd =~ s,^/,,) {
      @mode=split(m|/|,$cmd);
    } else {
      @mode=(@$Moderef,split(m|/|,$cmd));
    }

    my($tmp)=_GetMode(@mode);
    if ($tmp) {
      $$cmdref="";
    } else {
      $tmp2=pop(@mode);
      $tmp=_GetMode(@mode);
      $$cmdref=$tmp2  if ($tmp);
    }

    @mode=()  if (! $tmp);
    return ($tmp,@mode);
  }

  #
  # Takes a mode (as a list) and returns it's description (or "" if it's
  # not a mode).
  #
  sub _GetMode {
    my(@mode)=@_;
    my($tmp)=$Cmdref;
    my($mode);

    foreach $mode (@mode) {
      if (exists $$tmp{$mode}  &&
          ref $$tmp{$mode} eq "HASH") {
        $tmp=$$tmp{$mode};
      } else {
        $tmp="";
        last;
      }
    }
    $tmp;
  }

  ##############################################

  #
  # A command to change the mode.
  #    ..    op=0
  #    /     op=1
  #    MODE  op=2
  #
  sub _Mode {
    my($op,@mode)=@_;

    if ($op==0) {
      # Up one level
      if ($#$Moderef>=0) {
        pop(@$Moderef);
      } else {
        return "WARNING: Invalid operation\n";
      }

    } elsif ($op==1) {
      # Top
      @$Moderef=();

    } elsif ($op==2) {
      # Change modes
      @$Moderef=@mode;

    } else {
      return "ERROR: Invalid mode operation: $op\n";
    }
    return "";
  }

  sub _Help {
    my($cmd,@args)=@_;

    my($tmp,$mode,@mode);

    ($tmp,@mode)=_CheckMode(\$cmd)  if ($cmd);
    if (! $tmp) {
      @mode=@$Moderef;
      if (@mode) {
        $tmp=_GetMode(@mode);
      } else {
        $tmp=$Cmdref;
      }
    }

    return "IMPOSSIBLE: invalid mode\n"  if (! $tmp);

    my($mess);
    $cmd=shift(@args)  if (! $cmd && @args);
    if ($cmd) {
      #
      # Help on a command
      #
      if (exists $Cmds{$cmd}) {
        $tmp=$Cmds{$cmd};
        $mess=$$tmp[0];

      } elsif (exists $$tmp{$cmd}) {
        $tmp=$$tmp{$cmd};
        if (ref $tmp  ne  "ARRAY") {
          $mess="Invalid command $cmd";
        } else {
          $mess=$$tmp[0];
          $mess="No help available"  if (! $mess);
        }
      } else {
        $mess="Invalid command: $cmd";
      }

    } else {
      #
      # Help on a mode
      #
      if (exists $$tmp{".HELP"}) {
        $mess=$$tmp{".HELP"};
        my(@gc)=sort grep /^([^.]|\.\.)/i,keys %Cmds;
        my(@cmd)=sort grep /^[^.]/,keys %{ $tmp };
        my(@m,@c)=();
        foreach $cmd (@cmd) {
          if (ref $$tmp{$cmd} eq "ARRAY") {
            push(@c,$cmd);
          } elsif (ref $$tmp{$cmd} eq "HASH") {
            push(@m,$cmd);
          }
        }
        $mess .= "\n\nAdditional help:\n\n";
        $mess .= "   Modes: @m\n"  if (@m);
        $mess .= "   Cmds : @gc";
        $mess .= "\n"              if (@c);
        $mess .= "          @c"    if (@c);

      } else {
        $mess="No help available";
      }
    }

    return "\n$mess\n\n";
  }
}

#
# Takes a mode and command and return a description of the command.
#
sub _CheckCmd {
  my($moderef,$cmd)=@_;
  return $$moderef{$cmd}
    if (exists $$moderef{$cmd}  &&
        ref $$moderef{$cmd} eq "ARRAY");
  return ();
}

sub _Exit {
  my($flag)=@_;
  return "exit[$flag]";
}

#    sub {
#      map {lc($_)} (keys %commands, keys %aliases)
#    };

#  $term->Attribs->{'do_expand'}=1;
#  $term->Attribs->{'completion_entry_function'} =
#    sub {
#      $term->Attribs->{'line_buffer'} =~ /\s/ ?
#        &{$term->Attribs->{'filename_completion_function'}}(@_) :
#          &{$term->Attribs->{'list_completion_function'}}(@_)
#        };
#  $term->Attribs->{'completion_word'}=[(map {lc($_)} (keys %commands))];

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:
