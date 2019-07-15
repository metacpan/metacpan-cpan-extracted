use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use Test::Simple;

XS::Loader::load('MyTest');

subtest "no args" => sub {
    catch_run();
    done_testing(5);
};

subtest "by name" => sub {
    catch_run('a');
    done_testing(1);
};

subtest "by tag1" => sub {
    catch_run('[single]');
    done_testing(3);
};

subtest "by tag2" => sub {
    catch_run('[multi]');
    done_testing(2);
};

subtest "import" => sub {
    my $called;
    {
        no warnings 'redefine';
        local *Test::More::done_testing = sub { $called = 1};
        Test::Catch->import("[multi]");
    }
    ok($called);
    done_testing(3);
};

done_testing();