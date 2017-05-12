# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 14 };
use Perl6::Tokener;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $t;
ok ($t = new Perl6::Tokener);

$t->{buffer}=' $a.foo += $c*-x $d';
ok (not defined $t->toke());
ok (($t->toke())[1] eq '$a');
ok (($t->toke())[0] eq 'method');
ok (($t->toke())[0] eq 'bareword');
ok (not defined $t->toke());
ok (($t->toke())[0] eq 'assignop');
ok (not defined $t->toke());
ok (($t->toke())[1] eq '$c');
ok (($t->toke())[0] eq 'mulop');
ok (($t->toke())[0] eq 'filetest');
ok (not defined $t->toke());
ok (($t->toke())[1] eq '$d');
