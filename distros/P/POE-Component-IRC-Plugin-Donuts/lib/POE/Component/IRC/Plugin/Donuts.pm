package POE::Component::IRC::Plugin::Donuts;

use 5.008_005;
use WWW::KrispyKreme::HotLight;
use IRC::Utils qw(parse_user);
use Carp::POE qw(croak);

our $VERSION = '0.07';

use POE::Component::IRC::Plugin qw( :ALL );

our @channels;

sub new {
    my ($class, %args) = @_;
    croak 'must supply geo as array ref i.e. ->new(geo => [35.045556,-85.267222])'
      unless $args{geo}
          and ref $args{geo}
          and ref $args{geo} eq 'ARRAY';
    $args{ping} = 0;
    return bless \%args, $class;
}

# list events we are interested in
sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;
    $irc->plugin_register($self, 'SERVER', qw(join ping));
    return 1;
}

# This is method is mandatory but we don't actually have anything to do.
sub PCI_unregister {
    return 1;
}

# trigger a donut search when:
# -we join a channel
# -we are pinged by the server (every 20 times)
sub S_join {
    my ($self, $irc) = splice @_, 0, 2;
    my $joiner  = parse_user(${$_[0]});
    my $nick    = $irc->{nick};
    my $channel = ${$_[1]};
    push @channels, $channel;
    return $joiner eq $nick ? $self->_donuts($channel, $irc) : PCI_EAT_NONE;
}

sub S_ping {
    my ($self, $irc) = splice @_, 0, 2;
    $self->{ping}++;

    # ping interval on freenode is ~2 mins
    my $ready = $self->{ping} % 20 == 0;

    return PCI_EAT_NONE unless @channels and $ready;
    return $self->_donuts($_, $irc) for @channels;
}

sub _donuts {
    my ($self, $channel, $irc) = @_;

    my $donuts = WWW::KrispyKreme::HotLight->new(where => $self->{geo})->locations;
    my $stores = join ', ', map $_->{title}, grep $_->{hotLightOn}, @$donuts;
    $irc->yield(    #
        privmsg => $channel =>
          "Fresh donuts available at the following Kripsy Kreme locations: $stores"
    ) if $stores;
    return PCI_EAT_PLUGIN;
}

1;
__END__

=encoding utf-8

=head1 NAME

POE::Component::IRC::Plugin::Donuts - IRC Plugin
to announce when there are fresh donuts in the area!

=head1 SYNOPSIS

  use POE::Component::IRC::Plugin::Donuts;

  use strict;
  use warnings;

  use POE qw(
    Component::IRC
    Component::IRC::Plugin::Donuts
  );

  my $nick    = 'donut_bot';
  my $ircname = 'the donut bot';
  my $server  = 'irc.foobar';

  my @channels = ('#coffee');

  my $irc = POE::Component::IRC->spawn(
      nick    => $nick,
      ircname => $ircname,
      server  => $server
  ) or die "oops... $!";

  POE::Session->create(
      package_states => [main => [qw(_start irc_001)],],
      heap           => {irc  => $irc},
  );

  $poe_kernel->run;

  sub _start {
      my $heap = $_[HEAP];

      my $irc = $heap->{irc};
      $irc->yield(register => 'all');

      $irc->plugin_add(
          Donuts => POE::Component::IRC::Plugin::Donuts->new(    #
              geo => [34.101509, -118.32691]
          )
      );

      $irc->yield(connect  => {});
      return;
  }

  sub irc_001 {
      $irc->yield(join => $_) for @channels;
      return;
  }

=head1 CONSTRUCTOR

  $irc->plugin_add(
      Donuts => POE::Component::IRC::Plugin::Donuts->new(    #
          geo => [34.101509, -118.32691]
      )
  );

The geo attribute is REQUIRED.  See L<WWW::KrispyKreme::HotLight> for more info

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Donuts is an IRC
plugin that announces when there are fresh Krispy Kreme donuts near
the given location

=head1 SEE ALSO

L<WWW::KrispyKreme::HotLight>

L<POE::Component::IRC::Plugin>

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Curtis Brandt

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
