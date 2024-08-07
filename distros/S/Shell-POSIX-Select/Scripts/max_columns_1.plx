#!/usr/bin/perl -w
#########################################################
# Sample Program for Perl Module "Shell::POSIX::Select" #
#  tim@TeachMePerl.com  (888) DOC-PERL  (888) DOC-UNIX  #
#  Copyright 2002-2003, Tim Maher. All Rights Reserved  #
#########################################################

use Shell::POSIX::Select qw($Heading $Prompt $Eof $MaxColumns) ;
# following avoids used-only once warning
my ($type, $format) ;

# Would be more Perlish to associate choices with options
# using a Hash, but this approach demonstrates $Reply variable

@formats = ( 'regular', 'long' ) ;
@fmt_opt = ( '',        '-l'   ) ;

@types   = ( 'only non-hidden', 'all files' ) ;
@typ_opt = ( '',                '-a' ,      ) ;

print "** LS-Command Composer **\n\n" ;

$Heading="\n**** Style Menu ****" ;
$Prompt= "Choose listing style:" ;
$MaxColumns = 1;

OUTER:
select $format ( @formats ) {
    $user_format=$fmt_opt[ $Reply - 1 ] ;

    $Heading="\n**** File Menu ****" ;
    $Prompt="Choose files to list:" ;
    $MaxColumns = 1;
    select $type ( @types ) {   # ^D restarts OUTER
        $user_type=$typ_opt[ $Reply - 1 ] ;
        last OUTER ;    # leave loops once final choice obtained
    }
}
$Eof  and  exit ;   # handle ^D to OUTER

# Now construct user's command
$command="ls  $user_format  $user_type" ;

# Show command, for educational value
warn "\nPress <ENTER> to execute \"$command\"\n" ;

# Now wait for input, then run command
defined <>  or  print "\n"  and  exit ;

system $command ;    # finally, run the command
