echo off
REM This should be simple enough to convert to a bash script (don't name it just
REM "perlcritic", as this will conflict with the Perl command "perlcritic"!). 
REM You may need to install the Perl module Perl::Critic if you don't already 
REM have it. Windows users will probably have to install the very useful utility
REM "grep" in order to run this batch file. 
REM
REM Perl::Critic should pass level 5 (least strict) without errors. There are a
REM number of errors at level 4 that still need to be fixed, but can be 
REM suppressed for now via "grep -v".
REM
REM Messages being ignored:
REM   source OK  =  nothing to report at this level (passes)
REM   Code before warnings  =  due to use of "no warnings" pragma 
REM   Warnings disabled at  =  due to use of "no warnings" pragma
REM   Close filehandles as soon as possible  =  it thinks there is no "close"
REM     on an open filehandle, due to either too many lines for it to buffer
REM     or use of other code to close
REM   Always upack @_ first  =  not using @_ or $_[n] directly is good 
REM     practice, but it doesn't seem to recognize legitimate uses
REM   Subroutine name is a homonym for builtin function  =  e.g., we 
REM     define "open" when there is already a system (CORE::) open (ambiguous
REM     unless CORE:: added)
REM   Symbols are exported by default  =  it doesn't like something about
REM     our use of @EXPORT and @EXPORT_OK
REM
REM Note that level 4 includes any level 5 errors, etc.
REM Don't even *try* to use levels 3, 2, or 1 unless you're morbidly curious!
echo on
REM level 5 should run clean
REM perlcritic -5 .
REM level 4 expect lots of repeated errors
REM perlcritic -4 .
REM level 4 suppress common warnings
perlcritic -4 . |grep -v "source OK" |grep -v "Code before warnings" |grep -v "Warnings disabled at" |grep -v "Close filehandles as soon as possible" |grep -v "Always unpack @_ first" |grep -v "Subroutine name is a homonym for builtin function" |grep -v "Symbols are exported by default"
