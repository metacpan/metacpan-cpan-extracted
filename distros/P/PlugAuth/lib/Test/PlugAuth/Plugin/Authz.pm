package Test::PlugAuth::Plugin::Authz;

use strict;
use warnings;
use Test::PlugAuth::Plugin;
use 5.010001;
use Test::Builder;
use Role::Tiny ();
use PlugAuth;
use File::Temp qw( tempdir );
use YAML::XS qw( DumpFile );
use base qw( Exporter );

our @EXPORT = qw( run_tests );

# ABSTRACT: Test a PlugAuth Authz plugin for correctness
our $VERSION = '0.39'; # VERSION


my $Test = Test::Builder->new;

sub run_tests
{
  my($class, $global_config, $plugin_config) = @_;
  $class = "PlugAuth::Plugin::$class" unless $class =~ /::/;
  eval qq{ use $class };
  die $@ if $@;
  
  $Test->plan( tests => 65 );
  
  $global_config //= {};
  
  local $ENV{CLUSTERICIOUS_CONF_DIR} = do {
    my $dir = tempdir(CLEANUP => 1);
    my $list_fn = File::Spec->catfile($dir, 'user_list.txt');
    do {
      use autodie;
      open my $fh, '>', $list_fn;
      say $fh "optimus";
      say $fh "primus";
      say $fh "megatron";
      say $fh "grimlock";
      close $fh;
    };
    
    DumpFile(File::Spec->catfile($dir, 'PlugAuth.conf'), {
      %$global_config,
      plugins => [
        {
          'PlugAuth::Plugin::FlatUserList' => {
          user_list_file => $list_fn,
          },
        }
      ],
    });
    $dir;
  };
  
  $global_config = Clustericious::Config->new($global_config)
    unless eval { $global_config->isa('Clustericious::Config') };
  $plugin_config //= {};
  
  my $object = eval { $class->new($global_config, $plugin_config, PlugAuth->new()) };
  my $error = $@;
  if(ref $object)
  {
    $Test->ok(1, "New returns a reference");
  }
  else
  {
    $Test->ok(0, "New returns a reference");
    $Test->diag("ERROR: $error");
  }
  
  $Test->ok( Role::Tiny::does_role($object, 'PlugAuth::Role::Plugin'),  'does Plugin');
  $Test->ok( Role::Tiny::does_role($object, 'PlugAuth::Role::Authz'), 'does Auth');
  
  my $refresh = Role::Tiny::does_role($object, 'PlugAuth::Role::Refresh') ? sub { $object->refresh } : sub {};
  $refresh->();
  
  foreach my $username (qw( optimus primus megatron grimlock ))
  {
    my $groups = $object->groups_for_user($username);
    my $pass = ref($groups) eq 'ARRAY' && $#$groups == 0 && $groups->[0] eq $username;
    $Test->ok( $pass, "user $username belongs to exactly one group: $username" );
  }
  
  do {
    do {
      my @groups = $object->all_groups;
      $Test->ok( $#groups == -1, "no groups" );
    };
    
    $Test->ok( eval { $object->create_group( 'group1', 'optimus,primus' ) } == 1, "create_group returned 1" );
    $Test->diag($@) if $@;
    $refresh->();
    
    do {
      my @groups = $object->all_groups;
      $Test->ok( $#groups == 0 && $groups[0] eq 'group1', 'group1 exists' );
    
      my @optimus  = sort @{ $object->groups_for_user('optimus') };
      my @primus   = sort @{ $object->groups_for_user('primus') };
      my @megatron = sort @{ $object->groups_for_user('megatron') };
    
      $Test->ok( $#optimus == 1 && $optimus[0] eq 'group1' && $optimus[1] eq 'optimus',
                 "optimus groups = optimus,group1");
      $Test->ok( $#primus == 1 && $primus[0] eq 'group1' && $primus[1] eq 'primus',
                 "primus groups = primus,group1");
      $Test->ok( $#megatron == 0 && $megatron[0] eq 'megatron',
                 "megatron groups = megatron" );
    
      my @users = sort @{ $object->users_in_group('group1') };
      my $pass = $#users == 1 && $users[0] eq 'optimus' && $users[1] eq 'primus';
      $Test->ok( $pass, "group1 = optimus, primus" );
      $Test->diag("group1 actually = [ ", join(', ', @users) , " ]")
        unless $pass;
    };
    
    $Test->ok( eval { $object->update_group('group1', "optimus,megatron") } == 1, "update_group returned 1" );
    $Test->diag($@) if $@;
    $refresh->();

    do {
      my @groups = $object->all_groups;
      $Test->ok( $#groups == 0 && $groups[0] eq 'group1', 'group1 exists' );
    
      my @optimus  = sort @{ $object->groups_for_user('optimus') };
      my @primus   = sort @{ $object->groups_for_user('primus') };
      my @megatron = sort @{ $object->groups_for_user('megatron') };
    
      $Test->ok( $#optimus == 1 && $optimus[0] eq 'group1' && $optimus[1] eq 'optimus',
                 "optimus groups = optimus,group1");
      $Test->ok( $#primus == 0 && $primus[0] eq 'primus',
                 "primus groups = primus");
      $Test->ok( $#megatron == 1 && $megatron[0] eq 'group1' && $megatron[1] eq 'megatron',
                 "megatron groups = group1,megatron" );
    
      my @users = sort @{ $object->users_in_group('group1') };
      my $pass = $#users == 1 && $users[0] eq 'megatron' && $users[1] eq 'optimus';
      $Test->ok( $pass, "group1 = megatron, optimus" );
      $Test->diag("group1 actually = [ ", join(', ', @users) , " ]")
        unless $pass;
    };
    
    $Test->ok( eval { $object->delete_group('group1') } == 1, "delete_group returned 1" );
    $Test->diag($@) if $@;
    $refresh->();
    
    do {
      my @groups = $object->all_groups;
      $Test->ok( $#groups == -1, 'group1 DOES NOT exists' );
    
      my @optimus  = sort @{ $object->groups_for_user('optimus') };
      my @primus   = sort @{ $object->groups_for_user('primus') };
      my @megatron = sort @{ $object->groups_for_user('megatron') };
    
      $Test->ok( $#optimus == 0 && $optimus[0] eq 'optimus',
                 "optimus groups = group1");
      $Test->ok( $#primus == 0 && $primus[0] eq 'primus',
                 "primus groups = primus");
      $Test->ok( $#megatron == 0 && $megatron[0] eq 'megatron',
                 "megatron groups = megatron" );
    
      my $users = $object->users_in_group('group1');
      my $pass = ! defined $users;
      $Test->ok( $pass, "group1 is empty" );
    };
  };
  
  do {
    $Test->ok( !defined(eval { $object->can_user_action_resource('grimlock', 'be', '/bigbozo') }), "grimlock is not big bozo" );
    $Test->diag($@) if $@;
    
    $Test->ok( eval { $object->grant('grimlock', 'be', '/bigbozo') } == 1, 'grant returns 1' );
    $Test->diag($@) if $@;
    $refresh->();
    
    $Test->ok( defined(eval { $object->can_user_action_resource('grimlock', 'be', '/bigbozo') }), "grimlock is a big bozo" );
    $Test->diag($@) if $@;
    
    $Test->ok( !defined(eval { $object->can_user_action_resource('primus', 'be', '/bigbozo') }), "primus is not a big bozo" );
    $Test->diag($@) if $@;
    
    my @actions = $object->actions;
    
    my $pass = $#actions == 0 && $actions[0] eq 'be';
    $Test->ok( $pass, "actions = be" );
    $Test->diag("actions is actually = ", join(', ', @actions))
      unless $pass;
  };

  do {
    
    $object->create_group( 'public', '*' );
    $refresh->();
    my @public = sort @{ $object->users_in_group('public') };
    
    # grimlock megatron optimus primus  
    
    my $pass = $#public == 3 
      && $public[0] eq 'grimlock'
      && $public[1] eq 'megatron'
      && $public[2] eq 'optimus'
      && $public[3] eq 'primus';
    $Test->ok($pass, "public = [ grimlock, megatron, optimus, primus ]");
    $Test->diag("actual public = [ ", join(', ', @public), " ]")
      unless $pass;
  };

  do {
  
    foreach my $username (qw( optimus primus megatron grimlock ))
    {
      $Test->ok( !defined(eval { $object->can_user_action_resource($username, 'dislike', '/gobots') }), "$username likes gobots");
      $Test->diag($@) if $@;
    }
    
    $Test->ok( eval { $object->grant('public', 'dislike', '/gobots') } == 1, 'grant returns 1' );
    $Test->diag($@) if $@;
    $refresh->();
    
    foreach my $username (qw( optimus primus megatron grimlock ))
    {
      $Test->ok( defined(eval { $object->can_user_action_resource($username, 'dislike', '/gobots') }), "$username dislikes gobots");
      $Test->diag($@) if $@;
    }
    
    my @actions = $object->actions;
    
    my $pass = $#actions == 1 && $actions[0] eq 'be' && $actions[1] eq 'dislike';
    $Test->ok( $pass, "actions = be, dislike" );
    $Test->diag("actions is actually = ", join(', ', @actions))
      unless $pass;
  
  };
  
  do {
    $object->create_group( 'group2', 'grimlock,primus' );
    $refresh->();
    my @group2 = sort @{ $object->users_in_group('group2') };
    
    my $pass = $#group2 == 1
      && $group2[0] eq 'grimlock'
      && $group2[1] eq 'primus';
    $Test->ok($pass, "group2 = [ grimlock, primus ]");
  };
  
  do {
  
    foreach my $username (qw( optimus primus megatron grimlock ))
    {
      $Test->ok( !defined(eval { $object->can_user_action_resource($username, 'have', '/bighead') }), "$username does not have a big head");
      $Test->diag($@) if $@;
    }
    
    $Test->ok( eval { $object->grant('group2', 'have', '/bighead') } == 1, 'grant returns 1' );
    $Test->diag($@) if $@;
    $refresh->();
    
    foreach my $username (qw( primus grimlock ))
    {
      $Test->ok( defined(eval { $object->can_user_action_resource($username, 'have', '/bighead') }), "$username does have a big head");
      $Test->diag($@) if $@;
    }
    
    foreach my $username (qw( megatron optimus ))
    {
      $Test->ok( !defined(eval { $object->can_user_action_resource($username, 'have', '/bighead') }), "$username does not have a big head");
      $Test->diag($@) if $@;
    }

    my @actions = $object->actions;
    
    my $pass = $#actions == 2 && $actions[0] eq 'be' && $actions[1] eq 'dislike' && $actions[2] eq 'have';
    $Test->ok( $pass, "actions = be, dislike, have" );
    $Test->diag("actions is actually = ", join(', ', @actions))
      unless $pass;
  };

  do {
  
    $Test->ok( eval { $object->revoke('group2', 'have', '/bighead') } == 1, 'revoke returns 1' );
    $Test->diag($@) if $@;
    $refresh->();
  
    foreach my $username (qw( optimus primus megatron grimlock ))
    {
      $Test->ok( !defined(eval { $object->can_user_action_resource($username, 'have', '/bighead') }), "$username does not have a big head");
      $Test->diag($@) if $@;
    }
    
    $Test->ok( eval { $object->revoke('public', 'dislike', '/gobots') } == 1, 'revoke returns 1' );
    $Test->diag($@) if $@;
    $refresh->();

    foreach my $username (qw( optimus primus megatron grimlock ))
    {
      $Test->ok( !defined(eval { $object->can_user_action_resource($username, 'dislike', '/gobots') }), "$username likes gobots");
      $Test->diag($@) if $@;
    }
    
    $Test->ok( eval { $object->revoke('grimlock', 'be', '/bigbozo') } == 1, 'revoke returns 1' );
    $Test->diag($@) if $@;
    $refresh->();

    $Test->ok( !defined(eval { $object->can_user_action_resource('grimlock', 'be', '/bigbozo') }), "grimlock is not big bozo" );
    $Test->diag($@) if $@;

  };

  # These two do not have a write RESTful API yet and cannot be
  # tested.
  # TODO: match_resources
  # TODO: host_has_tag
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PlugAuth::Plugin::Authz - Test a PlugAuth Authz plugin for correctness

=head1 VERSION

version 0.39

=head1 SYNOPSIS

 use Test::PlugAuth::Plugin::Authz;
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
