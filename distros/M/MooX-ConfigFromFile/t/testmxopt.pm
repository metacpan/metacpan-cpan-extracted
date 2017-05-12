use strict;
use warnings FATAL => "all";

use FindBin;
use Cwd qw'abs_path getcwd';
use File::Spec;

eval sprintf( <<'EOCDECL', ($main::OO) x 5 );
{
    package    #
      oCalc::Role::BinaryOperation;
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
      oCalc::add;
    use %s;
    use MooX::Options with_config_from_file => 1;

    with "oCalc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a + $self->b;
    }
}

{
    package    #
      oCalc::sub;
    use %s;
    use MooX::Options with_config_from_file => 1;
    use MooX::ConfigFromFile
      config_identifier => "calc";

    with "oCalc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a - $self->b;
    }
}

{
    package    #
      oCalc::mul;
    use %s;
    use MooX::ConfigFromFile
      config_singleton => 1;
    use MooX::Options with_config_from_file => 1;

    with "oCalc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a * $self->b;
    }
}

{
    package    #
      oCalc::div;
    use %s;
    use MooX::ConfigFromFile
      config_singleton => 0;
    use MooX::Options with_config_from_file => 1;

    with "oCalc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a / $self->b;
    }
}
EOCDECL

# This is for warn once
note $main::OO;

my $cwd = abs_path(getcwd);
my @cfg_files = map { ( "--config-files", File::Spec->catfile( $cwd, qw(calc etc), $_ ) ) }
  qw(operands.json small-operands.json large-operands.json);

SCOPE:
{
    local @ARGV = qw(--config-prefix calc-operands);
    my $adder = oCalc::add->new_with_options;
    ok( defined( $adder->a ), "read \"a\" from add config" );
    ok( defined( $adder->b ), "read \"b\" from add config" );
    cmp_ok( $adder->execute, "==", 5, "read right adder config" );
    ok( Moo::Role::does_role( $adder, "MooX::ConfigFromFile::Role" ), "Applying MooX::ConfigFromFile::Role to oCalc::add" );
}

SCOPE:
{
    local @ARGV = qw(--config-prefix operands);
    my $subber = oCalc::sub->new_with_options;
    ok( defined( $subber->a ), "read \"a\" from sub config" );
    ok( defined( $subber->b ), "read \"b\" from sub config" );
    cmp_ok( $subber->execute, "==", 17, "read right subber config" );
    ok( Moo::Role::does_role( $subber, "MooX::ConfigFromFile::Role" ), "Applying MooX::ConfigFromFile::Role to oCalc::sub" );
}

SCOPE:
{
    local @ARGV = @cfg_files[ 0 .. 1 ];
    my $mul = oCalc::mul->new_with_options;
    is( $mul->a, 21,, "read \"a\" from mul config" );
    is( $mul->b, 4,   "read \"b\" from mul config" );
    cmp_ok( $mul->execute, "==", 84, "read right mul config" );
}

SCOPE:
{
    local @ARGV = @cfg_files[ 2 .. 3 ];
    my $mul = oCalc::mul->new_with_options;
    is( $mul->a, 21,, "keep \"a\" from first mul config" );
    is( $mul->b, 4,   "keep \"b\" from first mul config" );
    cmp_ok( $mul->execute, "==", 84, "read right mul config" );
}

SCOPE:
{
    local @ARGV = @cfg_files[ 2 .. 3 ];
    my $div = oCalc::div->new_with_options;
    is( $div->a, 30,, "read \"a\" from small div config" );
    is( $div->b, 6,   "read \"b\" from small div config" );
    cmp_ok( $div->execute, "==", 5, "read right div config" );
}

SCOPE:
{
    local @ARGV = @cfg_files[ 4 .. 5 ];
    my $div = oCalc::div->new_with_options;
    is( $div->a, 666,, "read \"a\" from large div config" );
    is( $div->b, 222,  "read \"b\" from large div config" );
    cmp_ok( $div->execute, "==", 3, "read right div config" );
}
