use Test::More;
use FindBin;
use Parser::FIT;

my $testFile = $FindBin::Bin . "/test-files/activity_multisport.fit";

subtest "de-register ctor handler", sub {
    my $recordCount = 0;
    my $parser = Parser::FIT->new(on => { record => sub {
        $recordCount++;
    }});

    $parser->on("record", 0);

    $parser->parse($testFile);

    is($recordCount, 0, "no callback called, since callback was de-registered");
};

subtest "de-register on handler", sub {
    my $recordCount = 0;
    my $parser = Parser::FIT->new();

    $parser->on("record" => sub { $recordCount++ });

    $parser->on("record", 0);

    $parser->parse($testFile);

    is($recordCount, 0, "no callback called, since callback was de-registered");
};

subtest "register handler via ctor", sub {
    my $recordCount = 0;
    my $parser = Parser::FIT->new(on => { record => sub { $recordCount++ } });

    $parser->parse($testFile);

    ok($recordCount > 0, "seen some records");
};

subtest "register handler on", sub {
    my $recordCount = 0;
    my $parser = Parser::FIT->new();
    $parser->on(record => sub { $recordCount++ });

    $parser->parse($testFile);

    ok($recordCount > 0, "seen some records");
};

subtest "overwrite ctor handler", sub {
    my $ctorRecordCount = 0;
    my $onRecordCount = 0;

    my $parser = Parser::FIT->new(on => { record => sub { $recordCount++ } });
    $parser->on(record => sub { $onRecordCount++ });

    $parser->parse($testFile);

    is($ctorRecordCount, 0, "ctor handler hasn't seen records");
    ok($onRecordCount > 0, "seen some records");
};

subtest "overwrite on handler", sub {
    my $firstRecordCount = 0;
    my $secondRecordCount = 0;

    my $parser = Parser::FIT->new();
    
    $parser->on(record => sub { $firstRecordCount++ });
    $parser->on(record => sub { $secondRecordCount++ });

    $parser->parse($testFile);

    is($firstRecordCount, 0, "ctor handler hasn't seen records");
    ok($secondRecordCount > 0, "seen some records");
};

subtest "deregister inside callback", sub {
    my $recordCount = 0;

    my $parser = Parser::FIT->new();
    
    $parser->on(record => sub {
        $recordCount++;
        $parser->on(record => 0);
    });

    $parser->parse($testFile);

    is($recordCount, 1, "saw one record, then de-registered itself");
};


done_testing;