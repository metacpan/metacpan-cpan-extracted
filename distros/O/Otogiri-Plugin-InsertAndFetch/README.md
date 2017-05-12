# NAME

Otogiri::Plugin::InsertAndFetch - An Otogiri plugin that keep compatibility for insert method

# SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    Otogiri->load_plugin('InsertAndFetch');
    

    my $db = Otogiri->new(...);
    

    my $row = $db->insert_and_fetch(book => {title => 'Acmencyclopedia', author => 'makamaka'});
    

    printf("title: %s\n", $row->{title}); # -> title: Acmencyclopedia

# DESCRIPTION

Otogiri::Plugin::InsertAndFetch is an Otogiri plugin. It provides 'insert\_and\_fetch' method to Otogiri instance.

# METHODS

## insert\_and\_fetch

    my $row = $db->insert($table_name => $columns_in_hashref);

Insert data. Then, returns row data.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>

# SEE ALSO

[Otogiri](http://search.cpan.org/perldoc?Otogiri)
