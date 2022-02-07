package Telebot::Command::bot::generate;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path decamelize);

has description => 'Generate Telebot application directory structure';
has usage       => sub { shift->extract_usage };

sub run {
    my ($self, $class) = (shift, shift || 'MyBot');

    # Script
    my $name = class_to_file $class;
    $self->render_to_rel_file('mojo', "$name/script/$name", {class => $class});
    $self->chmod_rel_file("$name/script/$name", 0744);

    # Application class
    my $app = class_to_path $class;
    $self->render_to_rel_file('appclass', "$name/lib/$app", {class => $class});

    # Config file (using the default moniker)
    $self->render_to_rel_file('config', "$name/telebot.conf");

    # Controller
    my $controller = "${class}::Controller::Site";
    my $path       = class_to_path $controller;
    $self->render_to_rel_file('controller', "$name/lib/$path", {class => $controller});

    # Test
    $self->render_to_rel_file('test', "$name/t/basic.t", {class => $class});

    # Static file
    $self->render_to_rel_file('static', "$name/public/index.html");

    # Templates
    $self->render_to_rel_file('layout',  "$name/templates/layouts/default.html.ep");
    $self->render_to_rel_file('site_index', "$name/templates/site/index.html.ep");
    
    # Handlers
    for my $type (qw(
        Update
        CallbackQuery
        ChannelPost
        ChatJoinRequest
        ChatMember
        ChosenInlineResult
        EditedChannelPost
        EditedMessage
        InlineQuery
        Message
        MyChatMember
        Poll
        PollAnswer
        PreCheckoutQuery
        ShippingQuery
    )) {
        my $handler = "${class}::Handler::${type}";
        my $path       = class_to_path $handler;
        $self->render_to_rel_file('handler', "$name/lib/$path", {class => $handler});
    }
}

1;

=encoding utf8

=head1 NAME

Telebot::Command::bot::generate - Bot generator command

=head1 SYNOPSIS

    Usage: APPLICATION bot generate [OPTIONS] [NAME]

        telebot bot generate
        telebot bot generate TestBot
        telebot bot generate My::TestBot

    Options:
        -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Telebot::Command::bot::generate> generates application directory structures for fully functional
L<Telebot> applications.

This is a core command, that means it is always enabled and its code a good example for learning to build new commands,
you're welcome to fork it.

=head1 ATTRIBUTES

L<Telebot::Command::bot::generate> inherits all attributes from L<Mojolicious::Command> and implements the
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

L<Telebot::Command::generate> inherits all methods from L<Mojolicious::Command> and implements the
following new ones.

=head2 run

    $app->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

__DATA__

@@ mojo
#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;
use Mojolicious::Commands;

# Start command line interface for application
Mojolicious::Commands->start_app('<%= $class %>');

@@ appclass
package <%= $class %>;
use Mojo::Base 'Telebot', -signatures;

# startup is already defined but some code can be invoked in it

sub pre_startup ($self) {
    # Code must be executed in the begining of startup
}

sub post_startup ($self) {
    # Code must be executed at the end of startup
}

1;

@@ controller
package <%= $class %>;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# This action will render a template
sub index ($self) {
  # Render template "site/index.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework! This is Telebot application for managing telegram bot');
}

1;

@@ static
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to the Telebot Mojolicious application!</title>
  </head>
  <body>
    <h2>Welcome to the Mojolicious real-time web framework!</h2>
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
  <head><title><%%= title %></title></head>
  <body><%%= content %></body>
</html>

@@ site_index
%% layout 'default';
%% title 'Welcome';
<h2><%%= $msg %></h2>
<p>
  This page was generated from the template "templates/site/index.html.ep"
  and the layout "templates/layouts/default.html.ep",
  <%%= link_to 'click here' => url_for %> to reload the page or
  <%%= link_to 'here' => '/index.html' %> to move forward to a static page.
</p>

@@ config
% use Mojo::Util qw(sha1_sum steady_time);
{
    hypnotoad => {
        listen  => ['http://*:5555'],
        workers => 3,
    },
    secrets => ['<%= sha1_sum $$ . steady_time . rand  %>'],
    connection => 'postgresql://telebot:password@localhost/telebot',
    mode => 'development',
    #mode => 'production',
    log_level => 'debug',
    # 8443 can be configured in NGINX with proxing to application 5555 port
    self_url => 'https://yourdomain.com:8443',
    telegram => {
        # Bot token - use @BotFather to get it
        token => '123456:token_from_botfather',
        # which updates will be processed by bot app
        allowed_updates => [qw(
            message edited_message
            channel_post edited_channel_post
            inline_query chosen_inline_result
            callback_query shipping_query pre_checkout_query
            poll poll_answer
            my_chat_member chat_member chat_join_request
        )],
    }
}

@@ handler
package <%= $class %>;
use Mojo::Base 'Telebot::Handler', -signatures;

sub run ($self) {
    # Magic here
    
    $self;
}

1;
