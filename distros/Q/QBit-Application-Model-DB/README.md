# Name
 

QBit::Application::Model::DB - base class for DB.
 

# Description
 

Base class for working with databases.

# GitHub

https://github.com/QBitFramework/QBit-Application-Model-DB

# Install

- cpanm QBit::Application::Model::DB
- apt-get install libqbit-application-model-db-perl (http://perlhub.ru/)

# Debug

    $QBit::Application::Model::DB::DEBUG = TRUE;

# Abstract methods
 

-  

    __query__

-  

    __filter__

-  

    __\_get\_table\_object__

-  

    __\_create\_sql\_db__

-  

    __\_connect__

-  

    __\_is\_connection\_error__
     

# Package methods
 

## meta
 

__Arguments:__
 

- __%meta__ - meta information about database
 

__Example:__

    package Test::DB;

    use qbit;

    use base qw(QBit::Application::Model::DB);
    
    my $meta = {
        tables => {
            users => {
                fields => [
                    {name => 'id',        type => 'INT',      unsigned => 1, not_null => 1, autoincrement => 1,},
                    {name => 'create_dt', type => 'DATETIME', not_null => 1,},
                    {name => 'login',     type => 'VARCHAR',  length => 255, not_null => 1,},
                ],
                primary_key => [qw(id)],
                indexes     => [{fields => [qw(login)], unique => 1},],
            },
         
            fio => {
                fields => [
                    {name => 'user_id'},
                    {name => 'name',    type => 'VARCHAR', length => 255,},
                    {name => 'midname', type => 'VARCHAR', length => 255,},
                    {name => 'surname', type => 'VARCHAR', length => 255,},
                ],
                foreign_keys => [[[qw(user_id)] => 'users' => [qw(id)]]]
            },
        },
    };

    __PACKAGE__->meta($meta);
    

in Appplication.pm

    use Test::DB accessor => 'db';

## get\_all\_meta
 

__Arguments:__

- __$package__ - package object or name (optional)

__Return values:__

- __$meta__ - meta information about database

__Example:__

    my $meta = $app->db->get_all_meta('Test::DB');

## init
 

__No arguments.__
 

Method called from ["new"](#new) before return object.
 

## quote
 

__Arguments:__

- __$name__ - string

__Return values:__

- __$quoted\_name__ - quoted string

__Example:__

    my $quoted_name = $app->db->quote('users'); # 'users'

## quote\_identifier
 

__Arguments:__

- __$name__ - string

__Return values:__

- __$quoted\_name__ - quoted string

__Example:__

    my $quoted_name = $app->db->quote_identifier('users'); # "users"

## begin
 

__No arguments.__

start a new transaction or create new savepoint

__Example:__

    $app->db->begin();

## commit
 

__No arguments.__

commits the current transaction or release savepoint

__Example:__

    $app->db->commit();

## rollback
 

__No arguments.__

rolls back the current transaction or savepoint

__Example:__

    $app->db->rollback();

## transaction
 

__Arguments:__

- __$sub__ - reference to sub

__Example:__

    $app->db->transaction(sub {
        # work with db
        ...
    });

## create\_sql
 

__Arguments:__

- __@tables__ - table names (optional)

__Return values:__

- __$sql__ - sql

__Example:__

    my $sql = $app->db->create_sql(qw(users));

## init\_db
 

__Arguments:__

- __@tables__ - table names (optional)

__Example:__

    $app->db->init_db(qw(users));

## finish
 

__No arguments.__

Check that transaction closed

__Example:__

    $app->db->finish();

# Internal packages
 

- __[QBit::Application::Model::DB::Class](https://metacpan.org/pod/QBit::Application::Model::DB::Class)__ - base class for DB modules;
 
- __[QBit::Application::Model::DB::Field](https://metacpan.org/pod/QBit::Application::Model::DB::Field)__ - base class for DB fields;
 
- __[QBit::Application::Model::DB::Filter](https://metacpan.org/pod/QBit::Application::Model::DB::Filter)__ - base class for DB filters;
 
- __[QBit::Application::Model::DB::Query](https://metacpan.org/pod/QBit::Application::Model::DB::Query)__ - base class for DB queries;
 
- __[QBit::Application::Model::DB::Table](https://metacpan.org/pod/QBit::Application::Model::DB::Table)__ - base class for DB tables;
 
- __[QBit::Application::Model::DB::VirtualTable](https://metacpan.org/pod/QBit::Application::Model::DB::VirtualTable)__ - base class for DB virtual tables;

___

# Name
 

QBit::Application::Model::DB::Class
 

# Description
 

Base class for DB modules.

# RO accessors
 

-  

    __db__

# Package methods

## init
 

## quote
 

## quote\_identifier
 

## filter
 

For more information see code and test.

___

# Name
 

QBit::Application::Model::DB::Field
 

# Description
 

Base class for DB fields.

# RO accessors
 

-  

    __name__

-  

    __type__

-  

    __table__

# Package methods

## init
 

## init\_check
 

# Abstract methods
 

-  

    __create\_sql__

For more information see code and test.

___

# Name
 

QBit::Application::Model::DB::Filter
 

# Description
 

Base class for DB filters.

# Package methods

## new
 

## and
 

## or
 

## and\_not
 

## or\_not
 

## expression
 

For more information see code and test.

___

# Name
 

QBit::Application::Model::DB::Query
 

# Description
 

Base class for DB queries.

# Abstract methods

- __\_found\_rows__

# Package methods

## init

__No arguments.__

Method called from ["new"](#new) before return object.
 

## select

__Arguments:__

- __%opts__ - options with keys
    - __table__ - object
    - __fields__ (optional, default: all fields)
    - __filter__ (optional)

__Return values:__

- __$query__ - object

__Example:__

    my $query = $app->db->query->select(
        table  => $app->db->users,
        fields => [qw(id login)],
        filter => {id => 3},
    );
    

## join

__Arguments:__

- __%opts__ - options with keys
    - __table__ - object
    - __alias__ (optional)
    - __fields__ (optional, default: all fields)
    - __filter__ (optional)
    - __join\_type__ (optional, default: 'INNER JOIN')
    - __join\_on__ (optional, default: use foreign keys)

__Return values:__

- __$query__ - object

__Example:__

     my $join_query = $query->join(
         table     => $app->db->fio,
         fields    => [qw(name surname)],
         filter    => ['name' => 'LIKE' => \'Max'],
         join_type => 'INNER JOIN',
         join_on   => ['user_id' => '=' => {'id' => $app->db->users}],
     );
    

## left\_join

join\_type => 'LEFT JOIN'
 

## right\_join

join\_type => 'RIGHT JOIN'
 

## group\_by

__Arguments:__

- __@fields__

__Return values:__

- __$query__ - object

__Example:__

     my $group_query = $query->group_by(qw(name surname));
    

## order\_by

__Arguments:__

- __@fields__ - fields or reference to array

__Return values:__

- __$query__ - object

__Example:__

     my $order_query = $query->order_by('id', ['login', 1]);
    

## limit

__Arguments:__

- __@limit__

__Return values:__

- __$query__ - object

__Example:__

     my $limit_query = $query->limit(100, 200);
    

## distinct

__No arguments.__

__Return values:__

- __$query__ - object

__Example:__

     my $distinct_query = $query->distinct();
    

## union

__Arguments:__

- __$query__ - object
- __%opts__ - options with keys
    - __all__ - boolean (optional, default: FALSE)

__Return values:__

- __$query__ - object

__Example:__

     my $union_query = $query->union(
         $app->db->query->select(
             table => $app->db->people,
             fields => [qw(id login name surname)]
         ),
         all => FALSE,
     );
    

## union\_all

all => TRUE
 

## calc\_rows

__Arguments:__

- __$flag__ - boolean

__Return values:__

- __$query__ - object

__Example:__

     my $calc_rows_query = $query->calc_rows(TRUE);
    

## all\_langs

__Arguments:__

- __$flag__ - boolean

__Return values:__

- __$query__ - object

__Example:__

     my $all_langs_query = $query->all_langs(TRUE);
    

## for\_update

__No arguments.__

__Return values:__

- __$query__ - object

__Example:__

     my $for_update_query = $query->for_update();
    

## filter
 

## get\_sql\_with\_data

__Arguments:__

- __%opts__ - options with keys
    - __offset__ - number (optional, default: 0)

__Return values:__

- __$sql__ - string

__Example:__

     my $sql = $query->get_sql_with_data();
    

## get\_all

__No arguments.__

__Return values:__

- __$data__ - reference to array

__Example:__

    my $data = $query->get_all();
     

## found\_rows

__No arguments.__

__Return values:__

- __$bool__

__Example:__

     my $bool = $query->found_rows();
    

For more information see code and test.

___

# Name
 

QBit::Application::Model::DB::Table
 

# Description
 

Base class for DB tables.

# RO accessors
 

-  

    __name__

-  

    __inherits__

-  

    __primary\_key__

-  

    __indexes__

-  

    __foreign\_keys__

# Abstract methods

- __create\_sql__
- __add\_multi__
- __add__
- __edit__
- __delete__
- __\_get\_field\_object__
- __\_convert\_fk\_auto\_type__

# Package methods

## init

__No arguments.__

Method called from ["new"](#new) before return object.
 

## fields

__No arguments.__

__Return values:__

- __$fields__ - reference to array of objects (QBit::Application::Model::DB::Field)

__Example:__

     my $fields = $app->db->users->fields();
    

## fields

__No arguments.__

__Return values:__

- __@field\_names__

__Example:__

     my @field_names = $app->db->users->field_names();
    

## get\_all

__Arguments:__

- __%opts__ - options with keys
    - __fields__
    - __filter__
    - __group\_by__
    - __order\_by__
    - __limit__
    - __distinct__
    - __for\_update__
    - __all\_langs__

For more information see QBit::Application::Model::DB::Query::get\_all

__Return values:__

- __$data__ - reference to array

__Example:__

    my $data = $app->db->users->get_all(
        fields => [qw(id login)],
        filter => {id => 3},
    );

## get

__Arguments:__

- __$id__ - scalar or hash
- __%opts__ - options with keys
    - __fields__
    - __for\_update__
    - __all\_langs__

For more information see QBit::Application::Model::DB::Query::get\_all

__Return values:__

- __$data__ - reference to hash

__Example:__

    my $data = $app->db->users->get(3, fields => [qw(id login)],);

## truncate

__No arguments.__

Truncate table.

__Example:__

     $app->db->users->truncate();
    

## default\_fields

You can redefine this method in your Model.
 

## default\_primary\_key

You can redefine this method in your Model.
 

## default\_indexes

You can redefine this method in your Model.
 

## default\_foreign\_keys

You can redefine this method in your Model.
 

## have\_fields

__Arguments:__

- __$fields__ - reference to array

__Return values:__

- __$bool__

__Example:__

    my $bool = $app->db->users->have_fields([qw(id login)]);

For more information see code and test.

___

# Name
 

QBit::Application::Model::DB::VirtualTable
 

# Description
 

Base class for DB virtual tables.

# RO accessors
 

-  

    __query__

-  

    __name__

# Package methods

## init
 

## fields
 

## get\_sql\_with\_data
 

For more information see code and test.
