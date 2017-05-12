package POE::Component::IRC::Plugin::WWW::Weather::US;

use 5.010;
use strict;
use warnings;

use POE::Component::IRC::Plugin qw( :ALL );
use Mojo::UserAgent;
use Cache::Memory::Simple;

our $VERSION = '0.04';

sub new {
    my $class = shift;
    my $self  = bless {
        cache => Cache::Memory::Simple->new,
    }, $class;
    return $self;
}

sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;

    $irc->plugin_register($self, 'SERVER', qw(public));
    return 1;
}

# This is method is mandatory but we don't actually have anything to do.
sub PCI_unregister {
    return 1;
}

sub S_public {
    my ($self, $irc) = splice @_, 0, 2;

    # Parameters are passed as scalar-refs including arrayrefs.
    my $nick    = (split /!/, ${$_[0]})[0];
    my $channel = ${$_[1]}->[0];
    my $msg     = ${$_[2]};

    if (my ($zip) = $msg =~ /^!weather\s+(\d{5})/i) {
        my $reply = $self->_get_weather($zip);
        $irc->yield(privmsg => $channel => "$nick: $reply") if $reply;
        return PCI_EAT_PLUGIN;
    }

    # Default action is to allow other plugins to process it.
    return PCI_EAT_NONE;
}

# the link I use for zip redirects, so set max_redirects to 1
sub _get_weather {
    my ($self, $zip) = @_ or return;
    $self->{cache}->purge(); # purge any expired items
    return $self->{cache}->get_or_set(
        $zip,
        sub {
            Mojo::UserAgent->new->max_redirects(1)
              ->get("http://forecast.weather.gov/zipcity.php?inputstring=$zip")
              ->res->dom->find('.point-forecast-7-day .row-odd')
              ->map(sub { $_->find('span')->pluck('text') . ': ' . $_->text })->[0];
        },
        3600 # cache for 1 hour
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

POE::Component::IRC::Plugin::WWW::Weather::US - IRC plugin that fetches US weather by zip code

=head1 SYNOPSIS

  use strict;
  use warnings;

  use POE qw(Component::IRC  Component::IRC::Plugin::WWW::Weather::US);

  my $irc = POE::Component::IRC->spawn(
      nick    => 'nickname',
      server  => 'irc.freenode.net',
      port    => 6667,
      ircname => 'ircname',
  );

  POE::Session->create(package_states => [main => [qw(_start irc_001)]]);

  $poe_kernel->run;

  sub _start {
      $irc->yield(register => 'all');

      $irc->plugin_add(Weather => POE::Component::IRC::Plugin::WWW::Weather::US->new);

      $irc->yield(connect => {});
  }

  sub irc_001 {
      $irc->yield(join => '#channel');
  }

=head1 DESCRIPTION

type !weather 91202 to get the current weather for a location, currenly fetched from L<http://forecast.weather.gov/zipcity.php>

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Curtis Brandt

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
