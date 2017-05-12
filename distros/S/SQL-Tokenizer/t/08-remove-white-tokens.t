use strict;
use warnings;

use Test::More;

use SQL::Tokenizer;

use constant SPACE => ' ';
use constant COMMA => ',';
use constant NL    => "\n";

my $query;
my @query;
my @tokenized;

my @tests= (
    {
        description => qq{equality and math operators},
        query =>
          q{SELECT a * 2, b / 3, c % 4 FROM table WHERE a <> b AND b >= c AND d <= c AND d <> a},
        wanted => [
            'SELECT', 'a', '*',   '2', COMMA,  'b',     '/',     '3',
            COMMA,    'c', '%',   '4', 'FROM', 'table', 'WHERE', 'a',
            '<>',     'b', 'AND', 'b', '>=',   'c',     'AND',   'd',
            '<=',     'c', 'AND', 'd', '<>',   'a'
        ],
    }, {
        description => q{complex explain query},
        query =>
          q{EXPLAIN PLAN LEFT JOIN user.name, email.address, mobile.number WHERE user.id = 100 AND email.user = user.id AND mobile.user = user.id GROUP BY mobile.country_code HAVING mobile.country_code IN ( '55', '31', '44' )},

        wanted => [
            'EXPLAIN',       'PLAN',                'LEFT',          'JOIN',
            'user.name',     COMMA,                 'email.address', COMMA,
            'mobile.number', 'WHERE',               'user.id',       '=',
            '100',           'AND',                 'email.user',    '=',
            'user.id',       'AND',                 'mobile.user',   '=',
            'user.id',       'GROUP',               'BY',            'mobile.country_code',
            'HAVING',        'mobile.country_code', 'IN',            '(',
            q{'55'},         COMMA,                 q{'31'},         COMMA,
            q{'44'},         ')'
        ],
    },

    {
        description => q{SQL script},
        query       => <<COMPLEX_SQL,
-- drop table
DROP TABLE test;
-- create table
CREATE TABLE test (id INT, name VARCHAR);
-- insert data
INSERT INTO test (id, name) VALUES (1, 't');
INSERT INTO test (id, name) VALUES (2, '''quoted''');
COMPLEX_SQL

        wanted => [
            q{-- drop table}, 'DROP',             'TABLE',   'test',
            ';',              q{-- create table}, 'CREATE',  'TABLE',
            'test',           '(',                'id',      'INT',
            COMMA,            'name',             'VARCHAR', ')',
            ';',              q{-- insert data},  'INSERT',  'INTO',
            'test',           '(',                'id',      COMMA,
            'name',           ')',                'VALUES',  '(',
            '1',              COMMA,              q{'t'},    ')',
            ';',              'INSERT',           'INTO',    'test',
            '(',              'id',               COMMA,     'name',
            ')',              'VALUES',           '(',       '2',
            COMMA,            q{'''quoted'''},    ')',       ';',
        ],
    },

    {
        description => q{really long SQL query},
        query       => <<'EOQ',
SELECT
    v.veiculo_id AS veiculo_id,
    v.imagem1 AS imagem1,
    v.imagem2 AS imagem2,
    v.imagem3 AS imagem3,
    v.imagem4 AS imagem4,
    v.combustivel AS combustivel,
    v.modelo_nome AS modelo_nome,
    COALESCE(m.nome,'&nbsp;') AS marca,
    COALESCE(v.versao,'&nbsp;') AS versao,
    COALESCE(v.placa,'&nbsp;') AS placa,
    COALESCE(v.ano,'0') AS ano,
    COALESCE(v.modelo_ano,'0') AS modelo_ano,
    COALESCE(v.cor,'&nbsp;') AS cor,
    COALESCE(v.portas,'0') AS portas,
    COALESCE(v.preco,'0.0') AS valor,
    c.cliente_id AS cliente_id
FROM
    veiculo AS v
INNER JOIN
    anuncio AS a ON a.veiculo_id = v.veiculo_id
INNER JOIN
    cliente AS c ON c.cliente_id = a.cliente_id
LEFT JOIN
    marca AS m ON v.marca_id = m.marca_id
WHERE
    1=1 AND
    (
        (a.data_inicio <= '20070502' AND a.data_fim >= '20060502') OR
        (a.data_inicio IS NULL AND a.data_fim IS NULL)
    ) AND
    a.ativo = 1 AND
    v.veiculo_tipo_id = 3 AND
    v.imagem1 IS NOT NULL AND
    (
        v.imagem1 is not null OR
        v.imagem2 is not null OR
        v.imagem3 is not null OR
        v.imagem4 is not null
    ) AND
    c.cliente_id = 12
ORDER BY v.preco ASC
EOQ

        wanted => [
            'SELECT',        'v.veiculo_id',  'AS',                'veiculo_id',
            COMMA,           'v.imagem1',     'AS',                'imagem1',
            COMMA,           'v.imagem2',     'AS',                'imagem2',
            COMMA,           'v.imagem3',     'AS',                'imagem3',
            COMMA,           'v.imagem4',     'AS',                'imagem4',
            COMMA,           'v.combustivel', 'AS',                'combustivel',
            COMMA,           'v.modelo_nome', 'AS',                'modelo_nome',
            COMMA,           'COALESCE',      '(',                 'm.nome',
            COMMA,           q{'&nbsp;'},     ')',                 'AS',
            'marca',         COMMA,           'COALESCE',          '(',
            'v.versao',      COMMA,           q{'&nbsp;'},         ')',
            'AS',            'versao',        COMMA,               'COALESCE',
            '(',             'v.placa',       COMMA,               q{'&nbsp;'},
            ')',             'AS',            'placa',             COMMA,
            'COALESCE',      '(',             'v.ano',             COMMA,
            q{'0'},          ')',             'AS',                'ano',
            COMMA,           'COALESCE',      '(',                 'v.modelo_ano',
            COMMA,           q{'0'},          ')',                 'AS',
            'modelo_ano',    COMMA,           'COALESCE',          '(',
            'v.cor',         COMMA,           q{'&nbsp;'},         ')',
            'AS',            'cor',           COMMA,               'COALESCE',
            '(',             'v.portas',      COMMA,               q{'0'},
            ')',             'AS',            'portas',            COMMA,
            'COALESCE',      '(',             'v.preco',           COMMA,
            q{'0.0'},        ')',             'AS',                'valor',
            COMMA,           'c.cliente_id',  'AS',                'cliente_id',
            'FROM',          'veiculo',       'AS',                'v',
            'INNER',         'JOIN',          'anuncio',           'AS',
            'a',             'ON',            'a.veiculo_id',      '=',
            'v.veiculo_id',  'INNER',         'JOIN',              'cliente',
            'AS',            'c',             'ON',                'c.cliente_id',
            '=',             'a.cliente_id',  'LEFT',              'JOIN',
            'marca',         'AS',            'm',                 'ON',
            'v.marca_id',    '=',             'm.marca_id',        'WHERE',
            '1',             '=',             '1',                 'AND',
            '(',             '(',             'a.data_inicio',     '<=',
            q{'20070502'},   'AND',           'a.data_fim',        '>=',
            q{'20060502'},   ')',             'OR',                '(',
            'a.data_inicio', 'IS',            'NULL',              'AND',
            'a.data_fim',    'IS',            'NULL',              ')',
            ')',             'AND',           'a.ativo',           '=',
            '1',             'AND',           'v.veiculo_tipo_id', '=',
            '3',             'AND',           'v.imagem1',         'IS',
            'NOT',           'NULL',          'AND',               '(',
            'v.imagem1',     'is',            'not',               'null',
            'OR',            'v.imagem2',     'is',                'not',
            'null',          'OR',            'v.imagem3',         'is',
            'not',           'null',          'OR',                'v.imagem4',
            'is',            'not',           'null',              ')',
            'AND',           'c.cliente_id',  '=',                 '12',
            'ORDER',         'BY',            'v.preco',           'ASC',
        ],
    },

);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized= SQL::Tokenizer->tokenize( $test->{query}, 1 );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}
