package Term::RawInput;

#    RawInput.pm
#
#    Copyright (C) 2011-2023
#
#    by Brian M. Kelly. <Brian.Kelly@fullautosoftware.net>
#
#    You may distribute under the terms of the GNU Affero General
#    Public License, as specified in the LICENSE file.
#    <http://www.gnu.org/licenses/agpl.html>.
#
#    http://www.fullautosoftware.net/

## See user documentation at the end of this file.  Search for =head


$VERSION = '1.25';


use 5.006;

## Module export.
use vars qw(@EXPORT);
@EXPORT = qw(rawInput);
## Module import.
use Exporter ();
use Config ();
our @ISA = qw(Exporter);

use strict;
use Term::ReadKey;
use IO::Handle;

sub rawInput {

   my $length_prompt=length $_[0];
   my $return_single=$_[1]||0;
   ReadMode('cbreak');
   my $a='';
   my $key='';
   my @char=();
   my $char='';
   my $output=$_[0];
   STDOUT->autoflush(1);
   if (exists $ENV{PARdir} && $^O eq 'cygwin') {
      printf("\r% ${length_prompt}s",$output."\n");
   } else {
      printf("\r% ${length_prompt}s",$output);
   }
   STDOUT->autoflush(0);
   my $save='';
   while (1) {
      $char=ReadKey(0);
      STDOUT->autoflush(1);
      $a=ord($char);
      push @char, $a;
      if ($a==10 || $a==13) {
         $save=$output;
         while (1) {
            last if (length $output==$length_prompt);
            substr($output,-1)=' ';
            printf("\r% ${length_prompt}s",$output);
            chop $output;
            printf("\r% ${length_prompt}s",$output);
            last if (length $output==$length_prompt);
         }
         $key='ENTER';
         last
      }
      if ($a==127 || $a==8) {
         return '','BACKSPACE' if $return_single;
         next if (length $output==$length_prompt);
         substr($output,-1)=' ';
         STDOUT->autoflush(1);
         printf("\r% ${length_prompt}s",$output);
         STDOUT->autoflush(0);
         chop $output;
         STDOUT->autoflush(1);
         printf("\r% ${length_prompt}s",$output);
         STDOUT->autoflush(0);
      } elsif ($a==27) {
         my $flag=0;
         while ($char=ReadKey(-1)) {
            $a=ord($char);
            push @char, $a;
            $flag++;
         }
         unless ($flag) {
            while ($char=ReadKey(1)) {
               $a=ord($char);
               push @char, $a;
               $flag++;
               last if $flag==2;
            }
         }
         unless ($flag) {
            $key='ESC';
            last;
         } elsif ($flag==1) {
            while ($char=ReadKey(1)) {
               $a=ord($char);
               push @char, $a;
               $flag++;
               last if $flag==2;
            }
         }
         if ($flag==2) {
            my $e=$#char-2;
            if ($char[$e+1]==79) {
               if ($char[$e+2]==80) {
                  $key='F1';
               } elsif ($char[$e+2]==81) {
                  $key='F2';
               } elsif ($char[$e+2]==82) {
                  $key='F3'; 
               } elsif ($char[$e+2]==83) {
                  $key='F4';
               } elsif ($char[$e+2]==115) {
                  $key='PAGEDOWN';
               } elsif ($char[$e+2]==121) {
                  $key='PAGEUP';
               }
            } elsif ($char[$e+1]==91) {
               if ($char[$e+2]==50) {
                  $key='F9';
                  ReadKey(1);
               } elsif ($char[$e+2]==51) {
                  $key='DELETE';
                  ReadKey(1);
               } elsif ($char[$e+2]==53) {
                  $key='PAGEUP';
                  ReadKey(1);
               } elsif ($char[$e+2]==54) {
                  $key='PAGEDOWN';
                  ReadKey(1);
               } elsif ($char[$e+2]==65) {
                  $key='UPARROW';
                  while (ReadKey(-1)) {
                     select(undef,undef,undef,0.5);
                     last;
                  };
                  #ReadKey(1);
               } elsif ($char[$e+2]==66) {
                  $key='DOWNARROW';
                  while (ReadKey(-1)) {
                     select(undef,undef,undef,0.5);
                     last;
                  };
                  #ReadKey(1);
               } elsif ($char[$e+2]==67) {
                  $key='RIGHTARROW';
               } elsif ($char[$e+2]==68) {
                  $key='LEFTARROW';
               } elsif ($char[$e+2]==70) {
                  $key='END';
               } elsif ($char[$e+2]==72) {
                  $key='HOME';
               }
               if ($key) {
                  $save=$output;
                  while (1) {
                     last if (length $output==$length_prompt);
                     substr($output,-1)=' ';
                     printf("\r% ${length_prompt}s",$output);
                     last if (length $output==$length_prompt);
                     chop $output;
                     printf("\r% ${length_prompt}s",$output);
                     last if (length $output==$length_prompt);
                  } last
               }
            }
            if ($key) {
               $save=$output;
               while (1) {
                  last if (length $output==$length_prompt);
                  substr($output,-1)=' ';
                  printf("\r% ${length_prompt}s",$output);
                  chop $output;
                  printf("\r% ${length_prompt}s",$output);
                  last if (length $output==$length_prompt);
               } last
            }
         } elsif ($flag==3) {
            my $e=$#char-3;
            if ($char[$e+1]==91) {
               if ($char[$e+2]==49) {
                  if ($char[$e+3]==126) {
                     $key='HOME';
                  }
               } elsif ($char[$e+2]==50) {
                  if ($char[$e+3]==126) {
                     $key='INSERT';
                  }
               } elsif ($char[$e+2]==51) {
                  if ($char[$e+3]==126) {
                     $key='DELETE';
                  }
               } elsif ($char[$e+2]==52) {
                  if ($char[$e+3]==126) {
                     $key='END';
                  }
               } elsif ($char[$e+2]==53) {
                  if ($char[$e+3]==126) {
                     $key='PAGEUP';
                  }
               } elsif ($char[$e+2]==54) {
                  if ($char[$e+3]==126) {
                     $key='PAGEDOWN';
                  }
               }
            }
            if ($key) {
               $save=$output;
               while (1) {
                  last if (length $output==$length_prompt);
                  substr($output,-1)=' ';
                  printf("\r% ${length_prompt}s",$output);
                  last if (length $output==$length_prompt);
                  chop $output;
                  printf("\r% ${length_prompt}s",$output);
                  last if (length $output==$length_prompt);
               } last
            }
         } elsif ($flag==4) {
            my $e=$#char-4;
            if ($char[$e+1]==91) {
               if ($char[$e+2]==49) {
                  if ($char[$e+3]==53) {
                     if ($char[$e+4]==126) {
                        $key='F5';
                     }
                  } elsif ($char[$e+3]==55) {
                     if ($char[$e+4]==126) {
                        $key='F6';
                     }
                  } elsif ($char[$e+3]==56) {
                     if ($char[$e+4]==126) {
                        $key='F7';
                     }
                  } elsif ($char[$e+3]==57) {
                     if ($char[$e+4]==126) {
                        $key='F8';
                     }
                  }
               } elsif ($char[$e+2]==50) {
                  if ($char[$e+3]==48) {
                     if ($char[$e+4]==126) {
                        $key='F9';
                     }
                  } elsif ($char[$e+3]==49) {
                     if ($char[$e+4]==126) {
                        $key='F10';
                     }
                  } elsif ($char[$e+3]==51) {
                     if ($char[$e+4]==126) {
                        $key='F11';
                     }
                  } elsif ($char[$e+3]==52) {
                     if ($char[$e+4]==126) {
                        $key='F12';
                     }
                  } elsif ($char[$e+3]==57) {
                     if ($char[$e+4]==126) {
                        $key='CONTEXT';
                     }
                  } 
               }

            }
            if ($key) {
               $save=$output;
               while (1) {
                  last if (length $output==$length_prompt);
                  substr($output,-1)=' ';
                  printf("\r% ${length_prompt}s",$output);
                  last if (length $output==$length_prompt);
                  chop $output;
                  printf("\r% ${length_prompt}s",$output);
                  last if (length $output==$length_prompt);
               } last
            }
         }
      } elsif ($return_single) {
         $key='TAB' if $a==9;
         $output.=chr($a);
         $save=$output;
         while (1) {
            last if (length $output==$length_prompt);
            substr($output,-1)=' ';
            printf("\r% ${length_prompt}s",$output);
            chop $output;
            printf("\r% ${length_prompt}s",$output);
            last if (length $output==$length_prompt);
         } last
      } else {
         $output.=chr($a);
         printf("\r% ${length_prompt}s",$output);
      }
      last unless defined $char;
   }
   substr($save,0,$length_prompt)='';
   STDOUT->autoflush(0);
   ReadMode('normal');

   return $save,$key;

}
1;

__END__;


######################## User Documentation ##########################


## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.
## For example, to nicely format this documentation for printing, you
## may use pod2man and groff to convert to postscript:
##   pod2man Term/Menus.pm | groff -man -Tps > Term::Menus.ps

=head1 NAME

Term::RawInput - A simple drop-in replacement for <STDIN> in scripts
              with the additional ability to capture and return
              the non-standard keys like 'End', 'Escape' [ESC], 'Insert', etc.

=head1 SYNOPSIS

   use Term::RawInput;

   my $prompt='PROMPT : ';
   my ($input,$key)=('','');
   ($input,$key)=rawInput($prompt,0);

   print "\nRawInput=$input" if $input;
   print "\nKey=$key\n" if $key;

   print "Captured F1\n" if $key eq 'F1';
   print "Captured ESCAPE\n" if $key eq 'ESC';
   print "Captured DELETE\n" if $key eq 'DELETE';
   print "Captured PAGEDOWN\n" if $key eq 'PAGEDOWN';   

=head1 DESCRIPTION

I needed a ridiculously simple function that behaved exactly like $input=<STDIN> in scripts, that captured user input and and populated a variable with a resulting string. BUT - I also wanted to use other KEYS like DELETE and the RIGHT ARROW key and have them captured and returned. So I really wanted this:

my $prompt='PROMPT : ';
($input,$key)=rawInput($prompt,0);

... where I could test the variable '$key' for the key that was used to terminate the input. That way I could use the arrow keys to scroll a menu for instance.

I looked through the CPAN, and could not find something this simple and straight-forward. So I wrote it. Enjoy.

The second argument to rawInput() is optional, and when set to 1 or any positive value, returns all keys instantly, instead of waiting for ENTER. This has turned out to be extremely useful for creating command environment "forms" without the need for curses. See Term::Menus and/or Net::FullAuto for more details.

NOTE: When the second argument is 0 or not used, BACKSPACE and TAB are not captured - but used to backspace and tab. DELETE is captured. Also, no Control combinations are captured - just the non-standard keys INSERT, DELETE, ENTER, ESC, HOME, PAGEDOWN, PAGEUP, END, the ARROW KEYS, and F1-F12 (but *NOT* F1-F12 with Windows Version of Perl - especially Strawberry Perl [ This is a limitation of the Term::ReadKey Module. ]; but, works with Cygwin Perl!). All captured keys listed will terminate user input and return the results - just like you would expect using ENTER with <STDIN>.

=head1 AUTHOR

Brian M. Kelly <Brian.Kelly@fullautosoftware.net>

=head1 COPYRIGHT

Copyright (C) 2011-2023
by Brian M. Kelly.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License.
(http://www.gnu.org/licenses/agpl.html).

