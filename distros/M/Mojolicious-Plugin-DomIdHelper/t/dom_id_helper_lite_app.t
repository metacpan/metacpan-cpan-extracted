package DB::Package::User;

sub new 
{  
    my $class = shift;
    bless { 
	id   => shift,
	name => shift
    }, $class; 
} 

sub id   { (shift)->{id} }
sub name { (shift)->{name} }

# Multi column PK
sub primary_key
{ 
    my $self = shift;
    return ($self->id, $self->name);
}

package main;

use Mojolicious::Lite;
use Test::More tests => 9;
use Test::Mojo;

my $user = DB::Package::User->new(1,'sshaw');

get '/plugin_defaults' => sub {
    plugin 'dom_id_helper'; 

    my $self = shift;
    $self->render('plugin_defaults', user => $user);
};

get '/plugin_overrides' => sub {
   plugin 'dom_id_helper', keep_namespace => 1, delimiter => '-', method => 'primary_key';
   
   my $self = shift;
   $self->render('plugin_overrides', user => $user);
};

get '/collection' => sub {
   plugin 'dom_id_helper';
   
   my $self = shift;
   $self->render('collection', user => $user);
};

my $t = Test::Mojo->new;
$t->get_ok('/plugin_defaults')->status_is(200)->content_is(<<END_HTML);
<div id="user_1" class="user"></div>
<div id="array" class="array"></div>
<div id="user*1"></div>
<div id="user_sshaw"></div>
<div id="db-package-user-1sshaw" class="db-package-user"></div>
END_HTML

$t->get_ok('/plugin_overrides')->status_is(200)->content_is(<<END_HTML);
<div id="db-package-user-1sshaw" class="db-package-user"></div>
END_HTML

SKIP: {
   skip "Lingua::EN::Inflect not installed", 3 unless eval "require Lingua::EN::Inflec; 1";
   $t->get_ok('/collection')->status_is(200)->content_is(<<END_HTML);
<div id="users" class="users"></div>
<div id="db_package_users" class="db_package_users"></div>
END_HTML
}

__DATA__
@@ plugin_defaults.html.ep
<div id="<%= dom_id($user) %>" class="<%= dom_class($user) %>"></div>
<div id="<%= dom_id([]) %>" class="<%= dom_class([]) %>"></div>
<div id="<%= dom_id($user, delimiter => '*') %>"></div>
<div id="<%= dom_id($user, method => 'name') %>"></div>
<div id="<%= dom_id($user, method => [qw{id name}], delimiter => '-', keep_namespace => 1) %>" class="<%= dom_class($user, delimiter => '-', keep_namespace => 1) %>"></div>

@@ plugin_overrides.html.ep
<div id="<%= dom_id($user) %>" class="<%= dom_class($user) %>"></div>

@@ collection.html.ep
<div id="<%= dom_id([$user]) %>" class="<%= dom_class([$user]) %>"></div>
<div id="<%= dom_id([$user], keep_namespace => 1) %>" class="<%= dom_class([$user], keep_namespace => 1) %>"></div>
