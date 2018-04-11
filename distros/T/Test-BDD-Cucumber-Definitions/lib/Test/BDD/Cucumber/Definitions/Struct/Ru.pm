package Test::BDD::Cucumber::Definitions::Struct::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(Struct);

our $VERSION = '0.34';

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
        Given содержимое HTTP-ответа прочитано как JSON
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

    Given содержимое HTTP-ответа прочитано как JSON

=cut

    #        read http response content as JSON
    Given qr/содержимое HTTP-ответа прочитано как JSON/, sub {
        Struct->read_http_response_content_as_json();
    };

=pod

Прочитать JSON из L<Файла|Test::BDD::Cucumber::Definitions::File::Ru>
в perl-структуру:

    Given содержимое файла прочитано как JSON

=cut

    #        read file content as JSON
    Given qr/содержимое файла прочитано как JSON/, sub {
        Struct->read_file_content_as_json();
    };

=pod

Прочитать список файлов L<Zip-архива|Test::BDD::Cucumber::Definitions::HTTP::Ru>
в perl-структуру

    Given перечень файлов Zip-архива прочитан как список

=cut

    #        read zip archive members as list
    Given qr/перечень файлов Zip-архива прочитан как список/, sub {
        Struct->read_zip_archive_members_as_list();
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
        Struct->data_element_eq( $1, $2 );
    };

=pod

Проверить массив структур на наличие элемента, точно соответствующего значению:

    Then массив структур данных "$[*]" содержит элемент, равный "user_42"

=cut

    #       struct data list "(.+?)" any eq "(.*)"
    Then qr/массив структур данных "(.+?)" содержит элемент, равный "(.*)"/,
        sub {
        Struct->data_list_any_eq( $1, $2 );
        };

=pod

Проверить элемент на совпадение с регулярным выражением:

    Then элемент структуры данных "$.name" совпадает с "Test-*"

=cut

    #       struct data element "(.+?)" re "(.*)"
    Then qr/элемент структуры данных "(.+?)" совпадает с "(.*)"/, sub {
        Struct->data_element_re( $1, $2 );
    };

=pod

Проверить массив структур на наличие элемента, совпадающего с регулярным выражением:

    Then массив структур данных  "$[*]" содержит элемент, совпадающий с ".+42"

=cut

    #       struct data list "(.+?)" any re "(.*)"
    Then
        qr/массив структур данных "(.+?)" содержит элемент, совпадающий с "(.*)"/,
        sub {
        Struct->data_list_any_re( $1, $2 );
        };

=pod

Проверить количество элементов в массиве структур данных:

    Then массив структур данных "$[*]" содержит "1" элемент
    Then массив структур данных "$[*]" содержит "4" элемента
    Then массив структур данных "$[*]" содержит "6" элементов

=cut

    #       struct data list "(.+?)" count "(.*)"
    Then qr/массив структур данных "(.+?)" содержит "(.*)" элемент(?:а|ов)?/,
        sub {
        Struct->data_list_count( $1, $2 );
        };

=pod

Проверить элемент на наличие ключа:

    Then элемент структуры данных "$.user" содержит ключ "login"

=cut

    #       struct data element "(.+?)" key "(.*)"
    Then qr/элемент структуры данных "(.+?)" содержит ключ "(.*)"/, sub {
        Struct->data_element_key( $1, $2 );
    };

=pod

Проверить элементы в списке на наличие ключа:

    Then все элементы в списке структур данных "$.users" содержат ключ "login"

=cut

    #       struct data list "(.+?)" all key "(.*)"
    Then
        qr/все элементы в списке структур данных "(.+?)" содержат ключ "(.*)"/,
        sub {
        Struct->data_list_all_key( $1, $2 );
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
