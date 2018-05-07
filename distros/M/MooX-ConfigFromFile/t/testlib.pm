use strict;
use warnings FATAL => "all";

use FindBin;

eval sprintf( <<'EOCDECL', ($main::OO) x 9);
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
      Calc::add_with_merge;
    use %s;
    use MooX::ConfigFromFile config_hashmergeloaded => 1;

    with "Calc::Role::BinaryOperation";

    sub execute
    {
        my $self = shift;
        return $self->a + $self->b;
    }
}

{
    package    #
      Calc::extended_add;
    use %s;
    extends "Calc::add";
    with "MooX::ConfigFromFile::Role::HashMergeLoaded";
    with "MooX::ConfigFromFile::Role::SortedByFilename";
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
      config_prefix           => "calc-operands",
      config_sortedbyfilename => 1,
      config_singleton        => 1;

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
    use MooX::ConfigFromFile
      config_sortedbyfilename => 0,
      config_hashmergeloaded  => 0;

    sub execute
    {
        return;
    }
}

{
    package    #
      Mock::Cfg;

    use %s;
    use MooX::ConfigFromFile
      config_sortedbyfilename => 1,
      config_hashmergeloaded  => 1;

    sub execute
    {
        return;
    }
}
EOCDECL

# This is for warn once
note $main::OO;

my $adder = Calc::add->new(config_prefix => "calc-operands");
ok(defined($adder->a), "read \"a\" from add config");
ok(defined($adder->b), "read \"b\" from add config");
cmp_ok($adder->execute, "==", 5, "read right adder config");
ok(Moo::Role::does_role($adder, "MooX::ConfigFromFile::Role"), "Applying MooX::ConfigFromFile::Role");

my $secadd = Calc::add->new(config_prefixes => [qw(calc operands)]);
ok(defined($secadd->a), "read \"a\" from add configs");
ok(defined($secadd->b), "read \"b\" from add configs");
cmp_ok($secadd->execute, "==", 7, "use topmost adder config");
ok(Moo::Role::does_role($secadd, "MooX::ConfigFromFile::Role"), "Applying MooX::ConfigFromFile::Role");

my $thiadd = Calc::add_with_merge->new(config_prefixes => [qw(calc operands)]);
ok(defined($thiadd->a), "read \"a\" from add configs");
ok(defined($thiadd->b), "read \"b\" from add configs");
cmp_ok($thiadd->execute, "==", 5, "read proper adder config");
ok(Moo::Role::does_role($thiadd, "MooX::ConfigFromFile::Role"), "Applying MooX::ConfigFromFile::Role");

my $fouadd = Calc::extended_add->new(config_prefixes => [qw(calc operands)]);
ok(defined($fouadd->a), "read \"a\" from add configs");
ok(defined($fouadd->b), "read \"b\" from add configs");
cmp_ok($fouadd->execute, "==", 7, "use topmost adder config");
ok(Moo::Role::does_role($fouadd, "MooX::ConfigFromFile::Role"), "Applying MooX::ConfigFromFile::Role");

my @copy_attrs = qw(dirs extensions merger merge_behavior);
foreach my $copy_attr ('raw_loaded_config', 'sorted_loaded_config', map { "config_$_" } @copy_attrs)
{
    my $fivadd = Calc::extended_add->new(
        $copy_attr      => $fouadd->$copy_attr,
        config_prefixes => [qw(calc operands)]
    );
    ok(defined($fivadd->a), "read \"a\" from add config using $copy_attr");
    ok(defined($fivadd->b), "read \"b\" from add config using $copy_attr");
    cmp_ok($fivadd->execute, "==", 7, "read topmost adder config using $copy_attr");
}

@copy_attrs = qw(extensions dirs prefix prefixes prefix_map prefix_map_separator files_pattern files);
foreach my $copy_attr ('sorted_loaded_config', map { "config_$_" } @copy_attrs)
{
    my $subber = Calc::sub->new($copy_attr => $adder->$copy_attr);
    ok(defined($subber->a), "read \"a\" from sub config using $copy_attr");
    ok(defined($subber->b), "read \"b\" from sub config using $copy_attr");
    cmp_ok($subber->execute, "==", -1, "read right subber config using $copy_attr");
}

my $secsub = Calc::sub->new(
    raw_loaded_config => [
        {
            t => {
                b => 2,
                a => 4
            }
        }
    ]
);
ok(defined($secsub->a), "read \"a\" from sub config");
ok(defined($secsub->b), "read \"b\" from sub config");
cmp_ok($secsub->execute, "==", 2, "use right secsub config");
ok(Moo::Role::does_role($secsub, "MooX::ConfigFromFile::Role"), "Applying MooX::ConfigFromFile::Role");

my $mul1 = Calc::mul->new(b => 4);
ok(defined($mul1->a), "read \"a\" from mul1 config");
ok(defined($mul1->b), "read \"b\" from mul1 config");
cmp_ok($mul1->execute, "==", 8, "read right mul config");

my $mul2 = Calc::mul->new(config_prefix => "no-calc-operands");
ok(defined($mul2->a), "copy \"a\" from mul1 config");
ok(defined($mul2->b), "copy \"b\" from mul1 config");
cmp_ok($mul2->execute, "==", 6, "right mul2 config duplicated");

my $mul3 = $mul2->new;
cmp_ok($mul3->execute, "==", 6, "right mul3 config duplicated");

my $div1 = Calc::div->new(12, 3);
ok(defined($div1->a), "read \"a\" from div1 config");
ok(defined($div1->b), "read \"b\" from div1 config");
cmp_ok($div1->execute, "==", 4, "read right div1 config");

my $div2 = Calc::div->new(12, 6);
ok(defined($div2->a), "read \"a\" from div2 config");
ok(defined($div2->b), "read \"b\" from div2 config");
cmp_ok($div2->execute, "==", 2, "read right div2 config");

my $dumb = Dumb::Cfg->new(config_dirs => 1);
isa_ok($dumb, "Dumb::Cfg");
is($dumb->config_prefix, $FindBin::Script, "fallback config prefix");
is_deeply($dumb->config_dirs,     [qw(.)],            "fallback config dirs");
is_deeply($dumb->config_prefixes, [$FindBin::Script], "fallback config prefix");

my $mock = Mock::Cfg->new(
    config_dirs       => [qw(/etc /opt/ctrl/etc /home/usr4711)],
    config_extensions => [qw(json yaml)],
    raw_loaded_config => [
        # global configuration by developers
        {'/etc/oper.json' => {}},
        # global configuration by operating policy
        {'/etc/oper.yaml' => {}},
        # vendor configuration by developers
        {'/opt/ctrl/etc/oper.json' => {}},
        # vendor configuration by operating policy
        {'/opt/ctrl/etc/oper.yaml' => {}},
        # vendor configuration by stage operating policy
        {'/opt/ctrl/etc/oper-int.yaml' => {}},
        # vendor configuration by report operating team
        {'/opt/ctrl/etc/oper-report.yaml' => {}},
        # usr4711 individual configuration (e.g. for template adoption)
        {'/home/usr4711/oper-report.yaml' => {}},
    ]
);
isa_ok($mock, "Mock::Cfg");
is_deeply(
    $mock->sorted_loaded_config,
    [
        {'/etc/oper.json'                 => {}},
        {'/opt/ctrl/etc/oper.json'        => {}},
        {'/etc/oper.yaml'                 => {}},
        {'/opt/ctrl/etc/oper.yaml'        => {}},
        {'/opt/ctrl/etc/oper-int.yaml'    => {}},
        {'/opt/ctrl/etc/oper-report.yaml' => {}},
        {'/home/usr4711/oper-report.yaml' => {}}
    ],
    "Filename based sort order"
);

my $mock2 = Mock::Cfg->new(raw_loaded_config => []);
is_deeply($mock2->sorted_loaded_config, []);
