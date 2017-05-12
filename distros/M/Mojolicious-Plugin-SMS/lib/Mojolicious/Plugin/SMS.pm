package Mojolicious::Plugin::SMS;
use Mojo::Base 'Mojolicious::Plugin';
use SMS::Send;

our $VERSION = '0.02';

sub register {
  my ($self, $app, $conf) = @_;
  $conf ||= {};
  $conf->{driver} = delete $conf->{driver};
  my $sms_send = SMS::Send->new($conf->{driver}, %$conf);

  $app->helper(
    sms => sub {
      my $self = shift;
      my %params;
      if (@_ == 2) {
          @params{qw(to text)} = @_;
      } elsif (@_ > 2 && @_ % 2 == 0) {
          %params = @_;
      } else {
          die "Invalid params passed to sms helper!";
      }
      return $sms_send->send_sms(%params);
    }
  );
}

1;

=head1 NAME

Mojolicious::Plugin::SMS - Easy SMS sending from Mojolicious apps

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'SMS' => {
    driver    => 'Test'
  };

  # Mojolicious
  $self->plugin(SMS => {
    driver    => 'Nexmo',
    _username => 'testuser',
    _password => 'testpassword'
    _from     => 'Bender'
  });

  # in controller named params
  $self->sms(
    to   => '+380506022375',
    text => 'use Perl or die;'
  );

  # in controller positional params
  $self->sms('+380506022375', 'use Perl or die;');

=head1 DESCRIPTION

Provides a quick and easy way to send SMS messages using L<SMS::Send> drivers
(of which there are many, so chances are the service you want to use is already
supported; if not, they're easy to write, and if you want to change providers
later, you can simply update a few lines in your config file, and you're done.

=head1 OPTIONS

L<Mojolicious::Plusin::SMS> has one required option 'driver', all other options
are passed to appropriate L<SMS::Send> driver.

=head2 C<driver>

L<SMS::Send> driver name. This is a required option. You may specify 'Test' if
you need a testing driver.

=head1 HELPERS

L<Mojolicious::Plugin::SMS> implements one helper.

=head2 sms

Send an SMS message.  You can pass the destination and message as positional
params:

    sms $to, $message;

Or, you can use named params:

    sms to => $to, text => $message;

The latter form may be clearer, and would allow any additional driver-specific
parameters to be passed too, but the former is terser.  The choice is yours.

=head1 METHODS

L<Mojolicious::Plugin::SMS> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 C<register>

$plugin->register;

Register plugin hooks and helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<SMS::Send>, L<SMS::Send::Test>.

=head1 AUTHOR

Yuriy Syrota <ysyrota@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 by Yuriy Syrota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
