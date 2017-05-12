use Test::More tests => 12;

BEGIN {
    use_ok('Test::Behaviour::Spec');
}

diag("Testing Test::Behaviour::Spec $Test::Behaviour::Spec::VERSION");

{
    # meta TB::Spec :-p
    my $subject;
    my $statement;

    sub DESCRIBE { $subject = shift }
    sub IT { $statement = shift }
    sub SPEC { join " ", $subject, $statement }
}

{
    DESCRIBE 'TB::Spec';
        my $it = 'Test::Behaviour::Spec';

    IT 'should describe a subject of behaviours.';
        ok $it->can('describe'), SPEC;

    IT 'should set a behaviour statement.';
        ok $it->can('it'), SPEC;

    IT 'should get a behaviour specification.';
        ok $it->can('spec'), SPEC;
}

{
    DESCRIBE 'TB::Spec, when writing behaviours,';

        my $s0 = 'Foo, when foo,';
        my $b0 = 'should foo ...';
        describe $s0;
        it $b0;

    IT 'should build spec with the describe.';
        ok index(spec(), $s0) >= 0, SPEC;

    IT 'should build spec from the behaviour.';
        ok index(spec(), $b0) >= 0, SPEC;
}

{
    DESCRIBE 'TB::Spec, when describe changed,';

        my $s0 = 'Foo, when foo,';
        my $b0 = 'should foo ...';
        describe $s0;
        it $b0;
        my $s1 = 'Bar, when bar,';
        describe $s1;

    IT 'should drop previous describe.';
        ok index(spec(), $s0) == -1, SPEC;

    IT 'should has changed describe.';
        ok index(spec(), $s1) >= 0, SPEC;

    IT 'should drop previous behaviour.';
        ok index(spec(), $b0) == -1, SPEC;
}

{
    DESCRIBE 'TB::Spec, when behaviour changed,';

        my $s0 = 'Foo, when foo,';
        my $b0 = 'should foo ...';
        my $b1 = 'must bar ...';
        my $b2 = 'baz ...';
        describe $s0;
        it $b0;
        it $b1;
        it $b2;

    IT 'should keep describe.';
        ok index(spec(), $s0) >=0, SPEC;

    IT 'should has latest behaviour.';
        ok index(spec(), $b2) >= 0, SPEC;

    IT 'should drop previous behaviour.';
        ok index(spec(), $b0) == -1 && index(spec(), $b1) == -1, SPEC;
}
