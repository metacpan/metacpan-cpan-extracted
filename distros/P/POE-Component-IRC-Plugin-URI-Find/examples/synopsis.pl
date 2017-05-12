  use strict;
  use warnings;
  use blib;
  use POE qw(Component::IRC Component::IRC::Plugin::URI::Find);
  use Data::Dumper;

  my $nickname = 'UriFind' . $$;
  my $ircname = 'UriFind the Sailor Bot';
  my $ircserver = 'irc.perl.org';
  my $port = 6667;
  my $channel = '#IRC.pm';

  my $irc = POE::Component::IRC->spawn(
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
        debug => 0,
        plugin_debug => 1,
        options => { trace => 0 },
  ) or die "Oh noooo! $!";

  POE::Session->create(
        package_states => [
                'main' => [ qw(_start irc_001 irc_urifind_uri) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our plugin
    $irc->plugin_add( 'UriFind' =>
        POE::Component::IRC::Plugin::URI::Find->new() );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

  sub irc_urifind_uri {
    my @data = @_[ARG0..ARG4];
    print Dumper( \@data );
    undef;
  }
