package Mojolicious::Plugin::Notifications::Alertify;
use Mojo::Base 'Mojolicious::Plugin::Notifications::Engine';
use Mojolicious::Plugin::Notifications::HTML qw/notify_html/;
use Exporter 'import';
use Mojo::ByteStream 'b';
use Mojo::Util qw/xml_escape quote/;
use Mojo::JSON qw/decode_json encode_json/;
use Scalar::Util qw/blessed/;
use File::Spec;
use File::Basename;

our @EXPORT_OK = ('notify_alertify');

has [qw/base_class base_timeout/];
state $path = '/alertify/';

use constant DEFAULT_TIMEOUT => 5000;

# Register plugin
sub register {
  my ($plugin, $app, $param) = @_;

  # Set config
  $plugin->base_class(   $param->{base_class}   // 'default' );
  $plugin->base_timeout( $param->{base_timeout} // DEFAULT_TIMEOUT );

  $plugin->scripts($path . 'alertify.min.js');
  $plugin->styles(
    $path . 'alertify.core.css',
    $path . 'alertify.' . $plugin->base_class . '.css'
  );

  # Add static path to JavaScript
  push @{$app->static->paths},
    File::Spec->catdir( File::Basename::dirname(__FILE__), 'Alertify' );
};


# Exportable function
sub notify_alertify {
  my $c = shift if blessed $_[0] && $_[0]->isa('Mojolicious::Controller');
  my $type = shift;
  my $param = shift;
  my $msg = pop;

  state $ajax = sub {
    return 'r.open("POST",' . quote($_[0]) . ');v=true';
  };

  my $js = '';

  # Confirmation
  if ($param->{ok} || $param->{cancel}) {

    $js .= 'var x=' . quote($c->csrf_token) . ';' if $c;

    # Set labels
    if ($param->{ok_label} || $param->{cancel_label}) {
      $js .= 'alertify.set({labels:{';
      $js .= 'ok:'.quote($param->{ok_label} // 'OK') . ',' ;
      $js .= 'cancel:'.quote($param->{cancel_label} // 'Cancel');
      $js .= "}});\n";
    };

    # Create confirmation
    $js .= 'alertify.confirm(' . quote($msg);
    $js .= ',function(ok){';
    $js .= 'var r=new XMLHttpRequest();var v;';

    if ($param->{ok} && $param->{cancel}) {
      $js .= 'if(ok){'. $ajax->($param->{ok}) .
        '}else{' . $ajax->($param->{cancel}) . '};';
    }
    elsif ($param->{ok}) {
      $js .= 'if(ok){' . $ajax->($param->{ok}) . '};';
    }
    else {
      $js .= 'if(!ok){' . $ajax->($param->{cancel}) . '};';
    };
    $js .= 'if(v){';
    $js .= 'r.setRequestHeader("Content-type","application/x-www-form-urlencoded");';
    $js .= 'r.send("csrf_token="+x);' if $c;

    # Alert if callback fails to respond
    $js .= 'r.onreadystatechange=function(){' .
      'if(this.readyState==4&&this.status!==200){' .
      'alertify.log(this.status?this.status+": "+this.statusText:"Connection Error",'.
      '"error")}}';

    $js .= '}},' . quote('notify notify-' . $type) . ");\n";
  }

  # Normal alert
  else {
    $js .= 'alertify.log(' . quote($msg);
    $js .= ',' . quote($type) . ',';
    $js .= $param->{timeout};
    $js .= ");\n";
  };
  return $js;
};


# Notification method
sub notifications {
  my ($self, $c, $notify_array, $rule, @post) = @_;

  return unless $notify_array->size;

  my $theme = shift @post // $self->base_class;

  my $js = '';
  unless ($rule->{no_include}) {
    $js .= $c->javascript( $self->scripts );

    unless ($rule->{no_css}) {
      $js .= $c->stylesheet( ($self->styles)[0] );
      $js .= $c->stylesheet( $path . 'alertify.' . $theme . '.css');
    };
  };

  # Start JavaScript snippet
  $js .= qq{<script>//<![CDATA[\n};

  my $noscript = "<noscript>";

  my $csrf = $c->csrf_token;

  # Add notifications
  foreach (@$notify_array) {

    # Set timeout
    # There is a parameter hash
    if (ref $_->[1] && ref $_->[1] eq 'HASH') {
      $_->[1]->{timeout} //= $self->base_timeout
    }

    # There is no parameter
    else {
      splice(@$_, 1, 0, { timeout => $self->base_timeout })
    };
    $js .= notify_alertify($c, @$_);
    $noscript .= notify_html($c, @$_);
  };

  return b($js . "//]]>\n</script>\n" . $noscript . '</noscript>');
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Notifications::Alertify - Event notifications using Alertify.js


=head1 SYNOPSIS

  # Register the engine
  plugin Notifications => {
    Alertify => {
      base_class => 'bootstrap'
    }
  };

  # In the template
  %= notifications 'Alertify'


=head1 DESCRIPTION

This plugin is a notification engine using
L<Alertify.js|http://fabien-d.github.io/alertify.js/>.

If this does not suit your needs, you can easily
L<write your own engine|Mojolicious::Plugin::Notifications::Engine>.


=head1 METHODS

L<Mojolicious::Plugin::Notifications::Alertify> inherits all methods
from L<Mojolicious::Plugin::Notifications::Engine> and implements or overrides
the following.

=head2 register

  plugin Notifications => {
    Alertify => {
       base_class => 'bootstrap'
    }
  };

Called when registering the main plugin.
All parameters under the key C<Alertify> are passed to the registration.

Accepts the following parameters:

=over 4

=item B<base_class>

The theme for all alertify notifications.
Defaults to C<bootstrap>. See the
L<Alertify.js documentation|https://github.com/fabien-d/alertify.js>
for more information on themes.


=item B<base_timeout>

The base timeout for all alertify notifications. Defaults to C<5000 ms>.
Set to C<0> for no timeout.

=back


=head1 HELPERS

=head2 notify

  # In controllers
  $c->notify(warn => 'Something went wrong');
  $c->notify(success => { timeout => 2000 } => 'Everything went fine');
  $c->notify(success => { ok => 'http://example.com/ok' } => 'Everything went fine');

Notify the user on certain events.

See the documentation for your chosen theme
at L<Alertify.js|http://fabien-d.github.io/alertify.js/> to see,
which notification types are presupported.

In addition to types and messages, the C<timeout> can be defined
in a hash reference.

In case an C<ok> or C<cancel> parameter is passed, this will create a confirmation
notification. The C<ok> and C<cancel> URLs will receive a POST request,
once the buttons are pressed.
In case an C<ok_label> is passed, this will be the label
for the confirmation button.
In case a C<cancel_label> is passed, this will be the label
for the cancelation button.
The POST will have a L<csrf_token|Mojolicious::Plugin::TagHelpers/csrf_token>
parameter to validate.

B<Confirmation is EXPERIMENTAL!>


=head2 notifications

  # In templates
  %= notifications 'alertify';
  %= notifications 'alertify', 'bootstrap', -no_include, -no_css

Include alertify notifications in your template.

If you want to use a class different to the defined base class, you can
pass this as a string attribute.

If you don't want to include the javascript and css assets for C<Alertify.js>,
append C<-no_include>. If you just don't want to render the
stylesheet tag for the inclusion of the CSS, append C<-no_css>.

All notifications are also rendered in a C<E<lt>noscript /E<gt>> tag,
following the notation described in the
L<HTML|Mojolicious::Plugin::Notifications::HTML> engine.


=head1 EXPORTABLE FUNCTIONS

=head2 notify_alertify

  use Mojolicious::Plugin::Notifications::Alertify qw/notify_alertify/;

  notify_alertify(warn => { timeout => 5000 } => 'This is a warning')
  # alertify.log("This is a warning","warn",5000);

Returns the notification as an L<Alertify.js|http://fabien-d.github.io/alertify.js/>
JavaScript snippet.

Accepts the controller as an optional first parameter,
the notification type, a hash reference with parameters,
and the message. In case the parameters include C<ok> or C<cancel> routes,
a confirmation notification is used.

If the first parameter is a L<Mojolicious::Controller> object,
and the notification is a confirmation, the requests will have
a L<csrf_token|Mojolicious::Plugin::TagHelpers/csrf_token>
parameter to validate.

B<Confirmation is EXPERIMENTAL!>


=head1 SEE ALSO

L<Alertify.js|http://fabien-d.github.io/alertify.js/>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Notifications


=head1 COPYRIGHT AND LICENSE

=head2 Mojolicious::Plugin::Notifications::Alertify

Copyright (C) 2014-2018, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.


=head2 Alertify.js (bundled)

Copyright (c) Fabien Doiron

See L<https://github.com/fabien-d/alertify.js> for further information.

Licensed under the terms of the
L<MIT License|http://opensource.org/licenses/MIT>.

=cut
