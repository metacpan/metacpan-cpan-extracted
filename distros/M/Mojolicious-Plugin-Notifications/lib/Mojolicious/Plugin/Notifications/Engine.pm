package Mojolicious::Plugin::Notifications::Engine;
use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw/blessed/;

# Register the plugin - optional
sub register {
  # Nothing to register - but has to be called
};


# scripts attribute
sub scripts {
  $_[0]->{scripts} //= [];
  return @{$_[0]->{scripts}} if @_ == 1;
  push(@{shift->{scripts}}, @_);
};


# styles atttribute
sub styles {
  $_[0]->{styles} //= [];
  return @{$_[0]->{styles}} if @_ == 1;
  push(@{shift->{styles}}, @_);
};


# notifications method
sub notifications {
  my $self = shift;
  state $msg = 'No notification engine specified';
  $self->app->log->error($msg . ' for ' . blessed $self);
  return $msg;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Notifications::Engine - Abstract Class for Notification Engines


=head1 SYNOPSIS

  package Mojolicious::Plugin::Notifications::MyEngine;
  use Mojo::Base 'Mojolicious::Plugin::Notifications::Engine';

  # Define notifications helper
  sub notifications {
    my ($self, $c, $notifications) = @_;

    my $string = '';
    foreach (@$notifications) {
      $string .= '<blink class="' . $_->[0] . '">' . $_->[-1] . '</blink>';
    };
    return $c->b($string);
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Notifications::Engine> is an abstract class
for creating notification engines. It is meant to be used as the base
of notification engine classes.


=head1 METHODS

L<Mojolicious::Plugin::Notifications::Engine> inherits all methods
from L<Mojolicious::Plugin> and implements the following new ones.


=head2 register

  sub register {
    my ($self, $app, $param) = @_;
    # ...
  };

Called when the engine is L<registered|Mojolicious::Plugin::Notifications/register>.
This by default does nothing, but the engine may define assets, helpers, hooks etc.
overriding this method.
The optional parameter will be passed as defined in the registration.


=head2 scripts

  $self->scripts('/mybasescript.js', '/myscript.js');
  print $self->scripts;

Add further script assets, to be used by the
L<scripts|Mojolicious::Plugin::Notifications::Assets/scripts> helper.


=head2 styles

  $self->styles('/mystyles.css', '/mycolors.css');
  print $self->styles;

Add further style assets, to be used by the
L<styles|Mojolicious::Plugin::Notifications::Assets/styles> helper.


=head2 notifications

  # Define notifications method
  sub notifications {
    my ($self, $c, $notifications) = @_;

    my $string = '';
    foreach my $note (@$notifications) {
      $string .= '<blink class="' . $note->[0] . '">' . $note->[-1] . '</blink>';
    };
    return $c->b($string);
  };

Create a notification method.

The C<notifications> method will be called whenever notifications are rendered.
The first parameter passed is the plugin object, the second parameter is the current
controller object and the third parameter is a L<Mojo::Collection> object containing all
notifications as array references.

The first element of the notification is the
notification type, the last element is the message. An optional second element may
contain further parameters in a hash reference.

To support confirmations, it is necessary to support the parameters C<ok> and C<cancel>.
If not, it is recommended to log a warning, that confirmations are not supported
by the engine.

  %= notifications 'MyEngine', -no_include

Possible flags (boolean parameters marked with a dash) are passed as a hash reference.
All other parameters passed to the L<notifications> helper are simply appended.

The L<bundled engines|Mojolicious::Plugin::Notifications/Bundled engines> can serve as good examples on how
to write an engine, especially the simple
L<HTML|Mojolicious::Plugin::Notifications::HTML> engine.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Notifications


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2018, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
