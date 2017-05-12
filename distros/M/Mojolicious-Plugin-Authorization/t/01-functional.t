#!/usr/bin/env perl
use strict;
use warnings;
# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }
use Test::More;
plan tests => 57;
# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;
my %roles = (role1=>{priv1=>1},
             role2=>{priv1=>1,priv2=>1});
plugin 'authorization', {
 has_priv => sub {
     my $self = shift;
     my ($priv, $extradata) = @_;
     return 0
      unless($self->session('role'));
     my $role  = $self->session('role');
     my $privs = $roles{$role};
     return 1
       if exists($privs->{$priv});
     return 0;
  },
  is_role => sub {
    my $self = shift;
    my ($role, $extradata) = @_;
    return 0
       unless($self->session('role'));
    return 1
       if ($self->session('role') eq $role);
    return 0;
  },
  user_privs => sub {
    my $self = shift;
    my ($extradata) = @_;
    return []
       unless($self->session('role'));
    my $role  = $self->session('role');
    my $privs = $roles{$role};
    return sort keys(%{$privs});
  },
  user_role => sub {
    my $self = shift;
    my ($extradata) = @_;
    return $self->session('role');
   },
};
get '/' => sub {
    my $self = shift;
    $self->session('role'=>'role1');
    $self->render(text => 'index page');
};
get '/priv1' => sub {
    my $self = shift;
    $self->render(text=> $self->has_priv('priv1') ? 'Priv 1' : 'fail');
};
get '/priv2' => sub {
    my $self = shift;
    $self->render(text=> $self->has_priv('priv2') ? 'Priv 2' : 'fail');
};
get '/priv3' => (has_priv => 'priv1') => sub {
    my $self = shift;
    $self->render(text=> 'Priv 1 (condition)');
};
get '/role1' => sub {
    my $self = shift;
    $self->render(text=> $self->is('role2') ? 'Role 1' : 'fail');
};
get '/role2' => sub {
    my $self = shift;
    $self->render(text=> $self->is_role('role2') ? 'Role 2' : 'fail');
};
get '/privilege1' => sub {
    my $self = shift;
    $self->render(text=> $self->has_privilege('priv1') ? 'Priv 1' : 'fail');
};
get '/privilege2' => sub {
    my $self = shift;
    $self->render(text=> $self->has_privilege('priv2') ? 'Priv 2' : 'fail');
};
get '/role1condition' => (is => 'role2') => sub {
    my $self = shift;
    $self->render(text=> 'Role 1 (condition)');
};
get '/role2condition' => (is_role => 'role2') => sub {
    my $self = shift;
    $self->render(text=> 'Role 2 (condition)');
};
get '/change/:role' => sub {
    my $self = shift;
    my $role =  $self->param('role');
    $self->session('role'=>$role);
    my $new_role = $self->role;
    $self->render(text=>$new_role);
};
get '/myrole' => sub {
    my $self = shift;
    my $new_role = $self->role;
    $self->render(text=>$new_role);
};
get '/myprivs' =>  sub {
    my $self = shift;
    my @privs = $self->privileges();
    my $priv = join(':', sort @privs);
    $self->render(text=>$priv);
};
my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('index page');
$t->get_ok('/priv1')->status_is(200)->content_is('Priv 1');
$t->get_ok('/priv2')->status_is(200)->content_is('fail');
$t->get_ok('/priv3')->status_is(200)->content_is('Priv 1 (condition)');
$t->get_ok('/privilege1')->status_is(200)->content_is('Priv 1');
$t->get_ok('/privilege2')->status_is(200)->content_is('fail');
$t->get_ok('/myrole')->status_is(200)->content_is('role1');
$t->get_ok('/myprivs')->status_is(200)->content_is('priv1');
$t->get_ok('/change/role2')->status_is(200)->content_is('role2');
$t->get_ok('/priv1')->status_is(200)->content_is('Priv 1');
$t->get_ok('/priv2')->status_is(200)->content_is('Priv 2');
$t->get_ok('/privilege1')->status_is(200)->content_is('Priv 1');
$t->get_ok('/privilege2')->status_is(200)->content_is('Priv 2');
$t->get_ok('/myrole')->status_is(200)->content_is('role2');
$t->get_ok('/myprivs')->status_is(200)->content_is('priv1:priv2');
$t->get_ok('/role1')->status_is(200)->content_is('Role 1');
$t->get_ok('/role2')->status_is(200)->content_is('Role 2');
$t->get_ok('/role1condition')->status_is(200)->content_is('Role 1 (condition)');
$t->get_ok('/role2condition')->status_is(200)->content_is('Role 2 (condition)');
