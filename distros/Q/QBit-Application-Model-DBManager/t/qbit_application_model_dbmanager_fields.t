#!/usr/bin/perl -w

use Test::More;
use Test::Deep;

use qbit;

use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/lib";

use TestApplication;

my $app = TestApplication->new();

$app->pre_run();

subtest(
    'locale_field' => sub {
        subtest(
            'ru' => sub {
                $app->set_app_locale('ru');

                $TestQuery::DATA = [
                    {
                        id        => 1,
                        parent_id => 2,
                        caption   => 'caption 1 ru',
                    },
                    {
                        id        => 2,
                        parent_id => 1,
                        caption   => 'caption 2 ru',
                    },
                ];

                cmp_deeply(
                    $app->test_model->get_all(),
                    [
                        {
                            id        => 1,
                            parent_id => 2,
                            caption   => 'caption 1 ru',
                        },
                        {
                            id        => 2,
                            parent_id => 1,
                            caption   => 'caption 2 ru',
                        },
                    ]
                );
            },
        );

        subtest(
            'en' => sub {
                $app->set_app_locale('en');

                $TestQuery::DATA = [
                    {
                        id        => 1,
                        parent_id => 2,
                        caption   => 'caption 1 en',
                    },
                    {
                        id        => 2,
                        parent_id => 1,
                        caption   => 'caption 2 en',
                    },
                ];

                cmp_deeply(
                    $app->test_model->get_all(),
                    [
                        {
                            id        => 1,
                            parent_id => 2,
                            caption   => 'caption 1 en',
                        },
                        {
                            id        => 2,
                            parent_id => 1,
                            caption   => 'caption 2 en',
                        },
                    ]
                );
            },
        );

        subtest(
            'all_locales' => sub {
                $TestQuery::DATA = [
                    {
                        id         => 1,
                        parent_id  => 2,
                        caption_en => 'caption 1 en',
                        caption_ru => 'caption 1 ru',
                    },
                    {
                        id         => 2,
                        parent_id  => 1,
                        caption_en => 'caption 2 en',
                        caption_ru => 'caption 2 ru',
                    },
                ];

                cmp_deeply(
                    $app->test_model->get_all(all_locales => TRUE),
                    [
                        {
                            id        => 1,
                            parent_id => 2,
                            caption   => {
                                en => 'caption 1 en',
                                ru => 'caption 1 ru',
                            },
                        },
                        {
                            id        => 2,
                            parent_id => 1,
                            caption   => {
                                en => 'caption 2 en',
                                ru => 'caption 2 ru',
                            },
                        },
                    ]
                );
            }
        );
    },
);

subtest(
    'get' => sub {
        subtest(
            'get without right' => sub {
                $TestQuery::DATA = [
                    {
                        id        => 1,
                        parent_id => 2,
                        caption   => 'caption 1 en',
                        secret    => 's3cret1',
                        fix_db    => 10,
                    },
                    {
                        id        => 2,
                        parent_id => 1,
                        caption   => 'caption 2 en',
                        secret    => 's3cret2',
                        fix_db    => 20,
                    },
                ];

                cmp_deeply(
                    $app->test_model->get_all(fields => [keys(%{$app->test_model->get_model_fields()})]),
                    [
                        {
                            id        => 1,
                            parent_id => 2,
                            caption   => 'caption 1 en',
                            view_id   => "id: 1, parent_id: 2",
                            parent    => 'PARENT 2',
                            reverse   => '1terc3s',
                            fix_db    => 100,
                        },
                        {
                            id        => 2,
                            parent_id => 1,
                            caption   => 'caption 2 en',
                            view_id   => "id: 2, parent_id: 1",
                            parent    => 'PARENT 1',
                            reverse   => '2terc3s',
                            fix_db    => 200,
                        },
                    ]
                );
            }
        );

        subtest(
            'get with right' => sub {
                my $tmp_rights = $app->add_tmp_rights('view_secret');

                $TestQuery::DATA = [
                    {
                        id        => 1,
                        parent_id => 2,
                        caption   => 'caption 1 en',
                        secret    => 's3cret1',
                        fix_db    => 10,
                    },
                    {
                        id        => 2,
                        parent_id => 1,
                        caption   => 'caption 2 en',
                        secret    => 's3cret2',
                        fix_db    => 20,
                    },
                ];

                cmp_deeply(
                    $app->test_model->get_all(fields => [keys(%{$app->test_model->get_model_fields()})]),
                    [
                        {
                            id          => 1,
                            parent_id   => 2,
                            caption     => 'caption 1 en',
                            view_id     => "id: 1, parent_id: 2",
                            parent      => 'PARENT 2',
                            reverse     => '1terc3s',
                            fix_db      => 100,
                            secret      => 's3cret1',
                            view_secret => 's3cret1',
                        },
                        {
                            id          => 2,
                            parent_id   => 1,
                            caption     => 'caption 2 en',
                            view_id     => "id: 2, parent_id: 1",
                            parent      => 'PARENT 1',
                            reverse     => '2terc3s',
                            fix_db      => 200,
                            secret      => 's3cret2',
                            view_secret => 's3cret2',
                        },
                    ]
                );
            }
        );

        subtest(
            'get all fields with "*"' => sub {
                my $tmp_rights = $app->add_tmp_rights('view_secret');

                $TestQuery::DATA = [
                    {
                        id        => 1,
                        parent_id => 2,
                        caption   => 'caption 1 en',
                        secret    => 's3cret1',
                        fix_db    => 10,
                    },
                    {
                        id        => 2,
                        parent_id => 1,
                        caption   => 'caption 2 en',
                        secret    => 's3cret2',
                        fix_db    => 20,
                    },
                ];

                cmp_deeply(
                    $app->test_model->get_all(fields => ['*']),
                    [
                        {
                            id          => 1,
                            parent_id   => 2,
                            caption     => 'caption 1 en',
                            view_id     => "id: 1, parent_id: 2",
                            parent      => 'PARENT 2',
                            reverse     => '1terc3s',
                            fix_db      => 100,
                            secret      => 's3cret1',
                            view_secret => 's3cret1',
                        },
                        {
                            id          => 2,
                            parent_id   => 1,
                            caption     => 'caption 2 en',
                            view_id     => "id: 2, parent_id: 1",
                            parent      => 'PARENT 1',
                            reverse     => '2terc3s',
                            fix_db      => 200,
                            secret      => 's3cret2',
                            view_secret => 's3cret2',
                        },
                    ]
                );
            }
        );
    }
);

$app->post_run();

done_testing();
