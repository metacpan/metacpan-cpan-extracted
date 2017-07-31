package Test::PlugAuth::Plugin::Auth;

use strict;
use warnings;
use Test::PlugAuth::Plugin;
use 5.010001;
use Test::Builder;
use Role::Tiny ();
use PlugAuth;
use base qw( Exporter );

our @EXPORT = qw( run_tests );

# ABSTRACT: Test a PlugAuth Auth plugin for correctness
our $VERSION = '0.38'; # VERSION


my $Test = Test::Builder->new;

sub run_tests
{
  my($class, $global_config, $plugin_config) = @_;
  $class = "PlugAuth::Plugin::$class" unless $class =~ /::/;
  eval qq{ use $class };
  die $@ if $@;
  
  $global_config //= {};
  $global_config = Clustericious::Config->new($global_config)
    unless eval { $global_config->isa('Clustericious::Config') };
  $plugin_config //= {};
  $plugin_config = Clustericious::Config->new($plugin_config)
    unless eval { $plugin_config->isa('Clustericious::Config') };
  
  $Test->plan( tests => 14);
  
  my $object = eval { $class->new($global_config, $plugin_config, PlugAuth->new()) };
  my $error = $@;
  if(ref $object)
  {
    $Test->ok(1, "New returns a reference");
    eval {
      foreach my $user ($object->all_users)
      {
        $object->delete_user($user);
      }
    };
  }
  else
  {
    $Test->ok(0, "New returns a reference");
    $Test->diag("ERROR: $error");
  }
  
  $Test->ok( Role::Tiny::does_role($object, 'PlugAuth::Role::Plugin'),  'does Plugin');
  $Test->ok( Role::Tiny::does_role($object, 'PlugAuth::Role::Auth'), 'does Auth');
  
  $Test->ok( eval { $object->check_credentials( 'foo', 'bar') } == 0, "check_credentials (foo:bar) == 0");
  $Test->diag($@) if $@;
  
  $Test->ok( eval { $object->create_user( 'foo', 'bar' ) } == 1, "create_user returns 1");
  $Test->diag($@) if $@;
  
  my $refresh = Role::Tiny::does_role($object, 'PlugAuth::Role::Refresh');
  if($refresh)
  {
    eval { $object->refresh };
    $Test->diag("refresh died: $@") if $@;
  }
  
  $Test->ok( eval { $object->check_credentials( 'foo', 'bar') } == 1, "check_credentials (foo:bar) == 1");
  $Test->diag($@) if $@;
  
  $Test->ok( eval { $object->change_password( 'foo', 'baz') } == 1, "change_password returns 1");
  $Test->diag($@) if $@;
  
  if($refresh)
  {
    eval { $object->refresh };
    $Test->diag("refresh died: $@") if $@;
  }
  
  $Test->ok( eval { $object->check_credentials( 'foo', 'bar') } == 0, "check_credentials (foo:bar) == 0");
  $Test->diag($@) if $@;
  
  $Test->ok( eval { $object->check_credentials( 'foo', 'baz') } == 1, "check_credentials (foo:baz) == 1");
  $Test->diag($@) if $@;
  
  do {
    my @users = $object->all_users;
    if(@users > 0)
    {
      my $pass = $#users == 0 && $users[0] eq 'foo';
      $Test->ok($pass, "all_users == [ foo ]");
      $Test->diag("all_users actually == [ " . join(', ', @users) . " ]")  unless $pass;
    
      eval { $object->create_user( 'fop', 'bar' ) };
      $Test->diag($@) if $@;
    
      if($refresh)
      {
        eval { $object->refresh };
        $Test->diag("refresh died: $@") if $@;
      }
    
      @users = $object->all_users;
    
      $pass = $#users == 1 && (($users[0] eq 'foo' && $users[1] eq 'fop') || ($users[0] eq 'fop' && $users[1] eq 'foo'));
      $Test->ok($pass, "all_users == [ foo, fop ]");
      $Test->diag("all_users actually == [ " . join(', ', @users) . " ]")  unless $pass;
    }
    else
    {
      $Test->skip("all_users returns ()");
      $Test->skip("all_users returns ()");
    }
  };
  
  $Test->ok( eval { $object->delete_user( 'foo') } == 1, "delete_user returns 1");
  $Test->diag($@) if $@;
  
  if($refresh)
  {
    eval { $object->refresh };
    $Test->diag("refresh died: $@") if $@;
  }
  
  $Test->ok( eval { $object->check_credentials( 'foo', 'bar') } == 0, "check_credentials (foo:bar) == 0");
  $Test->diag($@) if $@;
  
  $Test->ok( eval { $object->check_credentials( 'foo', 'baz') } == 0, "check_credentials (foo:baz) == 0");
  $Test->diag($@) if $@;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PlugAuth::Plugin::Auth - Test a PlugAuth Auth plugin for correctness

=head1 VERSION

version 0.38

=head1 SYNOPSIS

 use Test::PlugAuth::Plugin::Auth;
 run_tests 'MyPlugin';  # runs tests against PlugAuth::Plugin::MyPlugin

=head1 FUNCTIONS

=head2 run_tests $plugin_name, [ $global_config, [ $plugin_config ] ]

Run the specification tests against the given plugin.  The configuration
arguments are optional.  The first is the hash which is usually found in
~/etc/PlugAuth.conf and the second is the plugin config.

=head1 SEE ALSO

L<PlugAuth>,
L<PlugAuth::Guide::Plugin>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
