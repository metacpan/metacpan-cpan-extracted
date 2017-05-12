#!/usr/bin/env perl
# Write a plugin
package Mojolicious::Plugin::MyPlugin;
use Mojo::Base 'Mojolicious::Plugin';

# Register plugin
sub register {
  my ($self, $app, $param) = @_;

  # Establish Util::Callback plugin
  $app->plugin('Util::Callback');

  # Accept callbacks defined by parameter
  $app->callback(
    [qw/title_cb/] => $param
  );

  # Callbacks are deleted from param,
  # everything else stays intact
  my $tag = $param->{tag};

  # Establish a helper
  $app->helper(
    make_title => sub {
      my $c = shift;

      # Use the default tag helper
      return $c->tag(

        # Release title_cb callback
        $tag => $c->callback(title_cb => @_)
      );
    }
  );
};

# Mojolicious::Lite Plugin
package myapp;
use Mojolicious::Lite;

use lib '../lib';

# Establish plugin
plugin MyPlugin => {

  # Define the callback by parameter
  title_cb => sub {
    my $c = shift;
    my $title = shift;

    # Do something with the title
    return join ' ', map { ucfirst } split(/\s+/, $title);
  },
  tag => 'h1'
};

# Now you can use the helper in your Controller or Template
get '/' => sub {
  return shift->render(inline => '<%= make_title "this is a title" %>');
  # First:  <h1>This Is A Title</h1>
  # Second: <h1>This is a Title</h1>

};

# Now you can use the helper in your Controller or Template
get '/Change' => sub {
  my $c = shift;

  # And you can change the callback globally
  $c->callback(title_cb => sub {
    my $c = shift;
    my $title = shift;
    my @array = split(/\s+/, $title);
    foreach (@array) {
      unless ($_ eq 'a' || $_ eq 'is') {
        $_ = ucfirst $_;
      };
    };
    return join ' ', @array;
  });

  return $c->render(text => "Changed make_title helper\n");
};

package main;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('myapp');

$t->get_ok('/')->status_is(200)->content_is("<h1>This Is A Title</h1>\n");
$t->get_ok('/Change')->status_is(200)->content_is("Changed make_title helper\n");
$t->get_ok('/')->status_is(200)->content_is("<h1>This is a Title</h1>\n");

done_testing;
