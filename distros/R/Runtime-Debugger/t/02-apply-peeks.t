#!perl

package MyTest;

use 5.006;
use strict;
use Test::More tests => 3246;
use Runtime::Debugger;
use feature qw( say );

# Can enable for more outout when debugging.
$ENV{RUNTIME_DEBUGGER_DEBUG} = 0;

{

    package A;
    sub get { "got method" }
}

sub run_suite {
    $Term::ReadLine::Gnu::has_been_initialized = 0;

    my $s  = 777;
    my $ar = [ 1, 2 ];
    my $hr = { a => 1, b => 2 };
    my %h  = ( a => 1, b => 2 );
    my @a  = ( 1, 2 );
    my $o  = bless { cat => 5 }, "A";

    my $repl = Runtime::Debugger->_init;

    my @cases = (

        # Scalar.
        {
            name     => "Print scalar",
            input    => 'p $s',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\$s)}}',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "Get scalar",
            input    => '$s',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$s)}}',
                eval_result => 777,
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "Set scalar",
            input    => '$s = 555',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$s)}} = 555',
                eval_result => 555,
                vars_after  => sub {
                    is $s, 555, shift;
                },
            },
        },
        {
            name     => "Get scalar again",
            input    => '$s',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$s)}}',
                eval_result => 555,
                vars_after  => sub {
                    is $s, 555, shift;
                },
            },
            cleanup => sub {
                $s = 777;
            },
        },

        # Array reference.
        {
            name     => "Print array reference",
            input    => 'p $ar->[1]',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Get array reference",
            input    => '$ar->[1]',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Set array reference",
            input    => '$ar->[1] = "my_ar_1"',
            expected => {
                apply_peeks =>
                  '${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1] = "my_ar_1"',
                eval_result => "my_ar_1",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 'my_ar_1' ], shift;
                },
            },
        },
        {
            name     => "Get array reference again",
            input    => '$ar->[1]',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]',
                eval_result => "my_ar_1",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 'my_ar_1' ], shift;
                },
            },
            cleanup => sub {
                $ar->[1] = 2;
            },
        },

        # Hash reference.
        {
            name     => "Print hash reference",
            input    => 'p $hr->{b}',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Get hash reference",
            input    => '$hr->{b}',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Set hash reference",
            input    => '$hr->{b} = "my_hr_b"',
            expected => {
                apply_peeks =>
                  '${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b} = "my_hr_b"',
                eval_result => "my_hr_b",
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 'my_hr_b' }, shift;
                },
            },
        },
        {
            name     => "Get hash reference again",
            input    => '$hr->{b}',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}',
                eval_result => "my_hr_b",
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 'my_hr_b' }, shift;
                },
            },
            cleanup => sub {
                $hr->{b} = 2;
            },
        },

        # Object.
        {
            name     => "Print object",
            input    => 'p $o->{cat}',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Get object",
            input    => '$o->{cat}',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}',
                eval_result => 5,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Set object",
            input    => '$o->{cat} = "my_o_cat"',
            expected => {
                apply_peeks =>
                  '${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat} = "my_o_cat"',
                eval_result => "my_o_cat",
                vars_after  => sub {
                    is $o->{cat}, 'my_o_cat', shift;
                },
            },
        },
        {
            name     => "Get object again",
            input    => '$o->{cat}',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}',
                eval_result => "my_o_cat",
                vars_after  => sub {
                    is $o->{cat}, 'my_o_cat', shift;
                },
            },
            cleanup => sub {
                $o->{cat} = 5;
            },
        },
        {
            name     => "Print object method",
            input    => 'p $o->get',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\$o)}}->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Print object method (paren)",
            input    => 'p $o->get()',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\$o)}}->get()',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Get object method",
            input    => '$o->get',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$o)}}->get',
                eval_result => "got method",
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Get object method (paren)",
            input    => '$o->get()',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\$o)}}->get()',
                eval_result => "got method",
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },

        # Array.
        {
            name     => "Print array element",
            input    => 'p $a[1]',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Get array element",
            input    => '$a[1]',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Set array element",
            input    => '$a[1] = "my_a_1"',
            expected => {
                apply_peeks =>
                  '${$Runtime::Debugger::PEEKS{qq(\@a)}}[1] = "my_a_1"',
                eval_result => "my_a_1",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 'my_a_1' ], shift;
                },
            },
        },
        {
            name     => "Get array element again",
            input    => '$a[1]',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]',
                eval_result => "my_a_1",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 'my_a_1' ], shift;
                },
            },
            cleanup => sub {
                $a[1] = 2;
            },
        },
        {
            name     => "Print array",
            input    => 'p \@a',
            expected => {
                apply_peeks => 'p \@{$Runtime::Debugger::PEEKS{qq(\@a)}}',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Join array",
            input    => 'join " ", @a',
            expected => {
                apply_peeks =>
                  'join " ", @{$Runtime::Debugger::PEEKS{qq(\@a)}}',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },

        # Hash.
        {
            name     => "Print hash element",
            input    => 'p $h{b}',
            expected => {
                apply_peeks => 'p ${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Get hash element",
            input    => '$h{b}',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Set hash element",
            input    => '$h{b} = "my_h_b"',
            expected => {
                apply_peeks =>
                  '${$Runtime::Debugger::PEEKS{qq(\%h)}}{b} = "my_h_b"',
                eval_result => "my_h_b",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 'my_h_b' }, shift;
                },
            },
        },
        {
            name     => "Get hash element again",
            input    => '$h{b}',
            expected => {
                apply_peeks => '${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}',
                eval_result => "my_h_b",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 'my_h_b' }, shift;
                },
            },
            cleanup => sub {
                $h{b} = 2;
            },
        },
        {
            name     => "Get hash",
            input    => 'say for sort keys %h',
            expected => {
                apply_peeks =>
                  'say for sort keys %{$Runtime::Debugger::PEEKS{qq(\%h)}}',
                vars_after => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Join hash key",
            input    => 'join " ", sort keys %h',
            expected => {
                apply_peeks =>
                  'join " ", sort keys %{$Runtime::Debugger::PEEKS{qq(\%h)}}',
                eval_result => "a b",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: "
        {
            name     => "Double quoted scalar",
            input    => '"$s"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\$s)}}"',
                eval_result => "777",
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "Double quoted escaped scalar",
            input    => '"\$s"',
            expected => {
                apply_peeks => '"\$s"',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "Double quoted array ref",
            input    => '"$ar->[1]"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]"',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Double quoted hash ref",
            input    => '"$hr->{b}"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}"',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Double quoted object key",
            input    => '"$o->{cat}"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}"',
                eval_result => 5,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Double quoted object method",
            input    => '"$o->get"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\$o)}}->get"',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Double quoted scalar with fake method",
            input    => '"$s->get"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\$s)}}->get"',
                eval_result => "777->get",
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "Double quoted array",
            input    => '"@a"',
            expected => {
                apply_peeks => '"@{$Runtime::Debugger::PEEKS{qq(\@a)}}"',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Double quoted array escaped",
            input    => '"\@a"',
            expected => {
                apply_peeks => '"\@a"',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Double quotes array element",
            input    => '"$a[1]"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]"',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Double quotes array elements",
            input    => 'say "@a[1,2]"',
            expected => {
                apply_peeks =>
                  'say "@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]"',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Double quoted hash",
            input    => '"%h"',
            expected => {
                apply_peeks => '"%h"',
                eval_result => "%h",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Double quoted hash escaped",
            input    => '"\%h"',
            expected => {
                apply_peeks => '"\%h"',
                eval_result => "%h",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Double quoted hash key",
            input    => '"$h{b}"',
            expected => {
                apply_peeks => '"${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}"',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Double quoted hash keys",
            input    => '"@h{qw( a b )}"',
            expected => {
                apply_peeks =>
                  '"@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}"',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: '
        {
            name     => "Single quoted scalar",
            input    => q('$s'),
            expected => {
                apply_peeks => q('$s'),
                eval_result => q($s),
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "Single quoted escaped scalar",
            input    => q('\$s'),
            expected => {
                apply_peeks => q('\$s'),
                eval_result => q(\$s),
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "Single quoted array ref",
            input    => q('$ar->[1]'),
            expected => {
                apply_peeks => q('$ar->[1]'),
                eval_result => q($ar->[1]),
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Single quoted hash ref",
            input    => q('$hr->{b}'),
            expected => {
                apply_peeks => q('$hr->{b}'),
                eval_result => q($hr->{b}),
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Single quoted object key",
            input    => q('$o->{cat}'),
            expected => {
                apply_peeks => q('$o->{cat}'),
                eval_result => q($o->{cat}),
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Single quoted object method",
            input    => q('$o->get'),
            expected => {
                apply_peeks => q('$o->get'),
                eval_result => q($o->get),
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "Single quoted scalar with fake method",
            input    => q('$s->get'),
            expected => {
                apply_peeks => q('$s->get'),
                eval_result => q($s->get),
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "Single quoted array",
            input    => q('@a'),
            expected => {
                apply_peeks => q('@a'),
                eval_result => q(@a),
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Single quoted escaped array",
            input    => q('\@a'),
            expected => {
                apply_peeks => q('\@a'),
                eval_result => q(\@a),
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Single quotes array element",
            input    => q('$a[1]'),
            expected => {
                apply_peeks => q('$a[1]'),
                eval_result => q($a[1]),
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Single quotes array elements",
            input    => q('@a[1,2]'),
            expected => {
                apply_peeks => q('@a[1,2]'),
                eval_result => q(@a[1,2]),
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "Single quoted hash",
            input    => q('%h'),
            expected => {
                apply_peeks => q('%h'),
                eval_result => q(%h),
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Single quoted escaped hash",
            input    => q('\%h'),
            expected => {
                apply_peeks => q('\%h'),
                eval_result => q(\%h),
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Single quoted hash key",
            input    => q('$h{b}'),
            expected => {
                apply_peeks => q('$h{b}'),
                eval_result => q($h{b}),
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "Single quoted hash keys",
            input    => q('@h{qw( a b )}'),
            expected => {
                apply_peeks => q('@h{qw( a b )}'),
                eval_result => q(@h{qw( a b )}),
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qq - parens
        {
            name     => "qq parens scalar",
            input    => 'qq($s)',
            expected => {
                apply_peeks => 'qq(${$Runtime::Debugger::PEEKS{qq(\$s)}})',
                eval_result => "777",
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qq parens array ref",
            input    => 'qq($ar->[1])',
            expected => {
                apply_peeks =>
                  'qq(${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1])',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq parens hash ref",
            input    => 'qq($hr->{b})',
            expected => {
                apply_peeks =>
                  'qq(${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b})',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq parens object key",
            input    => 'qq($o->{cat})',
            expected => {
                apply_peeks =>
                  'qq(${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat})',
                eval_result => 5,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq parens object method",
            input    => 'qq($o->get)',
            expected => {
                apply_peeks => 'qq(${$Runtime::Debugger::PEEKS{qq(\$o)}}->get)',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq parens scalar with fake method",
            input    => 'qq($s->get)',
            expected => {
                apply_peeks => 'qq(${$Runtime::Debugger::PEEKS{qq(\$s)}}->get)',
                eval_result => "777->get",
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qq parens array",
            input    => 'qq(@a)',
            expected => {
                apply_peeks => 'qq(@{$Runtime::Debugger::PEEKS{qq(\@a)}})',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq parens array element",
            input    => 'qq($a[1])',
            expected => {
                apply_peeks => 'qq(${$Runtime::Debugger::PEEKS{qq(\@a)}}[1])',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq parens array elements",
            input    => 'say qq(@a[1,2])',
            expected => {
                apply_peeks =>
                  'say qq(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2])',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq parens hash",
            input    => 'qq(%h)',
            expected => {
                apply_peeks => 'qq(%h)',
                eval_result => "%h",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq parens hash key",
            input    => 'qq($h{b})',
            expected => {
                apply_peeks => 'qq(${$Runtime::Debugger::PEEKS{qq(\%h)}}{b})',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq parens hash keys",
            input    => 'qq(@h{qw( a b )})',
            expected => {
                apply_peeks =>
                  'qq(@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )})',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qq - curly
        {
            name     => "qq curly scalar",
            input    => 'qq{$s}',
            expected => {
                apply_peeks => 'qq{${$Runtime::Debugger::PEEKS{qq(\$s)}}}',
                eval_result => "777",
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qq curly array ref",
            input    => 'qq{$ar->[1]}',
            expected => {
                apply_peeks =>
                  'qq{${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]}',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq curly hash ref",
            input    => 'qq{$hr->{b}}',
            expected => {
                apply_peeks =>
                  'qq{${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}}',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq curly object key",
            input    => 'qq{$o->{cat}}',
            expected => {
                apply_peeks =>
                  'qq{${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}}',
                eval_result => 5,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq curly object method",
            input    => 'qq{$o->get}',
            expected => {
                apply_peeks => 'qq{${$Runtime::Debugger::PEEKS{qq(\$o)}}->get}',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq curly scalar with fake method",
            input    => 'qq{$s->get}',
            expected => {
                apply_peeks => 'qq{${$Runtime::Debugger::PEEKS{qq(\$s)}}->get}',
                eval_result => "777->get",
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qq curly array",
            input    => 'qq{@a}',
            expected => {
                apply_peeks => 'qq{@{$Runtime::Debugger::PEEKS{qq(\@a)}}}',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq curly array element",
            input    => 'qq{$a[1]}',
            expected => {
                apply_peeks => 'qq{${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]}',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq curly array elements",
            input    => 'say qq(@a[1,2]}',
            expected => {
                apply_peeks =>
                  'say qq(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]}',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq curly hash",
            input    => 'qq{%h}',
            expected => {
                apply_peeks => 'qq{%h}',
                eval_result => "%h",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq curly hash key",
            input    => 'qq{$h{b}}',
            expected => {
                apply_peeks => 'qq{${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}}',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq curly hash keys",
            input    => 'qq{@h{qw( a b )}}',
            expected => {
                apply_peeks =>
                  'qq{@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}}',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qq - square
        {
            name     => "qq square scalar",
            input    => 'qq[$s]',
            expected => {
                apply_peeks => 'qq[${$Runtime::Debugger::PEEKS{qq(\$s)}}]',
                eval_result => "777",
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qq square array ref",
            input    => 'qq[$ar->[1]]',
            expected => {
                apply_peeks =>
                  'qq[${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]]',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq square hash ref",
            input    => 'qq[$hr->{b}]',
            expected => {
                apply_peeks =>
                  'qq[${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}]',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq square object key",
            input    => 'qq[$o->{cat}]',
            expected => {
                apply_peeks =>
                  'qq[${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}]',
                eval_result => 5,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq square object method",
            input    => 'qq[$o->get]',
            expected => {
                apply_peeks => 'qq[${$Runtime::Debugger::PEEKS{qq(\$o)}}->get]',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq square scalar with fake method",
            input    => 'qq[$s->get]',
            expected => {
                apply_peeks => 'qq[${$Runtime::Debugger::PEEKS{qq(\$s)}}->get]',
                eval_result => "777->get",
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qq square array",
            input    => 'qq[@a]',
            expected => {
                apply_peeks => 'qq[@{$Runtime::Debugger::PEEKS{qq(\@a)}}]',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq square array element",
            input    => 'qq[$a[1]]',
            expected => {
                apply_peeks => 'qq[${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]]',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq square array elements",
            input    => 'say qq(@a[1,2]]',
            expected => {
                apply_peeks =>
                  'say qq(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]]',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq square hash",
            input    => 'qq[%h]',
            expected => {
                apply_peeks => 'qq[%h]',
                eval_result => "%h",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq square hash key",
            input    => 'qq[$h{b}]',
            expected => {
                apply_peeks => 'qq[${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}]',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq square hash keys",
            input    => 'qq[@h{qw( a b )}]',
            expected => {
                apply_peeks =>
                  'qq[@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}]',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qq - angle
        {
            name     => "qq angle scalar",
            input    => 'qq<$s>',
            expected => {
                apply_peeks => 'qq<${$Runtime::Debugger::PEEKS{qq(\$s)}}>',
                eval_result => "777",
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qq angle array ref (syntax error)",
            input    => 'qq<$ar->[1]>',
            expected => {
                apply_peeks =>
                  'qq<${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]>',
                eval_result => undef,
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq angle array ref",
            input    => 'qq<$ar-\>[1]>',
            expected => {
                apply_peeks =>
                  'qq<${$Runtime::Debugger::PEEKS{qq(\$ar)}}-\>[1]>',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq angle hash ref",
            input    => 'qq<$hr-\>{b}>',
            expected => {
                apply_peeks =>
                  'qq<${$Runtime::Debugger::PEEKS{qq(\$hr)}}-\>{b}>',
                eval_result => 2,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq angle object key",
            input    => 'qq<$o-\>{cat}>',
            expected => {
                apply_peeks =>
                  'qq<${$Runtime::Debugger::PEEKS{qq(\$o)}}-\>{cat}>',
                eval_result => 5,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq angle object method",
            input    => 'qq<$o-\>get>',
            expected => {
                apply_peeks =>
                  'qq<${$Runtime::Debugger::PEEKS{qq(\$o)}}-\>get>',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qq angle scalar with fake method",
            input    => 'qq<$s-\>get>',
            expected => {
                apply_peeks =>
                  'qq<${$Runtime::Debugger::PEEKS{qq(\$s)}}-\>get>',
                eval_result => "777->get",
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qq angle array",
            input    => 'qq<@a>',
            expected => {
                apply_peeks => 'qq<@{$Runtime::Debugger::PEEKS{qq(\@a)}}>',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq angle array element",
            input    => 'qq<$a[1]>',
            expected => {
                apply_peeks => 'qq<${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]>',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq angle array elements",
            input    => 'say qq(@a[1,2]>',
            expected => {
                apply_peeks =>
                  'say qq(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]>',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qq angle hash",
            input    => 'qq<%h>',
            expected => {
                apply_peeks => 'qq<%h>',
                eval_result => "%h",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq angle hash key",
            input    => 'qq<$h{b}>',
            expected => {
                apply_peeks => 'qq<${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}>',
                eval_result => "2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qq angle hash keys",
            input    => 'qq<@h{qw( a b )}>',
            expected => {
                apply_peeks =>
                  'qq<@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}>',
                eval_result => "1 2",
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: q - parens
        {
            name     => "q parens scalar",
            input    => 'q($s)',
            expected => {
                apply_peeks => 'q($s)',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "q parens array ref",
            input    => 'q($ar->[1])',
            expected => {
                apply_peeks => 'q($ar->[1])',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q parens hash ref",
            input    => 'q($hr->{b})',
            expected => {
                apply_peeks => 'q($hr->{b})',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q parens object key",
            input    => 'q($o->{cat})',
            expected => {
                apply_peeks => 'q($o->{cat})',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q parens object method",
            input    => 'q($o->get)',
            expected => {
                apply_peeks => 'q($o->get)',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q parens scalar with fake method",
            input    => 'q($s->get)',
            expected => {
                apply_peeks => 'q($s->get)',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "q parens array",
            input    => 'q(@a)',
            expected => {
                apply_peeks => 'q(@a)',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q parens array element",
            input    => 'q($a[1])',
            expected => {
                apply_peeks => 'q($a[1])',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q parens array elements",
            input    => 'q(@a[1,2])',
            expected => {
                apply_peeks => 'q(@a[1,2])',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q parens array elements (print)",
            input    => 'say q(@a[1,2])',
            expected => {
                apply_peeks => 'say q(@a[1,2])',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q parens hash",
            input    => 'q(%h)',
            expected => {
                apply_peeks => 'q(%h)',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q parens hash key",
            input    => 'q($h{b})',
            expected => {
                apply_peeks => 'q($h{b})',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q parens hash keys",
            input    => 'q(@h{qw( a b )})',
            expected => {
                apply_peeks => 'q(@h{qw( a b )})',
                eval_result => '@h{qw( a b )}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: q - curly
        {
            name     => "q curly scalar",
            input    => 'q{$s}',
            expected => {
                apply_peeks => 'q{$s}',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "q curly array ref",
            input    => 'q{$ar->[1]}',
            expected => {
                apply_peeks => 'q{$ar->[1]}',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q curly hash ref",
            input    => 'q{$hr->{b}}',
            expected => {
                apply_peeks => 'q{$hr->{b}}',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q curly object key",
            input    => 'q{$o->{cat}}',
            expected => {
                apply_peeks => 'q{$o->{cat}}',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q curly object method",
            input    => 'q{$o->get}',
            expected => {
                apply_peeks => 'q{$o->get}',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q curly scalar with fake method",
            input    => 'q{$s->get}',
            expected => {
                apply_peeks => 'q{$s->get}',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "q curly array",
            input    => 'q{@a}',
            expected => {
                apply_peeks => 'q{@a}',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q curly array element",
            input    => 'q{$a[1]}',
            expected => {
                apply_peeks => 'q{$a[1]}',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q curly array elements (get)",
            input    => 'q{@a[1,2]}',
            expected => {
                apply_peeks => 'q{@a[1,2]}',
                eval_result => '@a[1,2]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q curly array elements (print)",
            input    => 'say q{@a[1,2]}',
            expected => {
                apply_peeks => 'say q{@a[1,2]}',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q curly hash",
            input    => 'q{%h}',
            expected => {
                apply_peeks => 'q{%h}',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q curly hash key",
            input    => 'q{$h{b}}',
            expected => {
                apply_peeks => 'q{$h{b}}',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q curly hash keys",
            input    => 'q{@h{qw( a b )}}',
            expected => {
                apply_peeks => 'q{@h{qw( a b )}}',
                eval_result => '@h{qw( a b )}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: q - square
        {
            name     => "q square scalar",
            input    => 'q[$s]',
            expected => {
                apply_peeks => 'q[$s]',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "q square array ref",
            input    => 'q[$ar->[1]]',
            expected => {
                apply_peeks => 'q[$ar->[1]]',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q square hash ref",
            input    => 'q[$hr->{b}]',
            expected => {
                apply_peeks => 'q[$hr->{b}]',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q square object key",
            input    => 'q[$o->{cat}]',
            expected => {
                apply_peeks => 'q[$o->{cat}]',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q square object method",
            input    => 'q[$o->get]',
            expected => {
                apply_peeks => 'q[$o->get]',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q square scalar with fake method",
            input    => 'q[$s->get]',
            expected => {
                apply_peeks => 'q[$s->get]',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "q square array",
            input    => 'q[@a]',
            expected => {
                apply_peeks => 'q[@a]',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q square array element",
            input    => 'q[$a[1]]',
            expected => {
                apply_peeks => 'q[$a[1]]',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q square array elements (get)",
            input    => 'q[@a[1,2]]',
            expected => {
                apply_peeks => 'q[@a[1,2]]',
                eval_result => '@a[1,2]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q square array elements (print)",
            input    => 'say q[@a[1,2]]',
            expected => {
                apply_peeks => 'say q[@a[1,2]]',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q square hash",
            input    => 'q[%h]',
            expected => {
                apply_peeks => 'q[%h]',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q square hash key",
            input    => 'q[$h{b}]',
            expected => {
                apply_peeks => 'q[$h{b}]',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q square hash keys",
            input    => 'q[@h{qw( a b )}]',
            expected => {
                apply_peeks => 'q[@h{qw( a b )}]',
                eval_result => '@h{qw( a b )}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: q - angle
        {
            name     => "q angle scalar",
            input    => 'q<$s>',
            expected => {
                apply_peeks => 'q<$s>',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "q angle array ref (syntax error)",
            input    => 'q<$ar->[1]>',
            expected => {
                apply_peeks => 'q<$ar->[1]>',
                eval_result => undef,
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q angle array ref",
            input    => 'q<$ar-\>[1]>',
            expected => {
                apply_peeks => 'q<$ar-\>[1]>',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q angle hash ref",
            input    => 'q<$hr-\>{b}>',
            expected => {
                apply_peeks => 'q<$hr-\>{b}>',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q angle object key",
            input    => 'q<$o-\>{cat}>',
            expected => {
                apply_peeks => 'q<$o-\>{cat}>',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q angle object method",
            input    => 'q<$o-\>get>',
            expected => {
                apply_peeks => 'q<$o-\>get>',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "q angle scalar with fake method",
            input    => 'q<$s-\>get>',
            expected => {
                apply_peeks => 'q<$s-\>get>',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "q angle array",
            input    => 'q<@a>',
            expected => {
                apply_peeks => 'q<@a>',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q angle array element",
            input    => 'q<$a[1]>',
            expected => {
                apply_peeks => 'q<$a[1]>',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q angle array elements (get)",
            input    => 'q<@a[1,2]>',
            expected => {
                apply_peeks => 'q<@a[1,2]>',
                eval_result => '@a[1,2]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q angle array elements (print)",
            input    => 'say q<@a[1,2]>',
            expected => {
                apply_peeks => 'say q<@a[1,2]>',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "q angle hash",
            input    => 'q<%h>',
            expected => {
                apply_peeks => 'q<%h>',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q angle hash key",
            input    => 'q<$h{b}>',
            expected => {
                apply_peeks => 'q<$h{b}>',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "q angle hash keys",
            input    => 'q<@h{qw( a b )}>',
            expected => {
                apply_peeks => 'q<@h{qw( a b )}>',
                eval_result => '@h{qw( a b )}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qr - parens
        {
            name     => "qr parens scalar",
            input    => 'qr($s)',
            expected => {
                apply_peeks => 'qr(${$Runtime::Debugger::PEEKS{qq(\$s)}})',
                eval_result => qr{:777},
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qr parens array ref",
            input    => 'qr($ar->[1])',
            expected => {
                apply_peeks =>
                  'qr(${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1])',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr parens hash ref",
            input    => 'qr($hr->{b})',
            expected => {
                apply_peeks =>
                  'qr(${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b})',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr parens object key",
            input    => 'qr($o->{cat})',
            expected => {
                apply_peeks =>
                  'qr(${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat})',
                eval_result => qr{:5},
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr parens object method",
            input    => 'qr($o->get)',
            expected => {
                apply_peeks => 'qr(${$Runtime::Debugger::PEEKS{qq(\$o)}}->get)',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr parens scalar with fake method",
            input    => 'qr($s->get)',
            expected => {
                apply_peeks => 'qr(${$Runtime::Debugger::PEEKS{qq(\$s)}}->get)',
                eval_result => qr{:777->get},
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qr parens array",
            input    => 'qr(@a)',
            expected => {
                apply_peeks => 'qr(@{$Runtime::Debugger::PEEKS{qq(\@a)}})',
                eval_result => qr{:1 2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr parens array element",
            input    => 'qr($a[1])',
            expected => {
                apply_peeks => 'qr(${$Runtime::Debugger::PEEKS{qq(\@a)}}[1])',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr parens array elements",
            input    => 'say qr(@a[1,2])',
            expected => {
                apply_peeks =>
                  'say qr(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2])',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr parens hash",
            input    => 'qr(%h)',
            expected => {
                apply_peeks => 'qr(%h)',
                eval_result => qr{:%h},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr parens hash key",
            input    => 'qr($h{b})',
            expected => {
                apply_peeks => 'qr(${$Runtime::Debugger::PEEKS{qq(\%h)}}{b})',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr parens hash keys",
            input    => 'qr(@h{qw( a b )})',
            expected => {
                apply_peeks =>
                  'qr(@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )})',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qr - curly
        {
            name     => "qr curly scalar",
            input    => 'qr{$s}',
            expected => {
                apply_peeks => 'qr{${$Runtime::Debugger::PEEKS{qq(\$s)}}}',
                eval_result => qr{:777},
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qr curly array ref",
            input    => 'qr{$ar->[1]}',
            expected => {
                apply_peeks =>
                  'qr{${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]}',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr curly hash ref",
            input    => 'qr{$hr->{b}}',
            expected => {
                apply_peeks =>
                  'qr{${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}}',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr curly object key",
            input    => 'qr{$o->{cat}}',
            expected => {
                apply_peeks =>
                  'qr{${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}}',
                eval_result => qr{:5},
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr curly object method",
            input    => 'qr{$o->get}',
            expected => {
                apply_peeks => 'qr{${$Runtime::Debugger::PEEKS{qq(\$o)}}->get}',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr curly scalar with fake method",
            input    => 'qr{$s->get}',
            expected => {
                apply_peeks => 'qr{${$Runtime::Debugger::PEEKS{qq(\$s)}}->get}',
                eval_result => qr{:777->get},
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qr curly array",
            input    => 'qr{@a}',
            expected => {
                apply_peeks => 'qr{@{$Runtime::Debugger::PEEKS{qq(\@a)}}}',
                eval_result => qr{:1 2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr curly array element",
            input    => 'qr{$a[1]}',
            expected => {
                apply_peeks => 'qr{${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]}',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr curly array elements",
            input    => 'say qr(@a[1,2]}',
            expected => {
                apply_peeks =>
                  'say qr(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]}',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr curly hash",
            input    => 'qr{%h}',
            expected => {
                apply_peeks => 'qr{%h}',
                eval_result => qr{:%h},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr curly hash key",
            input    => 'qr{$h{b}}',
            expected => {
                apply_peeks => 'qr{${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}}',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr curly hash keys",
            input    => 'qr{@h{qw( a b )}}',
            expected => {
                apply_peeks =>
                  'qr{@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}}',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qr - square
        {
            name     => "qr square scalar",
            input    => 'qr[$s]',
            expected => {
                apply_peeks => 'qr[${$Runtime::Debugger::PEEKS{qq(\$s)}}]',
                eval_result => qr{:777},
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qr square array ref",
            input    => 'qr[$ar->[1]]',
            expected => {
                apply_peeks =>
                  'qr[${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]]',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr square hash ref",
            input    => 'qr[$hr->{b}]',
            expected => {
                apply_peeks =>
                  'qr[${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{b}]',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr square object key",
            input    => 'qr[$o->{cat}]',
            expected => {
                apply_peeks =>
                  'qr[${$Runtime::Debugger::PEEKS{qq(\$o)}}->{cat}]',
                eval_result => qr{:5},
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr square object method",
            input    => 'qr[$o->get]',
            expected => {
                apply_peeks => 'qr[${$Runtime::Debugger::PEEKS{qq(\$o)}}->get]',
                eval_result => qr{ A=HASH \( 0x\w+ \) ->get }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr square scalar with fake method",
            input    => 'qr[$s->get]',
            expected => {
                apply_peeks => 'qr[${$Runtime::Debugger::PEEKS{qq(\$s)}}->get]',
                eval_result => qr{:777->get},
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qr square array",
            input    => 'qr[@a]',
            expected => {
                apply_peeks => 'qr[@{$Runtime::Debugger::PEEKS{qq(\@a)}}]',
                eval_result => qr{:1 2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr square array element",
            input    => 'qr[$a[1]]',
            expected => {
                apply_peeks => 'qr[${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]]',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr square array elements",
            input    => 'say qr(@a[1,2]]',
            expected => {
                apply_peeks =>
                  'say qr(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]]',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr square hash",
            input    => 'qr[%h]',
            expected => {
                apply_peeks => 'qr[%h]',
                eval_result => qr{:%h},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr square hash key",
            input    => 'qr[$h{b}]',
            expected => {
                apply_peeks => 'qr[${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}]',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr square hash keys",
            input    => 'qr[@h{qw( a b )}]',
            expected => {
                apply_peeks =>
                  'qr[@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}]',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qr - angle
        {
            name     => "qr angle scalar",
            input    => 'qr<$s>',
            expected => {
                apply_peeks => 'qr<${$Runtime::Debugger::PEEKS{qq(\$s)}}>',
                eval_result => qr{:777},
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qr angle array ref (syntax error)",
            input    => 'qr<$ar->[1]>',
            expected => {
                apply_peeks =>
                  'qr<${$Runtime::Debugger::PEEKS{qq(\$ar)}}->[1]>',
                eval_result => undef,
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr angle array ref",
            input    => 'qr<$ar-\>[1]>',
            expected => {
                apply_peeks =>
                  'qr<${$Runtime::Debugger::PEEKS{qq(\$ar)}}-\>[1]>',
                eval_result => qr{: (?: ARRAY | \b2\b ) }x,    # For v5.20.
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr angle hash ref",
            input    => 'qr<$hr-\>{b}>',
            expected => {
                apply_peeks =>
                  'qr<${$Runtime::Debugger::PEEKS{qq(\$hr)}}-\>{b}>',
                eval_result => qr{: (?: HASH | \b2\b ) }x,          # For v5.20.
                eval_error  => qr{ Unescaped \s+ left \s+ brace }x,
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr angle object key",
            input    => 'qr<$o-\>{cat}>',
            expected => {
                apply_peeks =>
                  'qr<${$Runtime::Debugger::PEEKS{qq(\$o)}}-\>{cat}>',
                eval_result => qr{: (?: A=HASH | \b5\b ) }x,        # For v5.20.
                eval_error  => qr{ Unescaped \s+ left \s+ brace }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr angle object method",
            input    => 'qr<$o-\>get>',
            expected => {
                apply_peeks =>
                  'qr<${$Runtime::Debugger::PEEKS{qq(\$o)}}-\>get>',
                eval_result => qr{ A=HASH \( 0x\w+ \) -[\\]?>get }x,
                eval_error  => qr{ Unescaped \s+ left \s+ brace }x,
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qr angle scalar with fake method",
            input    => 'qr<$s-\>get>',
            expected => {
                apply_peeks =>
                  'qr<${$Runtime::Debugger::PEEKS{qq(\$s)}}-\>get>',
                eval_result => qr{:777-[\\]?>get}
                ,    # Some perl version do not output the backslash here.
                eval_error => qr{ Unescaped \s+ left \s+ brace }x,
                vars_after => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qr angle array",
            input    => 'qr<@a>',
            expected => {
                apply_peeks => 'qr<@{$Runtime::Debugger::PEEKS{qq(\@a)}}>',
                eval_result => qr{:1 2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr angle array element",
            input    => 'qr<$a[1]>',
            expected => {
                apply_peeks => 'qr<${$Runtime::Debugger::PEEKS{qq(\@a)}}[1]>',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr angle array elements",
            input    => 'say qr(@a[1,2]>',
            expected => {
                apply_peeks =>
                  'say qr(@{$Runtime::Debugger::PEEKS{qq(\@a)}}[1,2]>',
                vars_after => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qr angle hash",
            input    => 'qr<%h>',
            expected => {
                apply_peeks => 'qr<%h>',
                eval_result => qr{:%h},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr angle hash key",
            input    => 'qr<$h{b}>',
            expected => {
                apply_peeks => 'qr<${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}>',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qr angle hash keys",
            input    => 'qr<@h{qw( a b )}>',
            expected => {
                apply_peeks =>
                  'qr<@{$Runtime::Debugger::PEEKS{qq(\%h)}}{qw( a b )}>',
                eval_result => qr{:2},
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qw - parens
        {
            name     => "qw parens scalar",
            input    => 'qw($s)',
            expected => {
                apply_peeks => 'qw($s)',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qw parens array ref",
            input    => 'qw($ar->[1])',
            expected => {
                apply_peeks => 'qw($ar->[1])',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw parens hash ref",
            input    => 'qw($hr->{b})',
            expected => {
                apply_peeks => 'qw($hr->{b})',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw parens object key",
            input    => 'qw($o->{cat})',
            expected => {
                apply_peeks => 'qw($o->{cat})',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw parens object method",
            input    => 'qw($o->get)',
            expected => {
                apply_peeks => 'qw($o->get)',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw parens scalar with fake method",
            input    => 'qw($s->get)',
            expected => {
                apply_peeks => 'qw($s->get)',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qw parens array",
            input    => 'qw(@a)',
            expected => {
                apply_peeks => 'qw(@a)',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw parens array element",
            input    => 'qw($a[1])',
            expected => {
                apply_peeks => 'qw($a[1])',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw parens array elements",
            input    => 'qw(@a[1,2])',
            expected => {
                apply_peeks => 'qw(@a[1,2])',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw parens array elements (print)",
            input    => 'say qw(@a[1,2])',
            expected => {
                apply_peeks => 'say qw(@a[1,2])',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw parens hash",
            input    => 'qw(%h)',
            expected => {
                apply_peeks => 'qw(%h)',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw parens hash key",
            input    => 'qw($h{b})',
            expected => {
                apply_peeks => 'qw($h{b})',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw parens hash keys",
            input    => 'qw(@h{qw( a b )})',
            expected => {
                apply_peeks => 'qw(@h{qw( a b )})',
                eval_result => ')}',                  # last part.
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw parens hash keys",
            input    => 'join ",", qw(a b c)',
            expected => {
                apply_peeks => 'join ",", qw(a b c)',
                eval_result => 'a,b,c',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qw - curly
        {
            name     => "qw curly scalar",
            input    => 'qw{$s}',
            expected => {
                apply_peeks => 'qw{$s}',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qw curly array ref",
            input    => 'qw{$ar->[1]}',
            expected => {
                apply_peeks => 'qw{$ar->[1]}',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw curly hash ref",
            input    => 'qw{$hr->{b}}',
            expected => {
                apply_peeks => 'qw{$hr->{b}}',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw curly object key",
            input    => 'qw{$o->{cat}}',
            expected => {
                apply_peeks => 'qw{$o->{cat}}',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw curly object method",
            input    => 'qw{$o->get}',
            expected => {
                apply_peeks => 'qw{$o->get}',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw curly scalar with fake method",
            input    => 'qw{$s->get}',
            expected => {
                apply_peeks => 'qw{$s->get}',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qw curly array",
            input    => 'qw{@a}',
            expected => {
                apply_peeks => 'qw{@a}',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw curly array element",
            input    => 'qw{$a[1]}',
            expected => {
                apply_peeks => 'qw{$a[1]}',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw curly array elements (get)",
            input    => 'qw{@a[1,2]}',
            expected => {
                apply_peeks => 'qw{@a[1,2]}',
                eval_result => '@a[1,2]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw curly array elements (print)",
            input    => 'say qw{@a[1,2]}',
            expected => {
                apply_peeks => 'say qw{@a[1,2]}',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw curly hash",
            input    => 'qw{%h}',
            expected => {
                apply_peeks => 'qw{%h}',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw curly hash key",
            input    => 'qw{$h{b}}',
            expected => {
                apply_peeks => 'qw{$h{b}}',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw curly hash keys",
            input    => 'qw{@h{qw( a b )}}',
            expected => {
                apply_peeks => 'qw{@h{qw( a b )}}',
                eval_result => ')}',                  # last part.
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw curly hash keys",
            input    => 'join ",", qw{a b c}',
            expected => {
                apply_peeks => 'join ",", qw{a b c}',
                eval_result => 'a,b,c',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qw - square
        {
            name     => "qw square scalar",
            input    => 'qw[$s]',
            expected => {
                apply_peeks => 'qw[$s]',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qw square array ref",
            input    => 'qw[$ar->[1]]',
            expected => {
                apply_peeks => 'qw[$ar->[1]]',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw square hash ref",
            input    => 'qw[$hr->{b}]',
            expected => {
                apply_peeks => 'qw[$hr->{b}]',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw square object key",
            input    => 'qw[$o->{cat}]',
            expected => {
                apply_peeks => 'qw[$o->{cat}]',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw square object method",
            input    => 'qw[$o->get]',
            expected => {
                apply_peeks => 'qw[$o->get]',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw square scalar with fake method",
            input    => 'qw[$s->get]',
            expected => {
                apply_peeks => 'qw[$s->get]',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qw square array",
            input    => 'qw[@a]',
            expected => {
                apply_peeks => 'qw[@a]',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw square array element",
            input    => 'qw[$a[1]]',
            expected => {
                apply_peeks => 'qw[$a[1]]',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw square array elements (get)",
            input    => 'qw[@a[1,2]]',
            expected => {
                apply_peeks => 'qw[@a[1,2]]',
                eval_result => '@a[1,2]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw square array elements (print)",
            input    => 'say qw[@a[1,2]]',
            expected => {
                apply_peeks => 'say qw[@a[1,2]]',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw square hash",
            input    => 'qw[%h]',
            expected => {
                apply_peeks => 'qw[%h]',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw square hash key",
            input    => 'qw[$h{b}]',
            expected => {
                apply_peeks => 'qw[$h{b}]',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw square hash keys",
            input    => 'qw[@h{qw( a b )}]',
            expected => {
                apply_peeks => 'qw[@h{qw( a b )}]',
                eval_result => ')}',                  # last part.
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw parens hash keys",
            input    => 'join ",", qw[a b c]',
            expected => {
                apply_peeks => 'join ",", qw[a b c]',
                eval_result => 'a,b,c',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: qw - angle
        {
            name     => "qw angle scalar",
            input    => 'qw<$s>',
            expected => {
                apply_peeks => 'qw<$s>',
                eval_result => '$s',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },
        {
            name     => "qw angle array ref (syntax error)",
            input    => 'qw<$ar->[1]>',
            expected => {
                apply_peeks => 'qw<$ar->[1]>',
                eval_result => undef,
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw angle array ref",
            input    => 'qw<$ar-\>[1]>',
            expected => {
                apply_peeks => 'qw<$ar-\>[1]>',
                eval_result => '$ar->[1]',
                vars_after  => sub {
                    is_deeply $ar, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw angle hash ref",
            input    => 'qw<$hr-\>{b}>',
            expected => {
                apply_peeks => 'qw<$hr-\>{b}>',
                eval_result => '$hr->{b}',
                vars_after  => sub {
                    is_deeply $hr, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw angle object key",
            input    => 'qw<$o-\>{cat}>',
            expected => {
                apply_peeks => 'qw<$o-\>{cat}>',
                eval_result => '$o->{cat}',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw angle object method",
            input    => 'qw<$o-\>get>',
            expected => {
                apply_peeks => 'qw<$o-\>get>',
                eval_result => '$o->get',
                vars_after  => sub {
                    is $o->{cat}, 5, shift;
                },
            },
        },
        {
            name     => "qw angle scalar with fake method",
            input    => 'qw<$s-\>get>',
            expected => {
                apply_peeks => 'qw<$s-\>get>',
                eval_result => '$s->get',
                vars_after  => sub {
                    is $s,        777, shift;
                    is $o->{cat}, 5,   shift;
                },
            },
        },
        {
            name     => "qw angle array",
            input    => 'qw<@a>',
            expected => {
                apply_peeks => 'qw<@a>',
                eval_result => '@a',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw angle array element",
            input    => 'qw<$a[1]>',
            expected => {
                apply_peeks => 'qw<$a[1]>',
                eval_result => '$a[1]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw angle array elements (get)",
            input    => 'qw<@a[1,2]>',
            expected => {
                apply_peeks => 'qw<@a[1,2]>',
                eval_result => '@a[1,2]',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw angle array elements (print)",
            input    => 'say qw<@a[1,2]>',
            expected => {
                apply_peeks => 'say qw<@a[1,2]>',
                eval_result => '1',
                vars_after  => sub {
                    is_deeply \@a, [ 1, 2 ], shift;
                },
            },
        },
        {
            name     => "qw angle hash",
            input    => 'qw<%h>',
            expected => {
                apply_peeks => 'qw<%h>',
                eval_result => '%h',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw angle hash key",
            input    => 'qw<$h{b}>',
            expected => {
                apply_peeks => 'qw<$h{b}>',
                eval_result => '$h{b}',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw angle hash keys",
            input    => 'qw<@h{qw( a b )}>',
            expected => {
                apply_peeks => 'qw<@h{qw( a b )}>',
                eval_result => ')}',                  # last part.
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },
        {
            name     => "qw parens hash keys",
            input    => 'join ",", qw<a b c>',
            expected => {
                apply_peeks => 'join ",", qw<a b c>',
                eval_result => 'a,b,c',
                vars_after  => sub {
                    is_deeply \%h, { a => 1, b => 2 }, shift;
                },
            },
        },

        # Quoted: Mixed
        {
            name     => "mixed quotes",
            input    => 'join ",", qq($s), qw{a b c}',
            expected => {
                apply_peeks =>
'join ",", qq(${$Runtime::Debugger::PEEKS{qq(\$s)}}), qw{a b c}',
                eval_result => '777,a,b,c',
                vars_after  => sub {
                    is $s, 777, shift;
                },
            },
        },

        # Nested.
        {
            name     => "nested lookup",
            input    => '$hr->{$s}{$o->get} = $h{b}',
            expected => {
                apply_peeks =>
'${$Runtime::Debugger::PEEKS{qq(\$hr)}}->{${$Runtime::Debugger::PEEKS{qq(\$s)}}}{${$Runtime::Debugger::PEEKS{qq(\$o)}}->get} = ${$Runtime::Debugger::PEEKS{qq(\%h)}}{b}',
                eval_result => '2',
                vars_after  => sub {
                    is_deeply $hr,
                      { a => 1, b => 2, 777 => { 'got method' => 2 } }, shift;
                },
            },
            cleanup => sub {
                $hr = { a => 1, b => 2 };
            },
        },

    );

    for my $case ( @cases ) {
        pass( "--- $case->{name} ---" );

        # Check if peek data is properly applied.
        my $applied = $repl->_apply_peeks( $case->{input} );
        last
          unless is(
            $applied,
            $case->{expected}{apply_peeks},
            "$case->{name} - apply peeks",
          );

        # Check result of eval.
        if ( $case->{expected}{eval_result} ) {
            my $expected = $case->{expected}{eval_result};
            my $actual   = eval $applied;
            if ( $@ ) {
                if ( $case->{expected}{eval_error} ) {
                    my $error = $case->{expected}{eval_error};
                    last
                      unless like( "$@", $error,
                        "$case->{name} - eval result (error). [$actual]",
                      );
                }
                else {
                    fail "$case->{name} - eval result ($@). [$actual]";
                    last;
                }
            }
            elsif ( ref( $expected ) eq ref( qr// ) ) {
                last
                  unless like( $actual, $expected,
                    "$case->{name} - eval result (regex). [$actual]",
                  );
            }
            else {
                last
                  unless is( $actual, $expected,
                    "$case->{name} - eval result" );
            }
        }

        # Check variables are actually set.
        if ( $case->{expected}{vars_after} ) {
            last
              unless $case->{expected}{vars_after}
              ->( "$case->{name} - vars after" );
        }

        # Cleanup/reset variables.
        if ( $case->{cleanup} ) {
            $case->{cleanup}->();
        }
    }
}

sub title {
    my ( $scenario ) = @_;
    pass( "--- --- $scenario --- ---" );
}

################################
# Run under different scenarios.
################################

{
    title "Statement";
    run_suite();
}

sub Func {
    title "Function";
    run_suite();
}
Func();

sub {
    say "";
    title "Code Reference";
    run_suite();
  }
  ->();


