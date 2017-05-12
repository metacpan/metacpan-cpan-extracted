# NAME

Otogiri::Plugin::BulkInsert - bulk insert for Otogiri

# SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    
    my $otogiri = Otogiri->new(...);
    $otogiri->load_plugin('BulkInsert');

    $otogiri->bulk_insert(
        'book', 
        [qw| title author |],
        [
            {title => 'Acmencyclopedia 2009', author => 'Makamaka Hannyaharamitu'},
            {title => 'Acmencyclopedia Reverse', author => 'Makamaka Hannyaharamitu'},
            {title => 'Acmencyclopedia 2010', author => 'Makamaka Hannyaharamitu'},
            {title => 'Acmencyclopedia 2011', author => 'Makamaka Hannyaharamitu'},
            {title => 'Acmencyclopedia 2012', author => 'Makamaka Hannyaharamitu'},
            {title => 'Acmencyclopedia 2013', author => 'Makamaka Hannyaharamitu'},
            {title => 'Miyabi-na-Perl Nyuumon', author => 'Miyabi-na-Rakuda'},
            {title => 'Miyabi-na-Perl Nyuumon 2nd edition', author => 'Miyabi-na-Rakuda'},
        ],
    );

# DESCRIPTION

Otogiri::Plugin::BulkInsert is A plugin for otogiri that provides 'bulk insert' method.

# METHODS

## $otogiri->bulk\_insert($tablename, \[ @colnames \], \[ @rowdatas \]);

Insert multiple rowdata into specified table.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
