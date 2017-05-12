use strict;
use warnings;
use Test::More;

use SQL::Format;

subtest 'no args' => sub {
    my $f = SQL::Format->new;
    is $f->{delimiter}, $SQL::Format::DELIMITER;
    is $f->{name_sep}, $SQL::Format::NAME_SEP;
    is $f->{quote_char}, $SQL::Format::QUOTE_CHAR;
    is $f->{limit_dialect}, $SQL::Format::LIMIT_DIALECT;
};

subtest 'set all' => sub {
    my $f = SQL::Format->new(
        delimiter     => ',',
        name_sep      => '',
        quote_char    => '',
        limit_dialect => 'LimitXY',
    );
    is $f->{delimiter}, ',';
    is $f->{name_sep}, '';
    is $f->{quote_char}, '';
    is $f->{limit_dialect}, 'LimitXY';
};

subtest 'driver mysql' => sub {
    my $f = SQL::Format->new(
        driver => 'mysql',
    );
    is $f->{delimiter}, ', ';
    is $f->{name_sep}, '.';
    is $f->{quote_char}, '`';
    is $f->{limit_dialect}, 'LimitXY';
};

subtest 'driver sqlite' => sub {
    my $f = SQL::Format->new(
        driver => 'SQLite',
    );
    is $f->{delimiter}, ', ';
    is $f->{name_sep}, '.';
    is $f->{quote_char}, '"';
    is $f->{limit_dialect}, 'LimitOffset';
};

subtest 'driver sqlite with other args' => sub {
    my $f = SQL::Format->new(
        driver        => 'SQLite',
        quote_char    => '',
        limit_dialect => 'LimitXY',
    );
    is $f->{delimiter}, ', ';
    is $f->{name_sep}, '.';
    is $f->{quote_char}, '';
    is $f->{limit_dialect}, 'LimitXY';
};

done_testing;
