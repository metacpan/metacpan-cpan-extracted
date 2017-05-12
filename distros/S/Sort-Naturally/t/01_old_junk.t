# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# Time-stamp: "2004-12-29 18:29:18 AST"

use strict;
use Test;
# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 21 }

ok(1);

#sub Sort::Naturally::DEBUG () {0}
use Sort::Naturally;

print "# Perl v$], Sort::Naturally v$Sort::Naturally::VERSION\n#\n";

sub shuffle {
  my @out;
  while(@_) { push @out, splice @_, rand(@_), 1 };
  return @out
}

my $ok1 = '9x 14 foo fooa foolio Foolio foo12 foo12a Foo12a foo12z foo13a';
my $ok2 = '9x 14 foo fooa Foolio foolio foo12 Foo12a foo12a foo12z foo13a';

for(1 .. 10 ){
  my @x = shuffle
   qw(
    foo12a foo12z foo13a foo 14 9x foo12 fooa foolio Foolio Foo12a
   )
  ;

  print "#\n# In: <@x>\n";
  print "# nsort ...\n";
  my @y =  nsort(map $_, @x);
  print "# ncmp ...\n";
  my @z =  sort {&ncmp($a,$b)}
    # map $_,
    @x
  ;
  #print "OK, <@x> => <@y>\n";
  print(
   "@y" eq "@z"
     ? scalar(ok(1), "#  Good, eq") : scalar(ok(0), "#  Feh, NE!\n< <@x>"),
   "\n#  <@y>\n# :<@z>\n"
  );
  if("@y" eq $ok1) {
    ok 1;
    print "# sorts happily as ok1 <$ok1>\n";
  } elsif("@y" eq $ok2) {
    ok 1;
    print "# sorts happily as ok2 <$ok2>\n";
  } else {
    ok 0;
    print "# sorts unhappily, not as <$ok1> nor as <$ok2>\n";
  }
}
