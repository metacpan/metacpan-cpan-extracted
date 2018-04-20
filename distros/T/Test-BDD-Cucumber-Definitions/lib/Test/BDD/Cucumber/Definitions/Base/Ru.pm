package Test::BDD::Cucumber::Definitions::Base::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::Base qw(Base);

our $VERSION = '0.37';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

=encoding utf8

=head1 NAME

Test::BDD::Cucumber::Definitions::Base::Ru - Шаги на русском языке для работы
с базой данных

=head1 SYNOPSIS

В файле B<features/step_definitions/base_steps.pl>:

    #!/usr/bin/perl

    use strict;
    use warnings;
    use utf8;
    use open qw(:std :utf8);

    use Test::BDD::Cucumber::Definitions::Base::Ru;
    use Test::BDD::Cucumber::Definitions::Struct::Ru;

В файле B<features/base.feature>:

    Feature: Base (Ru)
        Проверка записей в безе данных

    Scenario: Выборка из базы
        Given параметр базы "driver" установлен в значение "mysql"
        And параметр базы "host" установлен в значение "127.0.0.1"
        And параметр базы "port" установлен в значение "3306"
        And параметр базы "user" установлен в значение "user"
        And параметр базы "password" установлен в значение "password"
        And параметр базы "base" установлен в значение "base"
        When выполнен запрос к базе "select * from table where id = 1"
        Given результат запроса к базе прочитан как структура
        Then элемент структуры данных "$[0].name" равен "Name"

=head1 ПАРАМЕТРЫ БАЗЫ

Для подключения к базе и выполнения запросов нужно задать некоторые параметры:

=over 4

=item * B<driver> - Драйвер базы

Для подключения к какой-либо базе нужно установить соответствующий модуль DBD.
Например, для подключения к MySQL нужно установить модуль L<DBD::mysql> и указать
драйвер C<mysql>.

=item * B<host> - Хост базы

Можно использовать доменное имя или IP.

=item * B<port> - Порт базы

=item * B<user> - Пользователь базы

=item * B<password> - Пароль пользователя

=item * B<base> - Название базы

=back

=head1 ШАГИ

=cut

sub import {

=head2 Формирование запроса

=pod

Задать какой-либо параметр базы:

    Given параметр базы "host" установлен в значение "127.0.0.1"

=cut

    #        base param "(.+?)" set "(.*)"
    Given qr/параметр базы "(.+?)" установлен в значение "(.*)"/, sub {
        Base->param_set( $1, $2 );
    };

=head2 Выполнение запроса

=pod

Выполнить запрос:

    When выполнен запрос к базе "select * from table where id = 1"

    # или, для многострочного запроса

    When выполнен запрос к базе
    """
    select *
    from table
    where
        id = 1
    """


=cut

    #       base request send "(.+?)"
    When qr/выполнен запрос к базе "(.+?)"/, sub {
        Base->request_send($1);
    };

    #       base request send
    When qr/выполнен запрос к базе/, sub {
        Base->request_send( C->data() );
    };

    return;
}

1;

=head1 AUTHOR

Mikhail Ivanov C<< <m.ivanych@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

=pod
