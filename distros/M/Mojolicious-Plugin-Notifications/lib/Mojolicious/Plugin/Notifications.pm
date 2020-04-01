package Mojolicious::Plugin::Notifications;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Collection qw/c/;
use Mojolicious::Plugin::Notifications::Assets;
use Mojo::Util qw/camelize/;
use Scalar::Util qw/blessed/;

our $TYPE_RE = qr/^[-a-zA-Z_]+$/;

our $VERSION = '1.05';

# TODO:
#   Maybe revert to tx-handler and use session instead of flash!
# TODO:
#   Support Multiple Times Loading
# TODO:
#   Subroutines for Engines should be given directly
# TODO:
#   Engines may use hooks in addition

# Register plugin
sub register {
  my ($plugin, $app, $param) = @_;

  $param ||= {};

  my $debug = $app->mode eq 'development' ? 1 : 0;

  # Load parameter from Config file
  if (my $config_param = $app->config('Notifications')) {
    $param = { %$param, %$config_param };
  };

  $param->{HTML} = 1 unless keys %$param;

  # Add engines from configuration
  my %engine;
  foreach my $name (keys %$param) {
    my $engine = camelize $name;
    if (index($engine,'::') < 0) {
      $engine = __PACKAGE__ . '::' . $engine;
    };

    # Load engine
    my $e = $app->plugins->load_plugin($engine);
    $e->register($app, ref $param->{$name} ? $param->{$name} : undef);
    $engine{lc $name} = $e;
  };

  # Create asset object
  my $asset = Mojolicious::Plugin::Notifications::Assets->new;

  # Set assets
  foreach (values %engine) {
    $asset->styles($_->styles)   if $_->can('styles');
    $asset->scripts($_->scripts) if $_->can('scripts');
  };


  # Add notifications
  $app->helper(
    notify => sub {
      my $c = shift;
      my $type = shift;
      my @msg = @_;

      # Ignore debug messages in production
      return if $type !~ $TYPE_RE || (!$debug && $type eq 'debug');

      my $notes;

      # Notifications already set
      if ($notes = $c->stash('notify.array')) {
        push @$notes, [$type => @msg];
      }

      # New notifications as a Mojo::Collection
      else {
        $c->stash('notify.array' => c([$type => @msg]));
      };
    }
  );


  # Embed notification display
  $app->helper(
    notifications => sub {
      my $c = shift;

      return $asset unless @_;

      my $e_type = lc shift;
      my @param = @_;

      # Get stash notifications
      my $notes = ($c->stash->{'notify.array'} //= c());

      # Get flash notifications
      my $flash = $c->flash('n!.a');

      if ($flash && ref $flash eq 'ARRAY') {

        # Ensure that no harmful types are injected
        unshift @$notes, grep { $_->[0] =~ $TYPE_RE } @$flash;
      };

      # Emit hook for further flexibility
      $app->plugins->emit_hook(
        before_notifications => $c, $notes
      );

      # Delete from stash
      delete $c->stash->{'notify.array'};

      # Nothing to do
      return '' unless $notes->size || @_;

      # Forward messages to notification center
      if (exists $engine{$e_type}) {

        my %rule;
        while ($param[-1] && index($param[-1], '-') == 0) {
          $rule{lc(substr(pop @param, 1))} = 1;
        };

        return $engine{$e_type}->notifications($c, $notes, \%rule, @param);
      }
      else {
        $c->app->log->error(qq{Unknown notification engine "$e_type"});
        return;
      };
    }
  );


  # Add hook for redirects
  $app->hook(
    after_dispatch => sub {
      my $c = shift;

      if ($c->res->is_redirect) {
        # Get notify array from stash
        my $notes = delete $c->stash->{'notify.array'};

        # Check flash notes
        if ($c->flash('n!.a')) {

          # Merge notes with flash
          if ($notes) {
            unshift @$notes, @{$c->flash('n!.a')};
          }

          # Get notes from flash
          else {
            $notes = $c->flash('n!.a');
          };
        };

        if ($notes) {
          $c->flash('n!.a' => $notes);
        };
      };
    });
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Notifications - Frontend Event Notifications


=head1 SYNOPSIS

  # Register the plugin and several engines
  plugin Notifications => {
    Humane => {
      base_class => 'libnotify'
    },
    JSON => 1
  };

  # Add notification messages in controllers
  $c->notify(warn => 'Something went wrong');

  # Render notifications in templates ...
  %= notifications 'humane';

  # ... or in any other responses
  my $json = { text => 'That\'s my response' };
  $c->render(json => $c->notifications(json => $json));


=head1 DESCRIPTION

L<Mojolicious::Plugin::Notifications> supports several engines
to notify users on events. Notifications will survive multiple
redirects and can be served depending on response types.


=head1 METHODS

L<Mojolicious::Plugin::Notifications> inherits all methods
from L<Mojolicious::Plugin> and implements the following new one.

=head2 register

  plugin Notifications => {
    Humane => {
      base_class => 'libnotify'
    },
    HTML => 1
  };

Called when registering the plugin.

Accepts the registration of multiple L<engines|/ENGINES> for notification
responses. Configurations of the engines can be passed as hash
references. If no configuration should be passed, just pass a scalar value.

All parameters can be set either as part of the configuration
file with the key C<Notifications> or on registration
(that can be overwritten by configuration).


=head1 HELPERS

=head2 notify

  $c->notify(error => 'Something went wrong');
  $c->notify(error => { timeout => 4000 } => 'Something went wrong');

Notify the user about an event.
Expects an event type and a message as strings.
In case a notification engine supports further refinements,
these can be passed in a hash reference as a second parameter.
Event types are free and its treatment is up to the engines,
however notifications of the type C<debug> will only be passed in
development mode.


=head2 notifications

  %= notifications 'humane' => [qw/warn error success/];
  %= notifications 'html';

  $c->render(json => $c->notifications(json => {
    text => 'My message'
  }));

Serve notifications to your user based on an engine.
The engine's name has to be passed as the first parameter
and the engine has to be L<registered|/register> in advance.
Notifications won't be invoked in case no notifications are
in the queue and no further engine parameters are passed.
Engine parameters are documented in the respective plugins.

The engine's name will be camelized. If no namespace is given,
the default namespace is C<Mojolicious::Plugin::Notifications>.

In case no engine name is passed to the notifications method,
an L<assets object|Mojolicious::Plugin::Notifications::Assets>
is returned, bundling all registered engines' assets for use
in the L<AssetPack|Mojolicious::Plugin::AssetPack> pipeline.

  # Register Notifications plugin
  app->plugin('Notifications' => {
    Humane => {
      base_class => 'libnotify'
    },
    Alertify => 1
  });

  # Register AssetPack plugin
  app->plugin('AssetPack');

  # Add notification assets to pipeline
  app->asset('myApp.js'  => 'myscripts.coffee', app->notifications->scripts);
  app->asset('myApp.css' => 'mystyles.scss', app->notifications->styles);

  %# In templates embed assets ...
  %= asset 'myApp.js'
  %= asset 'myApp.css'

  %# ... and notifications (without assets)
  %= notifications 'humane', -no_include;

B<The asset helper option is experimental and may change without warnings!>


=head1 ENGINES

L<Mojolicious::Plugin::Notifications> bundles a couple of different
notification engines, but you can
L<easily write your own engine|Mojolicious::Plugin::Notifications::Engine>.


=head2 Bundled engines

The following engines are bundled with this plugin:
L<HTML|Mojolicious::Plugin::Notifications::HTML>,
L<JSON|Mojolicious::Plugin::Notifications::JSON>,
L<Humane.js|Mojolicious::Plugin::Notifications::Humane>, and
L<Alertify.js|Mojolicious::Plugin::Notifications::Alertify>,


=head1 HOOKS

  app->hook(
    before_notifications => sub {
      my ($c, $notes) = @_;
      $c->app->log('Served ' . $notes->size . ' notifications to ' . $c->stash('user'));
    });

This hook is emitted before any notifications are rendered.
The hook passes the current controller object and a L<Mojo::Collection>
object including all notes.
The hook is emitted no matter if notifications are pending.

B<This hook is EXPERIMENTAL!>


=head1 SEE ALSO

If you want to use C<Humane.js> without L<Mojolicious::Plugin::Notifications>,
you should have a look at L<Mojolicious::Plugin::Humane>,
which was the original inspiration for this plugin.

Without my knowledge (due to a lack of research by myself),
L<Mojolicious::Plugin::BootstrapAlerts> already established
a similar mechanism for notifications using Twitter Bootstrap
(not yet supported by this module).
Accidentally the helper names collide - I'm sorry for that!
On the other hands, that makes these modules in most occasions
compatible.


=head1 HINTS

As flash information is stored in the session, notifications may be lost
in case the session expires using C<session(expires =E<gt> 1)>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Notifications


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2020, L<Nils Diewald|https://nils-diewald.de/>.

Part of the code was written at the
L<Mojoconf 2014|http://www.mojoconf.org/mojo2014/> hackathon.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
