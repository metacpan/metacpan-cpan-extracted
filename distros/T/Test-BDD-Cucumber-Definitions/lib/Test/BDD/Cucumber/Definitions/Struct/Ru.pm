package Test::BDD::Cucumber::Definitions::Struct::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(:util);

our $VERSION = '0.29';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

=encoding utf8

=head1 NAME

Test::BDD::Cucumber::Definitions::Struct::Ru - Шаги на русском языке
для работы с perl-структурами данных

=head1 SYNOPSIS

В файле B<features/step_definitions/struct_steps.pl>:

    #!/usr/bin/perl

    use strict;
    use warnings;
    use utf8;
    use open qw(:std :utf8);

    use Test::BDD::Cucumber::Definitions::HTTP::Ru;
    use Test::BDD::Cucumber::Definitions::Struct::Ru;

В файле B<features/struct.feature>:

    Feature: Struct (Ru)
        Работа с perl-структурами данных

    Scenario: HTTP->JSON->Struct
        When HTTP-запрос "GET" отправлен на "https://fastapi.metacpan.org/v1/distribution/Test-BDD-Cucumber-Definitions"
        When содержимое HTTP-ответа прочитано как JSON
        Then элемент структуры данных "$.name" совпадает с "Test-BDD-Cucumber-Definitions"

=head1 ИСТОЧНИКИ ДАННЫХ

Данные могут быть загружены в структуру из различных источников данных.

Для работы с источниками требуется использование модуля Struct
совместно с другими модулями, например HTTP.

=head1 ШАГИ

=cut

sub import {

=head2 Чтение данных

=pod

Прочитать JSON из L<HTTP-ответа|Test::BDD::Cucumber::Definitions::HTTP::Ru>
в perl-структуру:

    When содержимое HTTP-ответа прочитано как JSON

=cut

    #       http response content read JSON
    When qr/содержимое HTTP-ответа прочитано как JSON/, sub {
        http_response_content_read_json();
    };

=pod

Прочитать список файлов L<Zip-архива|Test::BDD::Cucumber::Definitions::HTTP::Ru>
в perl-структуру

    When перечень файлов Zip-архива прочитан как список

=cut

    #       zip archive members read list
    When qr/перечень файлов Zip-архива прочитан как список/, sub {
        zip_archive_members_read_list();
    };

=head2 Проверка данных

Для обращения к произвольным элементам структуры данных используется
L<JSON::Path>.

=pod

Проверить элемент на точное соответствие значению:

    Then элемент структуры данных "$.status" равен "success"

=cut

    #       struct data element "(.+?)" eq "(.*)"
    Then qr/элемент структуры данных "(.+?)" равен "(.*)"/, sub {
        struct_data_element_eq( $1, $2 );
    };

=pod

Проверить массив структур на наличие элемента, точно соответствующего значению:

    Then массив структур данных "$[*]" содержит элемент, равный "user_42"

=cut

    #       struct data array "(.+?)" any eq "(.*)"
    Then qr/массив структур данных "(.+?)" содержит элемент, равный "(.*)"/,
        sub {
        struct_data_array_any_eq( $1, $2 );
        };

=pod

Проверить элемент на совпадение с регулярным выражением:

    Then элемент структуры данных "$.name" совпадает с "Test-*"

=cut

    #       struct data element "(.+?)" re "(.*)"
    Then qr/элемент структуры данных "(.+?)" совпадает с "(.*)"/, sub {
        struct_data_element_re( $1, $2 );
    };

=pod

Проверить массив структур на наличие элемента, совпадающего с регулярным выражением:

    Then массив структур данных  "$[*]" содержит элемент, совпадающий с ".+42"

=cut

    #       struct data array "(.+?)" any re "(.*)"
    Then
        qr/массив структур данных "(.+?)" содержит элемент, совпадающий с "(.*)"/,
        sub {
        struct_data_array_any_re( $1, $2 );
        };

=pod

Проверить количество элементов в массиве структур данных:

    Then массив структур данных "$[*]" содержит "1" элемент
    Then массив структур данных "$[*]" содержит "4" элемента
    Then массив структур данных "$[*]" содержит "6" элементов

=cut

    #       struct data array "(.+?)" count "(.*)"
    Then qr/массив структур данных "(.+?)" содержит "(.*)" элемент(?:а|ов)?/,
        sub {
        struct_data_array_count( $1, $2 );
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
