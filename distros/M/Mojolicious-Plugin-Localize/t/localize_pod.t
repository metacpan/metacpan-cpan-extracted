#!usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;

my $t = Test::Mojo->new;
my $app = $t->app;

# Register the plugin with a defined dictionary
plugin  Localize => {
  dict => {
    _  => sub { $_->locale },
    de => {
      welcome => "Willkommen in <%=loc 'App_name_land' %>!",
      bye => 'Auf Wiedersehen!'
    },
    -en => {
      welcome => "Welcome to <%=loc 'App_name_land' %>!",
      bye => 'Good bye!'
    },
    App => {
      name => {
        -long => 'Mojolicious',
        short => 'Mojo',
        land  => 'MojoLand'
      }
    }
  }
};

# Call dictionary entries from templates
is(app->loc('welcome'), 'Welcome to MojoLand!', 'Welcome');

done_testing;
