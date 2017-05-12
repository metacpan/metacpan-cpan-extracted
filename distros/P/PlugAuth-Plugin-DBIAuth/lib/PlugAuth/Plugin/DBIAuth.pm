package PlugAuth::Plugin::DBIAuth;

use strict;
use warnings;
use 5.010;
use DBI;
use Log::Log4perl qw/:easy/;
use Role::Tiny::With;
use Crypt::PasswdMD5 qw( unix_md5_crypt apache_md5_crypt );

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Auth';

# ABSTRACT: DBI Authentication back end for PlugAuth
our $VERSION = '0.05'; # VERSION


sub init
{
  my($self) = @_;
  my %db  = $self->plugin_config->db;
  my %sql = $self->plugin_config->sql;

  $self->{dbh} = DBI->connect($db{dsn}, $db{user}, $db{pass}, 
    { RaiseError => 1, AutoCommit => 1 }
  );
  
  $self->{dbh}->do($sql{init})
    if defined $sql{init};
  
  foreach my $name (qw( check_credentials all_users create_user change_password delete_user ))
  {
    $self->{$name} = $self->{dbh}->prepare($sql{$name})
      if defined $sql{$name};
  }
  
  $self->{encryption} = $self->plugin_config->encryption(default => 'apache_md5');
}


sub check_credentials
{
  my($self, $user, $pass) = @_;

  if(defined $self->{check_credentials})
  {
    $self->{check_credentials}->execute($user);
    my($encrypted) = $self->{check_credentials}->fetchrow_array;
    $self->{check_credentials}->finish;
    if($encrypted)
    {
      my $tmp = crypt($pass, $encrypted);
      return 1 if (defined $tmp) && ($tmp eq $encrypted);
      
      if($encrypted =~ /^\$(\w+)\$/)
      {
        return 1 if $1 eq 'apr1' && apache_md5_crypt( $pass, $encrypted ) eq $encrypted;
        return 1 if $1 eq '1'    && unix_md5_crypt  ( $pass, $encrypted ) eq $encrypted;
      }
    }
  }

  $self->deligate_check_credentials($user, $pass);
}


sub all_users 
{
  my($self) = @_;
  
  my @list;
  
  if(defined $self->{all_users})
  {
    $self->{all_users}->execute;
    while(my $row = $self->{all_users}->fetchrow_arrayref)
    {
      push @list, $row->[0];
    }
  }
  
  @list;
}


sub create_user {
  my($self, $user, $pass) = @_;
  
  if(defined $self->{create_user})
  {
    $self->{create_user}->execute($user, $self->created_encrypted_password($pass));
    return 1;
  }
  else
  {
    return 0;
  }
}


sub change_password {
  my($self, $user, $pass) = @_;
  
  if(defined $self->{change_password})
  {
    $self->{change_password}->execute($self->created_encrypted_password($pass), $user);
    return 1;
  }
  else
  {
    return 0;
  }
}


sub delete_user {
  my($self, $user) = @_;
  
  if(defined $self->{delete_user})
  {
    $self->{delete_user}->execute($user);
    return 1;
  }
  else
  {
    return 0;
  }
} 


sub dbh { shift->{dbh} }


sub created_encrypted_password
{
    my($self, $plain) = @_;
    my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
    if($self->{encryption} eq 'apache_md5')
    {
      return apache_md5_crypt($plain, $salt);
    }
    elsif($self->{encryption} eq 'unix_md5')
    {
      return unix_md5_crypt($plain, $salt);
    }
    elsif($self->{encryption} eq 'unix')
    {
      return crypt($plain, $salt);
    }
    else
    {
      die "unknown encryption " . $self->{encryption};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::DBIAuth - DBI Authentication back end for PlugAuth

=head1 VERSION

version 0.05

=head1 SYNOPSIS

In your PlugAuth.conf file:

 ---
 plugins:
   - PlugAuth::Plugin::DBIAuth:
       db:
         dsn: 'dbi:SQLite:dbname=/path/to/dbfile.sqlite'
         user: ''
         pass: ''
       sql:
         init: 'CREATE TABLE IF NOT EXISTS users (username VARCHAR UNIQUE, password VARCHAR)'
         check_credentials: 'SELECT password FROM users WHERE username = ?'
         all_users: 'SELECT username FROM users'

=head1 DESCRIPTION

This plugin provides an authentication mechanism for PlugAuth using any
database supported by DBI as a backend.  It is configured as above, with
two hashes, db and sql.

=head2 encryption

Specifies the encryption method to use.  This is only used when creating
new users, or changing their passwords.  Existing passwords will remain
in their existing formats and will be decrypted automatically in the 
correct format.

If provided, must be one of:

=over 4

=item * unix

Traditional UNIX crypt()

=item * unix_md5

UNIX MD5

=item * apache_md5 [ default ]

Apache MD5

=back

=head2 db

The db hash provides the required parameters for the plugin needed to
connect to the database.

=head3 dsn

The DNS passed into DBI.  See the documentation for your database driver
for the exact format (L<DBD::SQLite>, L<DBD::Pg>, L<DBD::mysql> ... ).

=head3 user

The database user.

=head3 pass

The database password.

=head2 sql

The sql hash provides SQL statements which are executed for each 
operation.  They are all optional.  The examples shown here assumes
a simple table with usernames and passwords:

 CREATE TABLE IF NOT EXISTS users (
   username VARCHAR UNIQUE,
   password VARCHAR
 );

=head3 init

Arbitrary SQL executed when the plugin is started.

=head3 check_credentials

The SQL statement used to fetch the encrypted password of a
user.  The username is the first bind value when executed.
Example:

 SELECT password FROM users WHERE username = ?

=head3 all_users

The SQL statement used to fetch the list of users.  Example:

 SELECT username FROM users

=head3 create_user

The SQL statement used to create a new user.  Example:

 INSERT INTO users (username, password) VALUES (?,?)

=head3 change_password

The SQL statement used to change the password of an existing user.  Example:

 UPDATE users SET password = ? WHERE username = ?

=head3 delete_user

The SQL statement used to delete an existing user.  Example:

 DELETE FROM users WHERE username = ?

=head3 dbh

Returns the dbh handle used to query the database.

=head3 created_encrypted_password

Given a new plain text password, return the encrypted version.

=head1 SEE ALSO

L<DBI>,
L<PlugAuth>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
