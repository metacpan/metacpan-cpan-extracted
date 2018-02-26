package Test::BDD::Cucumber::Definitions::Struct::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Struct qw(:util);

=encoding utf8

=head1 NAME

Test::BDD::Cucumber::Definitions::Struct::Ru - Шаги на русском языке
для работы с perl-структурами данных

=cut

our $VERSION = '0.19';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

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
        Работа perl-структурами данных

    Scenario: HTTP->JSON->Struct
        When HTTP-запрос "GET" отправлен на "https://fastapi.metacpan.org/v1/distribution/Test-BDD-Cucumber-Definitions"
        When содержимое HTTP-ответа прочитано как JSON
        Then элемент структуры данных "$.name" совпадает с "Test-BDD-Cucumber-Definitions"

=head1 ИСТОЧНИКИ ДАННЫХ

Данные могут быть загружены в структуру из различных источников данных.

Для работы с источниками требуется использование модуля Struct
совместно с другими модулями, например HTTP.

=head1 ШАГИ

=head2 Чтение данных

=pod

Прочитать данные из L<HTTP-ответа|Test::BDD::Cucumber::Definitions::HTTP::Ru>
в L<perl-структуру|Test::BDD::Cucumber::Definitions::Struct::Ru>:

    When содержимое HTTP-ответа прочитано как JSON

=cut

# http response content read JSON
When qr/содержимое HTTP-ответа прочитано как JSON/, sub {
    read_content();
};

=head2 Проверка данных

Для обращения к произвольным элементам структуры данных используется
L<JSON::Path>.

=pod

Проверить элемент на точное соответствие значению:

    Then элемент структуры данных "$.status" равен "success"

=cut

# struct data element "" eq ""
Then qr/элемент структуры данных "(.+?)" равен "(.*)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_eq( $jsonpath, $value );
};

=pod

Проверить элемент на совпадение с регулярным выражением:

    Then элемент структуры данных "$.name" совпадает с "Test-*"

=cut

# struct data element "" re ""
Then qr/элемент структуры данных "(.+?)" совпадает с "(.+)"/, sub {
    my ( $jsonpath, $value ) = ( $1, $2 );

    jsonpath_re( $jsonpath, $value );
};

1;

=head1 AUTHOR

Mikhail Ivanov C<< <m.ivanych@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

=pod
