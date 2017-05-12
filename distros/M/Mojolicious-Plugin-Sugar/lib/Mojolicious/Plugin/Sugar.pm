package Mojolicious::Plugin::Sugar;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw(reftype);
use Data::Types qw(is_string);

our $VERSION = '0.002';

# ABSTRACT: Some sweet stuff for Mojolicious

sub register {
  my ( $self, $app ) = @_;

  $app->helper(
    'flash_add_to' => sub {
      my $c = shift;
      my $session = $c->session;

      # Initialize new flash and merge values
      my $flash = $session->{new_flash} ||= {};

      if ( @_ > 1 && is_string($_[0]) ) {
        my $key = shift;

        my $current_value = $flash->{$key};

        if ( defined $current_value && reftype($current_value) ne 'ARRAY' ) {
          $current_value = [ $current_value ];
        }

        foreach my $value (@_) {
          push @{ $current_value }, $value;
        }

        $flash->{$key} = $current_value;
      }
    }
  );

  $app->helper(
    'params' => sub {
      return shift->req->params;
    }
  );
}

1;


__END__
=pod

=head1 NAME

Mojolicious::Plugin::Sugar - Some sweet stuff for Mojolicious

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Sugar');

    # Mojolicious::Lite
    plugin 'Sugar';

    # To add more than one flash values, for messages, for example.
    $self->flash_add_to( 'messages' => 'message one' );
    $self->flash_add_to( 'messages' => 'message two' );
    $self->flash_add_to( 'messages' => 'message three', 'message four' );
    $self->redirect_to( '/list' );

    @@ list.html.ep
    % foreach my $msg ( @{ flash messages } ) {
    <li><%= $msg %>
    % }

    # Shortcut to process HTML::FormHandler form 
    my $form = MyApp::Form::Add->new;
    $form->process( $self->params->to_hash );

    if ($form->validated) {
      [...]
    }
    else {
      [...]
    }

=head1 DESCRIPTION

L<Mojolicious::Plugin::Sugar> is a L<Mojolicious> plugin that adds few convenience helpers.

=head1 NAME

Mojolicious::Plugin::Sugar - sugary helpers for your Mojolicious app

=head1 HELPERS

=head2 C<flash_add_to>

    $self->flash_add_to( 'messages' => 'message one' );
    $self->flash_add_to( 'messages' => 'message two' );

This helper allow you to add multiple values into flash variables. It creates referenced array 
when first called and all next calls will add additional elements into this array. Later
in your template you can do something like this:

    @@ list.html.ep
    % foreach my $msg ( @{ flash messages } ) {
    <li><%= $msg %>
    % }

You can also specify more than one value in one call:

    $self->flash_add_to( 'messages' => 'message three', 'message four' );

To overwrite flash variable simply use standard $self->flash() call.

=head1 AUTHOR

Pavel A. Karoukin <pavel@karoukin.us>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/hippich/perl-mojolicious-plugin-sugar>

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Pavel A. Karoukin <pavel@karoukin.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Pavel A. Karoukin <pavel@karoukin.us>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

