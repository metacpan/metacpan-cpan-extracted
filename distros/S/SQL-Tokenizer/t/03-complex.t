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

my @tests = (
    {
        description => q{complex explain query},
        query =>
q{EXPLAIN PLAN LEFT JOIN user.name, email.address, mobile.number WHERE user.id = 100 AND email.user = user.id AND mobile.user = user.id GROUP BY mobile.country_code HAVING mobile.country_code IN ( '55', '31', '44' )},

        wanted => [
            'EXPLAIN',             SPACE,
            'PLAN',                SPACE,
            'LEFT',                SPACE,
            'JOIN',                SPACE,
            'user.name',           COMMA,
            SPACE,                 'email.address',
            COMMA,                 SPACE,
            'mobile.number',       SPACE,
            'WHERE',               SPACE,
            'user.id',             SPACE,
            '=',                   SPACE,
            '100',                 SPACE,
            'AND',                 SPACE,
            'email.user',          SPACE,
            '=',                   SPACE,
            'user.id',             SPACE,
            'AND',                 SPACE,
            'mobile.user',         SPACE,
            '=',                   SPACE,
            'user.id',             SPACE,
            'GROUP',               SPACE,
            'BY',                  SPACE,
            'mobile.country_code', SPACE,
            'HAVING',              SPACE,
            'mobile.country_code', SPACE,
            'IN',                  SPACE,
            '(',                   SPACE,
            q{'55'},               COMMA,
            SPACE,                 q{'31'},
            COMMA,                 SPACE,
            q{'44'},               SPACE,
            ')'
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
            q{-- drop table}, NL,
            'DROP',           SPACE,
            'TABLE',          SPACE,
            'test',           ';',
            NL,               q{-- create table},
            NL,               'CREATE',
            SPACE,            'TABLE',
            SPACE,            'test',
            SPACE,            '(',
            'id',             SPACE,
            'INT',            COMMA,
            SPACE,            'name',
            SPACE,            'VARCHAR',
            ')',              ';',
            NL,               q{-- insert data},
            NL,               'INSERT',
            SPACE,            'INTO',
            SPACE,            'test',
            SPACE,            '(',
            'id',             COMMA,
            SPACE,            'name',
            ')',              SPACE,
            'VALUES',         SPACE,
            '(',              '1',
            COMMA,            SPACE,
            q{'t'},           ')',
            ';',              NL,
            'INSERT',         SPACE,
            'INTO',           SPACE,
            'test',           SPACE,
            '(',              'id',
            COMMA,            SPACE,
            'name',           ')',
            SPACE,            'VALUES',
            SPACE,            '(',
            '2',              COMMA,
            SPACE,            q{'''quoted'''},
            ')',              ';',
            NL,
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
            'SELECT',            NL,
            '    ',              'v.veiculo_id',
            SPACE,               'AS',
            SPACE,               'veiculo_id',
            COMMA,               NL,
            '    ',              'v.imagem1',
            SPACE,               'AS',
            SPACE,               'imagem1',
            COMMA,               NL,
            '    ',              'v.imagem2',
            SPACE,               'AS',
            SPACE,               'imagem2',
            COMMA,               NL,
            '    ',              'v.imagem3',
            SPACE,               'AS',
            SPACE,               'imagem3',
            COMMA,               NL,
            '    ',              'v.imagem4',
            SPACE,               'AS',
            SPACE,               'imagem4',
            COMMA,               NL,
            '    ',              'v.combustivel',
            SPACE,               'AS',
            SPACE,               'combustivel',
            COMMA,               NL,
            '    ',              'v.modelo_nome',
            SPACE,               'AS',
            SPACE,               'modelo_nome',
            COMMA,               NL,
            '    ',              'COALESCE',
            '(',                 'm.nome',
            COMMA,               q{'&nbsp;'},
            ')',                 SPACE,
            'AS',                SPACE,
            'marca',             COMMA,
            NL,                  '    ',
            'COALESCE',          '(',
            'v.versao',          COMMA,
            q{'&nbsp;'},         ')',
            SPACE,               'AS',
            SPACE,               'versao',
            COMMA,               NL,
            '    ',              'COALESCE',
            '(',                 'v.placa',
            COMMA,               q{'&nbsp;'},
            ')',                 SPACE,
            'AS',                SPACE,
            'placa',             COMMA,
            NL,                  '    ',
            'COALESCE',          '(',
            'v.ano',             COMMA,
            q{'0'},              ')',
            SPACE,               'AS',
            SPACE,               'ano',
            COMMA,               NL,
            '    ',              'COALESCE',
            '(',                 'v.modelo_ano',
            COMMA,               q{'0'},
            ')',                 SPACE,
            'AS',                SPACE,
            'modelo_ano',        COMMA,
            NL,                  '    ',
            'COALESCE',          '(',
            'v.cor',             COMMA,
            q{'&nbsp;'},         ')',
            SPACE,               'AS',
            SPACE,               'cor',
            COMMA,               NL,
            '    ',              'COALESCE',
            '(',                 'v.portas',
            COMMA,               q{'0'},
            ')',                 SPACE,
            'AS',                SPACE,
            'portas',            COMMA,
            NL,                  '    ',
            'COALESCE',          '(',
            'v.preco',           COMMA,
            q{'0.0'},            ')',
            SPACE,               'AS',
            SPACE,               'valor',
            COMMA,               NL,
            '    ',              'c.cliente_id',
            SPACE,               'AS',
            SPACE,               'cliente_id',
            NL,                  'FROM',
            NL,                  '    ',
            'veiculo',           SPACE,
            'AS',                SPACE,
            'v',                 NL,
            'INNER',             SPACE,
            'JOIN',              NL,
            '    ',              'anuncio',
            SPACE,               'AS',
            SPACE,               'a',
            SPACE,               'ON',
            SPACE,               'a.veiculo_id',
            SPACE,               '=',
            SPACE,               'v.veiculo_id',
            NL,                  'INNER',
            SPACE,               'JOIN',
            NL,                  '    ',
            'cliente',           SPACE,
            'AS',                SPACE,
            'c',                 SPACE,
            'ON',                SPACE,
            'c.cliente_id',      SPACE,
            '=',                 SPACE,
            'a.cliente_id',      NL,
            'LEFT',              SPACE,
            'JOIN',              NL,
            '    ',              'marca',
            SPACE,               'AS',
            SPACE,               'm',
            SPACE,               'ON',
            SPACE,               'v.marca_id',
            SPACE,               '=',
            SPACE,               'm.marca_id',
            NL,                  'WHERE',
            NL,                  '    ',
            '1',                 '=',
            '1',                 SPACE,
            'AND',               NL,
            '    ',              '(',
            NL,                  '        ',
            '(',                 'a.data_inicio',
            SPACE,               '<=',
            SPACE,               q{'20070502'},
            SPACE,               'AND',
            SPACE,               'a.data_fim',
            SPACE,               '>=',
            SPACE,               q{'20060502'},
            ')',                 SPACE,
            'OR',                NL,
            '        ',          '(',
            'a.data_inicio',     SPACE,
            'IS',                SPACE,
            'NULL',              SPACE,
            'AND',               SPACE,
            'a.data_fim',        SPACE,
            'IS',                SPACE,
            'NULL',              ')',
            NL,                  '    ',
            ')',                 SPACE,
            'AND',               NL,
            '    ',              'a.ativo',
            SPACE,               '=',
            SPACE,               '1',
            SPACE,               'AND',
            NL,                  '    ',
            'v.veiculo_tipo_id', SPACE,
            '=',                 SPACE,
            '3',                 SPACE,
            'AND',               NL,
            '    ',              'v.imagem1',
            SPACE,               'IS',
            SPACE,               'NOT',
            SPACE,               'NULL',
            SPACE,               'AND',
            NL,                  '    ',
            '(',                 NL,
            '        ',          'v.imagem1',
            SPACE,               'is',
            SPACE,               'not',
            SPACE,               'null',
            SPACE,               'OR',
            NL,                  '        ',
            'v.imagem2',         SPACE,
            'is',                SPACE,
            'not',               SPACE,
            'null',              SPACE,
            'OR',                NL,
            '        ',          'v.imagem3',
            SPACE,               'is',
            SPACE,               'not',
            SPACE,               'null',
            SPACE,               'OR',
            NL,                  '        ',
            'v.imagem4',         SPACE,
            'is',                SPACE,
            'not',               SPACE,
            'null',              NL,
            '    ',              ')',
            SPACE,               'AND',
            NL,                  '    ',
            'c.cliente_id',      SPACE,
            '=',                 SPACE,
            '12',                NL,
            'ORDER',             SPACE,
            'BY',                SPACE,
            'v.preco',           SPACE,
            'ASC',               NL
        ],
    },

);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized = SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}
