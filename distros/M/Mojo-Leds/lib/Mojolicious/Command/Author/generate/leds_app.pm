package Mojolicious::Command::Author::generate::leds_app;
$Mojolicious::Command::Author::generate::leds_app::VERSION = '1.06';
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path decamelize);
use Mojo::File;

has description => 'Generate Mojo::Leds application directory structure';
has usage       => sub { shift->extract_usage };

sub run {
    my ( $self, $class ) = ( shift, shift || 'MyApp' );

    # Script
    my $name = class_to_file $class;
    $self->render_to_rel_file( 'mojo', "$name/script/$name",
        { class => $class } );
    $self->chmod_rel_file( "$name/script/$name", 0744 );

    # Application class
    my $app = class_to_path $class;
    $self->render_to_rel_file( 'appclass', "$name/lib/$app",
        { class => $class } );

    # Config file (using the default moniker)
    $self->render_to_rel_file( 'config', "$name/cfg/app.cfg" );

    # Default Template
    $self->render_to_rel_file( 'layout', "$name/www/layouts/default.html.ep" );

    # Welcome Controller
    my $controller = "welcome::index";
    my $path       = class_to_path $controller;
    $self->render_to_rel_file( 'controller', "$name/www/$path",
        { class => $controller } );

    # Welcome Template
    my $dir = Mojo::File->new($path)->dirname;
    $self->render_to_rel_file( 'welcome', "$name/www/$dir/index.html.ep" );

    # Welcome CSS
    $self->render_to_rel_file( 'welcomecss', "$name/www/$dir/index.css" );

    # Static file
    $self->render_to_rel_file( 'static', "$name/public/index.html" );

    # Test
    $self->render_to_rel_file( 'test', "$name/t/basic.t", { class => $class } );

}

1;

# ABSTRACT: Mojo::Leds app generator command

=pod

=head1 NAME

Mojolicious::Command::Author::generate::leds_app - Mojo::Leds app generator command

=head1 VERSION

version 1.06

=head1 SYNOPSIS

  Usage: APPLICATION generate leds_app [OPTIONS] [NAME]

    mojo generate leds_app
    mojo generate leds_app TestApp
    mojo generate leds_app My::TestApp

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::Author::generate::leds_app> generates application directory structures for fully functional
L<Mojo::Leds> applications.

This is a core command, that means it is always enabled and its code a good example for learning to build new commands,
you're welcome to fork it.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are available by default.

=encoding UTF-8

=head1 ATTRIBUTES

L<Mojolicious::Command::Author::generate::leds_app> inherits all attributes from L<Mojolicious::Command> and implements the
following new ones.

=head2 description

  my $description = $app->description;
  $app            = $app->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $app->usage;
  $app      = $app->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::Author::generate::leds_app> inherits all methods from L<Mojolicious::Command> and implements the
following new ones.

=head2 run

  $app->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ mojo
#!/usr/bin/env perl
use v5.12; # strict & say
use FindBin;
use lib ("$FindBin::Bin/../www", "$FindBin::Bin/../lib");
use Mojolicious::Commands;
Mojolicious::Commands->start_app(Mojo::Util::camelize($FindBin::Script=~s/.pl//r));

@@ appclass
package <%= $class %>;

use Mojo::Base 'Mojo::Leds';

sub startup {
	my $s	= shift;
    $s->SUPER::startup(@_);

    my $app = $s->app;
    my $r	= $s->routes;

	$r->any('/')->to(cb => sub {shift->redirect_to('/welcome/index')});

	$s->plugin('AutoRoutePm' => {
		route 			=> [ $r ],
		exclude 		=> ['rest/']
	});

}

1;
@@ controller
package <%= $class %>;
use Mojo::Base 'Mojo::Leds::Page';

sub render_html {
    my $c = shift;

    $c->stash(msg => 'Welcome to Mojo::Leds framework based on Mojolicious!' );
    $c->SUPER::render_html;
}

sub render_json {
    my $c = shift;
}

1;

@@ static
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to Mojo::Leds framework based on Mojolicious!</title>
  </head>
  <body>
    <h2>Welcome to Mojo::Leds framework based on Mojolicious!</h2>
    This is the static document "public/index.html",
    <a href="/">click here</a> to get back to the start.
  </body>
</html>

@@ test
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('<%= $class %>');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();

@@ layout
<!DOCTYPE html>
<html>
  <head>
      <title><%%= $title %></title>
      <%%= content 'header' %>
  </head>
  <body><%%= content %></body>
</html>

@@ welcome
%% layout 'default', title  => 'Welcome';
%% content_for header => begin
    <link rel="stylesheet" href="index.css">
%% end
<h2><%%= $msg %></h2>
<p>
  This page was generated from the template "/welcome/index.html.ep"
  and the layout "/layouts/default.html.ep",
  <ul>
  <li><%%= link_to 'click here' => url_for %> to reload the page or </li>
  <li><%%= link_to here => 'index.css' %> to see the css </li>
  <li><%%= link_to 'here' => '/index.html' %> to move forward to a static page. </li>
  </ul>
</p>

@@welcomecss
body {
    font-family: sans-serif;
}


@@ config
% use Mojo::Util qw(sha1_sum steady_time);
{
    docs_root => 'www',
    secret    => ['<%= sha1_sum $$ . steady_time . rand  %>'],
    session   => {
        name               => app->moniker . '.sessions',
        default_expiration => 28800
    },
    log => {
        path  => app->home->rel_file('/log/app.log'),
        level => 'warn',
    },
    hypnotoad => {
        listen   => ['http://*:9091'],
        workers  => 5,
        pid_file => '/var/run/' . app->moniker . '.pid',
        proxy    => 1,
    },
    plugins => [
        { RenderFile              => {} },
        { AccessLog               => {} },
        { LinkedContent           => {} },
        { 'Restify::OtherActions' => {} },
        { AutoReload              => {} },
    ],
}
