# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OpenGL-Simple-GLM.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('OpenGL::GLM') };


my $fail = 0;
foreach my $constname (qw(
	GLM_2_SIDED GLM_COLOR GLM_FLAT GLM_MATERIAL GLM_MAX_SHININESS
	GLM_MAX_TEXTURE_SIZE GLM_NONE GLM_SMOOTH GLM_TEXTURE )) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined OpenGL::GLM macro $constname/) {
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

