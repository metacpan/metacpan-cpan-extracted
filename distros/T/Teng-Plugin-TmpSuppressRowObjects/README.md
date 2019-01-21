# NAME

Teng::Plugin::TmpSuppressRowObjects - add methods with temporaly use of suppress\_row\_objects

# SYNOPSIS

    #  In your Model ...
    package Your::Model;
    use parent qw(Teng);

    __PACKAGE__->load_plugin('TmpSuppressRowObjects');


    #  In case suppress_row_objects = 0 ...
    my $teng = Your::Model->new(dbh => $dbh, suppress_row_objects => 0);
    my @rows;

    #  same usage with original 'search'
    @rows = $teng->search_hashref(test_table => +{ id => 100 });     #  elements in @rows are hashref

    #  does not affect original 'search'
    @rows = $teng->search(test_table => +{ id => 100 });     #  elements in @rows are row object

# DESCRIPTION

This plugin adds some methods, which return hashref as a result, rather than row objects, even when `suppress_row_objects` is 0.
It is useful when we want row objects as default, and lightweight hashref in some cases to improve performance.

# METHODS

    insert_hashref
    search_hashref
    single_hashref
    search_by_sql_hashref
    single_by_sql_hashref
    search_named_hashref
    single_named_hashref

Usage of those methods are the same to original methods (without `_hashref`).

# LICENSE

Copyright (C) egawata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

egawata <egawa.takashi@gmail.com>
