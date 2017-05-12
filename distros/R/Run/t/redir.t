#! perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use Run ':NEW';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#open SAVEDERR, ">&STDERR" or print "not ok 1.5\n";

#print STDERR "." or print("not ok 2.5 ", fileno STDERR, " $!\n");
(new_system 'perl', '-le', 'print STDERR "ok 2"')
  ->run({redir => {2 => {filehandle => \*STDOUT, mode => 'w'}}})
  and print "ok 3\n";
#print STDERR "." or print("not ok 3.5 ", fileno STDERR, " $!\n"), exit 1;

(new_system 'perl', '-le', 'open FH12, ">&=12" or die $!; print FH12 "ok 4"')
  ->run({redir => {12 => {filehandle => \*STDOUT, mode => 'w'}}})
  and print "ok 5\n";
#print STDERR "." or print "not ok 5.5\n";

(new_redir
 {2 => {filehandle => \*STDOUT, mode => 'w'}},
 (new_system 'perl', '-le', 'print STDERR "ok 6"'))->run
  and print "ok 7\n";
#print STDERR "." or print "not ok 7.5\n";

(new_redir
 {12 => {filehandle => \*STDOUT, mode => 'w'}},
 (new_system 'perl', '-le', 'open FH12, ">&=12" or die $!; print FH12 "ok 8"'))
  ->run
  and print "ok 9\n";

if (0) {
  (new_redir
   {11 => {filehandle => \*STDOUT, mode => 'w'}},
   (new_redir
    {13 => {filehandle => \*STDOUT, mode => 'w'}},
    (new_system 'perl', '-le', 
     'open FH11, ">&=11" or die $!; print FH11 "ok 10";
    open FH13, ">&=13" or die $!; print FH13 "ok 11";')))
    ->run and print "ok 12\n";
} else {
  # Now tested in redir_mayfail.t
  print <<EOP;
ok 10
ok 11
ok 12
EOP
}

(new_redir
  {13 => {filehandle => \*STDOUT, mode => 'w'}},
  (new_system 'perl', '-le', 
   'open FH11, ">&=11" or print "ok 13";'))
  ->run
  and print "ok 14\n";

(new_redir
 {11 => {filehandle => \*STDOUT, mode => 'w'}},
 (new_redir
  {13 => {filename => ">&=11"}},
  (new_system 'perl', '-le', 
   'open FH13, ">&=13" or die $!; print FH13 "ok 15";')))
  ->run
  and print "ok 16\n";

(new_redir
 {11 => {filename => ">&STDOUT"}},
 (new_redir
  {13 => {filename => ">&STDOUT"}},
  (new_system 'perl', '-le', 
   'open FH11, ">&=11" or die $!; print FH11 "ok 17";
    open FH13, ">&=13" or die $!; print FH13 "ok 18";')))
  ->run
  and print "ok 19\n";

