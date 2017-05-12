# -*- perl -*-

# t/13_rt_112156.t - RT112156 inheritance

use Test::Most tests => 2+1;
use Test::NoWarnings;

use lib 't/testlib';

{
    package Test13;
    use MooseX::App qw(Depends);

    option 'unrelated' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'One thing',
    );
}

{
    package Test13::SomeCommand;
    use MooseX::App::Command;
    # no inheritance

    option 'one' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'One thing',
        depends        => ['other'],
    );

    option 'other' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'Other thing',
    );

    sub run {
        my ($self) = @_;
        return "ok";
    }
}

{
    package Test13::AnotherCommand;
    use MooseX::App::Command;
    extends qw(Test13);

    option 'one' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'One thing',
        depends        => ['other'],
    );

    option 'other' => (
        is             => 'rw',
        isa            => 'Int',
        documentation  => 'Other thing',
    );

    sub run {
        my ($self) = @_;
        return "ok";
    }
}

subtest 'no inheritance' => sub {
    plan tests => 8;

    {
        MooseX::App::ParsedArgv->new(argv => [qw(some --one 1 --other 2)]);
        my $test01 = Test13->new_with_command();
        isa_ok($test01,'Test13::SomeCommand');
        is($test01->one,1,'Option ok');
        is($test01->other,2,'Option ok');
        ok(! $test01->can('unrelated'),'No option');
    }

    {
        MooseX::App::ParsedArgv->new(argv => [qw(another --one 1 --other 2 --unrelated 3)]);
        my $test02 = Test13->new_with_command();
        isa_ok($test02,'Test13::AnotherCommand');
        is($test02->one,1,'Option ok');
        is($test02->other,2,'Option ok');
        is($test02->unrelated,3,'Option ok');
    }
};

subtest 'check plugin functionality' => sub {
    plan tests => 2;

    {
        MooseX::App::ParsedArgv->new(argv => [qw(some --one 1)]);
        my $test03 = Test13->new_with_command();
        isa_ok( $test03, 'MooseX::App::Message::Envelope' );
    }

    {
        MooseX::App::ParsedArgv->new(argv => [qw(another --one 1)]);
        my $test03 = Test13->new_with_command();
        isa_ok( $test03, 'MooseX::App::Message::Envelope' );
    }
};
