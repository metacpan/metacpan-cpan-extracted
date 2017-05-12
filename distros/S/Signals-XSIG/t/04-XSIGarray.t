package PackageOne;
use Signals::XSIG;
use t::SignalHandlerTest;
use Test::More tests => 42;
use Config;
use strict;
use warnings;

# are signal handlers registered correctly when we
# set $XSIG{signal} or @{$XSIG{signal}} directly?

sub foo { 42 }

################### valid signal name ###############

my $sig = appropriate_signals();

ok(tied @{$XSIG{$sig}}, "\@{\$XSIG{$sig}} is tied");

$XSIG{$sig} = [];
ok(!defined $XSIG{$sig}[0], "\$XSIG{$sig} empty after clear");

$XSIG{$sig} = ['foo'];
ok($XSIG{$sig}[0] eq 'main::foo', 'list assignment is qualified');
ok(!defined $XSIG{$sig}[1]);

if ($Config{PERL_VERSION} != 8) {
  $XSIG{$sig} = ['foo',*bar,\&foo];
  ok($XSIG{$sig}[1] eq *PackageOne::bar, 'glob assignment is qualified');
} else {
  $XSIG{$sig} = ['foo',\&PackageOne::bar,\&foo];
  ok($XSIG{$sig}[1] eq \&PackageOne::bar);
}
ok($XSIG{$sig}[0] eq 'main::foo', 'scalar assignment is qualified');
ok($XSIG{$sig}[2] eq \&foo, 'coderef assignment ok');

ok(tied @{$XSIG{$sig}}, "\@{\$XSIG{$sig}} is still tied");

# also try/test $XSIG{sig} = scalar as synonym for  $XSIG{$sig} = [func] ?

################### alias signal name ###############

my $alias;
($sig,$alias) = alias_pair();

ok(tied @{$XSIG{$sig}}, "\@{\$XSIG{$sig}} is tied (main)");
ok(tied @{$XSIG{$alias}}, "\@{\$XSIG{$sig}} is tied (alias)");

$XSIG{$sig} = ['bar'];
ok($XSIG{$sig}[0] eq 'main::bar', 'main: assignment to main is qualified');
ok($XSIG{$alias}[0] eq 'main::bar', 'alias: assignment to main is qualified');

if ($Config{PERL_VERSION} != 8) {
  $XSIG{$alias} = ['foo', *bar, \&foo];
  ok($XSIG{$sig}[1] eq *PackageOne::bar);
  ok($XSIG{$alias}[1] eq *PackageOne::bar);
} else {
  $XSIG{$alias} = ['foo', \&bar, \&foo];
  ok($XSIG{$sig}[1] eq \&PackageOne::bar,
     'main: func assign to alias is qualified');
  ok($XSIG{$alias}[1] eq \&PackageOne::bar,
     'alias: func assign to alias is qualified');
}
ok($XSIG{$sig}[0] eq 'main::foo', 'main: scalar assign to alias is qualified');
ok($XSIG{$alias}[0] eq 'main::foo','alias:scalar assign to alias is qualified');
ok(ref $XSIG{$alias}[2] eq 'CODE');
ok($XSIG{$sig}[2] eq \&foo,'main: func assignment to alias is correct');
ok($XSIG{$sig}[2] eq $XSIG{$alias}[2],'main, alias have same func assignment');

ok(tied @{$XSIG{$sig}}, "\@{\$XSIG{$sig}} is still tied (main)");
ok(tied @{$XSIG{$alias}}, "\@{\$XSIG{$alias}} is still tied (main)");

################### bogus signal name ###############

$sig = 'qwerty';
ok(!tied $XSIG{$sig}, 'no scalar tie for bogus signal');
ok(!tied @{$XSIG{$sig}}, 'no array tie for bogus signal');

$XSIG{$sig} = ['foo'];
ok(ref $XSIG{$sig} eq 'ARRAY', 'assign list to bogus signal');
ok($XSIG{$sig}[0] eq 'foo', 'retrieve list assignment to bogus signal');

$XSIG{$sig} = 'oof';
ok(ref $XSIG{$sig} eq '', 'assign scalar to bogus signal');
ok($XSIG{$sig} eq 'oof', 'retrieve scalar assignment to bogus signal');

#####################################################

$sig = appropriate_signals();

$XSIG{$sig} = [];
ok(!defined($XSIG{$sig}[0]), '$XSIG{$sig} is clear ');
push @{$XSIG{$sig}}, \&ook;
ok(!defined($XSIG{$sig}[0]), 'push does not set default handler');
ok($XSIG{$sig}[1] eq \&ook, 'push sets posthandler');

ok(!defined $XSIG{$sig}[-1], 'prehandler not set');
my $u = pop @{$XSIG{$sig}};
ok($u eq \&ook, 'pop retrieves pushed value');
ok(!defined($XSIG{$sig}[0]), 'still no default handler');
ok(!defined($XSIG{$sig}[1]), 'pop removes signal post-handler');

push @{$XSIG{$sig}}, '::posthandler';
ok(defined $XSIG{$sig}[1], "push operation extended \@{\$XSIG{$sig}}");
$u = shift @{$XSIG{$sig}};
ok(!defined($u), 'shift does not access signal post-handler');
ok(defined($XSIG{$sig}[1]),'post-handler remains after shift');
$XSIG{$sig}[1] = undef;

unshift @{$XSIG{$sig}}, '::prehandler2', '::prehandler';
ok($XSIG{$sig}[-1] eq '::prehandler', 'unshift installs pre-handler');
$u = pop @{$XSIG{$sig}};
ok(!defined($u) && $XSIG{$sig}[-1] eq '::prehandler',
   'pop does not remove pre-handler');
$u = shift @{$XSIG{$sig}};
ok($u eq '::prehandler2' && !defined($XSIG{$sig}[-2]),
   'shift removes pre-handler');

$XSIG{$sig} = [];
$XSIG{$sig}[0] = '::default';
$u = pop @{$XSIG{$sig}};
ok(!defined($u), 'pop does not remove default handler');
$XSIG{$sig}[0] = '::default';
$u = shift @{$XSIG{$sig}};
ok(!defined($u), 'shift does not remove default handler');

# array operators. 4 spec:
#    splice => no result
