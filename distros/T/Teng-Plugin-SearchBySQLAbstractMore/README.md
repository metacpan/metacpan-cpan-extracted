# NAME

Teng::Plugin::SearchBySQLAbstractMore - use [SQL::Abstract::More](http://search.cpan.org/perldoc?SQL::Abstract::More) as Query Builder for Teng

# SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('SearchBySQLAbstractMore');
    __PACAKGE__->sql_abstract_more_new_option(sql_dialect => 'Oracle'); # If you want to pass SQL::Abstract::More new options

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);

    my $itr  = $db->search_by_sql_abstract_more('user' => {type => 3});
    my @rows  = $db->search_by_sql_abstract_more('user' => {type => 3}, {rows => 5});

    # use pager
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager('user' => {type => 3}, {page => $page, rows => 5});
    

If you want to replace Teng search

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('SearchBySQLAbstractMore');
    __PACKAGE__->install_sql_abstract_more;
    # now, search method is replaced by search_by_sql_abstract_more

If you want to load pager at the same time

    # search_with_pager from SearchBySQLAbstractMore::Pager
    __PACKAGE__->install_sql_abstract_more(pager => 'Pager');
    # search_with_pager from SearchBySQLAbstractMore::Pager::MySQLFoundRows
    __PACKAGE__->install_sql_abstract_more(pager => 'Pager::MySQLFoundRows');
    # search_with_pager from SearchBySQLAbstractMore::Pager::Count
    __PACKAGE__->install_sql_abstract_more(pager => 'Pager::Count');

Create complex SQL using SQL::Abstract::More.

Compatible usage with Teng's search method.

    $teng->search_by_sql_abstract_more
       ('table1',
        { name => { like => '%perl%'},
          -and => [
                   {x => 1},
                   {y => [-or => {'>' => 2}, {'<' => 10}]},
                  ],
        },
        {
         from     => ['-join',
                      'table1|t1',
                      't1.id=t2.id',
                      'table2|t2',
                      't1.id=t3.table1_id,t2.id=t3.table2_id',
                      'table3|t3',
                     ],
         columns  => ['x', 'y', 'min(age) as min_age', 'max(age) as max_age'],
         group_by => ['x', 'y'],
         having   => {'max_age' => {'<' => 10}},
        },
       );
    # SELECT x, y, min(age) as min_age, max(age) as max_age
    #   FROM table1 AS t1
    #     INNER JOIN table2 AS t2 ON ( t1.id = t2.id )
    #     INNER JOIN table3 AS t3 ON ( ( t1.id = t3.table1_id AND t2.id = t3.table2_id ) )
    #   WHERE ( ( ( x = ? AND ( y > ? OR y < ? ) ) AND name LIKE ? ) )
    #   GROUP BY x, y  HAVING ( max_age < ? );

SQL::Abstract::More original usage(as first argument, use hash ref instead of table name):

    $teng->search_by_sql_abstract_more(
      {
        -columns  => ['x', 'y', 'min(age) as min_age', 'max(age) as max_age'],
        -from     => [-join,
                      'table1|t1',
                      't1.id=t2.id',
                      'table2|t2',
                      't1.id=t3.table1_id,t2.id=t3.table2_id',
                      'table3|t3',
                    ],
        -group_by => ['x', 'y'],
        -having   => {'max_age' => {'<' => 10'}},
        -where => {
           name => { like => '%perl%'},
           -and => [
               {x => 1},
               {y => [-or => {'>' => 2}, {'<' => 10}]},
           ],
         },
      },
    );
    # SQL is as same as the avobe code.

Using pager.

Compatible usage:

    $teng->search_by_sql_abstract_more(
      'table', {
        name => 1,
        age  => 10,
      },
      {
        -columns  => ['x', 'y'],
        -from     => ['table'],
        -page     => 2,
        -rows     => 20,
      },
    );

Originaly usage:

    $teng->search_by_sql_abstract_more(
      {
        -columns  => ['x', 'y'],
        -from     => ['table'],
        -where    => {
             name => 1,
             age  => 10,
        },
        -page     => 2,
        -rows     => 20,
      },
    );

Generate SQL by SQLAbstractMore

    ($sql, @binds) = $teng->create_sql_by_sql_abstract_more($table, $where, $opt);

It returns SQL and bind values with same args of `search_bys_sql_abstract_more` method.

# METHODS

## search\_by\_sql\_abstract\_more

see SYNOPSIS.

## create\_sql\_by\_sql\_abstract\_more

    ($sql, @binds) = $teng->create_sql_by_sql_abstract_more($table, $where, $opt);

This method returns SQL statement and its bind values.
It doesn't check table is in schema.

# CLASS METHOD

## sql\_abstract\_more\_instance

    YourClass->sql_abstract_more_instance;

return SQL::Abstract::More object.

## sql\_abstract\_more\_new\_option

    YourClass->sql_abstract_more_new_option(sql_dialect => 'Oracle');

This method's arguments are passed to SQL::Abstract::More->new().
see [SQL::Abstract::More](http://search.cpan.org/perldoc?SQL::Abstract::More) new options.

## replace\_teng\_search

If you want to replace `search` method of original Teng, call this.

    Teng::Plugin::SearchBySQLAbstractMore->replace_teng_search;

It is useful when you wrap `search` method in your module and call Teng's `search` method in it
and you want to use same usage with SQL::Abstract::More.

## install\_sql\_abstract\_more

    package YourClass;
    use Teng::Plugin::SearchBySQLAbstract::More; # no need to use ->load_plugin();
    

    YourClass->install_sql_abstract_more; # search_sql_abstract_more is defined as YourClass::search
    YourClass->install_sql_abstract_more(alias => 1); # same as the above

    YourClass->install_sql_abstract_more(replace => 1); # Teng::Search is replaced by search_sql_abstract_more
    

    YourClass->install_sql_abstract_more(alias => 'complex_search');
    # sql_abstract_more is defined as YourClass::complex_search
    

    YourClass->install_sql_abstract_more(alias => 'complex_search', pager => 1);
    # sql_abstract_more is defined as YourClass::complex_search
    # sql_abstract_more_pager is defined as YourClass::complex_search_with_pager
    

    YourClass->install_sql_abstract_more(alias => 'complex_search', pager => 1, pager_alias => 'complex_search_paged');
    # sql_abstract_more is defined as YourClass::complex_search
    # sql_abstract_more_pager is defined as YourClass::complex_search_paged
    

    # use different pager
    YourClass->install_sql_abstract_more(pager => 1); # or pager => 'simple' / 'Pager'
    YourClass->install_sql_abstract_more(pager => 'mysql_found_rows'); # or pager => 'Pager::MySQL::FoundRows'
    YourClass->install_sql_abstract_more(pager => 'count'); # or pager => 'Pager::Count'

It call replace\_teng\_search if replace option is passed and it is true
and loads pager plugin with alias option if pager option is true.
`search` and `search_with_pager` are installed to your class.

This method can take the following options.

### replace

If you want to replace Teng's search method, pass this option.

    YourClass->install_sql_abstract_more(replace => 1);

### alias

    YourClass->install_sql_abstract_more(alias => 'complex_search');
    YourClass->install_sql_abstract_more(pager => 'Pager', alias => 'complex_search');

This is equals to:

    YourClass->load_plugin('Teng::Plugin::SearchBySQLAbstractMore', {
       alias => 'search_by_sql_abstract_more' => 'complex_search',
    });
    YourClass->load_plugin('Teng::Plugin::SearchBySQLAbstractMore::Pager', {
       alias => 'search_by_sql_abstract_more_with_pager' => 'complex_search_with_pager',
    });

### pager\_alias

If you want to use different alias for pager search.

    YourClass->install_sql_abstract_more(pager => 'Pager', pager_alias => 'complex_search_with_pager');

This is equals to:

    YourClass->load_plugin('Teng::Plugin::SearchBySQLAbstractMore', {
       alias => 'search_by_sql_abstract_more' => 'search',
    });
    YourClass->load_plugin('Teng::Plugin::SearchBySQLAbstractMore::Pager', {
       alias => 'search_by_sql_abstract_more_with_pager' => 'complex_search_with_pager',
    });

### pager

Pass pager plugin name or 1.

    YourClass->install_sql_abstract_more(pager => 1);       # load SearchBySQLAbstractMore::Pager
    YourClass->install_sql_abstract_more(pager => 'Pager'); # same as the above
    YourClass->install_sql_abstract_more(pager => 'simple'); # same as the above

    YourClass->install_sql_abstract_more(pager => 'Pager::MySQLFoundRows');# load SearchBySQLAbstractMore::Pager::MySQLFoundRows
    YourClass->install_sql_abstract_more(pager => 'mysql_found_rows');          # same as the above

    YourClass->install_sql_abstract_more(pager => 'Pager::Count'); # load SearchBySQLAbstractMore::Pager::Count
    YourClass->install_sql_abstract_more(pager => 'count');  # same as the above

# AUTHOR

Ktat, `<ktat at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-teng-plugin-searchbysqlabstractmore at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Teng-Plugin-SearchBySQLAbstractMore](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Teng-Plugin-SearchBySQLAbstractMore).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Teng::Plugin::SearchBySQLAbstractMore

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Teng-Plugin-SearchBySQLAbstractMore](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Teng-Plugin-SearchBySQLAbstractMore)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore](http://annocpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Teng-Plugin-SearchBySQLAbstractMore](http://cpanratings.perl.org/d/Teng-Plugin-SearchBySQLAbstractMore)

- Search CPAN

    [http://search.cpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore/](http://search.cpan.org/dist/Teng-Plugin-SearchBySQLAbstractMore/)



# SEE ALSO

- [Teng](http://search.cpan.org/perldoc?Teng)
- [SQL::Abstract::More](http://search.cpan.org/perldoc?SQL::Abstract::More)

# ACKNOWLEDGEMENTS



# LICENSE AND COPYRIGHT

Copyright 2012 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


