package Test::BDD::Cucumber::Definitions::HTTP::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(C Given When Then);
use Test::BDD::Cucumber::Definitions::HTTP qw(:util);

=encoding utf8

=head1 NAME

Test::BDD::Cucumber::Definitions::HTTP::Ru - Шаги на русском языке для работы
с веб-ресурсами по протоколу HTTP

=cut

our $VERSION = '0.29';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

=head1 SYNOPSIS

В файле B<features/step_definitions/http_steps.pl>:

    #!/usr/bin/perl

    use strict;
    use warnings;
    use utf8;
    use open qw(:std :utf8);

    use Test::BDD::Cucumber::Definitions::HTTP::Ru;

В файле B<features/http.feature>:

    Feature: HTTP (Ru)
        Проверка веб-ресурсов по протоколу HTTP

    Scenario: Загрузка страницы
        When HTTP-запрос "GET" отправлен на "http://metacpan.org"
        Then код HTTP-ответа равен "200"

=head1 ШАГИ

=cut

sub import {

=head2 Формирование запроса

=pod

Задать любой заголовок запроса с любым значением:

    When заголовок HTTP-запроса "User-Agent" установлен в значение "TBCD"

=cut

    #       http request header "(.+?)" set "(.*)"
    When qr/заголовок HTTP-запроса "(.+?)" установлен в значение "(.*)"/, sub {
        http_request_header_set( $1, $2 );
    };

=pod

Использовать в запросе данные произвольного вида и размера (предполагается
отправка POST-запросом):

    When тело HTTP-запроса заполнено данными
        """
        какие-то
        данные
        любого вида
        """

=cut

    #       http request content set
    When qr/тело HTTP-запроса заполнено данными/, sub {
        http_request_content_set( C->data() );
    };

=head2 Отправка запроса

=pod

Отправить запрос любым HTTP-методом на любой URL (внутри URL можно использовать
переменные окружения):

    When HTTP-запрос "GET" отправлен на "http://${TEST_HOST}/index.html"

=cut

    #       http request "(.+?)" send "(.+)"
    When qr/HTTP-запрос "(.+?)" отправлен на "(.+)"/, sub {
        http_request_send( $1, $2 );
    };

=head2 Проверка ответа

=pod

Проверить код ответа:

    Then код HTTP-ответа равен "200"

=cut

    #       http response code eq "(.+)"
    Then qr/код HTTP-ответа равен "(.+)"/, sub {
        http_response_code_eq($1);
    };

=pod

Проверить любой заголовок ответа на точное соответствие значению:

    Then заголовок HTTP-ответа "Server" равен "Nginx"

=cut

    #       http response header "(.+?)" eq "(.*)"
    Then qr/заголовок HTTP-ответа "(.+?)" равен "(.*)"/, sub {
        http_response_header_eq( $1, $2 );
    };

=pod

Проверить любой заголовок ответа на совпадение с регулярным выражением:

    Then заголовок HTTP-ответа "Content-Type" совпадает с "text/*"

=cut

    #       http response header "(.+?)" re "(.+)"
    Then qr/заголовок HTTP-ответа "(.+?)" совпадает с "(.+)"/, sub {
        http_response_header_re( $1, $2 );
    };

=pod

Проверить содержимое ответа на точное соответствие значению:

    Then содержимое HTTP-ответа равно "42"

=cut

    #       http response content eq "(.*)"
    Then qr/содержимое HTTP-ответа равно "(.*)"/, sub {
        http_response_content_eq($1);
    };

=pod

Проверить содержимое ответа на совпадение с регулярным выражением:

    Then содержимое HTTP-ответа совпадает с "<title>.+</title>"

=cut

    #       http response content re "(.+)"
    Then qr/содержимое HTTP-ответа совпадает с "(.+)"/, sub {
        http_response_content_re($1);
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
