use strict;
use warnings FATAL => "all";

use FindBin;

eval sprintf( <<'EOCDECL', ($main::OO) x 6 );
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
    use MooX::ConfigFromFile;

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
    use MooX::ConfigFromFile config_prefix => "calc-operands";

    with "Calc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a - $self->b;
    }
}

{
    package    #
      Calc::mul;
    use %s;
    use MooX::ConfigFromFile
      config_prefix    => "calc-operands",
      config_singleton => 1;

    with "Calc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a * $self->b;
    }
}

{
    package    #
      Calc::div;
    use %s;
    use MooX::ConfigFromFile
      config_singleton => 0;

    with "Calc::Role::BinaryOperation";

    around BUILDARGS => sub {
        my $next          = shift;
        my $class         = shift;
	my $a             = shift;
	my $b             = shift;
        my $loaded_config = { a => $a, b => $b };
        $class->$next(
            loaded_config => $loaded_config,
        );
    };

    sub execute
    {
        my $self = shift;
        return $self->a / $self->b;
    }
}

{
    package    #
      Dumb::Cfg;

    use %s;
    use MooX::ConfigFromFile;

    sub execute
    {
        return;
    }
}
EOCDECL

# This is for warn once
note $main::OO;

my $adder = Calc::add->new( config_prefix => "calc-operands" );
ok( defined( $adder->a ), "read \"a\" from add config" );
ok( defined( $adder->b ), "read \"b\" from add config" );
cmp_ok( $adder->execute, "==", 5, "read right adder config" );
ok( Moo::Role::does_role( $adder, "MooX::ConfigFromFile::Role" ), "Applying MooX::ConfigFromFile::Role" );

foreach my $copy_attr ( map { "config_$_" } qw(extensions dirs prefix_map_separator prefixes prefix_map files_pattern files) )
{
    my $subber = Calc::sub->new( $copy_attr => $adder->$copy_attr );
    ok( defined( $subber->a ), "read \"a\" from sub config using $copy_attr" );
    ok( defined( $subber->b ), "read \"b\" from sub config using $copy_attr" );
    cmp_ok( $subber->execute, "==", -1, "read right subber config using $copy_attr" );
}

my $secsub = Calc::sub->new( raw_loaded_config => [ { t => { b => 2, a => 4 } } ]);
ok( defined( $secsub->a ), "read \"a\" from sub config" );
ok( defined( $secsub->b ), "read \"b\" from sub config" );
cmp_ok( $secsub->execute, "==", 2, "use right secsub config" );
ok( Moo::Role::does_role( $secsub, "MooX::ConfigFromFile::Role" ), "Applying MooX::ConfigFromFile::Role" );

my $mul1 = Calc::mul->new( b => 4 );
ok( defined( $mul1->a ), "read \"a\" from mul1 config" );
ok( defined( $mul1->b ), "read \"b\" from mul1 config" );
cmp_ok( $mul1->execute, "==", 8, "read right mul config" );

my $mul2 = Calc::mul->new( config_prefix => "no-calc-operands" );
ok( defined( $mul2->a ), "copy \"a\" from mul1 config" );
ok( defined( $mul2->b ), "copy \"b\" from mul1 config" );
cmp_ok( $mul2->execute, "==", 6, "right mul2 config duplicated" );

my $mul3 = $mul2->new;
cmp_ok( $mul3->execute, "==", 6, "right mul3 config duplicated" );

my $div1 = Calc::div->new( 12, 3 );
ok( defined( $div1->a ), "read \"a\" from div1 config" );
ok( defined( $div1->b ), "read \"b\" from div1 config" );
cmp_ok( $div1->execute, "==", 4, "read right div1 config" );

my $div2 = Calc::div->new( 12, 6 );
ok( defined( $div2->a ), "read \"a\" from div2 config" );
ok( defined( $div2->b ), "read \"b\" from div2 config" );
cmp_ok( $div2->execute, "==", 2, "read right div2 config" );

my $dumb = Dumb::Cfg->new( config_dirs => 1 );
isa_ok( $dumb, "Dumb::Cfg" );
is( $dumb->config_prefix, $FindBin::Script, "fallback config prefix" );
is_deeply( $dumb->config_dirs,     [qw(.)],            "fallback config dirs" );
is_deeply( $dumb->config_prefixes, [$FindBin::Script], "fallback config prefix" );
