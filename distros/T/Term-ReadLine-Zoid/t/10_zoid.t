use strict;
use Test::More tests => 48;
use Term::ReadLine::Zoid;

$|++;

# C<new($appname, $IN, $OUT)>

$ENV{PERL_RL} = 'Zoid';
if (eval 'use Term::ReadLine; 1') {
	my $t = Term::ReadLine->new('test');
	ok $t->ReadLine eq 'Term::ReadLine::Zoid', 'rl:zoid loaded';
}
else { ok 1, 'skip Term::ReadLine NOT installed, this *might* be a problem' }

my $t = Term::ReadLine::Zoid->new('test');
$t->{config}{bell} = sub {}; # Else the "\cG" fucks up test harness

#use Data::Dumper; print Dumper $t;

# test routines
sub test_reset {
	$_[0]->reset();
	$_[0]->{lines} = [ 'duss ja', 'nou ja', 'test 123' ]; # 3 X 7,6,8
	$_[0]->{pos} = [5, 1];
}

print "# delete &&  backspace\n";
test_reset $t;
$t->delete_char;
$t->delete_char;
ok $t->{lines}[1] eq 'nou jtest 123', 'delete \n';

test_reset $t;
$t->press("\c?\c?\c?");
ok $t->{lines}[1] eq 'noa', 'backspace';

print "# control-U\n";
test_reset $t;
$t->press("\cU");
is_deeply $t->{lines}, [''], '^U';

print "# left && right\n";
test_reset $t;
ok $t->forward_char, 'right 1';
ok $t->forward_char, 'right 2';
is_deeply $t->{pos}, [0,2], 'pos 1';
ok $t->backward_char, 'left 1';
is_deeply $t->{pos}, [6,1], 'pos 2';
$t->backward_char for 1 .. 14; # 6 + \n + 7
is_deeply $t->{pos}, [0,0], 'pos 3';
ok ! $t->backward_char(), 'left 2';
$t->{pos} = [8, 2];
ok ! $t->forward_char(), 'right 3';

print "# up && down\n";
$t->{lines} = [ 'entry0' ];
$t->{history} = ['entry1', "entry2\ntest123", 'entry3'];
$t->previous_history;
$t->previous_history;
is_deeply $t->{lines}, ['entry2', 'test123'], 'hist 1';
$t->previous_history;
ok $t->{lines}[0] eq 'entry3', 'hist 2';
ok ! $t->previous_history, 'hist 3';
$t->next_history;
$t->next_history;
ok $t->{lines}[0] eq 'entry1', 'hist 4';
$t->next_history;
ok $t->{lines}[0] eq 'entry0', 'hist 5';
ok ! $t->next_history, 'hist 6';

print "# control-W\n";
$t->{lines} = ['word1 word2 word3'];
$t->{pos} = [13, 0];
$t->press("\cW");
ok $t->{lines}[0] eq 'word1 word2 ord3', '^W 1';
$t->press("\cW");
ok $t->{lines}[0] eq 'word1 ord3', '^W 2';

print "# control-V\n";
@$t{'pos','lines'} = ([0,0], ['']);
push @Term::ReadLine::Zoid::Base::_key_buffer, "\cV", "\cW";
$t->do_key();
ok $t->{lines}[0] eq "\cW", '^V';

print "# save and restore\n";
test_reset $t;
my $save = $t->save();
$t->{lines} = ['duss', 'ja'];
$t->{pos} = [333,444];
$t->restore($save);
is_deeply [[ 'duss ja', 'nou ja', 'test 123' ], [5, 1]], [@$t{'lines', 'pos'}], 'save n restore';

print "# escape\n";
$t->press("\e");
ok ref($t) eq 'Term::ReadLine::Zoid::ViCommand', 'escape to command mode';

if (eval 'Term::ReadKey::GetTerminalSize() and 1') {
	print "# readline && continue\n";
	my $prompt = "# readline() test !> "; # Test::Harness might choke without the "#"
	$t->unread_key("test 1 2 3\n");
	ok $t->readline($prompt) eq 'test 1 2 3', 'readline \n';

	$t->unread_key("test\cH\cH\cH\cH\cD");
	ok ! defined( $t->readline($prompt) ), 'readline \cD';

	$t->unread_key("test 1 2 3\cC");
	ok $t->readline($prompt) eq '', 'readline \cC';

	$t->Attribs()->{PS2} = "# ps2> ";
	$t->unread_key("test 1 2 3\n");
	$t->readline($prompt);
	$t->unread_key("ok\n");
	ok $t->continue() eq "test 1 2 3\nok", 'readline continue';
}
else {
	ok 1, 'skip - No TermSize, cross your fingers' for 1 .. 4;
}

print "# bindkey() and bindchr()\n";
$t->switch_mode();

test_reset $t;
$t->bindchr('^B', 'backspace');
$t->press("\cB\cB\cB");
ok $t->{lines}[1] eq 'noa', 'bindchr';

test_reset $t;
$t->bindkey('^Q', sub { $t->press('abc') });
$t->press("\cQ");
ok $t->{lines}[1] eq 'nou jabca', 'bindkey';

test_reset $t;
$t->bindkey('backspace', sub { $_[0]->press("\cQ") });
$t->press("\cB");
ok $t->{lines}[1] eq 'nou jabca', 'another bindkey';

test_reset $t;
$t->bindkey('^Q', 'backward_delete_char');
$t->press("\cQ\cQ\cQ");
ok $t->{lines}[1] eq 'noa', 'scalar bindkey';

print "# substring()\n";
test_reset $t;
$t->{lines} = ['test 123, dit is test data'] ;

$t->substring('dus ', [17,0]);
ok( $$t{lines}[0] eq 'test 123, dit is dus test data', 'simple insert');

$t->substring("\nduss ", [30,0]);
$t->substring('ja', [5,1]);

is_deeply(
	$$t{lines},
	['test 123, dit is dus test data', 'duss ja'],
	'more inserts'
);

my $re = $t->substring(undef, [21,0], [30,0]);
ok( ($re eq 'test data') && ($$t{lines}[0] eq 'test 123, dit is dus test data'), 'copy');

$re = $t->substring('een test', [21,0], [30,0]);
ok( ($re eq 'test data') && ($$t{lines}[0] eq 'test 123, dit is dus een test'), 'simple replace');

$re = $t->substring(",\ntest 123, test 123 .. ok", [29,0], [4,1]);
is_deeply(
	[$re, $$t{lines}],
	["\nduss", ['test 123, dit is dus een test,', 'test 123, test 123 .. ok ja'] ],
	'multiline replace');

push @{$$t{lines}}, '?';
$re = $t->substring('', [27,1], [0,2]);
ok( ($re eq "\n") && ($$t{lines}[1] eq 'test 123, test 123 .. ok ja?'), 'delete \n');

$t->{lines} = ['test 123'];
$t->substring(" duss\n", [8,0]);
is_deeply $t->{lines}, ['test 123 duss', ''], 'insert empty line';

print "# up & down -- very simple regression test\n";

$$t{lines} = [
	'test 123, dit is dus een test',
	'test 123, test 123 .. ok ja?',
	'test 123'
];
$$t{pos} = [5, 0];

ok ! $t->backward_line, 'up 1';
ok $t->forward_line, 'down 1';
ok $t->forward_line, 'down 2';
is_deeply $t->{pos}, [5, 2], 'pos 1';
ok ! $t->forward_line, 'down 3';
ok ! $t->forward_line, 'down 4';
ok $t->backward_line, 'up 2';
ok $t->backward_line, 'up 3';
ok ! $t->backward_line, 'up 4';
is_deeply $t->{pos}, [5, 0], 'pos 2';
