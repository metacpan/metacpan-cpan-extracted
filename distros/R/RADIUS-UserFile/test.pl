# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use RADIUS::UserFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $USERS_FILE = 'examples/users';              # RADIUS users data file
my $NUM_USERS = 4;                              # how many users are in there
my @USERS = qw(banner joeuser chumpsize gandalf);    # who those users are
my $NUM_JOES_ATTRIBS = 8;                       # how many attribs joeuser has

my $RU;                                         # RADIUS::UserFile object

# simple test:  can we create a new object?
$t = 2;
eval { $RU = new RADIUS::UserFile(Debug => 0); } or print 'not ';
print "ok $t { new }\n";

# make sure there aren't any files loaded yet.  that'd be weird.
$t++;
scalar @{$RU->files} == 0 or print('[', @{$RU->files}, '] not ');
print "ok $t { files }\n";

# no users yet, either.
$t++;
$RU->users == undef or print 'not ';
print "ok $t { users }\n";

$t++;
scalar @{$RU->usernames} == 0 or print 'not ';
print "ok $t { username }\n";

$t++;
$RU->attributes('joeuser') == undef or print 'not ';
print "ok $t { attributes }\n";

$t++;
$RU->values('joeuser', 'attributename') == undef or print 'not ';
print "ok $t { value }\n";

# Load the users file now, and do some (slightly) more significant testing.
$t++;
eval { $RU->load(File => $USERS_FILE); } or print 'not ';
print "ok $t { load }\n";

# does the object think it loaded the file we told it to?
$t++;
eval { join('', $RU->files) eq $USERS_FILE } or print 'not ';
print "ok $t { files }\n";

# did it load the right number of users?
$t++;
eval { scalar keys %{$RU->users} == $NUM_USERS } or print 'not ';
print "ok $t { users }\n";

# check the quality of the data it loaded...
$t++;
eval { scalar @{$RU->usernames} == $NUM_USERS } or print 'not ';
print "ok $t { usernames #1 }\n";

$t++;
eval { join(' ', sort @{$RU->usernames}) eq join(' ', sort @USERS) }
 or print 'not ';
print "ok $t { usernames #2 }\n";

$t++;
eval { scalar $RU->attributes('joeuser') == $NUM_JOES_ATTRIBS }
 or print "not ";
print "ok $t { attributes }\n";

$t++;
eval { ($RU->values('joeuser', 'Password'))[0] eq '"UNIX"' } or print 'not ';
print "ok $t { value }\n";

# Ye olde "empty sub-class" test, as suggestd in the CPAN module list docs.
$t++;
eval { 
    package Subclass;
    my $USERS_FILE = 'examples/users';
    my $NUM_USERS = 4;
    @Subclass::ISA = qw(RADIUS::UserFile);
    $subRU = new Subclass;
    $subRU->load(File => $USERS_FILE);
    scalar keys %{$subRU->users} == $NUM_USERS;
} or print 'not ';
print "ok $t { empty subclass }\n";

#print "joe's attribs: ", join(', ', @{$RU->attributes('joeuser')}), "\n";
#$RU->dump('joeuser');
#foreach my $who (@{ $RU->usernames }) {
#    print "$who: \n";
#    print map(sprintf("\t%s -> %s\n", $_, $RU->value($who, $_)),
#              $RU->attributes($who)),
#          "\n";
#}

# now try adding a new user
$t++;
eval {
    $RU->add(Who        => 'areallylonguser@somedomain',
             Attributes => { 'Auth-Type' => 'unix', Password => '"jabberwocky"',
                             junkkey1 => 'val1', junkkey2 => 'val2' },
             Comment    => 'meep meep!')
     or die("test $t: couldn't add areallylonguser\@somedomain\n");
    $RU->update() or die("test $t: couldn't update $USERS_FILE\n".
                         "files are ".$RU->files."\n");
} or print 'not ';
print "ok $t { add }\n";
print $@ if $@;

# check removal of a user from the object
$t++;
eval { join('', $RU->remove('areallylonguser@somedomain'))
        eq 'areallylonguser@somedomain'
        or die("removing areallylonguser\@somedomain failed\n");
       join(' ', sort @{$RU->usernames}) eq join(' ', sort @USERS)
        or die("testing remove(areallylonguser\@somedomain) failed\n");
	} or print 'not ';
print "ok $t { remove }\n";
print $@ if $@;

# now verify the contents of the file again
$t++;
my $RU2;
eval {
    $RU2 = RADIUS::UserFile->new(File => $USERS_FILE, Debug => 0)
     or die("test $t: couldn't reload $USERS_FILE\n");
    join(' ', sort @{$RU2->usernames})
     eq join(' ', sort (@USERS, 'areallylonguser@somedomain'))
     or die("test $t: just added a user and can't find it now\n".
            'only have: '. join(' ', @{$RU2->usernames}). "\n");
} or print 'not ';
print "ok $t { verify add }\n";
print $@ if $@;
