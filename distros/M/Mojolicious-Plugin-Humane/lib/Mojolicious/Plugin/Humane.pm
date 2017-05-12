package Mojolicious::Plugin::Humane;
use Mojo::Base 'Mojolicious::Plugin';

use File::Spec;
use File::Basename ();
use File::ShareDir ();

our $VERSION = '0.07';
$VERSION = eval $VERSION;

has 'humane_version' => '3.2.0';

has 'static_path' => sub {
  my $self = shift;
  $self->path('humane-' . $self->humane_version);
};

has 'template' => 'humane_template';

has 'theme' => 'libnotify';

sub path {
  my $self   = shift;
  my $folder = shift;

  my $local = File::Spec->catdir( File::Basename::dirname(__FILE__), 'Humane', 'files', $folder );
  return $local if -d $local;

  my $share = File::Spec->catdir( File::ShareDir::dist_dir('Mojolicious-Plugin-Humane'), $folder );
  return $share if -d $share;

  die "Cannot find files. Tried '$local' and '$share'.\n";
}

sub register {
  my ($plugin, $app) = (shift, shift);
  my %conf = ref $_[0] ? %{ shift() } : @_;

  $conf{auto} //= 1;      #/# highlight fix

  # Append static to directories
  push @{$app->static->paths}, $plugin->static_path;
  push @{$app->renderer->classes}, __PACKAGE__;

  $app->helper( humane => sub { $plugin } );

  $app->helper( humane_stash => sub {
    my $self  = shift;
    my $key   = 'humane.stash';
    my $stash = $self->stash($key) || [];

    if ( @_ ) {
      push @$stash, @_;
      $self->stash( $key => $stash );
    }

    return $stash;
  });

  $app->helper( humane_flash => sub {
    my $self  = shift;
    my $key   = 'humane.flash';
    my $flash = $self->flash($key) || [];

    if ( @_ ) {
      push @$flash, @_;
      $self->flash( $key => $flash );
    }

    return $flash;
  });

  $app->helper( humane_include => sub {
    my $self = shift;
    $self->include( #TODO use render_to_string once Mojo 5.00 is required 
      template => $self->humane->template,
    );
  });

  $app->helper( humane_messages => sub {
    my $self = shift;
    my @messages = (
      @{ $self->humane_flash },
      @{ $self->humane_stash },
    );
    return @messages;
  });

  $app->hook( after_dispatch => sub { 
    my $c = shift;
    my @messages = $c->humane_messages;
    return unless @messages;

    my $dom  = $c->res->dom;
    my $head = $dom->at('head') or return;

    my $append = $c->humane_include;
    $head->append_content( $append );
    $c->tx->res->body( $dom->to_string );
  } ) if $conf{auto};

  return $plugin;
}

sub all_themes {
  my $self = shift;
  my $path = $self->static_path;
  opendir my $dh, $path or die "Cannot open $path\n";
  return map { s/\.css$// ? $_ : () } readdir $dh;
}

1;

__DATA__

@@ humane_template.html.ep

% my $theme = humane->theme;
%= javascript '/humane.min.js'
%= stylesheet "/$theme.css"
%= javascript begin
  humane.baseCls = 'humane-<%= $theme %>';
  % foreach my $message ( humane_messages ) {
    humane.log( "<%= $message %>" );
  % }
%= end


__END__

=head1 NAME

Mojolicious::Plugin::Humane - Mojolicious integration for humane.js

=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('Humane');
  # then elsewhere
  $c->humane_flash('Not authorized');

  # Mojolicious::Lite
  plugin 'Humane';
  get '/' => sub {
    my $c = shift;
    $c->humane_stash('Welcome back!');
  ...

  # Without 'auto' feature
  plugin 'Humane', auto => 0;
  ...
  __DATA__
  ...
  %= humane_include

=head1 DESCRIPTION

L<Mojolicious::Plugin::Humane> is a L<Mojolicious> plugin allowing easy use of humane.js, a browser notification handler (L<http://wavded.github.com/humane-js/>).

By default the template needed to render the messages is injected only if needed. For infrequent use, this is less costly overall and less to think about. If messages are to be used frequently or perhaps humane.js is to also be used without reloading the page (via websockets perhaps) then turn the C<auto> feature off and add the template to your layout manually.

Internally this plugin uses the (non-localized) stash keys C<humane.stash> and C<humane.flash>. Other stash keys starting with C<humane.> are reserved for future use should be avoided.

=head1 ATTRIBUTES

=head2 humane_version 

Version of humane.js (to be) loaded. Defaults to the highest bundled version. Currently version 3.2.0 is bundled.

In future, non-breaking releases will be silently upgraded, while breaking versions will be kept and left at the highest version that had been bundled.

=head2 static_path

The path to the folder containing the bundled version of humane to be used. This path is added to the static rendering path.
The default is C<< $plugin->path('humane-' . $self->humane_version); >>.

=head2 template 

The name of the template to be used. This allows the user to supply their own template name if desired.

=head2 theme

Selects the humane.js theme. This should be chosen from the available themes (see L</all_themes>). The default is C<libnotify>.

=head1 METHODS

L<Mojolicious::Plugin::Humane> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<all_themes>

  $plugin->all_themes();

Get a list of all the available themes for humane.js.

=head2 C<path>

  $plugin->path($directory);

Find the path to a directory relative to the shared data directory. This isn't likely to be needed.

=head2 C<register>

  $plugin->register($app);

Register plugin in L<Mojolicious> application. Optionally key-value pairs or a hashreference of the same may be passed. Those options are:

=over

=item auto

Set to a true value, the template necessary for humane.js will be automatically added to the C<< <head> >> tag of the rendered document if needed. Note that this will be skipped if no C<< <head> >> tag is found or if no messages are waiting to be added. Default is true.

=back

=head1 HELPERS

This plugin provides several helpers which are available as methods to the application and controllers and as functions to the templates (and lite apps).

=head2 C<humane>

  $app->humane->theme($newtheme);

Holds the instance of the plugin.

=head2 C<humane_stash>/C<humane_flash>

  $app->humane_stash('Welcome back');
  $app->humane_flash('Not authorized');

Take a message or list of messages and adds them to the stack of messages to be rendered during the current or next rendering respectively. Returns an array reference of all the buffered messages in that stack. May be called without argument to get the stack while not adding messages. 

Note that each stack is rendered first-in first-out, however all flashed messages are shown before stashed messages.

=head2 C<humane_include>

Behaves like C<include> inserting the template needed to render the messages. You need to use this when setting C<< auto => 0 >>.

=head2 C<humane_messages>

Returns a list of all the messages to be rendered in this rendering, in order; flashed messages first, then stashed.

=head1 SEE ALSO

L<Mojolicious>, L<http://wavded.github.com/humane-js/>

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-Humane>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Mojolicious::Plugin::Humane is

Copyright (C) 2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

humane.js bears the license

(The MIT License)

Copyright (c) 2011 Marc Harter <wavded@gmail.com>

See L<http://wavded.github.com/humane-js/> for terms of use.

=cut
