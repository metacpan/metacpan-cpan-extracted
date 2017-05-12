#!perl

use strict;
use warnings FATAL => "all";

use Test::More;

my $moodel;

BEGIN {
    $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;

    eval "use MooX::ConfigFromFile 0.006;";
    $@ and plan skip_all => "Need MooX::ConfigFromFile 0.006 -- $@";
}

eval sprintf( <<'EOCDECL', ($moodel) x 3 );
{
    package    #
      Calc::Role::BinaryOperation;
    use %s::Role;

    has a => (
        is       => "ro",
        required => 1,
    );

    has b => (
        is       => "ro",
        required => 1,
    );
}

{
    package    #
      Calc::add;
    use %s;
    use MooX::ConfigFromFile config_prefix => "calc-operands";

    with "Calc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a + $self->b;
    }
}

{
    package    #
      Calc::sub;
    use %s;
    use MooX::ConfigFromFile config_prefix => "operands", config_identifier => "calc";

    with "Calc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a - $self->b;
    }
}
EOCDECL

my $adder = Calc::add->new;
ok( defined( $adder->a ), "read \"a\" from add config" );
ok( defined( $adder->b ), "read \"b\" from add config" );
cmp_ok( $adder->execute, "==", 5, "read right adder config" );

my $adderly = Calc::add->new(config_prefix => "operands", config_identifier => "calc");
ok( defined( $adderly->a ), "read \"a\" from adderly config" );
ok( defined( $adderly->b ), "read \"b\" from adderly config" );
cmp_ok( $adderly->execute, "==", 25, "read right adderly config" );

my $subber = Calc::sub->new;
ok( defined( $subber->a ), "read \"a\" from sub config" );
ok( defined( $subber->b ), "read \"b\" from sub config" );
cmp_ok( $subber->execute, "==", 17, "read right subber config" );

my $subberly = Calc::sub->new(config_identifier => undef, config_prefix => "calc-operands");
ok( defined( $subberly->a ), "read \"a\" from subberly config" );
ok( defined( $subberly->b ), "read \"b\" from subberly config" );
cmp_ok( $subberly->execute, "==", -1, "read right subberly config" );

done_testing();
