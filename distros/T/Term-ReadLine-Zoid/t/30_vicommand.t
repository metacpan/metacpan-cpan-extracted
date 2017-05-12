
use strict;

BEGIN {
	require Test::More;
	use Term::ReadLine::Zoid::ViCommand;
	Test::More->import( tests => 18 + scalar @Term::ReadLine::Zoid::ViCommand::vi_motions - 6 );
}

my $t;
$t = Term::ReadLine::Zoid->new('test');
$t->{config}{bell} = sub {}; # Else the "\cG" fucks up test harness

# test routines
sub test_reset {
	$_[0]->reset();
	$_[0]->switch_mode('command');
	$_[0]->{lines} = [ 'duss ja', 'nou ja', 'test 123' ]; # 3 X 7,6,8
	$_[0]->{pos} = [5, 1];
}

# escape
test_reset $t;
$t->{vi_command} = '!**^sgf@#$34342dfs#$fsg#$4g^$^)*!fgd';
$t->press("\e");
ok $t->{vi_command} eq '', 'escape reset';

# h, l/space (left, right)
test_reset $t;
$t->press('4h');
is_deeply $t->{pos}, [1,1], 'h 1';
ok $t->self_insert('h'), 'h 2';
$t->{pos} = [0,0];
ok !$t->self_insert('h'), 'h 3';
$t->press('7 ');
is_deeply $t->{pos}, [7,0], 'space';
ok $t->self_insert('l'), 'l 1';
$t->{pos} = [8,2];
ok !$t->self_insert('l'), 'l 2';

# control-z

# i
# I
# a
# A
# m
# M
# R
# #
# =
# \
# *

# [I<count>] @ I<char>
$t->reset;
$t->{lines} = [ 'test123 123' ];
$t->{pos} = [1,0];
$t->{config}{aliases}{_A} = "\elldl";
$t->press('@A');
ok $t->{lines}[0] eq 'tet123 123', 'macro 1';
$t->press('3@A');
ok $t->{lines}[0] eq 'tet2 23', 'macro 2';

# [I<count>] ~
$t->reset;
$t->{lines} = [ 'nou ja duss jaa' ];
$t->{pos} = [0,0];
$t->press('~3l~2l~4l~');
ok $t->{lines}[0] eq 'Nou Ja Duss Jaa', '~ 1';
$t->press('015~');
ok $t->{lines}[0] eq 'nOU jA dUSS jAA', '~ 2';

# [I<count>] .
$t->reset;
$t->{lines} = [ 'nou ja duss jaa' ];
$t->{pos} = [11,0];
$t->press('2dh');
ok $t->{lines}[0] eq 'nou ja du jaa', '3dh';
$t->press('..');
ok $t->{lines}[0] eq 'nou j jaa', '..';
$t->press('4.');
ok $t->{lines}[0] eq 'n jaa', '4.';

# v
# [I<count>] w
# [I<count>] W
# [I<count>] e 
# [I<count>] E 
# [I<count>] b 
# [I<count>] B 
# ^
# $
# 0
# [I<count>] |

# [I<count>] f I<char>
# [I<count>] F I<char>
# [I<count>] t I<char>
# [I<count>] T I<char>

#TODO multiline the fFtT function
#test_reset $t;
#$t->press("\e");
#for ( ['fs', []], ['Fs', []], ['ts', []], ['Ts', []] ) {
#	test_reset $t;
#	$t->press($$_[0]);
#	print "# $$_[0]: $t->{pos}[0], $t->{pos}[1]\n";
#	is_deeply $t->{pos}, $$_[1], $$_[0];
#}

# [I<count>] ;
# [I<count>] ,
# [I<count>] c I<motion>
# C
# S

# [I<count>] r I<char>
$t->reset;
$t->{lines} = ['gdgfgfffghg'];
$t->{pos} = [2,0];
$t->press('rall3ra');
ok $t->{lines}[0] eq 'gdafaaafghg', 'r';

# [I<count>] _
$t->reset;
$t->{history} = ['word1 word2 word3'];
$t->press("_\el2_\el1_");
ok $t->{lines}[0] eq ' word3 word2 word1', '_';

# [I<count>] x
# [I<count>] X

# [I<count>] d I<motion>
# D

# lines have to change, the exact change isn't tested here,
# thats up to the motion test

test_reset $t;
$t->press("\e");
my $lines = join '', @{$$t{lines}};
#TODO multiline the fFtT function
#$t->press('fs'); # for repeat movements
for my $k (@Term::ReadLine::Zoid::ViCommand::vi_motions, 'd') {
	test_reset $t;
#	print STDERR "# pos: $$t{pos}[0],$$t{pos}[1] lines: ".join( "\n", @{$$t{lines}})."\n";
	my $p = 'd'.$k;
	next if grep {$_ eq $k} qw/f F t T ;/, ',';
#	$p .= 's' if grep {$_ eq $k} qw/f F t T/;
	$p = '1'.$p if $k eq '|';
#	print STDERR "# pressing $p\n";
	$t->press($p);
#	print STDERR "# pos: $$t{pos}[0],$$t{pos}[1] lines: ".join( "\n", @{$$t{lines}})."\n";
	ok length( join( '', @{$$t{lines}}) ) < length $lines, $p;
}

test_reset $t;
$t->press('D');
ok length( join( '', @{$$t{lines}}) ) < length $lines, 'D';

# [I<count>] y I<motion>
# Y
# [I<count>] p
# [I<count>] P
# u
# U
# [I<count>] k
# [I<count>] -
# [I<count>] j
# [I<count>] +
# [I<number>] G
# control-a
# control-x
# TODO
# :
# B<set> [I<+o>|I<-o>] [I<option>=I<value>]
# B<ascii>
# B<testchr>
# B<bindchr> I<chr>=I<keyname>
# B<!>, B<shell> I<shellcode>
# B<eval> I<perlcode>
# B<alias> I<char>=I<macro>
# aliases
# editor
# shell
