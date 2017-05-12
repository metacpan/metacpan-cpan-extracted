# NAME

Teng::Plugin::ResultSet - Teng plugin providing ResultSet

# SYNOPSIS

    package MyDB;
    use parent 'Teng';
    __PACKAGE__->load_plugin('ResultSet');
    

    package main;
    my $db = MyDB->new(...);
    my $rs = $db->resultset('TableName');
    $rs = $rs->search({id, {'>', 10});
    while (my $row = $rs->next) {
        ...
    }

# DESCRIPTION

Teng::Plugin::ResultSet is plugin of [Teng](http://search.cpan.org/perldoc?Teng) providing ResultSet class.

__THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.__

# METHODS

- `$result_set:Teng::ResultSet = $db->resultset($result_set_name:Str)`

# SEE ALSO

[Teng::ResultSet](http://search.cpan.org/perldoc?Teng::ResultSet)

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
