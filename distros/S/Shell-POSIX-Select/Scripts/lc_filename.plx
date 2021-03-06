#!/usr/bin/perl -w
#########################################################
# Sample Program for Perl Module "Shell::POSIX::Select" #
#  tim@TeachMePerl.com  (888) DOC-PERL  (888) DOC-UNIX  #
#  Copyright 2002-2003, Tim Maher. All Rights Reserved  #
#########################################################
use Shell::POSIX::Select (
    '$Eof' ,
    prompt => 'Enter number (^D to exit):' ,
    style =>  'Korn'	# for automatic prompting
);

# Rename selected files from current dir to lowercase
while ( @files=<*[A-Z]*> ) {    # restarts select to get updated menu
   select ( @files ) { # skip fully lower-case names
       if (rename $_, "\L$_") {
           last ;
       }
       else {
           warn "$0: rename failed for $_: $!\n";
       }
   }
   $Eof  and  last ;   # Handle <^D> to menu prompt
}
