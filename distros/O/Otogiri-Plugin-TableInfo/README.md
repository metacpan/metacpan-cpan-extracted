[![Build Status](https://travis-ci.org/tsucchi/p5-Otogiri-Plugin-TableInfo.png?branch=master)](https://travis-ci.org/tsucchi/p5-Otogiri-Plugin-TableInfo) [![Coverage Status](https://coveralls.io/repos/tsucchi/p5-Otogiri-Plugin-TableInfo/badge.png?branch=master)](https://coveralls.io/r/tsucchi/p5-Otogiri-Plugin-TableInfo?branch=master)
# NAME

Otogiri::Plugin::TableInfo - retrieve table information from database

# SYNOPSIS

    use Otogiri::Plugin::TableInfo;
    my $db = Otogiri->new( connect_info => [ ... ] );
    $db->load_plugin('TableInfo');
    my @table_names = $db->show_tables();

# DESCRIPTION

Otogiri::Plugin::TableInfo is Otogiri plugin to fetch table information from database.

# METHODS

## my @table\_names = $self->show\_tables(\[$like\_regex\]);

returns table names in database.

parameter `$like_regex` is optional. If it is passed, table name is filtered by regex like MySQL's `SHOW TABLES LIKE ...` statement.

    my @table_names = $db->show_tables(qr/^user_/); # return table names that starts with 'user_'

If `$like_regex` is not passed, all table\_names in current database are returned.

## my @view\_names = $self->show\_views(\[$like\_regex\]);

returns view names in database.

## my $create\_table\_ddl = $self->desc($table\_name);

## my $create\_table\_ddl = $self->show\_create\_table($table\_name);

returns create table statement like MySQL's 'show create table'.

## my $create\_view\_sql = $self->show\_create\_view($view\_name);

returns create view SQL like MySQL's 'show create view'.

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>
