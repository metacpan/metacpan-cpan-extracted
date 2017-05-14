#!/usr/local/bin/perl -Tw

use strict;
use lib qw(blib/lib);
use ShellScript::Env;


################
print "1..6\n";

# set up the test variable
my $test = new ShellScript::Env('/usr/local');
$test->set('MAIL', '/var/spool/mail/$USER');
$test->set('PAGER', 'less');

################
# Test 1, check if set works in Bourne Shell
&check($test->sh(), <<'EXPECT'
MAIL=/var/spool/mail/$USER
PAGER=less
export MAIL PAGER
EXPECT
);

################
# Test 2, check if set works in C Shell
&check($test->csh(), <<'EXPECT'
setenv MAIL /var/spool/mail/$USER
setenv PAGER less
EXPECT
);

# Add path
$test->set_path('PATH', 'bin', '$PATH');

################
# Test 3, lets put in something with a path in C Shell
&check($test->csh(), <<'EXPECT'
setenv MAIL /var/spool/mail/$USER
setenv PAGER less
set path = (/usr/local/bin $path)
EXPECT
);

################
# Test 4, same with Bourne Shell
&check($test->sh(), <<'EXPECT'
MAIL=/var/spool/mail/$USER
PAGER=less
PATH=/usr/local/bin:$PATH
export MAIL PAGER PATH
EXPECT
);

# Make it so the script will pipe things through utok.
$test->{'utok'}->{'PATH'} = 1;

################
# Test 5, turn utok on and try Bourne Shell
&check($test->sh(), <<'EXPECT'
MAIL=/var/spool/mail/$USER
PAGER=less
PATH=`utok /usr/local/bin:$PATH`
export MAIL PAGER PATH
EXPECT
);

################
# Test 6, and C Shell
&check($test->csh(), <<'EXPECT'
setenv MAIL /var/spool/mail/$USER
setenv PAGER less
set path = (`utok -s ' ' /usr/local/bin $path`)
EXPECT
);


##################
# Little auxiliary function to save me typing.

sub check {
  my $got = shift;
  my $expect = shift;

  if ($got eq $expect) {
    print "ok\n";
  } else {
    print "not ok\n";
  }

  $got =~ s/^/\# /gm;
  print $got;
}
