# -*-CPerl-*-
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

use Mojo::ByteStream 'b';
use Scalar::Util 'weaken';

use Mojo::Promise::Role::Repeat;

my $promise_class = Mojo::Promise->with_roles('+Repeat');
ok(length($promise_class), 'with_roles works');

sub loop_test {
    my $start = shift;
    my $is_repeat_catch = shift;
    my $expect = shift;
    my $title = shift;
    my $repeat = $is_repeat_catch ? 'repeat_catch' : 'repeat';
    my $out;
    my $loop_body = sub {
	my $n = 0+shift;
	$_->(12) if $n <= 0;
	$out .= "($n)";
	return $promise_class->new(sub {$_[0]->(2)}) if $n == 11;
	return $promise_class->new(sub {$_[1]->(3)}) if $n == 14;
	die b(13) if $n == 7;
	if ($is_repeat_catch) {
	    --$n; die b($n);
	}
	else {
	    return $n-1;
	}
    };
    for my $clobj ($promise_class, $promise_class->new) {
	my $p;
	$out = '';
	$clobj
	  ->$repeat( $start, $loop_body )
	  ->tap( sub { weaken($p = $_); })
	  ->then( sub { $out .= shift; },
		  sub { $out .= '!'.shift; })
	  ->tap( sub { unless (ref $clobj) { } elsif ($is_repeat_catch) { $clobj->reject(); } else { $clobj->resolve(); }})
	  ->wait;
	ok(!defined $p, "gc happened for $start");
	is ($out, $expect, $title);
    }
}

loop_test( 5,0, "(5)(4)(3)(2)(1)12", 'break');
loop_test( 9,0, "(9)(8)(7)!13", 'die');
loop_test(12,0, "(12)(11)(2)(1)12", 'presolved');
loop_test(15,0, "(15)(14)!3", 'prejected');
loop_test(-1,0, "12", 'first iteration');
loop_test( 5,1, "(5)(4)(3)(2)(1)!12", 'break');
loop_test( 9,1, "(9)(8)(7)(13)(12)(11)2", 'die');
loop_test(12,1, "(12)(11)2", 'presolved');
loop_test(15,1, "(15)(14)(3)(2)(1)!12", 'prejected');
loop_test(-1,1, "!12", 'first iteration');

sub break_test {
    my @s = split '',shift;
    my ($repeat1,$repeat2)
      = map { $_ ? 'repeat_catch' : 'repeat' } (shift,shift);
    my $out = '';
    my $die = sub { die b("noBC:$_[0]");};
    my $do = sub {
	die b("end: $out") unless @s>=2;
	my ($o,$a) = splice(@s,0,2);
	if ($o =~ m/[PF]/) {
	    my $rejolv = $o eq 'F' ? 'reject' : 'resolve';
	    $o = $a;
	    $a = $promise_class->new;
	    die b("end2: $out") unless @s;
	    my $a1 = shift @s;
	    $a->ioloop->next_tick(sub {$a->$rejolv($a1)});
	}
	($_[0] // $die)->($a) if $o eq 'B';
	($_[1] // $die)->($a) if $o eq 'C';
	die ref $a ? $a : b($a) if $o eq 'D';
	return $a;
    };
    $do->()->repeat(
	sub {
	    my $B = $_;
	    $out .= shift;
	    $out .= 'o';
	    $do->($B) eq 'S'
	      ? $do->($B)
	      : $do->($B)->then(
		  sub {
		      $out .= shift;
		      $out .= 't';
		      $do->($B);
		      $out .= 'T';
		      $do->($B);
		  }
	      )->repeat(
		  sub {
		      my $C = $_;
		      $out .= shift;
		      $out .= 'r';
		      $do->($B,$C);
		      $out .= 'R';
		      $do->($B,$C);
		  }
	      )->then(
		  sub {
		      $out .= shift;
		      $out .= 'u';
		      $do->($B);
		      $out .= 'U';
		      $do->($B);
		  },
		  sub {
		      $out .= shift;
		      $out .= 'e';
		      $do->($B);
		      $out .= 'E';
		      $do->($B);
		  }
	      );
	}
    )->then(
	sub { $out .= shift; $out .= 'W'; },
	sub { $out .= shift; $out .= 'L'; }
    )->wait;
    return $out;
}
is(break_test("PR1RSRxRIPR2R3R4R5R6R7R6C8R9R0B!"),
   "1oxo2tT4rR6rR6r8uU0o!W");
is(break_test("PR1RIPR2R3R4R5R6R7R6C8R9R0B!"),
   "1o2tT4rR6rR6r8uU0o!W");
is(break_test("PR1RIPR2R3R4R5R6R7R6FC8R9R0B!"),
   "1o2tT4rR6rR6r8eE0o!W");
is(break_test("PR1RSRxRIPR2R3R4B!"),
   "1oxo2tT4r!W");
is(break_test("PR1RIPR2R3R4B!"),
   "1o2tT4r!W");
is(break_test("PR1RIPR2R3R4FB!"),
   "1o2tT4r!L");
is(break_test("PR1RSRxRIPR2R3R4R5R6R7R6C8R9R0B!",1),
   "1oxo2tT4rR6rR6r8uU0o!W");
is(break_test("PR1RSRxRIPR2R3R4R5R6R7R6C8R9R0B!",0,1),
   "1oxo2tT4rR6rR6r8uU0o!W");

done_testing();
