package Rose::DB::Object::MakeMethods::Pg;

use strict;

our $VERSION = '0.771';

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DB::Object::Constants 
  qw(STATE_LOADING STATE_SAVING MODIFIED_COLUMNS MODIFIED_NP_COLUMNS SET_COLUMNS STATE_IN_DB);

use constant SALT_CHARS => './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

sub chkpass
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $encrypted = $name . ($args->{'encrypted_suffix'} || '_encrypted');
  my $cmp       = $name . ($args->{'cmp_suffix'} || '_is');

  my $default = $args->{'default'};

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_LOADING()});

        if(defined $_[0])
        {
          if(index($_[0], ':') == 0)
          {
            $self->{$key} = undef;
            return $self->{$encrypted} = shift;
          }
          else
          {
            my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                       substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
            $self->{$encrypted} = ':' . crypt($_[0], $salt);
            return $self->{$key} = $_[0];
          }
        }

        return $self->{$encrypted} = $self->{$key} = undef;
      }

      if($self->{STATE_SAVING()})
      {


        unless(!defined $default || defined $self->{$encrypted} ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        #if(!defined $self->{$encrypted} && defined $default)
        {
          if(index($default, ':') == 0)
          {
            $self->{$encrypted} = $default;
          }
          else
          {
            my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                       substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
            $self->{$encrypted} = ':' . crypt($default, $salt);
          }
        }

        return $self->{$encrypted};
      }

      return $self->{$key};
    };

    $methods{$encrypted} = sub
    {
      my($self) = shift;

      if(@_)
      {
        $self->{$mod_columns_key}{$column_name} = 1
          unless($self->{STATE_LOADING()});

        if(!defined $_[0] || index($_[0], ':') == 0)
        {
          return $self->{$encrypted} = shift;
        }
        else
        {
          my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                     substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
          $self->{$encrypted} = ':' . crypt($_[0], $salt);
          $self->{$key} = $_[0];
        }
      }

      unless(!defined $default || defined $self->{$encrypted} ||
           ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
            ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      #if(!defined $self->{$encrypted} && defined $default)
      {
        if(index($default, ':') == 0)
        {
          $self->{$encrypted} = $default;
        }
        else
        {
          my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                     substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
          $self->{$encrypted} = ':' . crypt($default, $salt);
        }
      }

      return $self->{$encrypted};
    };

    $methods{$cmp} = sub
    {
      my($self, $check) = @_;

      my $pass = $self->{$key};

      if(defined $pass)
      {
        return ($check eq $pass) ? 1 : 0;
      }

      my $crypted = $self->{$encrypted};

      unless(!defined $default || defined $crypted ||
             ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
              ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
      #if(!defined $crypted && defined $default)
      {
        if(index($default, ':') == 0)
        {
          $crypted = $self->{$encrypted} = $default;
        }
        else
        {
          my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                     substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
          $crypted = $self->{$encrypted} = ':' . crypt($default, $salt);
        }
      }

      if(defined $crypted)
      {
        my $salt = substr($crypted, 1, 2);

        if(':' . crypt($check, $salt) eq $crypted)
        {
          $self->{$key} = $check;
          return 1;
        }

        return 0;
      }

      return undef;
    };
  }
  elsif($interface eq 'get')
  {
    $methods{$name} = sub 
    {
      my($self) = shift;

      if($self->{STATE_SAVING()})
      {

        unless(!defined $default || defined $self->{$encrypted} ||
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        #if(!defined $self->{$encrypted} && defined $default)
        {
          if(index($default, ':') == 0)
          {
            $self->{$encrypted} = $default;
          }
          else
          {
            my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                       substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
            $self->{$encrypted} = ':' . crypt($default, $salt);
          }
        }

        return $self->{$encrypted};
      }

      return $self->{$key};
    };
  }
  elsif($interface eq 'set')
  {
    my $encrypted = $key . ($args->{'encrypted_suffix'} || '_encrypted');

    $methods{$name} = sub
    {
      my($self) = shift;

      Carp::croak "Missing argument in call to $name"  unless(@_);

      $self->{$mod_columns_key}{$column_name} = 1
        unless($self->{STATE_LOADING()});

      if(defined $_[0])
      {
        if(index($_[0], ':') == 0)
        {
          $self->{$key} = undef;
          return $self->{$encrypted} = shift;
        }
        else
        {
          my $salt = substr(SALT_CHARS, int rand(length SALT_CHARS), 1) . 
                     substr(SALT_CHARS, int rand(length SALT_CHARS), 1);
          $self->{$encrypted} = ':' . crypt($_[0], $salt);
          return $self->{$key} = $_[0];
        }
      }

      return $self->{$encrypted} = $self->{$key} = undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::Pg - Create PostgreSQL-specific object methods for Rose::DB::Object-derived objects.

=head1 SYNOPSIS

  package MyDBObject;

  our @ISA = qw(Rose::DB::Object);

  use Rose::DB::Object::MakeMethods::Pg
  (
    chkpass => 
    [
      'password',
      'secret' => 
      {
        encrypted_suffix => '_mangled',
        cmp_suffix       => '_equals',
      },
    ],
  );

  ...

  $o = MyDBObject->new(...);

  $o->password('foobar');

  # Something like: ":vOR7BujbRZSLM" (varies based on salt used)
  print $o->password_encrypted;

  print $o->password; # "foobar"
  print "ok" if($o->password_is('foobar'); # "ok"

  $o->secret('baz');

  # Something like: ":jqROBZMqtWGJE" (varies based on salt used)
  print $o->secret_mangled;

  print $o->secret; # "baz"
  print "ok" if($o->secret_equals('baz'); # "ok"

=head1 DESCRIPTION

C<Rose::DB::Object::MakeMethods::Pg> creates methods that deal with data types that are specific to the PostgreSQL database server.  It inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  In particular, the object is expected to have a C<db> method that returns a L<Rose::DB>-derived object.  See the L<Rose::DB::Object> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<chkpass>

Create a family methods for handling PostgreSQL's "CHKPASS" data type.  This data type is not installed by default, but is included in the standard PostgreSQL source code distribution (in the "contrib" directory).  From the README file for CHKPASS:

"Chkpass is a password type that is automatically checked and converted upon
entry.  It is stored encrypted.  To compare, simply compare against a clear
text password and the comparison function will encrypt it before comparing.

If you precede the string with a colon, the encryption and checking are
skipped so that you can enter existing passwords into the field.

On output, a colon is prepended.  This makes it possible to dump and reload
passwords without re-encrypting them.  If you want the password (encrypted)
without the colon then use the raw() function.  This allows you to use the
type with things like Apache's Auth_PostgreSQL module."

This data type is very handy for storing encrypted values such as passwords while still retaining the ability to perform SELECTs and such using unencrypted values in comparisons.  For example, the query

    SELECT * FROM users WHERE password = 'foobar'

will actually find all the users whose passwords are "foobar", even though all the passwords are encrypted in the database.

=over 4

=item Options

=over 4

=item C<cmp_suffix>

The string appended to the default method name to form the name of the comparison method.  Defaults to "_is".

=item C<encrypted_suffix>

The string appended to the default method name to form the name of the get/set method that handles the encrypted version of the CHKPASS value.  Defaults to "_encrypted".

=item C<hash_key>

The key inside the hash-based object to use for the storage of the unencrypted value.  Defaults to the name of the method.

The encrypted value is stored in a hash key with the same name, but with C<encrypted_suffix> appended.  

=item C<interface>

Choose the interface.  The default is C<get_set>.

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a family of methods for handling PostgreSQL's "CHKPASS" data type.  The methods are:

=over 4

=item C<default>

The get/set method for the unencrypted value.  (This method uses the default method name.)  If called with no arguments, the unencrypted value is returned, if it is known.  If not, undef is returned.

If passed an argument that begins with ":", it is assumed to be an encrypted value and is stored as such.  Undef is returned, since it is not feasible to determine the unencrypted value based on the encrypted value.

If passed an argument that does not begin with ":", it is taken as the unencrypted value.  The value is encrypted using Perl's C<crypt()> function paired with a randomly selected salt, and the unencrypted value is returned.

=item C<encrypted>

The get/set method for the encrypted value.  The method name will be formed by concatenating the C<default> method name (above) and the value of the C<encrypted_suffix> option.

If called with no arguments, the encrypted value is returned, if it is known.  If not, undef is returned.

If passed an argument that begins with ":", it is assumed to be an encrypted value and is stored as such.  The unencrypted value is set to undef, since it is not feasible to determine the unencrypted value based on the encrypted value.  The encrypted value is returned.

If passed an argument that does not begin with ":", it is taken as the unencrypted value.  The value is encrypted using Perl's C<crypt()> function paired with a randomly selected salt, and the encrypted value is returned.

=item C<comparison>

This method compares its argument to the unencrypted value and returns true if the two values are identical (string comparison), false if they are not, and undef if both the encrypted and unencrypted values are undefined.

=back

=back

=item C<get>

Creates an accessor method for PostgreSQL's "CHKPASS" data type.  This method behaves like the C<get_set> method, except that the value cannot be set.

=item C<set>

Creates a mutator method for PostgreSQL's "CHKPASS" data type.  This method behaves like the C<get_set> method, except that a fatal error will occur if no arguments are passed. 

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Pg
    (
      chkpass => 
      [
        'password',
        'get_password' => { interface => 'get', hash_key => 'password' },
        'set_password' => { interface => 'set', hash_key => 'password' },
        'secret' => 
        {
          encrypted_suffix => '_mangled',
          cmp_suffix       => '_equals',
        },
      ],
    );

    ...

    $o = MyDBObject->new(...);

    $o->set_password('blah');

    $o->password('foobar');

    # Something like: ":vOR7BujbRZSLM" (varies based on salt used)
    print $o->password_encrypted;

    print $o->get_password; # "foobar"
    print $o->password;     # "foobar"
    print "ok" if($o->password_is('foobar'); # "ok"

    $o->secret('baz');

    # Something like: ":jqROBZMqtWGJE" (varies based on salt used)
    print $o->secret_mangled;

    print $o->secret; # "baz"
    print "ok" if($o->secret_equals('baz'); # "ok"

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
