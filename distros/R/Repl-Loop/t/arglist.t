#!/usr/bin/perl -w

use strict;
use Test::More tests => 44;

BEGIN {use_ok('Repl::Core::Pair')};

BEGIN {use_ok('Repl::Spec::Args::FixedArg')};
BEGIN {use_ok('Repl::Spec::Args::NamedArg')};
BEGIN {use_ok('Repl::Spec::Args::OptionalArg')};
BEGIN {use_ok('Repl::Spec::Args::VarArg')};

BEGIN {use_ok('Repl::Spec::Args::StdArgList')};
BEGIN {use_ok('Repl::Spec::Args::VarArgList')};

BEGIN {use_ok('Repl::Spec::Type::IntegerType')};
BEGIN {use_ok('Repl::Spec::Type::BooleanType')};
BEGIN {use_ok('Repl::Spec::Type::StringEnumType')};

my $int_type = new Repl::Spec::Type::IntegerType();
my $bool_type = new Repl::Spec::Type::BooleanType();
my $latin_type = new Repl::Spec::Type::StringEnumType("UNO", "DUO", "TRES");
my $dutch_type = new Repl::Spec::Type::StringEnumType("EEN", "TWEE", "DRIE");

my $fixed_latin_arg = new Repl::Spec::Args::FixedArg($latin_type);
my $fixed_dutch_arg = new Repl::Spec::Args::FixedArg($dutch_type);
my $opt_arg = new Repl::Spec::Args::OptionalArg($int_type, 13);
my $named_force_arg = new Repl::Spec::Args::NamedArg("force", $bool_type, "false", 1);
my $vararg = new Repl::Spec::Args::VarArg($int_type);

# Standard argument list.
# -----------------------
# Arg 1: Fixed, a latin number.
# Arg 2: Fixed, a dutch number.
# Arg 3: Optional, an integer with default value 13.
# Arg 'force': Optional named boolean argument, with default false.
my $stdlst = new Repl::Spec::Args::StdArgList([$fixed_latin_arg, $fixed_dutch_arg], [$opt_arg], [$named_force_arg]);
my $checked;
# Normal case: a fully specified list.
eval {$checked = $stdlst->guard(["CMD", "UNO", "EEN", 42, new Repl::Core::Pair(LEFT=>"force", RIGHT=>"true")], [])};
ok(!$@, 'The guard lets us pass.');
ok(scalar(@$checked) == 5, 'The length of concerted parameter list.');
ok($checked->[0] eq "CMD", 'First arg is the command');
ok($checked->[1] eq "UNO", 'Arg 2 should be unmodified.');
ok($checked->[2] eq "EEN", 'Arg 3 should be unmodified.');
ok($checked->[3] == 42, 'Arg 3 is optional.');
ok($checked->[4] == 1, 'Arg 4 is converted to 0 or 1.');

# We leave out the optional parameters.
eval {$checked = $stdlst->guard(["CMD", "UNO", "EEN"], [])};
ok(!$@, 'The guard lets us pass.');
ok(scalar(@$checked) == 5, 'The length of converted parameter list.');
ok($checked->[0] eq "CMD", 'First arg is the command.');
ok($checked->[1] eq "UNO", 'Arg 2 should be unmodified.');
ok($checked->[2] eq "EEN", 'Arg 3 should be unmodified.');
ok($checked->[3] == 13, 'Arg 3 optional takes default value.');
ok($checked->[4] == 0, 'Arg 4 optional named takes default value.');

# A bad argument list.
eval {$checked = $stdlst->guard(["CMD", "ONE", "EEN"], [])};
ok($@, 'First argument guard.');

# A bad argument list.
eval {$checked = $stdlst->guard(["CMD", "UNO", "EEN", "DEUX" ], [])};
ok($@, 'An argument too much.');

# Variable argument list.
# -----------------------
# Arg 1 - 3: An integer.
# Arg 'force': Optional named boolean argument.
my $varlist = new Repl::Spec::Args::VarArgList([$fixed_dutch_arg], $vararg, 2, 3, [$named_force_arg]);
my $checked2;
# Normal case.
eval{$checked2 = $varlist->guard(["CMD", "TWEE", 17, 23, 31, new Repl::Core::Pair(LEFT=>"force", RIGHT=>"true")], [])};
ok(!$@, 'The guard lets us pass.');
ok(scalar(@$checked2) == 6, 'The length of converted parameter list.');
ok($checked2->[0] eq 'CMD', 'First arg is the command.');
ok($checked2->[1] eq 'TWEE', 'Second arg is the fixed arg.');
ok($checked2->[2] eq 1, 'After fixed the named.');
ok($checked2->[3] == 17, 'Vararg 1.');
ok($checked2->[4] == 23, 'Vararg 2');
ok($checked2->[5] == 31, 'Vararg 3');

# Normal case, we omit the named.
eval{$checked2 = $varlist->guard(["CMD", "TWEE", 17, 23, 31], [])};
ok(!$@, 'The guard lets us pass.');
ok(scalar(@$checked2) == 6, 'The length of converted parameter list.');
ok($checked2->[0] eq 'CMD', 'First arg is the command.');
ok($checked2->[1] eq 'TWEE', 'Second arg is the fixed arg.');
ok($checked2->[2] eq 0, 'After fixed the named (default value this time).');
ok($checked2->[3] == 17, 'Vararg 1.');
ok($checked2->[4] == 23, 'Vararg 2');
ok($checked2->[5] == 31, 'Vararg 3');

# Too few varars.
eval{$checked2 = $varlist->guard(["CMD", "TWEE", 17, new Repl::Core::Pair(LEFT=>"force", RIGHT=>"true")], [])};
ok($@ =~ /Too few arguments/ , 'Too few arguxments.');

# Too many varargs.
eval{$checked2 = $varlist->guard(["CMD", "TWEE", 17, 23, 31, 19, 101, 223, new Repl::Core::Pair(LEFT=>"force", RIGHT=>"true")], [])};
ok($@ =~ /Too many arguments/, 'Too many arguments');
