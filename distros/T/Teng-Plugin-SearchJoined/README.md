# NAME

Teng::Plugin::SearchJoined - Teng plugin for Joined query

# SYNOPSIS

    package MyDB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('SearchJoined');
    

    package main;
    my $db = MyDB->new(...);
    my $itr = $db->search_joined(user_item => [
        user => {'user_item.user_id' => 'user.id'},
        item => {'user_item.item_id' => 'item.id'},
    ], {
        'user.id' => 2,
    }, {
        order_by => 'user_item.item_id',
    });
    

    while (my ($user_item, $user, $item) = $itr->next) {
        ...
    }

# DESCRIPTION

Teng::Plugin::SearchJoined is a Plugin of Teng for joined query.

# INTERFACE

## Method

### `$itr:Teng::Plugin::SearchJoined::Iterator = $db->search_joined($table, $join_conds, \%where, \%opts)`

Return [Teng::Plugin::SearchJoined::Iterator](http://search.cpan.org/perldoc?Teng::Plugin::SearchJoined::Iterator) object.

`$table`, `\%where` and `\%opts` are same as arguments of [Teng](http://search.cpan.org/perldoc?Teng)'s `search` method.

`$join_conds` is same as argument of [SQL::Maker::Plugin::JoinSelect](http://search.cpan.org/perldoc?SQL::Maker::Plugin::JoinSelect)'s `join_select` method.

# SEE ALSO

[Teng](http://search.cpan.org/perldoc?Teng)

[SQL::Maker::Plugin::JoinSelect](http://search.cpan.org/perldoc?SQL::Maker::Plugin::JoinSelect)

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
