package SQL::Load;

use strict;
use warnings;
use Carp;
use SQL::Load::Util qw/
    name_list 
    remove_extension
/;
use SQL::Load::Method;

our $VERSION = '0.02';

sub new {
    my ($class, $path) = @_;
    
    # valid if path exists
    croak "Path not defined!" unless $path;
    croak "The '$path' path does not exist!" unless -d $path;    
    
    my $self = {
        _path => $path,
        _data => {},
        _keys => {}
    };    
    
    return bless $self, $class;
}

sub load {
    my ($self, $name, $reload) = @_;
    
    $name = remove_extension($name);
    
    if ($name && $name =~ /^[\w-]+$/) {
        # if true not get tmp
        unless ($reload) {
            # check if exist the key to get tmp
            my $key = $self->_key($name);
            
            # check if tmp exists, if true return
            return $self->_get_tmp($key) if $key;
        }
        
        # get name list
        my $name_list = name_list($name);
        
        # get file from name list
        my $file = $self->_find_file($name_list);   
        
        # get content
        my $content = $self->_file_content($file);
        
        # set tmp
        $self->_set_tmp($content, $file, $name_list);
        
        return SQL::Load::Method->new($content);
    }
    
    croak "the name '$name' is invalid!";
}

sub reload {
    my ($self, $name) = @_;
    
    return $self->load($name, 1);
}

sub _find_file {
    my ($self, $name_list) = @_;
    
    my $file;
    
    for my $name (@$name_list) {
        my $is_file = $self->{_path} . '/' . $name . '.sql';
        
        if (-e $is_file) {
            $file = $is_file;
            
            last;
        }
        
        last if $file;
    }
    
    return $file if $file;
    
    croak "The file does not exist!";    
}

sub _file_content {
    my ($self, $file) = @_;

    my $content = '';
    
    open FH, '<', $file or croak $!;
    while (<FH>) {
       $content .= $_;
    }
    close FH; 
    
    $content =~ s/^\s+|\s+$//g;
    
    return $content;
}

sub _key {
    my ($self, $name) = @_;
    
    return $self->{_keys}->{$name} if exists $self->{_keys}->{$name};
    
    return;
}

sub _generate_key {
    my @characters = ('0'..'9', 'A'..'Z', 'a'..'z');
    my $x = int scalar @characters;
    my $result = join '', map $characters[rand $x], 1..16;

    return $result;
}

sub _get_tmp {
    my ($self, $key) = @_;
    
    return SQL::Load::Method->new($self->{_data}->{$key}->{content}) 
        if exists $self->{_data}->{$key}->{content};
    
    return;
}

sub _set_tmp {
    my ($self, $content, $file, $name_list) = @_;
    
    # generate new key
    my $key = $self->_generate_key;
    
    # save name => key in tmp keys
    $self->{_keys}->{$_} = $key for @$name_list;
    
    # save data in tmp data
    $self->{_data}->{$key}->{content}   = $content;
}

1;

__END__

=encoding utf8
 
=head1 NAME
 
SQL::Load - This module is a simple SQL file loader

=head1 SYNOPSIS

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
  
=head1 DESCRIPTION

Intended to separate SQL from Perl code, this module provides some functions that make it easier to do so.

=head1 METHODS

=head2 new

    my $sql_load = SQL::Load->new($path);

Construct a new L<SQL::Load>, passing the folder path is required.

=head2 load

    my $method = $sql_load->load('file_name'); 
    my $method = $sql_load->load('file_name.sql');
    my $method = $sql_load->load('file_name', 1); # reload to get content directly from the file
    
Load the content in the reference and return an instance of L<SQL::Load::Method>.

=head2 reload

    my $method = $sql_load->reload('file_name'); 
    my $method = $sql_load->reload('file_name.sql');
    my $method = $sql_load->reload('file_name');
    
Reload to get content directly from the file without getting from the tmp from reference.

=head1 FILES SQL
    
=head2 Named SQL

B<For you to name the SQL has 3 ways:>

    -- # NAME
    -- (NAME)
    -- [NAME]
    
These three ways have the same result.

B<Examples:>

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
    
B<Important informations:>

Names must be CamelCase, snake_case or kebab-case.

Each SQL statement must end with a semicolon(;).

=head2 SQL in list

Must be separated by semicolon(;)

B<Examples:>

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

=head1 SEE ALSO
 
L<SQL::Load::Method>.
 
=head1 AUTHOR
 
Lucas Tiago de Moraes, C<lucastiagodemoraes@gmail.com>.
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut
