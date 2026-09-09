#!perl
# A custom op registered as "simple" may be used as a function-style accessor
# operand without deoptimising the call back to a real subroutine call.
use strict;
use warnings;
use Test::More;
use Object::Proto;

plan tests => 7;

can_ok 'Object::Proto', 'register_simple_custom_op';

ok Object::Proto::register_simple_custom_op('confold'),
   'the seeded entry registers idempotently';

ok Object::Proto::register_simple_custom_op('t057_example_op'),
   'a new name registers';

ok Object::Proto::register_simple_custom_op('t057_example_op'),
   'registering the same name twice is harmless';

{
    my $ok = eval { Object::Proto::register_simple_custom_op(''); 1 };
    ok !$ok, 'an empty name is rejected';
}

{
    my $ok = eval { Object::Proto::register_simple_custom_op(); 1 };
    ok !$ok, 'a missing argument is rejected';
}

# The optimisation itself is only observable with a module that provides such
# an op, so exercise it against Confold when that is available.
SKIP: {
    skip 'Confold required to exercise a real simple custom op', 1
        unless eval { require Confold; 1 };
    skip 'B::Concise required', 1
        unless eval { require B::Concise; 1 };

    my $code = <<'END';
        use Object::Proto; use Confold; use B::Concise;
        BEGIN {
            Object::Proto::define('T057', qw(slot));
            Object::Proto::import_accessors('T057');
        }
        my $o = T057->new(slot => 1);
        my $v = 5;
        sub t057_probe { slot($o, <: $v) }
        my $out = '';
        open my $fh, '>', \$out or die $!;
        B::Concise::walk_output($fh);
        B::Concise::compile('-exec', \&t057_probe)->();
        close $fh;
        $out;
END
    my $out = eval $code;
    my $err = $@;
    like $out || '', qr/object_func_set/,
        'a confold operand keeps the optimised accessor op'
        or diag $err || $out;
}
