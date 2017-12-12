
use strict;
use warnings;
use Term::GentooFunctions qw(start_spinner step_spinner end_spinner einfo ewarn eerror);
use Time::HiRes qw(sleep);

equiet(1) if $ENV{SHH_QUIET};

start_spinner "testing spinner - test#1";
for( 1 .. 20 ) {
    step_spinner;
    sleep 0.1;
}
end_spinner 1;

start_spinner "testing spinner - test#2";
for( 1 .. 20 ) {
    step_spinner "$_/20";
    sleep 0.1;
}
end_spinner 1;

start_spinner "testing spinner - test#3: this time with extra status updates";
for( 1 .. 20 ) {
    step_spinner "$_/20";
    einfo "status #1 \$_=$_" if $_ == 1;
    ewarn "status #2 \$_=$_" if $_ == 2;
   eerror "status #3 \$_=$_" if $_ == 3;
    einfo "status #4 \$_=$_" if $_ == 6;
    ewarn "status #5 \$_=$_" if $_ == 7;
   eerror "status #6 \$_=$_" if $_ == 8;
    sleep 0.1;
}
end_spinner 1;

start_spinner "testing spinner - test#4: again with the status updates";
for( 1 .. 20 ) {
    step_spinner "$_/20";
    einfo "status #1 \$_=$_" if $_ == 1;
    ewarn "status #2 \$_=$_" if $_ == 2;
   eerror "status #3 \$_=$_" if $_ == 3;
    einfo "status #4 \$_=$_" if $_ == 6;
    ewarn "status #5 \$_=$_" if $_ == 7;
   eerror "status #6 \$_=$_" if $_ == 8;
    sleep 0.1;
}
end_spinner 1;

start_spinner "testing spinner - test#5: with multiple prints per step (2\@3, 3\@7)";
for( 1 .. 20 ) {
    step_spinner "$_/20";
    if( $_ == 3 ) { einfo "1/2 \@3"; einfo "2/2 \@3"; }
    if( $_ == 7 ) { einfo "1/3 \@7"; einfo "2/3 \@7"; einfo "3/3 \@7"; }
    sleep 0.1;
}
end_spinner 1;

start_spinner "testing spinner - test#6: exit early (\@7)";
for( 1 .. 20 ) {
    step_spinner "$_/20";
    exit if $_ == 7;
    sleep 0.1;
}
end_spinner 1;

