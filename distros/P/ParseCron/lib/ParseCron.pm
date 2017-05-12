package ParseCron;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Exporter qw(import);
our @EXPORT_OK = qw(parse_cron);

our $VERSION = '0.02';

# SET UP THE ENVIRONMENT ####################################################
#############################################################################
  

#############################################################################
our $posix = $ENV{'POSIXLY_CORRECT'} || $ENV{'POSIX_ME_HARDER'};

our $atom;
if ($posix) {
    $atom = '\d+|(?:\d+-\d+)';  # POSIX allows no stepped ranges.
} 
else {
    $atom = '\d+|(?:\d+-\d+(?:/\d+)?)';  
}

our $atoms = "^(?:$atom)(?:,$atom)*\$";    
#############################################################################






our @dows   = qw(Sun Mon Tue Wed Thu Fri Sat);
our @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
our ($dow, $month, %month2num, %dow2num, %num2dow, %num2month);

our %mil2ampm;
@mil2ampm{0 .. 23} = ('midnight', map($_ . 'am', 1 .. 11), 'noon', map($_ . 'pm', 1 .. 11));


@dow2num{map lc($_), @dows} = (0 .. 6);



push @dows, 'Sun' unless $posix;
  # POSIX doesn't know about day 7
@num2dow{0 .. $#dows} = @dows;

@month2num{map lc($_), @months} = (1 .. 12);
@num2month{1 .. 12} = @months;
unshift @months, '';

{
  my $x = join '|', map quotemeta($_), @dows;
  $dow = "^($x)\$";    # regexp
  $x = join '|', map quotemeta($_), @months;
  $month = "^($x)\$";  # regexp
}



# SET UP THE ENVIRONMENT ####################################################
#############################################################################

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    
    return $self;
}

sub parse_cron {
    my $self = shift;

    my $crontab = shift;
    
    my (@bits, $k, $v, $english);
    
    my %atword = (  # for latter-day Vixie-isms
      'reboot'   => 'At reboot',
      'yearly'   => 'Yearly (midnight on January 1st)',
      'annually' => 'Yearly (midnight on January 1st)',
      'monthly'  => 'Monthly (midnight on the first of every month)',
      'weekly'   => 'Weekly (midnight every Sunday)',
      'daily'    => 'Daily, at midnight',
      'midnight' => 'Daily, at midnight',
      'hourly'   => 'At the top of every hour',
     # These are no longer documented in Vixie cron 3.0.  Why not?
    );
    
    #next if $crontab =~ m/^[ \t]*#/s or $crontab =~ m/^[ \t]*$/s;
    $crontab =~ s/^[ \t]+//s; # "leading spaces and tabs are ignored"

    # The POSIX cron spec doesn't seem to mention
    #  environment-setting lines at all!

    if (!$posix and $crontab =~ m/^([^= \t]+)[ \t]*=[ \t]*\"(.*)\"[ \t]*$/s) {
        # NAME = "VALUE"
        $k = ($crontab =~ s/[ \t]+$//);
    } 
    elsif (!$posix and $crontab =~ m/^([^= \t]+)[ \t]*=[ \t]*\'(.*)\'[ \t]*$/s) {
        ($k, $v) = ($1, $2);
    } 
    elsif (!$posix and $crontab =~ m/^([^= \t]+)[ \t]*=(.*)/s) {
        ($k,$v) = ($1, $2);
        $v = ($crontab =~ s/^[ \t]+//);
    } 
    elsif (!$posix and $crontab =~ m/^\@(\w+)[ \t]+(.*)/s and exists $atword{lc $1}) {
        $english = process_command($crontab, $atword{lc $1}, $2);
    }
    # for adding commands to be run to cron lines:
    #elsif ((@bits = split m/[ \t]+/, $crontab, 6) and @bits == 6) { 
    elsif ((@bits = split m/[ \t]+/, $crontab, 5) and @bits == 5) {
        $english = process_command($crontab, @bits);
    } 
    else {
        $english = 'ERROR';
    }

    $english = 'ERROR' if scalar (@bits) > 5;
    
    return $english;
}

sub process_command {
  # 0 m,   1 h,   2 day-of-month,  3 month,  4 dow
  ###my $line = shift;
  ###
  ###  my $filter = shift;
#print Dumper(\@_); 

    my $filter = '';
shift @_;
my $res = '';
  my(@time_lines, $command_string);
  if(@_ == 2) { # hack for funky vixieism
    $command_string = $_[1];
    @time_lines = ($_[0]);
  } else {
    # a normal line -- expand and Englishify it
    my(@bits) = expand_time_bits(@_);
#print Dumper(\@bits); 
    @time_lines = bits_to_english(@bits);
#print Dumper(\@time_lines); 
    $time_lines[0] = ucfirst($time_lines[0]);
    if(length(join '    ', @time_lines) <= 75) {
      @time_lines = (join '    ', @time_lines);
    }
    for(@time_lines) { $_ = ' ' . $_ }; # indent over
  #  $time_lines[0] = "At:" . $time_lines[0];
    
        ###$time_lines[0] = ":" . $time_lines[0];
        $time_lines[0] = $time_lines[0];
    $command_string = pop @bits;
  }
 
  my @command = split( "\n", percent_proc($command_string), -1 );
  
  if(@command) {
    pop @command if @command == 2 and $command[1] eq '';
     # Eliminate mention of basically null input
  } else {
    push @command, '';
  }
  
  if(@command > 1) {
    my $x = join "\n", splice @command, 1;
    push @command, " with input \"" . esc($x) . "\"";
  }
  if($command[0] =~ m<^\*>s) {
    push @command, " (Do you really mean the command to start with \"*\"?)";
  } elsif($command[0] eq '') {
    push @command, " (Do you really mean to run a null command?)";
  }
  $command[0] = "Run: $command[0]";
  
  if($filter) {
   ### print
      $res = map("$filter $_\n",
          (@command == 1) ? () : (@command), # be concise for simple cases
          @time_lines
         );
    ###;
  } else {
        foreach my $time_line (@time_lines) {
            $time_line =~ s/\s{2,}/ /g;
        }
    ###print
      ###@time_lines, "\n";
        $res = join(' ', @time_lines)
  }
  
  return $res;
}

sub expand_time_bits {
  my @bits = @_;
  my @unparseable;

  # 0 m,   1 h,   2 day-of-month,  3 month,  4 dow
  
  unless($posix) {
    if($bits[3] =~ m/($month)/oi) { $bits[3] = $month2num{lc $1} }
    if($bits[4] =~ m/($dow)/oi  ) { $bits[4] =   $dow2num{lc $1} }
  }

  for(my $i = 0; $i < 5 ; ++$i) {
    my @segments;
    if($bits[$i] eq '*') {
      push @segments, ['*'];
    } elsif(!$posix and $bits[$i] =~ m<^\*/(\d+)$>s) {
      # a hack for "*/3" etc
      push @segments, ['*', 0 + $1];
    } elsif($bits[$i] =~ m/$atoms/ois) {
      foreach my $thang (split ',', $bits[$i]) {
        if($thang =~ m<^(?:(\d+)|(?:(\d+)-(\d+)(?:/(\d+))?))$>s) {
          if(defined $1) {
            push @segments, [0 + $1]; # "7"
          } elsif(defined $4) {
            push @segments, [0 + $2, 0 + $3, 0 + $4];  # "3-20/4"
          } else {
            push @segments, [0 + $2, 0 + $3]; # "3-20"
          }
        } else {
          warn "GWAH? thang \"$thang\"";
        }
      }
    } else {
      push @unparseable, sprintf "field %s: \"%s\"", $i + 1, esc($bits[$i]);
      next;
    }
    
    $bits[$i] = \@segments;
  }
  return \@unparseable if @unparseable;
  return @bits;
}

sub bits_to_english {
  # This is the deep ugly scary guts of this program.
  # The older and eldritch among you might recognize this as sort of a
  # parody of bad old Lisp style of data-structure handling.

  my @bits = @_;
  my @time_lines;
  #use Data::Dumper; print STDERR Dumper(\@bits);

  if (scalar(@bits) != 5) {
      $time_lines[0] = 'ERROR';

      return @time_lines;
  }

my %num2month_long = (
    '1'  => 'January',
    '2'  => 'February',
    '3'  => 'March',
    '4'  => 'April',
    '5'  => 'May',
    '6'  => 'June',
    '7'  => 'July',
    '8'  => 'August',
    '9'  => 'September',
    '10' => 'October',
    '11' => 'November',
    '12' => 'December',
);
my %num2dow_long = (
    '0'  => 'Sunday',
    '1'  => 'Monday',
    '2'  => 'Tuesday',
    '3'  => 'Wednesday',
    '4'  => 'Thursday',
    '5'  => 'Friday',
    '6'  => 'Saturday',
);

$num2dow_long{'7'} = 'Sunday' unless $posix;
  { # gratuitous block.
   
    # Render the minutes and hours ########################################
    if(@{$bits[0]}    == 1   and @{$bits[1]}    == 1 and 
       @{$bits[0][0]} == 1   and @{$bits[1][0]} == 1 and 
       $bits[0][0][0] ne '*' and $bits[1][0][0] ne '*'
       # It's a highly simplifiable time expression!
       #  This is a very common case.  Like "46 13" -> 1:46pm
       #  Formally: when minute and hour are each a single number.
    ) {
      my $h = $bits[1][0][0];
      if($bits[0][0][0] == 0) {
	# Simply at the top of the hour, so just call it by the hour name.
	push @time_lines, $mil2ampm{$h};
      } else {
	# Can't say "noon:02", so use an always-numeric time format:
	push @time_lines, sprintf '%s:%02d%s',
	    ($h > 12) ? ($h - 12) : $h,
	    $bits[0][0][0],
	    ($h >= 12) ? 'pm' : 'am';
      }
      $time_lines[-1] .= ' on';

    } else {    # It's not a highly simplifiable time expression
      
      # First, minutes:
      if($bits[0][0][0] eq '*') {
        if(1 == @{$bits[0][0]} or $bits[0][0][1] == 1) {
          push @time_lines, 'every minute of';
        } else {
          push @time_lines, 'every ' . freq($bits[0][0][1]) . ' minute of';
        }
        
      } elsif( @{$bits[0]} == 1 and $bits[0][0][0] == 0 ) {
        # It's just a '0'.  Ignore it -- instead of bothering
	# to add a "0 minutes past"
      } elsif( !grep @$_ > 1, @{$bits[0]} ) {
        # it's all like 7,10,15.  conjoinable
        push @time_lines, conj_and(map $_->[0], @{$bits[0]}) . (
          $bits[0][-1][0] == 1 ? ' minute past' : ' minutes past' );
      } else { # it's just gonna be long.
        my @hunks;
        foreach my $bit (@{$bits[0]}) {
          if(@$bit == 1) {   #"7"
            push @hunks, $bit->[0] == 1 ? '1 minute' : "$bit->[0] minutes";
          } elsif(@$bit == 2) { #"7-9"
            push @hunks, sprintf "from %d to %d %s", @$bit,
              $bit->[1] == 1 ? 'minute' : 'minutes';
          } elsif(@$bit == 3) { # "7-20/2"
            push @hunks, sprintf "every %d %s from %d to %d",
              $bit->[2],
              $bit->[2] == 1 ? 'minute' : 'minutes',
              $bit->[0], $bit->[1],
            ;
          }
        }
        push @time_lines, conj_and(@hunks) . ' past';
      }
      
      # Now hours
      if($bits[1][0][0] eq '*') {
        if(1 == @{$bits[1][0]} or $bits[1][0][1] == 1) {
          push @time_lines, 'every hour of';
        } else {
          push @time_lines, 'every ' . freq($bits[1][0][1]) . ' hour of';
        }
      } else {
        my @hunks;
        foreach my $bit (@{$bits[1]}) {
          if(@$bit == 1) {   # "7"
            push @hunks, $mil2ampm{$bit->[0]} || "HOUR_$bit->[0]??";
          } elsif(@$bit == 2) { # "7-9"
            push @hunks, sprintf "from %s to %s",
              $mil2ampm{$bit->[0]} || "HOUR_$bit->[0]??",
              $mil2ampm{$bit->[1]} || "HOUR_$bit->[1]??",
          } elsif(@$bit == 3) { # "7-20/2"
            push @hunks, sprintf "every %d %s from %s to %s",
              $bit->[2],
              $bit->[2] == 1 ? 'hour' : 'hours',
              $mil2ampm{$bit->[0]} || "HOUR_$bit->[0]??",
              $mil2ampm{$bit->[1]} || "HOUR_$bit->[1]??",
          }
        }
        push @time_lines, conj_and(@hunks) . ' of';
      }
      # End of hours and minutes
    }

    # Day-of-month ########################################################
    if($bits[2][0][0] eq '*') {
      $time_lines[-1] =~ s/ on$//s;
      if(1 == @{$bits[2][0]} or $bits[2][0][1] == 1) {
        push @time_lines, 'every day of';
      } else {
        push @time_lines, 'every ' . freq($bits[2][0][1]) . ' day of';
      }
    } else {
      my @hunks;
      foreach my $bit (@{$bits[2]}) {
        if(@$bit == 1) {   # "7"
          push @hunks, 'the ' . ordinate($bit->[0]);
        } elsif(@$bit == 2) { # "7-9"
          push @hunks, sprintf "from the %s to the %s",
            ordinate($bit->[0]), ordinate($bit->[1]),
        } elsif(@$bit == 3) { # "7-20/2"
          push @hunks, sprintf "every %d %s from the %s to the %s",
            $bit->[2],
            $bit->[2] == 1 ? 'day' : 'days',
            ordinate($bit->[0]), ordinate($bit->[1]),
        }
      }
      
      # collapse the "the"s, if all the elements have one
      if(@hunks > 1 and !grep !m/^the /s, @hunks) {
        for (@hunks) { s/^the //s; }
        $hunks[0] = 'the '. $hunks[0];
      }
      
      push @time_lines, conj_and(@hunks) . ' of';
    }

    # Month ###############################################################
    if($bits[3][0][0] eq '*') {
      if(1 == @{$bits[3][0]} or $bits[3][0][1] == 1) {
        push @time_lines, 'every month';
      } else {
        push @time_lines, 'every ' . freq($bits[3][0][1]) . ' month';
      }
    } else {
      my @hunks;
      foreach my $bit (@{$bits[3]}) {
        if(@$bit == 1) {   # "7"
          push @hunks, $num2month_long{$bit->[0]} || "MONTH_$bit->[0]??"
        } elsif(@$bit == 2) { # "7-9"
          push @hunks, sprintf "from %s to %s",
            $num2month_long{$bit->[0]} || "MONTH_$bit->[0]??",
            $num2month_long{$bit->[1]} || "MONTH_$bit->[1]??",
        } elsif(@$bit == 3) { # "7-20/2"
          push @hunks, sprintf "every %d %s from %s to %s",
            $bit->[2],
            $bit->[2] == 1 ? 'month' : 'months',
            $num2month_long{$bit->[0]} || "MONTH_$bit->[0]??",
            $num2month_long{$bit->[1]} || "MONTH_$bit->[1]??",
        }
      }
      push @time_lines, conj_and(@hunks);
      
      # put in semicolons in the case of complex constituency
      #if($time_lines[-1] =~ m/every|from/) {
      #  $time_lines[-1] =~ tr/,/;/;
      #  s/ (and|or)\b/\; $1/g;
      #}
    }
    
    
    # Weekday #############################################################
   #
  #
 #
#
# From man 5 crontab:
#   Note: The day of a command's execution can be specified by two fields
#   -- day of month, and day of week.  If both fields are restricted
#   (ie, aren't *), the command will be run when either field matches the
#   current time.  For example, "30 4 1,15 * 5" would cause a command to
#   be run at 4:30 am on the 1st and 15th of each month, plus every Friday.
#
# [But if both fields ARE *, then it just means "every day".
#  and if one but not both are *, then ignore the *'d one --
#  so   "1 2 3 4 *" means just 2:01, April 3rd
#  and  "1 2 * 4 5" means just 2:01, on every Friday in April
#  But  "1 2 3 4 5" means 2:01 of every 3rd or Friday in April. ]
#
 #
  #
   #
    # And that's a bit tricky.
    
    if($bits[4][0][0] eq '*' and (
      @{$bits[4][0]} == 1 or $bits[4][0][1] == 1
     )
    ) {
      # Most common case -- any weekday.  Do nothing really.
      #
      #   Hm, does "*/1" really mean "*" here, given the above note?
      #
      
      # Tidy things up while we're here:
      if($time_lines[-2] eq "every day of" and
         $time_lines[-1] eq 'every month'
      ) {
        $time_lines[-2] = "every day";
        pop @time_lines;
      }
      
    } else {
      # Ugh, there's some restriction on weekdays.
      
      # Translate the DOW-expression
      my $expression;
      my @hunks;
      foreach my $bit (@{$bits[4]}) {
        if(@$bit == 1) {
          push @hunks, $num2dow_long{$bit->[0]} || "DOW_$bit->[0]??";
        } elsif(@$bit == 2) {
          if($bit->[0] eq '*') { # it's like */3
            #push @hunks, sprintf "every %s day of the week", freq($bit->[1]);
            #  the above was ambiguous -- "every third day of the week"
            #  sounds synonymous with just "3"
            if($bit->[1] eq 2) {
              # common and unambiguous case.
              push @hunks, "every other day of the week";
            } else {
              # rare cases: N > 2
              push @hunks, "every $bit->[1] days of the week";
               # sounds clunky, but it's a clunky concept
            }
          } else {
            # it's like "7-9"
            push @hunks, sprintf "%s through %s",
              $num2dow_long{$bit->[0]} || "DOW_$bit->[0]??",
              $num2dow_long{$bit->[1]} || "DOW_$bit->[1]??",
          }
        } elsif(@$bit == 3) { # "7-20/2"
          push @hunks, sprintf "every %s %s from %s through %s",
            ordinate_soft($bit->[2]), #$bit->[2],
            'day',               #$bit->[2] == 1 ? 'days' : 'days',
            $num2dow_long{$bit->[0]} || "DOW_$bit->[0]??",
            $num2dow_long{$bit->[1]} || "DOW_$bit->[1]??",
        }
      }
      $expression = conj_or(@hunks);
      
      # Now figure where to put it...
      #
      if($time_lines[-2] eq "every day of") {
        # Unrestricted day-of-month, hooray.
        #
        if($time_lines[-1] eq 'every month') {
          # change it to "every Tuesday", killing the "of every month".
          $time_lines[-2] = "every $expression";
          $time_lines[-2] =~ s/every every /every /g;
          pop @time_lines;
        } else {
          # change it to "every Tuesday in"
          $time_lines[-2] = "every $expression in";
          $time_lines[-2] =~ s/every every /every /g;
        }
      } else {
        # This is the messy case where there's a DOM and DOW
        #  restriction
        
        # Was, wrongly:
        #  $time_lines[-1] .= ',';
        #  push @time_lines, "if it's also " . $expression;
        
        $time_lines[-2] .= " -- or every $expression in --";
         # Yes, dashes look very strange, but then this is a very
         # rare case.
        $time_lines[-2] =~ s/every every /every /g;
      }
    }
    #######################################################################
  }
    # TODO: change "3pm" -> "the 3pm hour" or something?
  $time_lines[-1] =~ s/ of$//s;
  
  return @time_lines;
}

sub esc {
    our %pretty_form = ( 
        '"'  => '\"',  
        '\\' => '\\\\', 
    );
  
    my $x = $_[0];
  
    $x =~ s<([\x00-\x1F"\\])><$pretty_form{$1} || '\\x'.(unpack("H2",$1))>eg;
  
    return $x;
}

#      if($time_lines[-1] =~ m/every|from/) {
#        $time_lines[-1] =~ tr/,/;/;
#        s/ (and|or)\b/\; $1/g;
#      }

sub conj_and {
  if(grep m/every|from/, @_) {
    # put in semicolons in the case of complex constituency
    return join('; and ', @_) if @_ < 2;
    my $last = pop @_;
    return join('; ', @_) . '; and ' . $last;
  }
  
  return join(' and ', @_) if @_ < 3;
  my $last = pop @_;
  return join(', ', @_) . ', and ' . $last;
}

sub conj_or {
  if(grep m/every|from/, @_) {
    # put in semicolons in the case of complex constituency
    return join('; or ', @_) if @_ < 2;
    my $last = pop @_;
    return join('; ', @_) . '; or ' . $last;
  }
  
  return join(' or ', @_) if @_ < 3;
  my $last = pop @_;
  return join(', ', @_) . ', or ' . $last;
}

sub ordsuf  {
  return 'th' if not(defined($_[0])) or not( 0 + $_[0] );
   # 'th' for undef, 0, or anything non-number.
  my $n = abs($_[0]);  # Throw away the sign.
  return 'th' unless $n == int($n); # Best possible, I guess.
  $n %= 100;
  return 'th' if $n == 11 or $n == 12 or $n == 13;
  $n %= 10;
  return 'st' if $n == 1; 
  return 'nd' if $n == 2;
  return 'rd' if $n == 3;
  return 'th';
}

sub ordinate  {
    # English-language overrides for common ordinals
    my %ordinations = (
        '1'  => 'first',
        '2'  => 'second',
        '3'  => 'third',
        '4'  => 'fourth',
        '5'  => 'fifth',
        '6'  => 'sixth',
        '7'  => 'seventh',
        '8'  => 'eigth',
        '9'  => 'ninth',
        '10' => 'tenth',
    );
  
    my $i = $_[0] || 0;
  
    $ordinations{$i} || ($i . ordsuf($i));
}

sub freq {
    # English-language overrides for common ordinals
    my %ordinations = (
        '1'  => 'first',
        '2'  => 'second',
        '3'  => 'third',
        '4'  => 'fourth',
        '5'  => 'fifth',
        '6'  => 'sixth',
        '7'  => 'seventh',
        '8'  => 'eigth',
        '9'  => 'ninth',
        '10' => 'tenth',
    );
  
    # frequentive form.  Like ordinal, except that 2 -> 'other' (as in every other)
    my $i = $_[0] || 0;
  
    return 'other' if $i == 2;  # special case
  
    $ordinations{$i} || ($i . ordsuf($i));
}

sub ordinate_soft  {
  my $i = $_[0] || 0;
  $i . ordsuf($i);
}

sub percent_proc {
  # Translated literally from the C, cron/do_command.c.
  my($esc,$need_newline);
  my $out = '';
  my $c;
  for(my $i = 0; $i < length($_[0]); $i++) {
    $c = substr($_[0],$i,1);
    if($esc) {
      $out .= "\\" unless $c eq '%';
    } else {
      $c = "\n" if $c eq '%';
    }
    unless($esc = ($c eq "\\")) {
      # For unescaped characters,
      $out .= $c;
      $need_newline = ($c ne "\n");
    }
  } 
  $out .= "\\" if $esc;
  $out .= "\n" if $need_newline;
  return $out;
  
  # I think this would do the same thing:
  #  $x =~ s/((?:\\\\)+)  |  (\\\%)  |  (\%)  /$3 ? "\n" : $2 ? '%'   : $1/xeg;
  # But I don't want to think about it, and I need it to work just
  #  as the original does.
}



1;



__END__
=head1 NAME

ParseCron - describe a cron job in human-readable form 

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

describe a cron job in human-readable form.  adapted from http://interglacial.com/~sburke/pub/crontab2english.html for use in DDG Goodies.

C<use ParseCron qw/parse_cron/;>

C<...>

C< my $english = parse_cron('42 12 3 Feb Sat'); >       

will produce '(42 12 3 Feb Sat) means this cron job will run: 12:42pm on the third of -- or every Saturday in -- February'.

See ParseCron.t for more example uses.

=head1 EXPORT

parse_cron

=head1 SUBROUTINES/METHODS

=head2 new()

Create a new ParseCron object.

=head2 parse_cron()

This is the workhorse.  All translation work gets done here.  This is the only exported sub.

=head2 bits_to_english()

=head2 conj_and()

=head2 conj_or()

=head2 esc()

=head2 expand_time_bits()

=head2 freq()

=head2 ordinate()

=head2 ordinate_soft()

=head2 ordsuf()

=head2 percent_proc()

=head2 process_command()

=head1 AUTHOR

sean m burke, C<< <sburke@cpan.org> >>
bradley andersen, C<< <bradley at pvnp.us> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ParseCron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ParseCron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ParseCron>

=item * Search CPAN

L<http://search.cpan.org/dist/ParseCron/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Bradley Andersen. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 PRIOR ART

=head1 TODO

=over 4

=item *

fix this documentation!

=back

=cut
