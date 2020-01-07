use Mojo::Base -strict;
use Mojo::Util ();
use Test::More;
use Test::Exception;
require Mojo::DB::Results::Role::MoreMethods;

plan skip_all => 'Mojo::Pg not installed' unless eval { require Mojo::Pg; 1 };
plan skip_all => 'Mojo::mysql not installed' unless eval { require Mojo::mysql; 1 };

lives_ok
    { Mojo::DB::Results::Role::MoreMethods->import() }
    'import with no arguments lives';

note 'Test -mysql flag';
throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-mysql', '-mysql') }
    qr/-mysql flag provided more than once/,
    'two -mysql flags throw';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-mysql', '-mysql', '-mysql') }
    qr/-mysql flag provided more than once/,
    'three -mysql flags throw';

lives_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-mysql') }
    'one -mysql flag lives';

note 'Test -Pg flag';
throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-Pg', '-Pg') }
    qr/-Pg flag provided more than once/,
    'two -Pg flags throw';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-Pg', '-Pg', '-Pg') }
    qr/-Pg flag provided more than once/,
    'three -Pg flags throw';

lives_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-Pg') }
    'one -Pg flag lives';

note 'Test results_class';
throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => undef) }
    qr/results_class must be a defined and non-empty value/,
    'undef results_class throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => '') }
    qr/results_class must be a defined and non-empty value/,
    'empty string results_class throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => {}) }
    qr/results_class must be a string or an arrayref/,
    'hashref results_class throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => []) }
    qr/results_class array cannot be empty/,
    'empty results_class array throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => [undef]) }
    qr/results_class array entries must be non-empty strings/,
    'undef results_class array element throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => ['']) }
    qr/results_class array entries must be non-empty strings/,
    'empty string results_class array element throws';

my $dump = Mojo::Util::dumper {key => 'value'};
throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => ['Mojo::mysql::Results'], key => 'value') }
    qr/unknown options provided to import: \Q$dump\E/,
    'unknown options throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-mysql', results_class => ['Mojo::mysql::Results']) }
    qr/cannot provide -mysql flag and provide Mojo::mysql::Results in result_class/,
    'providing -mysql and Mojo::mysql::Results throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import('-Pg', results_class => ['Mojo::Pg::Results']) }
    qr/cannot provide -Pg flag and provide Mojo::Pg::Results in result_class/,
    'providing -Pg and Mojo::Pg::Results throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => ['Mojo::Pg::Results', 'Mojo::mysql::Results', 'Mojo::mysql::Results']) }
    qr/Mojo::mysql::Results provided more than once to result_class/,
    'repeated Mojo::mysql::Results results classes throws';

throws_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => ['Mojo::mysql::Results', 'Mojo::Pg::Results', 'Mojo::Pg::Results']) }
    qr/Mojo::Pg::Results provided more than once to result_class/,
    'repeated Mojo::Pg::Results results classes throws';

lives_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => 'Mojo::mysql::Results') }
    'valid results_class string lives';

lives_ok
    { Mojo::DB::Results::Role::MoreMethods->import(results_class => ['Mojo::mysql::Results']) }
    'valid results_class array entry lives';

done_testing;
