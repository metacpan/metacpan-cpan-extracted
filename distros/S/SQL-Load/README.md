# NAME
 
SQL::Load - This module is a simple SQL file loader

# VERSION

0.05

# SYNOPSIS

File SQL: users.sql

    -- (find)
    SELECT * FROM users WHERE id = ?;
    
    -- # find-all
    SELECT * FROM users ORDER BY id DESC;
    
    -- [insert]
    INSERT INTO users (name, login, password) VALUES (?, ?, ?);

Code:

    use SQL::Load;
    
    my $sql = SQL::Load->new('/home/user/sql/directory/path');
    
    # load users.sql file
    my $users = $sql->load('users');
     
    print $users->name('find')     # SELECT * FROM users WHERE id = ?;
    print $users->name('find-all') # SELECT * FROM users ORDER BY id DESC;
    print $users->name('insert')   # INSERT INTO users (name, login, password) VALUES (?, ?, ?);
    
    print $sql->load('users#find');     # SELECT * FROM users WHERE id = ?; 
    print $sql->load('users#find-all'); # SELECT * FROM users ORDER BY id DESC;
    print $sql->load('users#insert');   # INSERT INTO users (name, login, password) VALUES (?, ?, ?);    
  
# DESCRIPTION

Intended to separate SQL from Perl code, this module provides some functions that make it easier to do so.

# METHODS

## new

    my $sql_load = SQL::Load->new($path, $end);

Construct a new L<SQL::Load>, passing the folder path is required.
The end param is optional, default returns SQLs with a semicolon in the end, for example using break line:

    my $sql = SQL::Load->new('/home/user/sql/directory/path', "\n");

    my $users = $sql->load('users');
     
    print $users->name('find');     # SELECT * FROM users WHERE id = ?\n
    print $users->name('find-all'); # SELECT * FROM users ORDER BY id DESC\n
    print $users->name('insert');   # INSERT INTO users (name, login, password) VALUES (?, ?, ?)\n

## load

    my $method = $sql_load->load('file_name'); 
    my $method = $sql_load->load('file_name.sql');
    my $method = $sql_load->load('file_name#sql_name'); 
    my $method = $sql_load->load('file_name#sql_at');    
    my $method = $sql_load->load('file_name', 1); # reload to get content directly from the file
    
Load the content in the reference and return an instance of L<SQL::Load::Method>.

## reload

    my $method = $sql_load->reload('file_name'); 
    my $method = $sql_load->reload('file_name.sql');
    my $method = $sql_load->reload('file_name');
    my $method = $sql_load->reload('file_name#sql_name');
    my $method = $sql_load->reload('file_name#sql_at');
    
Reload to get content directly from the file without getting from the tmp from reference.

# FILES SQL
    
## Named SQL

For you to name the SQL has 3 ways:

    -- # NAME
    -- (NAME)
    -- [NAME]
    
These three ways have the same result.

**Examples:**

    -- # find
    SELECT * FROM users WHERE id = ?;
    
    -- # find-all
    SELECT * FROM users ORDER BY id DESC;
    
    -- [FindByEmail]
    SELECT * FROM users WHERE email = ?;   
    
    -- (insert)
    INSERT INTO users (name, email, password) VALUES (?, ?, ?);
    
    -- [delete_by_email]
    DELETE FROM users WHERE email = ?;
    
    -- (UpdatePassword)
    UPDATE users SET password = ? WHERE id = ?;
    
**Important informations:**

Names must be CamelCase, snake_case or kebab-case.

Each SQL statement must end with a semicolon(;).

## SQL in list

Must be separated by semicolon(;)

**Examples:**

    CREATE TABLE users (
        id INT NOT NULL AUTO_INCREMENT,
        name VARCHAR (50) NOT NULL,
        email VARCHAR (100) NOT NULL,
        username VARCHAR (40) NOT NULL,
        password VARCHAR (64) NOT NULL,
        PRIMARY KEY (id)
    );

    CREATE TABLE articles (
        id INT NOT NULL AUTO_INCREMENT,
        user_id INT NOT NULL,
        title VARCHAR (255) NOT NULL,
        data TEXT NOT NULL,
        created TIMESTAMP NOT NULL,
        PRIMARY KEY (id)
    );

    INSERT INTO users (name, email, username, password) 
         VALUES ('John', 'john@email.com', 'john', 'john12345');
         
First is 1, second is 2, and third is 3 in the list position.

# SEE ALSO
 
[SQL::Load::Method](https://metacpan.org/pod/SQL::Load::Method)
 
# AUTHOR
 
Lucas Tiago de Moraes, `lucastiagodemoraes@gmail.com`.
 
# COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
