package Mojolicious::Plugin::Message::Locale;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

sub register {
    my ($self, $app, $conf) = @_;

    $conf->{default_message} ||= '';
    $conf->{locale}          ||= 'en';
    $conf->{file}            ||= 'locale.conf';

    my $messages = $app->plugin('Config', { file => $conf->{file} } );

    $app->helper ( set_locale => sub {
        my ($c, $loc,) = @_;
	$conf->{locale} = $loc ? $loc : 'en';
    });

    $app->helper ( locale => sub {
        my ($c, $key, $group,) = @_;
	unless ( $key ) {
	    warn 'key is undefined or incorrenct.';
            return $conf->{default_message};
        }
	$group ||= 'common';

        if ( exists $messages->{$group}->{$key}->{$conf->{locale}} ) {
            $messages->{$group}->{$key}->{$conf->{locale}};
	} elsif ( exists $messages->{'common'}->{$key}->{$conf->{locale}} ) {
	    $messages->{'common'}->{$key}->{$conf->{locale}}
	} else {
	    $conf->{default_message};
        }
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Message::Locale - Mojolicious Plugin

=head1 SYNOPSIS

  # locale.conf
  {
      common => {
          title => { en => 'TITLE', ja => 'タイトル' },
          message => { en => 'MESSAGE', ja => 'メッセージ' }
      },
      original => {
          message => { en => 'OROGINAL MESSAGE', ja => 'オリジナル' }
      }
  }

  # Mojolicious
  $self->plugin('Message::Locale', {
      default_message => '',
      locale => 'en',
      file => 'locale.conf',
  });
  # same $self->plugin('Message::Locale');

  $self->locale('message', 'common'); # MESSAGE
  $self->locale('message', 'original'); # ORIGINAL MESSAGE

  $self->set_locale('ja');
  $self->locale('title');   # タイトル
  $self->locale('message', 'original'); # オリジナル

  $self->set_locale('en');
  $self->locale('title');   # TITLE
  $self->locale('title', 'original'); # TITLE

  # template   .html.ep
  <%= locale "title" %>
  <%= locale "title", "original" %>
  <%= locale "message" %>
  <%= locale "message", "original" %>

=head1 DESCRIPTION

L<Mojolicious::Plugin::Message::Locale> is a plugin for Mojolicious apps to localize messages using L<Mojolicious::Plugin::Config>

=head1 METHODS

L<Mojolicious::Plugin::Message::Locale> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register($app, $conf);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious>.

=head1 AUTHOR

Kei Shimada C<< <sasakure_kei __at__ cpan.org> >>

=head1 REPOSITORY

  git clone git@github.com:sasakure-kei/p5-Mojolicious-Plugin-Message-Locale.git

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Kei Shimada C<< <sasakure_kei __at__ cpan.org> >>. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
