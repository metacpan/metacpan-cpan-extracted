# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Access.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 1;
use Test::More qw(no_plan); # replace this later.

BEGIN { use_ok('SVN::Access') };

#########################
# make sure there are no leftovers from previous tests
unlink('svn_access_test.conf',
       'whitespace_at_end_test.conf',
       'line_cont.conf',
       'syntax-err.conf',
       'expn.conf',
       'undef.conf');

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# create a new file.
my $acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
$acl->add_group('@folks', 'bob', 'ed', 'frank');

is(scalar($acl->group('folks')->members), 3, "Added new group to the object.");
$acl->add_resource('/', '@folks', 'rw');
is($acl->resource('/')->authorized->{'@folks'}, 'rw', "Make sure we added these folks to the '/' resource.");
$acl->write_acl;

$acl->add_resource('/test');
is(ref($acl->resource('/test')), 'SVN::Access::Resource', "Do empty resources show up in the array?");
$acl->write_acl;

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
is(ref($acl->resource('/test')), 'SVN::Access::Resource', "Do empty resources show up in the array after re-parsing the file?");

$acl->add_resource('repo:/something with spaces', mike => 'rw');

$acl->add_resource('/kagetest', 
    joey => 'rw',
    billy => 'r',
    sam => 'r',
);

$acl->resource('/kagetest')->authorize(
    judy => 'rw',
    phil => 'r',
    frank => '',
    wanda => 'r'
);

$acl->resource('/kagetest')->authorize(sammy => 'r', 2);

# add / remove aliases test
$acl->add_alias('mikey', 'uid=mgregorowicz,ou=people,dc=mg2,dc=org'); 
is($acl->alias('mikey'), 'uid=mgregorowicz,ou=people,dc=mg2,dc=org', "Making sure we can add an alias.");
$acl->remove_alias('mikey');
is($acl->alias('mikey'), undef, "Delete alias check.");

# putting the alias back after the roundtrip test
$acl->add_alias('mikey', 'uid=mgregorowicz,ou=people,dc=mg2,dc=org');

$acl->write_acl;

my $whitespace_at_end_test = <<EOF;
[aliases]
mikey = uid=mgregorowicz,ou=people,dc=mg2,dc=org

[groups]
folks = bob, ed, frank

[/]
\@folks = rw

[/test]

[repo:/something with spaces]
mike = rw

[/kagetest]
joey = rw
billy = r
sammy = r
sam = r
judy = rw
phil = r
frank = 
wanda = r
EOF

chomp($whitespace_at_end_test); # no newline here!
$whitespace_at_end_test .= "          "; # <- have some whitespace!
open(WSTEST, '>', 'whitespace_at_end_test.conf');
print WSTEST $whitespace_at_end_test;
close(WSTEST);
my $wstestacl = SVN::Access->new(acl_file => 'whitespace_at_end_test.conf');
is(scalar($wstestacl->group('folks')->members), 3, "Sanity checking our whitespace test.");
is($wstestacl->resource('/kagetest')->authorized->{wanda}, 'r', "Making sure there's no trailing whitespace after wanda's 'r' access.");

# cleanup whitespace check...
unlink('whitespace_at_end_test.conf');

my $test_contents = <<EOF;
[aliases]
mikey = uid=mgregorowicz,ou=people,dc=mg2,dc=org

[groups]
folks = bob, ed, frank

[/]
\@folks = rw

[/test]

[repo:/something with spaces]
mike = rw

[/kagetest]
joey = rw
billy = r
sammy = r
sam = r
judy = rw
phil = r
frank = 
wanda = r

EOF

my $actual_contents;
open(TEST_ACL, '<', 'svn_access_test.conf');
{
    local $/;
    $actual_contents = <TEST_ACL>;
}

is($actual_contents, $test_contents, "Making sure our output remains in-order.");

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
is(scalar($acl->group('folks')->members), 3, "Checking our group after the write-out.");
$acl->remove_group('folks');
is(defined($acl->groups), '', "Making sure groups is undefined when we delete the last one");

# Aliases added at Trent Fisher's request, tested here...
is($acl->aliases->{mikey}, 'uid=mgregorowicz,ou=people,dc=mg2,dc=org', "Does my alias still exist after round trip?");

# use the name => notation... (this broke when we introduced Tie::IxHash, fixed in 0.11)
$acl->add_resource(
    name => '/awesomeness',
    authorized => {
        mike => 'rw',
    }
);

# ... and make sure it was understood
is($acl->resource('/awesomeness')->authorized->{mike}, 'rw', 'was hash param understood?');

$acl->remove_resource('/awesomeness');

# instantiate object with 'authorized' as hashref.
my $resource = SVN::Access::Resource->new(name => '/awesomeness', 
    authorized => {
        mike => 'rw',
    },
);
push(@{$acl->{acl}->{resources}}, $resource);

is($acl->resource('/awesomeness')->authorized->{mike}, 'rw', 'sideloaded resource instantiated with hashref authorized');

# Jesse Thompson's verify_acl tests
$acl->add_resource('/new', '@doesntexist', 'rw');
eval {
    $acl->write_acl;
};
ok(defined($@), 'We encountered a fatal error when trying to write an erroneous ACL.');
# save future writes the grief
$acl->remove_resource('/new');

# little bit of testing for Matt Smith's new regex.
$acl->add_resource('my-repo:/test/path', 'mikey_g',  'rw');
is($acl->resource('my-repo:/test/path')->authorized->{mikey_g}, 'rw', 'Can we call up perms on the new path?');
$acl->remove_resource('/');

# Matt's regex is updated now.. we are allowed to have spaces in ACLs
$acl->add_resource('my-repo2:/this/that/the other/thing');
$acl->write_acl;

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
$acl->remove_resource('/test');
$acl->remove_resource('my-repo:/test/path');
$acl->remove_resource('/kagetest');
$acl->remove_resource('my-repo2:/this/that/the other/thing');
$acl->remove_resource('repo:/something with spaces');
$acl->remove_resource('/awesomeness');
$acl->remove_alias('mikey');

is(defined($acl->resources), '', "Making sure resources is undefined when we delete the last one");
$acl->write_acl;

# the config file should be empty now.. so lets clean up if it is
is((stat('svn_access_test.conf'))[7], 0, "Making sure our SVN ACL file is zero bytes, and unlinking.");
system("cat svn_access_test.conf");
unlink('svn_access_test.conf');

# test for line continuations and trailing comments
open(LTEST, '>', 'line_cont.conf');
print LTEST <<'CHUMBA';
[groups]
folks = bob, 
 ed,
	frank
missing=not
  
# the line above contains some whitespace
foo=bar # not allowed, baz
@tempt = incorrect
# see libsvn_subr/config_file.c:svn_config__parse_file()
[/]
@folks = rw

CHUMBA
#/];# (keep emacs perl-mode happy)
close(LTEST);

# load in default mode
$acl = SVN::Access->new(acl_file => 'line_cont.conf');
ok(defined($acl), "Make sure we can parse file with line continuations");
my @m = $acl->group('folks')->members;
is($#m, 2, "Make sure group has three members, via continuations");
is($m[2], "frank", "Make sure frank is at the end of the list");

# check the trailing comment
@m = $acl->group('foo')->members;
is($#m, 0, "Make sure group has 1 members due to trailing comment");
is($m[0], "bar", "make sure trailing comment was stripped");

# check the incorrect group
@m = $acl->group('tempt')->members;
is($#m, 0, "Make sure group with @ is renamed and has one member");
is($m[0], "incorrect", "Make sure that group has correct member");

# no reload in pedantic mode and make sure the @ got left on the group
$acl = SVN::Access->new(acl_file => 'line_cont.conf', pedantic => 1);
@m = $acl->group('@tempt')->members;
is($#m, 0, "Make sure group with @ has the name preserved (as svn allows)");
is($m[0], "incorrect", "Make sure group with @ has proper membership");

# check for trailing comment handling
@m = $acl->group('foo')->members;
is($#m, 1, "Make sure group has 2 members");
is($m[0], "bar # not allowed", "make sure comment is appended as svn does");
is($m[1], "baz", "make sure next entry is right");

# check for handling lines with whitespace... they should not get treated as
# line continuations
is(ref $acl->group('missing'), "SVN::Access::Group",
   "Group before bogus line continuation should be present");

unlink('line_cont.conf');

# tests for syntax errors
open(STEST, '>', 'syntax-err.conf');
print STEST <<'CHUMBA';
[groups]
broken_line = one,
two

[]
ugh = foo

[/]
broken_line = w
foo = r@foobar = rw

CHUMBA
#/];# (keep emacs perl-mode happy)
close(STEST);

# capture errors
my @errs;
$SIG{__WARN__} = sub { push @errs, @_; };

$acl = eval { SVN::Access->new(acl_file => 'syntax-err.conf'); };
ok(defined($acl), "Make sure we can parse file with syntax errors");
is($#errs, 2, "Make sure we got the right number of errors");
ok($errs[0] =~ /^Unrecognized line two\s*/, "Make sure we detected the broken line syntax error");
ok($errs[1] =~ /^Unrecognized line \[\]/, "Make sure we catch the bogus section divider");
ok($errs[2] =~ /^Invalid character in authz rule/, "Make sure we catch the syntax error in rw spec");

unlink('syntax-err.conf');

# tests for complex expansions
open(STEST, '>', 'expn.conf');
print STEST <<'CHUMBA';
[groups]
alicorn = &twilight
earth = applejack
unicorn = rarity
pony = @alicorn, @earth, @unicorn

[aliases]
twilight = twilight_sparkle

[/]
pony = rw

CHUMBA
#/];# (keep emacs perl-mode happy)
close(STEST);

$acl = eval { SVN::Access->new(acl_file => 'expn.conf'); };
ok(defined($acl), "Make sure we can parse complex file");
@g = $acl->group("pony")->members();
is($g[0], '@alicorn', "Make sure group returns groups unexpanded");
@g = $acl->resolve('@pony');
is($g[0], 'twilight_sparkle', 'Make sure resolve expands groups and aliases');

unlink('expn.conf');

# tests undefined groups and aliases
open(STEST, '>', 'undef.conf');
print STEST <<'CHUMBA';
[aliases]
right = correct
backwards = &forwards
forwards = backwards

[groups]
broken = one, two, three, &none, @nada, &right
outoforder = @working
working = yes

[/]
@zip = rw
&zilch = rw
@broken = rw
&right = rw

CHUMBA
#/];# (keep emacs perl-mode happy)
close(STEST);

@errs = ();
$acl = eval { SVN::Access->new(acl_file => 'undef.conf'); };
ok(defined($acl), "Make sure we can parse a file with errors");
is($#errs, -1, "the parser doesn't catch the errors");
@errs = split(/\n/, $acl->verify_acl);
is($#errs, 3, "Make sure we got the right number of verify errors");
ok($errs[0] =~ /'none', which is undefined/, "Make sure we catch the undefined alias in group defn");
ok($errs[1] =~ /'nada', which is undefined/, "Make sure we catch the undefined group in group defn");
ok($errs[2] =~ /'\@zip', which is undefined/, "Make sure we catch the undefined group in resource");
ok($errs[3] =~ /'\&zilch', which is undefined/, "Make sure we catch the undefined alias in resource");
unlink('undef.conf');

# prevent recursion loops
open(STEST, '>', 'loop.conf');
print STEST <<'CHUMBA';
[aliases]

[groups]
one = two, three, @four
four = five, six, @one

direct = @direct, foo

[/]
@one = r
@four = rw

CHUMBA
#/];# (keep emacs perl-mode happy)
close(STEST);

@errs = ();
$acl = eval { SVN::Access->new(acl_file => 'loop.conf'); };
ok(defined($acl), "Make sure we can parse a file with loops");
is($#errs, -1, "the parser doesn't catch the errors");

# verify doesn't check for loops... yet
@errs = split(/\n/, $acl->verify_acl);
is($#errs, 2, "Make sure we got the right number of verify errors");

@errs = ();
my @g = $acl->resolve('@one');
is($#errs, 0, "One error from loop in group one");
ok($errs[0] =~ /^Error: group loop detected \@one/, "sanity checking error string content");

@errs = ();
@g = $acl->resolve('@four');
is($#errs, 0, "One error from loop in group four");
ok($errs[0] =~ /^Error: group loop detected \@four/, "sanity checking error string content");

@errs = ();
@g = $acl->resolve('@direct');
is($#errs, 0, "One error from loop in group direct");
ok($errs[0] =~ /^Error: group loop detected \@direct/, "sanity checking error string content");

unlink('loop.conf');

exit 0;
