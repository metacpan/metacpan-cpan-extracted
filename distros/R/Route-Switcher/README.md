# NAME

Route::Switcher - give feature of nest to other router module

# SYNOPSIS

    package TestDispatcher;
    use Your::Router qw/ get post /; #export get,post method
    use Route::Switcher;

    # override get,post method in switcher method
    Route::Switcher->init(qw/get post/);

    switcher '/user_account' => 'Hoge::UserAccount', sub {
        get('/new'  => '#new'); # equal to get('/user_account/new' => 'Hoge::UserAccount#new');
        post('/new'  => '#new');
        get('/edit' => '#edit');
    };

    switcher '/post/' => 'Hoge::Post', sub {
        get('new'  => '#new');
        post('new'  => '#new');
        get('edit' => '#edit');
    };

    switcher '' => '', sub {
        get('new'  => 'NoBase#new');
    };

    # original methods of Your::Router
    get('/no_base'  => 'NoBase#new');
    post('/no_base'  => 'NoBase#new');

# DESCRIPTION

Route::Switcher give feature of nest to other router module.

# METHODS

## init

set name of overridden method.

## switcher

argument of switcher and argument of overriden method are joined within the dynamic scope of switcher method.

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass <tokubass@cpan.org>
