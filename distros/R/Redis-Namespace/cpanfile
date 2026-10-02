requires 'perl', '5.014000';
requires 'Redis';

on 'test' => sub {
   requires 'Test::More';
   requires 'Test::Exception';
   requires 'Test::Deep';
   requires 'Test::Fatal';
   requires 'Test::TCP';
   requires 'File::Temp';
   requires 'Test::RedisServer';
};

on 'develop' => sub {
   requires 'Test::Kwalitee';
   requires 'Test::Kwalitee::Extra';
};
