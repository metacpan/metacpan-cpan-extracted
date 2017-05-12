use Test::Simple tests => 1;
eval 'use RTx::S3Invoker';
ok(!$@, $@);
