# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl OpenGL-Modern.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok( 'OpenGL::Modern' ) }

use OpenGL::Modern::NameLists::MakefileAll;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl OpenGL-Modern.t'

my $fail = 0;
foreach my $constname ( OpenGL::Modern::NameLists::MakefileAll::makefile_all() ) {
    next if ( eval "my \$a = OpenGL::Modern::$constname(); 1" );

    if ( $@ =~ /^Your vendor has not defined OpenGL::Modern macro $constname/ ) {
        print "# pass: $@";
    }
    else {
        print "# fail: $@";
        $fail = 1;
    }

}

ok( $fail == 0, 'The expected constants get exported' );

for my $function ( qw(glClear ) ) {
    my $exported = 0;
    my $ok = eval { OpenGL::Modern->import( $function ); $exported = 1 };
    ok( $exported, "Function $function gets exported upon request" );
}
