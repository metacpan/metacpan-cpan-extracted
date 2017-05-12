package Rose::DBx::Object::MakeMethods::EKSBlowfish;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Rose::DB::Object::Metadata;
use Crypt::Eksblowfish::Bcrypt qw /bcrypt en_base64/;

use Rose::DBx::Object::Metadata::Column::EKSBlowfish;
Rose::DB::Object::Metadata->column_type_class(
    eksblowfish => 'Rose::DBx::Object::Metadata::Column::EKSBlowfish'
);

our $VERSION = '0.07';

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DB::Object::Constants
  qw(STATE_LOADING STATE_SAVING MODIFIED_COLUMNS MODIFIED_NP_COLUMNS SET_COLUMNS STATE_IN_DB);

sub eksblowfish
{
  my($class, $name, $args) = @_;
  my $eks_sign = qr /^\$2a?\$\d{2}\$/;

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

  $methods{$name} = sub
  {
    my($self) = shift;

    if(@_)
    {
      $self->{$mod_columns_key}{$column_name} = 1
        unless($self->{STATE_LOADING()});

      if(defined $_[0])
      {
        if(($_[0] =~ $eks_sign) && length($_[0]) > 57)
        {
          $self->{$key} = undef;
          return $self->{$encrypted} = shift;
        }
        else
        {
          $self->{$encrypted} = _encrypt($_[0],$args);
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
        if(($_[0] =~ $eks_sign) && length($_[0]) > 57)
        {
          $self->{$encrypted} = $default;
        }
        else
        {
          $self->{$encrypted} = _encrypt($default, $args);
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

      if(!defined $_[0] || (($_[0] =~ $eks_sign) && length($default) > 57))
      {
        return $self->{$encrypted} = shift;
      }
      else
      {
        $self->{$encrypted} =  _encrypt($_[0],$args);
        $self->{$key} = $_[0];
      }
    }

    unless(!defined $default || defined $self->{$encrypted} ||
         ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} ||
          ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
    #if(!defined $self->{$encrypted} && defined $default)
    {
      if(($default =~ $eks_sign) && length($default) > 57)
      {
        $self->{$encrypted} = $default;
      }
      else
      {
        $self->{$encrypted} = _encrypt($default,$args);
      }
    }

    return $self->{$encrypted};
  };

  $methods{$cmp} = sub
  {
    my($self, $check) = @_;

    my $pass = $self->{$key};
    my $crypted = $self->{$encrypted};

    return 0 if not $check;
    if(defined $pass)
    {
      if(bcrypt($check, $crypted) eq $crypted)
      {
         $self->{$key} = $check;
        return 1;
      }
      return 0;
    }


    unless(!defined $default || defined $crypted ||
           ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} ||
            ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
    #if(!defined $crypted && defined $default)
    {
      if(($default =~ $eks_sign) && length($default) > 57)
      {
        $crypted = $self->{$encrypted} = $default;
      }
      else
      {
        $crypted = $self->{$encrypted} = bcrypt($check, $default);
      }
    }

    if(defined $crypted)
    {
      if(bcrypt($check, $crypted) eq $crypted)
      {
        $self->{$key} = $check;
        return 1;
      }

      return 0;
    }

    return undef;
  };

  return \%methods;
}



sub _encrypt {

  my ($pass, $args) = @_;
  my $cost = exists $args->{cost}    ? $args->{cost}    : 8;
  my $nul  = exists $args->{key_nul} ? $args->{key_nul} : 0;

  $nul = $nul ? 'a' : '';
  $cost = sprintf("%02i", 0+$cost);

  # It must begin with "$2",  optional "a", bcrypt identifier, two digits, bcrypt identifier
  # /^\$2a?\$\d{2}\$/
  my $settings_base = join('','$2',$nul,'$',$cost, '$');

  my $encoder = sub {
    my ($plain_text, $settings_str) = @_;
    unless ( $settings_str ) {
      my $salt = join('', map { chr(int(rand(256))) } 1 .. 16);
      $salt = Crypt::Eksblowfish::Bcrypt::en_base64( $salt );
      $settings_str =  $settings_base.$salt;
    }
    return bcrypt($plain_text, $settings_str);
  };
  return $encoder->($pass);
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::EKSBlowfish - Create Blowfish-specific object methods for Rose::DB::Object-derived objects.

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

   package MyDBObject;

   our @ISA = qw(Rose::DB::Object);

   use Rose::DBx::Object::MakeMethods::EKSBlowfish(
   eksblowfish =>
      [
        'type' =>
        {
          cost      => 8,
          key_nul   => 0,
        },
      ],
   );

  ...

  $o = MyDBObject->new(...);

  $o->password('foobar');

  # Something like: "$2$08$NWgpob52QKA2fRUgCwB93O1qoHZGu/Kr9iGfI/2nhy9uc9R2IG9by"
  print $o->password_encrypted;

  print $o->password; # "foobar"
  print "ok" if($o->password_is('foobar'); # "ok"


=head1 DESCRIPTION

C<Rose::DB::Object::MakeMethods::EKSBlowfish> creates methods that deal with eksblowfish encrypted passwords.  It inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  In particular, the object is expected to have a C<db> method that returns a L<Rose::DB>-derived object.  See the L<Rose::DB::Object> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<eksblowfish>

Create a family methods for handling eksblowfish encrypted passwords.

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

=back

=item Interfaces

=over 4

=item C<get_set>

Creates a family of methods for handling eksblowfish encrypted passwords.  The methods are:

=over 4

=item C<default>

The get/set method for the unencrypted value.  (This method uses the default method name.)  If called with no arguments, the unencrypted value is returned, if it is known.  If not, undef is returned.

If passed an argument that begins with bcrypt identifier, it is assumed to be an encrypted value and is stored as such.  Undef is returned, since it is not feasible to determine the unencrypted value based on the encrypted value.

If passed an argument that does not begin with bcrypt identifier, it is taken as the unencrypted value.

=item C<encrypted>

The get/set method for the encrypted value.  The method name will be formed by concatenating the C<default> method name (above) and the value of the C<encrypted_suffix> option.

If called with no arguments, the encrypted value is returned, if it is known.  If not, undef is returned.

If passed an argument that begins with bcrypt identifier, it is assumed to be an encrypted value and is stored as such.  The unencrypted value is set to undef, since it is not feasible to determine the unencrypted value based on the encrypted value.  The encrypted value is returned.

If passed an argument that does not begin with bcrypt identifier, it is taken as the unencrypted value. =item C<comparison>

This method compares its argument to the unencrypted value and returns true if the two values are identical (string comparison), false if they are not, and undef if both the encrypted and unencrypted values are undefined.

=back

=back

=back

Example:

    package MyDBObject;

    use base qw(Rose::DB::Object);
    use Rose::DBx::Object::MakeMethods::EKSBlowfish(
    eksblowfish =>
       [
         'type' =>
         {
           cost      => 8,
           key_nul   => 0,
         },
       ],
    );:w


    __PACKAGE__->meta->setup(
        db => $db,
        table => 'users',

        columns => [
            id              => { type => 'serial',    not_null => 1 },
            name            => { type => 'varchar',   length   => 255, not_null => 1 },
            password        => { type => 'eksblowfish', not_null => 1, },
        ],

        primary_key_columns => ['id'],

        unique_key => ['name'],

    );

    ...

    $o = MyDBObject->new(...);

    $o->password('blah');

    $o->password('foobar');

    # Something like: "$2$08$ft6IhGIrQz1uDJiv6nD7sePuQEfcpb7excBQnDGu2GmDuk7kb5Ie6"
    print $o->password_encrypted;

    print $o->get_password; # "foobar"
    print $o->password;     # "foobar"
    print "ok" if($o->password_is('foobar'); # "ok"

=item B<_encrypted>

the encryption generator

=back

=head1 AUTHOR

Holger Rupprecht (holger.rupprecht@gmx.de)

=head1 LICENSE

Copyright (c) 2013 by Holger Rupprecht.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

1; # End of Rose::DBx::Object::MakeMethods::EKSBlowfish
