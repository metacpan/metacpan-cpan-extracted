package PlugAuth::Plugin::FlatAuth;

# ABSTRACT: Authentication using Flat Files for PlugAuth
our $VERSION = '0.39'; # VERSION


use strict;
use warnings;
use 5.010001;
use Log::Log4perl qw( :easy );
# TODO: maybe optionally use Crypt::Passwd::XS instead
use Crypt::PasswdMD5 qw( unix_md5_crypt apache_md5_crypt );
use Role::Tiny::With;

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Auth';
with 'PlugAuth::Role::Refresh';
with 'PlugAuth::Role::Flat';

our %Userpw;              # Keys are usernames, values are lists of crypted passwords.

sub init {
    shift->flat_init;
}


sub refresh {
  # Should be called with every request.
  my $config = __PACKAGE__->global_config;
  my @user_files = $config->user_file;
  if ( grep has_changed($_), @user_files )
  {
    my @users = map +{ __PACKAGE__->read_file($_, lc_keys => 1) }, @user_files;
    %Userpw = ();
    for my $list (@users)
    {
      for my $user (map { lc $_ } keys %$list)
      {
        $Userpw{$user} //= [];
        push @{ $Userpw{$user} }, $list->{$user};
      }
    }

    # if the user file has changed, then that may mean the
    # group file has to be reloaded, for example, for groups
    # with wildcards * need to be updated.
    mark_changed($config->group_file);
  }
}


sub _validate_pw
{
  my($plain, $encrypted) = @_;
  return 1 if do {
    # crypt on an apache apr1 encrypted
    # password seems to return undef
    # on Debian 8 (probably others)
    my $ret = crypt($plain, $encrypted);
    (defined $ret) && ($ret eq $encrypted);
  };
    
  # idea borrowed from Authen::Simple::Password
  if($encrypted =~ /^\$(\w+)\$/)
  {
    return 1 if $1 eq 'apr1' && apache_md5_crypt( $plain, $encrypted ) eq $encrypted;

    # on at least modern Linux crypt will accept a UNIX 
    # MD5 password, so this may be redundant
    return 1 if $1 eq '1'    && unix_md5_crypt  ( $plain, $encrypted ) eq $encrypted;
  }
  return 0;
}

sub check_credentials {
  my ($self, $user,$pw) = @_;
  $user = lc $user;

  if($pw && $Userpw{$user})
  {
    return 1 if grep { _validate_pw($pw, $_) } @{ $Userpw{$user} };
  }
  return $self->deligate_check_credentials($user, $pw);
}


sub all_users {
  return sort keys %Userpw;
}


sub _created_encrypted_password
{
  my($plain) = @_;
  my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
  apache_md5_crypt($plain, $salt);
}

sub create_user { goto &create_user_cb }

sub create_user_cb
{
  my($self, $user, $password, $cb) = @_;

  unless($user && $password)
  {
    WARN "User or password not provided";
    return 0;
  }

  $user = lc $user;

  if(defined $Userpw{$user})
  {
    WARN "User $user already exists";
    return 0;
  }

  foreach my $filename ($self->global_config->user_file)
  {
    next unless -w $filename;

    $password = _created_encrypted_password($password);

    my $ok = $self->lock_and_update_file($filename, sub {
      use autodie;
      my($fh) = @_;

      my $buffer = '';
      while(! eof $fh)
      {
        my $line = <$fh>;
        chomp $line;
        $buffer .= "$line\n";
      }
      $buffer .= join(':', $user, $password) . "\n";
      
      # as a rule we don't update the data structure
      # directly, we update the config files and let
      # refresh do that on the next request, but in
      # this case the callback is used to modify groups,
      # and for that to work we need to update the 
      # userdatabase first.
      $Userpw{$user} = $password;
      $cb->() if defined $cb;
      
      $buffer;
    });

    return 0 unless $ok;

    INFO "created user $user";
    return 1;
  }

  ERROR "None of the user files were writable";
  return 0;
}


sub change_password
{
  my($self, $user, $password) = @_;

  unless($user && $password)
  {
    WARN "User or password not provided";
    return 0;
  }

  $user = lc $user;

  unless(defined $Userpw{$user})
  {
    WARN "User $user does not exist";
    return 0;
  }

  $password = _created_encrypted_password($password);

  foreach my $filename ($self->global_config->user_file)
  {
    $self->lock_and_update_file($filename, sub {
      use autodie;
      my($fh) = @_;

      my $buffer = '';
      
      while(! eof $fh)
      {
        my $line = <$fh>;
        chomp $line;
        my($thisuser, $oldpassword) = split /:/, $line;
        if(defined $thisuser && lc($thisuser) eq $user)
        {
          $buffer .= join(':', $user, $password) . "\n";
        }
        else
        {
          $buffer .= "$line\n";
        }
      }
      
      $buffer;
    });
  }

  INFO "user password changed $user";
  return 1;
}


sub delete_user
{
  my($self, $user) = @_;

  $user = lc $user;

  unless(defined $Userpw{$user})
  {
    WARN "User $user does not exist";
    return 0;
  }

  foreach my $filename ($self->global_config->user_file)
  {
    $self->lock_and_update_file($filename, sub {
      use autodie;
      my($fh) = @_;

      my $buffer = '';
      while(! eof $fh)
      {
        my $line = <$fh>;
        chomp $line;
        my($thisuser, $password) = split /:/, $line;
        next if ($thisuser//'') eq $user;
        $buffer .= "$line\n";
      }
      $buffer;
    });
  }

  INFO "deleted user $user";
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::FlatAuth - Authentication using Flat Files for PlugAuth

=head1 VERSION

version 0.39

=head1 SYNOPSIS

In your PlugAuth.conf file:

 ---
 url: http://localhost:1234
 user_file: /path/to/user.txt

Touch the user file:

 % touch /path/to/user.txt

Add users using htpasswd (comes with Apache):

 % htpasswd -m /path/to/user.txt newusername
 New password: 
 Re-type new password: 

Start PlugAuth:

 % plugauth start

=head1 DESCRIPTION

This is the default Authentication plugin for L<PlugAuth>.  It is designed to work closely
with L<PlugAuth::Plugin::FlatAuthz> which is the default Authorization plugin.

This plugin provides storage and password verification for users.  This plugin also provides 
a mechanism for PlugAuth to change passwords, create and delete users.  Although the user 
information is stored in flat files, the entire user database is kept in memory and the 
files are only re-read when a change is detected, so this plugin is relatively fast.

=head1 CONFIGURATION

=head2 user_file

The user file is 
specified in the PlugAuth.conf file using the user_file field.  The format of the user
is a basic user:password comma separated list, which is compatible with Apache password
files.  Either the UNIX crypt, Apache MD5 or UNIX MD5 format may be used for the passwords.

 foo:$apr1$F3VOmjio$O8dodh0VEljQvuzeruvsb0
 bar:yOJEfNAE.gppk

It is possible to have multiple user files if you specify a list:

 ---
 user_file:
   - /path/to/user1.txt
   - /path/to/user2.txt

=head1 METHODS

=head2 PlugAuth::Plugin::FlatAuth-E<gt>refresh

Refresh the data (checks the files, and re-reads if necessary).

=head2 PlugAuth::Plugin::FlatAuth-E<gt>check_credentials( $user, $password )

Given a user and password, check to see if the password is correct.

=head2 PlugAuth::Plugin::FlatAuth-E<gt>all_users

Returns a list of all users.

=head2 PlugAuth::Plugin::FlatAuth-E<gt>create_user( $user, $password )

=head2 PlugAuth::Plugin::FlatAuth-E<gt>create_user_cb( $user, $password, $callback)

Create a new user with the given password.

=head2 PlugAuth::Plugin::FlatAuth-E<gt>change_password( $user, $password )

Change the password of the given user.

=head2 PlugAuth::Plugin::FlatAuth-E<gt>delete_user( $user )

Delete the given user.

=head1 SEE ALSO

L<PlugAuth>, L<PlugAuth::Plugin::FlatAuthz>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
