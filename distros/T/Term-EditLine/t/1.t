# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Term::EditLine') };


my $fail = 0;
foreach my $constname (qw(
	CC_ARGHACK CC_CURSOR CC_EOF CC_ERROR CC_FATAL CC_NEWLINE CC_NORM
	CC_REDISPLAY CC_REFRESH CC_REFRESH_BEEP EL_ADDFN EL_BIND
	EL_BUILTIN_GETCFN EL_CLIENTDATA EL_ECHOTC EL_EDITMODE EL_EDITOR
	EL_GETCFN EL_HIST EL_PROMPT EL_RPROMPT EL_SETTC EL_SETTY EL_SIGNAL
	EL_TELLTC EL_TERMINAL H_ADD H_APPEND H_CLEAR H_CURR H_END H_ENTER
	H_FIRST H_FUNC H_GETSIZE H_LAST H_LOAD H_NEXT H_NEXT_EVENT H_NEXT_STR
	H_PREV H_PREV_EVENT H_PREV_STR H_SAVE H_SET H_SETSIZE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Term::EditLine macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

