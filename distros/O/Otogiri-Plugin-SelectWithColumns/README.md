# NAME

Otogiri::Plugin::SelectWithColumns - Otogiri plugin to search row-data that contains only specific columns from database

# SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    my $db = Otogiri->new(connect_info => [...]);
    $db->load_plugin('SelectWithColumns');
    
    ## SELECT `id`, `name` FROM `some_table` WHERE `author`="ytnobody" ORDER BY id ASC
    my @rows = $db->select_with_columns(
        'some_table', 
        ['id', 'name'], 
        {'author' => 'ytnobody'}, 
        {order_by => 'id ASC'}
    );
    
    my $row = $rows[0];
    print join(", ", keys($row)) . "\n"; ## --> "id, name\n"

# DESCRIPTION

Otogiri::Plugin::SelectWithColumns is plugin for [Otogiri](https://metacpan.org/pod/Otogiri) to search row-data that contains only specific columns from database。

# LICENSE

Copyright (C) Satoshi Azuma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Satoshi Azuma <ytnobody@gmail.com>
