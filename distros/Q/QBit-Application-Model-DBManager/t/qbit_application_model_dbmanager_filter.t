#!/usr/bin/perl -w

use Test::More;
use Test::Deep;

use qbit;

use FindBin qw($Bin);

use lib "$Bin/../lib";

subtest(
    'text' => sub {
        my $filter_class = 'QBit::Application::Model::DBManager::Filter::text';
        eval("require $filter_class");

        subtest(
            'IS NULL' => sub {
                my $filter    = [field => 'IS' => undef];
                my $db_filter = [field => 'IS' => \undef];
                my $text_filter = 'field IS NULL';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter), $db_filter,   'as_filter');
                is_deeply($filter_class->as_text($filter),   $text_filter, 'as_text');
            }
        );
        subtest(
            'IS NOT NULL' => sub {
                my $filter    = [field => 'IS NOT' => undef];
                my $db_filter = [field => 'IS NOT' => \undef];
                my $text_filter = 'field IS NOT NULL';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter), $db_filter,   'as_filter');
                is_deeply($filter_class->as_text($filter),   $text_filter, 'as_text');
            }
        );
    }
);

subtest(
    'number' => sub {
        my $filter_class = 'QBit::Application::Model::DBManager::Filter::number';
        eval("require $filter_class");

        subtest(
            'IS NULL' => sub {
                my $filter    = [field => 'IS' => undef];
                my $db_filter = [field => 'IS' => \undef];
                my $text_filter = 'field IS NULL';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter), $db_filter,   'as_filter');
                is_deeply($filter_class->as_text($filter),   $text_filter, 'as_text');
            }
        );
        subtest(
            'IS NOT NULL' => sub {
                my $filter    = [field => 'IS NOT' => undef];
                my $db_filter = [field => 'IS NOT' => \undef];
                my $text_filter = 'field IS NOT NULL';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter), $db_filter,   'as_filter');
                is_deeply($filter_class->as_text($filter),   $text_filter, 'as_text');
            }
        );
    }
);

subtest(
    'dictionary' => sub {
        my $filter_class = 'QBit::Application::Model::DBManager::Filter::dictionary';
        eval("require $filter_class");

        my $field_description = {
            id2key => {100   => "id100", 101   => "id101",},
            key2id => {id100 => 100,     id101 => 101,},
            label  => "Канал",
            type   => "dictionary",
            values =>
              [{id => 100, key => "id100", label => "Undefined",}, {id => 101, key => "id101", label => "OEMs",},],
        };

        subtest(
            '= 101' => sub {
                my $filter    = [field => '=' => 101];
                my $db_filter = [field => '=' => \101];
                my $text_filter = 'field = id101';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter, $field_description), $db_filter, 'as_filter');
                is_deeply($filter_class->as_text($filter, $field_description), $text_filter, 'as_text');
            }
        );

        subtest(
            'IS NULL' => sub {
                my $filter    = [field => 'IS' => undef];
                my $db_filter = [field => 'IS' => \undef];
                my $text_filter = 'field IS NULL';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter, $field_description), $db_filter, 'as_filter');
                is_deeply($filter_class->as_text($filter, $field_description), $text_filter, 'as_text');
            }
        );
        subtest(
            'IS NOT NULL' => sub {
                my $filter    = [field => 'IS NOT' => undef];
                my $db_filter = [field => 'IS NOT' => \undef];
                my $text_filter = 'field IS NOT NULL';

                eval {$filter_class->check($filter)};
                is("$@", '', 'check');

                is_deeply($filter_class->as_filter($filter, $field_description), $db_filter, 'as_filter');
                is_deeply($filter_class->as_text($filter, $field_description), $text_filter, 'as_text');
            }
        );
    }
);

done_testing();
