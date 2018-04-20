package Test::BDD::Cucumber::Definitions::Zip::Ru;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions qw(Given When Then);
use Test::BDD::Cucumber::Definitions::Zip qw(Zip);

our $VERSION = '0.37';

## no critic [RegularExpressions::ProhibitCaptureWithoutTest]
## no critic [RegularExpressions::RequireExtendedFormatting]
## no critic [RegularExpressions::ProhibitComplexRegexes]

=encoding utf8

=head1 NAME

Test::BDD::Cucumber::Definitions::Zip::Ru - Шаги на русском языке
для работы с архивами Zip

=head1 SYNOPSIS

В файле B<features/step_definitions/zip_steps.pl>:

    #!/usr/bin/perl

    use strict;
    use warnings;
    use utf8;
    use open qw(:std :utf8);

    use Test::BDD::Cucumber::Definitions::HTTP::Ru;
    use Test::BDD::Cucumber::Definitions::Zip::Ru;

В файле B<features/zip.feature>:

    Feature: Zip (Ru)
        Работа с архивами Zip

    Scenario: HTTP->Zip
        When HTTP-запрос "GET" отправлен на "http://example.com/test.zip"
        Given содержимое HTTP-ответа прочитано как Zip

=head1 ИСТОЧНИКИ ДАННЫХ

Архивы Zip могут быть прочитаны из различных источников.

Для работы с источниками требуется использование модуля Zip
совместно с другими модулями, например HTTP.

=head1 ШАГИ

=cut

sub import {

=head2 Чтение данных

=pod

Прочитать данные из L<содержимого HTTP-ответа|Test::BDD::Cucumber::Definitions::HTTP::Ru>
в L<архив Zip|Test::BDD::Cucumber::Definitions::Zip::Ru>:

    Given содержимое HTTP-ответа прочитано как Zip

=cut

    #        read http response content as Zip
    Given qr/содержимое HTTP-ответа прочитано как Zip/, sub {
        Zip->read_http_response_content_as_zip();
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
