use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    use_ok 'Parse::Crontab::Entry::Env';
}

my $entry = new_ok 'Parse::Crontab::Entry::Env', [line => 'hoge=fuga', line_number => 1];
ok !$entry->is_error;
is $entry->key,   'hoge';
is $entry->value, 'fuga';

$entry = new_ok 'Parse::Crontab::Entry::Env', [line => ' hoge = fuga ', line_number => 1];
ok !$entry->is_error;
is $entry->key,   'hoge';
is $entry->value, 'fuga';


$entry = new_ok 'Parse::Crontab::Entry::Env', [line => '"hoge"="fuga"', line_number => 1];
ok !$entry->is_error;
is $entry->key,   'hoge';
is $entry->value, 'fuga';

$entry = new_ok 'Parse::Crontab::Entry::Env', [line => q{'hoge'='fuga'}, line_number => 1];
ok !$entry->is_error;
is $entry->key,   'hoge';
is $entry->value, 'fuga';

$entry = new_ok 'Parse::Crontab::Entry::Env', [line => q{'ho'ge'='fuga'}, line_number => 1];
ok $entry->is_error;

done_testing;
