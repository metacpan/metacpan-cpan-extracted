# NAME

SQL::Abstract::Plugin::InsertMulti - add mysql bulk insert supports for SQL::Abstract

# SYNOPSIS

    use SQL::Abstract;
    use SQL::Abstract::Plugin::InsertMulti;

    my $sql = SQL::Abstract->new;
    my ($stmt, @bind) = $sql->insert_multi('people', [
      +{ name => 'foo', age => 23, },
      +{ name => 'bar', age => 40, },
    ]);

# DESCRIPTION

SQL::Abstract::Plugin::InsertMulti is enable bulk insert support for [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract). Declare 'use SQL::Abstract::Plugin::InsertMulti;' with 'use SQL::Abstract;',
exporting insert\_multi() and update\_multi() methods to [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) namespace from SQL::Abstract::Plugin::InsertMulti.
Plugin system is depends on 'into' options of [Sub::Exporter](https://metacpan.org/pod/Sub::Exporter).

Notice: please check your mysql\_allow\_packet parameter using this module.

# METHODS

## insert\_multi($table, \\@data, \\%opts)

    my ($stmt, @bind) = $sql->insert_multi('foo', [ +{ a => 1, b => 2, c => 3 }, +{ a => 4, b => 5, c => 6, }, ]);
    # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? )|
    # @bind = (1, 2, 3, 4, 5, 6);

@data is HashRef list.
%opts details is below.

- ignore

    Use 'INSERT IGNORE' instead of 'INSERT INTO'.

- update

    Use 'ON DUPLICATE KEY UPDATE'.
    This value is same as update()'s data parameters.

- update\_ignore\_fields

    update\_multi() method is auto generating 'ON DUPLICATE KEY UPDATE' parameters:

        my ($stmt, @bind) = $sql->update_multi('foo', [qw/a b c/], [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
        # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a ), b = VALUES( b ), c = VALUES( c )|
        # @bind = (1, 2, 3, 4, 5, 6);

    given update\_ignore\_fields,

        my ($stmt, @bind) = $sql->update_multi('foo', [qw/a b c/], [ [ 1, 2, 3 ], [ 4, 5, 6 ] ], +{ update_ignore_fields => [qw/b c/], });
        # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a )|
        # @bind = (1, 2, 3, 4, 5, 6);

## insert\_multi($table, \\@field, \\@data, \\%opts)

    my ($stmt, @bind) = $sql->insert_multi('foo', [qw/a b c/], [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
    # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? )|
    # @bind = (1, 2, 3, 4, 5, 6);

@data is ArrayRef list. See also ["insert\_multi($table, \\@data, \\%opts)"](#insert_multi-table-data-opts) %opts details.

## update\_multi($table, \\@data, \\%opts)

@data is HashRef list. See also ["insert\_multi($table, \\@data, \\%opts)"](#insert_multi-table-data-opts) %opts details.

    my ($stmt, @bind) = $sql->update_multi('foo', [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
    # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a ), b = VALUES( b ), c = VALUES( c )|
    # @bind = (1, 2, 3, 4, 5, 6);

## update\_multi($table, \\@field, \\@data, \\%opts)

    my ($stmt, @bind) = $sql->update_multi('foo', [qw/a b c/], [ +{ a => 1, b => 2, c => 3 }, +{ a => 4, b => 5, c => 6, }, ]);
    # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a ), b = VALUES( b ), c = VALUES( c )|
    # @bind = (1, 2, 3, 4, 5, 6);

@data is ArrayRef list. See also ["insert\_multi($table, \\@data, \\%opts)"](#insert_multi-table-data-opts) %opts details.

# AUTHOR

Toru Yamaguchi <zigorou@cpan.org>

Thanks ma.la [http://subtech.g.hatena.ne.jp/mala/](http://subtech.g.hatena.ne.jp/mala/). This module is based on his source codes.

# SEE ALSO

- http://subtech.g.hatena.ne.jp/mala/20090729/1248880239
- http://gist.github.com/158203
- [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract)
- [Sub::Exporter](https://metacpan.org/pod/Sub::Exporter)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
