use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Perl::AtEndOfScope') };

my $v=1;

{
  my $restore=Perl::AtEndOfScope->new( sub{$v=shift}, $v );
  $v++;
  ok $v==2, '$v set';
}

ok $v==1, '$v reset';

eval {
  my $restore=Perl::AtEndOfScope->new( sub{$v=shift}, $v );
  $v++;
  die;
};

ok $v==1, '$v reset after die';

eval {
  my $restore=Perl::AtEndOfScope->new( sub{$v=shift}, $v );
  $v++;
  my $i=0;
  $i=1/$i;
};

ok $v==1, '$v reset after 1/0';

{
  package e;
  sub new {my $class=shift; bless [@_]=>$class}
}

my $inner=e->new('inner exception');
my $outer=e->new('outer exception');

eval {
  my $restore=Perl::AtEndOfScope->new( sub{$v=shift; die $inner}, $v );
  $v++;
  die $outer;
};

ok $v==1, '$v reset after nested exception';
ok $@==$outer, '$@ is outer exception';
ok $Perl::AtEndOfScope::EXC==$inner, '$EXC is inner exception';

eval {
  my $restore=Perl::AtEndOfScope->new( sub{$v=shift; die $inner}, $v );
  $v++;
};

ok $v==1, '$v reset after inner exception';
ok $@ eq '', '$@ empty (only inner exception)';
ok $Perl::AtEndOfScope::EXC==$inner, '$EXC is inner exception';

# Local Variables: #
# mode: cperl #
# End: #
